import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../../features/auth/data/token_store.dart';
import '../network/api_client.dart';

/// Subscription tiers for in-app purchases
enum SubscriptionTier { monthly, quarterly, yearly }

/// Service for handling in-app purchases
/// Uses mock purchases for development, can be toggled to real IAP
class PurchaseService {
  PurchaseService({
    required ApiClient client,
    required TokenStore tokenStore,
  })  : _client = client,
        _tokenStore = tokenStore;

  final ApiClient _client;
  final TokenStore _tokenStore;
  late final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  // Timeout values used during the purchase flow.
  static const Duration _purchaseStreamFallbackDuration = Duration(seconds: 12);
  static const Duration _overallPurchaseTimeout = Duration(minutes: 2);
  static const Duration _receiptVerificationTimeout = Duration(seconds: 30);

  /// Subscription ID for Android.
  ///
  /// Google Play Billing treats the subscription itself as the "product" (the
  /// product ID), and the monthly/quarterly/yearly options are represented as
  /// base plans / offers under that subscription. That means querying for
  /// "monthly" / "quarterly" / "yearly" directly will return nothing on
  /// Android.
  static const String androidSubscriptionId = 'discovery_unlock_forever';

  /// Base product IDs (used on platforms that treat each tier as a separate
  /// product, such as iOS).
  static const String monthlyProductId = 'monthly';
  static const String quarterlyProductId = 'quarterly';
  static const String yearlyProductId = 'yearly';

  Future<Map<String, String>> _authHeaders() async {
    final String? token = await _tokenStore.readToken();
    if (token == null || token.isEmpty) {
      throw Exception('No access token available');
    }
    return <String, String>{
      'Authorization': 'Bearer $token',
    };
  }

  Future<bool> _verifyPurchase(
    PurchaseDetails purchase, {
    String? productId,
  }) async {
    return verifyReceipt(
      platform: _platformName(),
      receipt: purchase.verificationData.serverVerificationData,
      productId: productId ?? purchase.productID,
    );
  }

  Future<PurchaseDetails?> _findPurchasedSubscriptionInPastPurchases(
    String productId,
  ) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }

    final InAppPurchaseAndroidPlatformAddition androidAddition = InAppPurchase
        .instance
        .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();

    final QueryPurchaseDetailsResponse pastPurchases =
        await androidAddition.queryPastPurchases();

    if (pastPurchases.error != null) {
      debugPrint('queryPastPurchases error: ${pastPurchases.error}');
      return null;
    }

    for (final PurchaseDetails p in pastPurchases.pastPurchases) {
      if (p.productID == productId &&
          (p.status == PurchaseStatus.purchased ||
              p.status == PurchaseStatus.restored)) {
        return p;
      }
    }

    return null;
  }

  /// Get the appropriate product ID based on platform and tier.
  ///
  /// Google Play expects the *subscription* ID (e.g. `discovery_unlock_forever`),
  /// while iOS expects each tier to be its own product ID.
  String _getProductId({SubscriptionTier tier = SubscriptionTier.monthly}) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return androidSubscriptionId;
    }

    switch (tier) {
      case SubscriptionTier.monthly:
        return monthlyProductId;
      case SubscriptionTier.quarterly:
        return quarterlyProductId;
      case SubscriptionTier.yearly:
        return yearlyProductId;
    }
  }

  /// Purchase discovery game access
  /// Returns true if purchase was successful
  Future<bool> purchaseDiscovery({
    SubscriptionTier tier = SubscriptionTier.monthly,
  }) async {
    final String productId = _getProductId(tier: tier);
    return _completePurchase(productId);
  }

  /// Purchase a subscription (primarily for iOS)
  /// Allows explicit tier selection
  Future<bool> purchaseSubscription(SubscriptionTier tier) async {
    final String productId = _getProductId(tier: tier);
    return _completePurchase(productId);
  }

  /// Internal method to complete a purchase for a given product ID
  Future<bool> _completePurchase(String productId) async {
    final bool storeAvailable = await _inAppPurchase.isAvailable();
    if (!storeAvailable) {
      debugPrint('In-app purchase store is unavailable');
      return false;
    }

    final ProductDetailsResponse response =
        await _inAppPurchase.queryProductDetails(<String>{productId});

    if (response.error != null || response.productDetails.isEmpty) {
      debugPrint(
        'Could not load product details: '
        'error=${response.error}, '
        'notFoundIds=${response.notFoundIDs}, '
        'foundCount=${response.productDetails.length}',
      );
      return false;
    }

    final ProductDetails product = response.productDetails.first;
    final Completer<bool> resultCompleter = Completer<bool>();

    Timer? fallbackTimer;
    void cancelFallbackTimer() {
      if (fallbackTimer?.isActive ?? false) {
        fallbackTimer?.cancel();
      }
    }

    late final StreamSubscription<List<PurchaseDetails>> subscription;
    subscription = _inAppPurchase.purchaseStream.listen(
      (List<PurchaseDetails> purchases) async {
        for (final PurchaseDetails purchase in purchases) {
          debugPrint(
              'Received purchase update: ${purchase.productID} (${purchase.status}) [${purchase.verificationData}]');
          if (purchase.productID != productId) {
            continue;
          }

          if (purchase.status == PurchaseStatus.pending) {
            continue;
          }

          if (purchase.status == PurchaseStatus.purchased ||
              purchase.status == PurchaseStatus.restored) {
            final bool verified = await _verifyPurchase(
              purchase,
              productId: productId,
            );

            if (!resultCompleter.isCompleted) {
              resultCompleter.complete(verified);
              cancelFallbackTimer();
            }
          } else {
            if (!resultCompleter.isCompleted) {
              resultCompleter.complete(false);
              cancelFallbackTimer();
            }
          }

          if (purchase.pendingCompletePurchase) {
            await _inAppPurchase.completePurchase(purchase);
          }
        }
      },
      onError: (Object error) {
        debugPrint('Purchase stream error: $error');
        if (!resultCompleter.isCompleted) {
          resultCompleter.complete(false);
          cancelFallbackTimer();
        }
      },
    );

    final bool purchaseStarted = await _inAppPurchase.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
    if (!purchaseStarted) {
      await subscription.cancel();
      return false;
    }

    // If the store does not emit a purchase update (e.g. "Already subscribed"),
    // query past purchases as a fallback so we don't hang indefinitely.
    fallbackTimer = Timer(_purchaseStreamFallbackDuration, () async {
      if (resultCompleter.isCompleted) {
        return;
      }

      debugPrint(
        'No purchase update received after ${_purchaseStreamFallbackDuration.inSeconds}s; querying past purchases.',
      );

      try {
        final PurchaseDetails? owned =
            await _findPurchasedSubscriptionInPastPurchases(productId);
        if (owned != null) {
          final bool verified =
              await _verifyPurchase(owned, productId: productId);
          if (!resultCompleter.isCompleted) {
            resultCompleter.complete(verified);
          }
          return;
        }
      } catch (e) {
        debugPrint('Fallback queryPastPurchases failed: $e');
      }

      if (!resultCompleter.isCompleted) {
        resultCompleter.complete(false);
      }
    });

    try {
      return await resultCompleter.future.timeout(
        _overallPurchaseTimeout,
        onTimeout: () => false,
      );
    } finally {
      cancelFallbackTimer();
      await subscription.cancel();
    }
  }

  /// Restore previous purchases.
  ///
  /// Returns a user-friendly message indicating if a subscription was restored.
  Future<String> restorePurchases() async {
    try {
      final bool storeAvailable = await _inAppPurchase.isAvailable();
      debugPrint('Restoring purchases, store available: $storeAvailable');

      if (!storeAvailable) {
        debugPrint('In-app purchase store is unavailable');
        return 'App store is not available. Please try again later.';
      }

      final Completer<String> resultCompleter = Completer<String>();
      Timer? timeoutTimer;

      void completeOnce(String message) {
        if (!resultCompleter.isCompleted) {
          resultCompleter.complete(message);
        }
      }

      late final StreamSubscription<List<PurchaseDetails>> subscription;
      subscription = _inAppPurchase.purchaseStream.listen(
        (List<PurchaseDetails> purchases) async {
          for (final PurchaseDetails purchase in purchases) {
            debugPrint(
                'Received purchase update: ${purchase.productID} (${purchase.status}) [${purchase.verificationData}]');
            if (purchase.status != PurchaseStatus.restored) {
              continue;
            }

            // Verify restored purchase
            final bool verified = await _verifyPurchase(purchase);

            if (verified) {
              completeOnce(
                  'Restore completed. Your subscription has been restored.');
              break;
            }
          }
        },
        onError: (Object error) {
          debugPrint('Restore purchase stream error: $error');
        },
      );

      // Trigger platform restore
      await _inAppPurchase.restorePurchases();

      // If no restored purchase arrives, fall back to querying past purchases.
      timeoutTimer = Timer(const Duration(seconds: 12), () async {
        try {
          if (resultCompleter.isCompleted) return;

          if (defaultTargetPlatform == TargetPlatform.android) {
            final InAppPurchaseAndroidPlatformAddition androidAddition =
                InAppPurchase.instance.getPlatformAddition<
                    InAppPurchaseAndroidPlatformAddition>();

            final QueryPurchaseDetailsResponse pastPurchases =
                await androidAddition.queryPastPurchases();

            if (pastPurchases.error != null) {
              debugPrint('queryPastPurchases error: ${pastPurchases.error}');
            } else {
              // If any restored/purchased subscription exists, treat as success.
              PurchaseDetails? owned;
              for (final PurchaseDetails p in pastPurchases.pastPurchases) {
                if ((p.status == PurchaseStatus.purchased ||
                        p.status == PurchaseStatus.restored) &&
                    p.productID == androidSubscriptionId) {
                  owned = p;
                  break;
                }
              }

              if (owned != null) {
                final bool verified = await verifyReceipt(
                  platform: _platformName(),
                  receipt: owned.verificationData.serverVerificationData,
                  productId: owned.productID,
                );

                if (verified) {
                  completeOnce(
                      'Restore completed. Your subscription has been restored.');
                  return;
                }
              }
            }
          }
        } catch (e) {
          debugPrint('Fallback restore queryPastPurchases failed: $e');
        }

        if (!resultCompleter.isCompleted) {
          completeOnce('No active subscription was found.');
        }
      });

      final String result = await resultCompleter.future.timeout(
        const Duration(seconds: 20),
        onTimeout: () => 'Restore did not complete. Please try again.',
      );

      timeoutTimer.cancel();
      await subscription.cancel();

      return result;
    } catch (e) {
      debugPrint('Restore purchases failed: $e');
      return 'Failed to restore purchases. Please try again.';
    }
  }

  String _platformName() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return 'unknown';
    }
  }

  /// Get available subscription products for the current platform
  /// Returns product details that can be used to display pricing info in UI
  Future<List<ProductDetails>> getAvailableProducts() async {
    final bool storeAvailable = await _inAppPurchase.isAvailable();
    if (!storeAvailable) {
      debugPrint('In-app purchase store is unavailable');
      return <ProductDetails>[];
    }

    final Set<String> productIds;

    // Android requires the subscription product ID (not the base plan IDs).
    // For other platforms (e.g. iOS) we still query the per-tier product IDs.
    if (defaultTargetPlatform == TargetPlatform.android) {
      productIds = <String>{androidSubscriptionId};
    } else {
      productIds = <String>{
        monthlyProductId,
        quarterlyProductId,
        yearlyProductId,
      };
    }

    final ProductDetailsResponse response =
        await _inAppPurchase.queryProductDetails(productIds);

    if (response.error != null || response.productDetails.isEmpty) {
      debugPrint(
        'Error loading products: '
        'error=${response.error}, '
        'notFoundIds=${response.notFoundIDs}, '
        'foundCount=${response.productDetails.length}',
      );
      return <ProductDetails>[];
    }

    return response.productDetails;
  }

  /// Verify a purchase receipt with the backend.
  ///
  /// Network issues or server delays should not block the purchase flow
  /// indefinitely, so we use a timeout here.
  Future<bool> verifyReceipt({
    required String platform,
    required String receipt,
    required String productId,
  }) async {
    try {
      final Map<String, dynamic> response = await _client
          .postJson(
        '/purchases/verify',
        body: <String, dynamic>{
          'platform': platform,
          'receipt': receipt,
          'productId': productId,
        },
        headers: await _authHeaders(),
      )
          .timeout(
        _receiptVerificationTimeout,
        onTimeout: () {
          debugPrint('Receipt verification timed out');
          return <String, dynamic>{'success': false};
        },
      );

      return response['success'] == true;
    } catch (e) {
      debugPrint('Receipt verification failed: $e');
      return false;
    }
  }
}
