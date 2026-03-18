import 'dart:async';

import 'package:flutter/foundation.dart';

import 'ad_service.dart';
import 'purchase_service.dart';

/// Manages discovery game access combining subscription purchases and temporary ad access
class DiscoveryAccessManager extends ChangeNotifier {
  DiscoveryAccessManager({
    required PurchaseService purchaseService,
    required AdService adService,
  })  : _purchaseService = purchaseService,
        _adService = adService;

  final PurchaseService _purchaseService;
  final AdService _adService;

  /// Timestamp when temporary (ad-based) access expires
  DateTime? _tempAccessExpiry;

  /// Timer for countdown updates
  Timer? _countdownTimer;

  /// Whether a purchase is in progress
  bool _isPurchasing = false;

  /// Whether an ad is being shown
  bool _isShowingAd = false;

  /// Error message if something went wrong
  String? _error;

  // Getters
  bool get isPurchasing => _isPurchasing;
  bool get isShowingAd => _isShowingAd;
  String? get error => _error;

  /// Check if user has any form of access (subscription or temporary ad-based)
  bool hasAccess(bool hasActiveSubscription) {
    // Active subscription takes priority
    if (hasActiveSubscription) {
      return true;
    }

    // Check temporary ad-based access
    if (_tempAccessExpiry != null) {
      if (DateTime.now().isBefore(_tempAccessExpiry!)) {
        return true;
      }
      // Expired — clear it
      _tempAccessExpiry = null;
      _stopCountdownTimer();
    }

    return false;
  }

  /// Time remaining for temporary access (null if no temp access)
  Duration? get remainingTime {
    if (_tempAccessExpiry == null) {
      return null;
    }
    final Duration remaining = _tempAccessExpiry!.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  /// Whether user has active temporary access
  bool get hasTemporaryAccess {
    if (_tempAccessExpiry == null) {
      return false;
    }
    return DateTime.now().isBefore(_tempAccessExpiry!);
  }

  /// Grant temporary access after watching an ad
  void grantTemporaryAccess() {
    _tempAccessExpiry = DateTime.now().add(
      Duration(minutes: AdService.tempAccessMinutes),
    );
    _startCountdownTimer();
    notifyListeners();
    debugPrint(
      'Temporary access granted until: $_tempAccessExpiry',
    );
  }

  /// Clear temporary access (e.g., when it expires)
  void clearTemporaryAccess() {
    _tempAccessExpiry = null;
    _stopCountdownTimer();
    notifyListeners();
  }

  /// Purchase discovery subscription
  /// Returns true if successful
  Future<bool> purchaseDiscovery() async {
    _isPurchasing = true;
    _error = null;
    notifyListeners();

    try {
      final bool success = await _purchaseService.purchaseDiscovery();

      if (!success) {
        _error = 'Purchase failed. Please try again.';
      }

      return success;
    } catch (e) {
      debugPrint('Purchase failed with platform error: $e');
      _error = _mapPurchaseError(e);
      return false;
    } finally {
      _isPurchasing = false;
      notifyListeners();
    }
  }

  String _mapPurchaseError(Object error) {
    final String message = error.toString();
    final String lower = message.toLowerCase();

    if (lower.contains('not authorized to make purchases') &&
        lower.contains('sandbox')) {
      return 'This Apple ID is not authorized for Sandbox purchases. '
          'Sign in with a Sandbox Tester account and try again.';
    }

    if (lower.contains('user cancelled') ||
        lower.contains('cancelled by user') ||
        lower.contains('canceled by user')) {
      return 'Purchase was cancelled.';
    }

    return 'Could not complete purchase. Please try again.';
  }

  String _mapAdError(Object error) {
    final String message = error.toString();
    final String lower = message.toLowerCase();

    if (lower.contains('timeout') || lower.contains('timed out')) {
      return 'Ad took too long to load. Please try again.';
    }

    if (lower.contains('controller') && lower.contains('no view controller')) {
      return 'Could not open the ad right now. Please try again.';
    }

    if (lower.contains('kcferrordomaincfnetwork') ||
        lower.contains('nsurlerrordomain') ||
        lower.contains('network')) {
      return 'Could not load the ad due to a network issue. Please try again.';
    }

    if (lower.contains('no fill') || lower.contains('no ad')) {
      return 'No ad is available right now. Please try again in a moment.';
    }

    return 'Could not load the ad right now. Please try again shortly.';
  }

  /// Watch a rewarded ad for temporary access
  /// Returns true if user earned access
  Future<bool> watchAdForAccess() async {
    _isShowingAd = true;
    _error = null;
    notifyListeners();

    try {
      final bool earned = await _adService
          .showRewardedAdForAccess()
          .timeout(const Duration(seconds: 120));

      if (earned) {
        grantTemporaryAccess();
        return true;
      } else {
        _error = 'Ad was not completed. Please try again.';
        return false;
      }
    } catch (e) {
      debugPrint('Ad failed with platform error: $e');
      _error = _mapAdError(e);
      return false;
    } finally {
      _isShowingAd = false;
      notifyListeners();
    }
  }

  /// Restore previous purchases
  /// Returns a message describing what happened (for UI display)
  Future<String> restorePurchases() async {
    _isPurchasing = true;
    _error = null;
    notifyListeners();

    try {
      final String message = await _purchaseService.restorePurchases();
      return message;
    } catch (e) {
      _error = 'Restore error: $e';
      return 'An error occurred while restoring purchases.';
    } finally {
      _isPurchasing = false;
      notifyListeners();
    }
  }

  /// Pre-load ad for better UX
  Future<void> preloadAd() async {
    await _adService.loadRewardedAd();
  }

  /// Start countdown timer for UI updates
  void _startCountdownTimer() {
    _stopCountdownTimer();
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (_tempAccessExpiry == null ||
            DateTime.now().isAfter(_tempAccessExpiry!)) {
          clearTemporaryAccess();
        } else {
          notifyListeners();
        }
      },
    );
  }

  /// Stop countdown timer
  void _stopCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  @override
  void dispose() {
    _stopCountdownTimer();
    _adService.dispose();
    super.dispose();
  }
}
