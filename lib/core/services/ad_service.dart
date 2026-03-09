import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Service for handling rewarded ads
/// Uses mock ads for development, can be toggled to real AdMob
class AdService {
  /// Toggle for development vs production
  /// Set to false when ready to use real AdMob ads
  static const bool useMockAds = true;

  /// Duration of temporary access granted by watching an ad
  static const int tempAccessMinutes = 5;

  /// Test ad unit IDs (work without AdMob account setup)
  /// These are Google's official test ad unit IDs
  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917'; // Android test
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313'; // iOS test
    }
    return '';
  }

  // RewardedAd? _rewardedAd; // Uncomment when using google_mobile_ads
  bool _isAdLoading = false;
  bool _isAdReady = false;

  /// Whether an ad is currently loading
  bool get isAdLoading => _isAdLoading;

  /// Whether an ad is ready to be shown
  bool get isAdReady => useMockAds || _isAdReady;

  /// Pre-load a rewarded ad (call early so it's ready when needed)
  Future<void> loadRewardedAd() async {
    if (useMockAds) {
      // In mock mode, ad is always "ready"
      _isAdReady = true;
      return;
    }

    if (_isAdLoading || _isAdReady) {
      return;
    }

    _isAdLoading = true;

    // TODO: Uncomment when using google_mobile_ads package
    /*
    await RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          _isAdReady = true;
          _isAdLoading = false;
          debugPrint('Rewarded ad loaded successfully');
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isAdLoading = false;
          _isAdReady = false;
          debugPrint('Rewarded ad failed to load: $error');
        },
      ),
    );
    */

    // Placeholder until real ads are implemented
    _isAdLoading = false;
    debugPrint('AdService: Real ads not yet implemented');
  }

  /// Show a rewarded ad for temporary discovery access
  /// Returns true if user earned the reward (watched the ad completely)
  Future<bool> showRewardedAdForAccess() async {
    if (useMockAds) {
      return _showMockAd();
    }
    return _showRealAd();
  }

  /// Mock ad experience for development
  Future<bool> _showMockAd() async {
    debugPrint('Mock ad: Simulating ad viewing...');
    
    // Simulate watching a 2-second ad
    await Future<void>.delayed(const Duration(seconds: 2));
    
    debugPrint('Mock ad: User watched ad successfully');
    return true;
  }

  /// Show real AdMob rewarded ad
  Future<bool> _showRealAd() async {
    // TODO: Uncomment when using google_mobile_ads package
    /*
    if (_rewardedAd == null) {
      debugPrint('No rewarded ad available');
      return false;
    }

    final Completer<bool> completer = Completer<bool>();
    bool rewarded = false;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        ad.dispose();
        _rewardedAd = null;
        _isAdReady = false;
        
        // Pre-load next ad
        loadRewardedAd();
        
        // Complete with whether user earned reward
        if (!completer.isCompleted) {
          completer.complete(rewarded);
        }
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        ad.dispose();
        _rewardedAd = null;
        _isAdReady = false;
        debugPrint('Ad failed to show: $error');
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        rewarded = true;
        debugPrint('User earned reward: ${reward.amount} ${reward.type}');
      },
    );

    return completer.future;
    */

    debugPrint('AdService: Real ads not yet implemented');
    return false;
  }

  /// Dispose of loaded ad resources
  void dispose() {
    // TODO: Uncomment when using google_mobile_ads package
    /*
    _rewardedAd?.dispose();
    _rewardedAd = null;
    */
    _isAdReady = false;
    _isAdLoading = false;
  }
}
