import 'package:flutter/foundation.dart';

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

  /// Toggle for development vs production
  /// Set to false when ready to use real in-app purchases
  static const bool useMockPurchases = true;

  /// Product IDs for in-app purchases
  static const String discoveryProductId = 'discovery_unlock_forever';

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
    // TODO: Implement real IAP when ready
    // 1. Initialize in_app_purchase package
    // 2. Load products
    // 3. Complete purchase flow
    // 4. Verify receipt with backend
    return false;
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
    // TODO: Implement real IAP restore when ready
    // 1. Call restorePurchases on in_app_purchase
    // 2. Re-verify receipts with backend
    return false;
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
