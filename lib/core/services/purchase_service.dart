import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../features/auth/data/token_store.dart';
import '../network/api_client.dart';

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

  /// Toggle for development vs production
  /// Set to false after configuring products in Play/App Store
  static const bool useMockPurchases = false;

  /// Product ID for subscription (monthly, quarterly, yearly available)
  static const String discoveryProductId = 'discovery_premium';

  Future<Map<String, String>> _authHeaders() async {
    final String? token = await _tokenStore.readToken();
    if (token == null || token.isEmpty) {
      throw Exception('No access token available');
    }
    return <String, String>{
      'Authorization': 'Bearer $token',
    };
  }

  /// Purchase discovery game access (permanent unlock)
  /// Returns true if purchase was successful
  Future<bool> purchaseDiscovery() async {
    if (useMockPurchases) {
      return _mockPurchaseDiscovery();
    }

    final bool storeAvailable = await _inAppPurchase.isAvailable();
    if (!storeAvailable) {
      debugPrint('In-app purchase store is unavailable');
      return false;
    }

    final ProductDetailsResponse response =
        await _inAppPurchase.queryProductDetails(<String>{discoveryProductId});
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
          if (purchase.productID != discoveryProductId) {
            continue;
          }

          if (purchase.status == PurchaseStatus.pending) {
            continue;
          }

          if (purchase.pendingCompletePurchase) {
            await _inAppPurchase.completePurchase(purchase);
          }

          if (purchase.status == PurchaseStatus.purchased ||
              purchase.status == PurchaseStatus.restored) {
            final bool verified = await verifyReceipt(
              platform: _platformName(),
              receipt: purchase.verificationData.serverVerificationData,
            );
            if (!resultCompleter.isCompleted) {
              resultCompleter.complete(verified);
            }
            continue;
          }

          if (!resultCompleter.isCompleted) {
            resultCompleter.complete(false);
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

  /// Mock purchase for development testing
  Future<bool> _mockPurchaseDiscovery() async {
    try {
      // Call mock endpoint on backend
      await _client.postJson(
        '/purchases/mock-unlock',
        headers: await _authHeaders(),
      );
      debugPrint('Mock purchase successful');
      return true;
    } catch (e) {
      debugPrint('Mock purchase failed: $e');
      return false;
    }
  }

  /// Restore previous purchases
  /// Used when user reinstalls app or switches devices
  Future<bool> restorePurchases() async {
    if (useMockPurchases) {
      // In mock mode, just refresh profile from backend
      // The hasDiscoveryAccess field will reflect the current state
      debugPrint('Mock restore: Profile refresh will handle this');
      return true;
    }

    try {
      final bool storeAvailable = await _inAppPurchase.isAvailable();
      if (!storeAvailable) {
        debugPrint('In-app purchase store is unavailable');
        return false;
      }

      await _inAppPurchase.restorePurchases();
      return true;
    } catch (e) {
      debugPrint('Restore purchases failed: $e');
      return false;
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

  /// Verify a purchase receipt with the backend
  Future<bool> verifyReceipt({
    required String platform,
    required String receipt,
  }) async {
    try {
      final Map<String, dynamic> response = await _client.postJson(
        '/purchases/verify',
        body: <String, dynamic>{
          'platform': platform,
          'receipt': receipt,
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
