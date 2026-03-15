import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

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
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  /// Base product IDs (used when _useSameProductIdsAcrossPlatforms is true)
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

  /// Get the appropriate product ID based on platform and tier
  String _getProductId({SubscriptionTier tier = SubscriptionTier.monthly}) {
    // If using same IDs across platforms, return base product IDs
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
      debugPrint('Could not load product details: ${response.error}');
      return false;
    }

    final ProductDetails product = response.productDetails.first;
    final Completer<bool> resultCompleter = Completer<bool>();

    late final StreamSubscription<List<PurchaseDetails>> subscription;
    subscription = _inAppPurchase.purchaseStream.listen(
      (List<PurchaseDetails> purchases) async {
        for (final PurchaseDetails purchase in purchases) {
          if (purchase.productID != productId) {
            continue;
          }

          if (purchase.status == PurchaseStatus.pending) {
            continue;
          }

          if (purchase.status == PurchaseStatus.purchased ||
              purchase.status == PurchaseStatus.restored) {
            // IMPORTANT: For Android, the receipt is the purchase token
            final bool verified = await verifyReceipt(
              platform: _platformName(),
              receipt: purchase.verificationData.serverVerificationData,
              productId: productId,
            );

            if (!resultCompleter.isCompleted) {
              resultCompleter.complete(verified);
            }
          } else {
            if (!resultCompleter.isCompleted) {
              resultCompleter.complete(false);
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

    try {
      return await resultCompleter.future.timeout(
        const Duration(minutes: 2),
        onTimeout: () => false,
      );
    } finally {
      await subscription.cancel();
    }
  }

  /// Restore previous purchases
  /// Used when user reinstalls app or switches devices
  /// Returns a user-friendly message about what was restored
  Future<String> restorePurchases() async {
    try {
      final bool storeAvailable = await _inAppPurchase.isAvailable();
      if (!storeAvailable) {
        debugPrint('In-app purchase store is unavailable');
        return 'App store is not available. Please try again later.';
      }

      // Trigger platform restore
      await _inAppPurchase.restorePurchases();
      
      // Note: The restore will trigger the purchase stream if there are
      // any purchases to restore. The backend will be updated through
      // the normal verification flow.
      
      return 'Restore completed. Your subscriptions have been refreshed.';
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

    // If using same IDs across platforms, use base product IDs

    productIds = <String>{
      monthlyProductId,
      quarterlyProductId,
      yearlyProductId,
    };

    final ProductDetailsResponse response =
        await _inAppPurchase.queryProductDetails(productIds);

    if (response.error != null) {
      debugPrint('Error loading products: ${response.error}');
      return <ProductDetails>[];
    }

    return response.productDetails;
  }

  /// Verify a purchase receipt with the backend
  Future<bool> verifyReceipt({
    required String platform,
    required String receipt,
    required String productId,
  }) async {
    try {
      final Map<String, dynamic> response = await _client.postJson(
        '/purchases/verify',
        body: <String, dynamic>{
          'platform': platform,
          'receipt': receipt,
          'productId': productId,
        },
        headers: await _authHeaders(),
      );
      return response['success'] == true;
    } catch (e) {
      debugPrint('Receipt verification failed: $e');
      return false;
    }
  }
}
