import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:yandex_mobileads/mobile_ads.dart';

/// Service for handling rewarded ads
/// Uses Yandex rewarded ads with optional mock mode for local development
class AdService {
  /// Toggle for development vs production
  /// Set to true to bypass ad SDK calls while testing paywall flow
  static const bool useMockAds = false;

  /// Duration of temporary access granted by watching an ad
  static const int tempAccessMinutes = 5;

  static const String _productionRewardedAdUnitId = 'R-M-18953743-1';
  static const String _demoRewardedAdUnitId = 'demo-rewarded-yandex';
  static const Duration _loadWaitTimeout = Duration(seconds: 15);
  static const Duration _inFlightLoadWaitTimeout = Duration(seconds: 20);
  static const Duration _showFlowTimeout = Duration(seconds: 90);

  static String get rewardedAdUnitId {
    return kDebugMode ? _demoRewardedAdUnitId : _productionRewardedAdUnitId;
  }

  AdService() {
    if (useMockAds) {
      return;
    }
    _mobileAdsInitFuture = _initializeMobileAds();
  }

  Future<void>? _mobileAdsInitFuture;
  Future<RewardedAdLoader>? _adLoader;
  Completer<void>? _adLoadCompleter;
  RewardedAd? _rewardedAd;
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

    await _ensureSdkInitialized();

    if (_isAdReady) {
      return;
    }

    if (_isAdLoading) {
      final Completer<void>? inFlightLoad = _adLoadCompleter;
      if (inFlightLoad != null) {
        try {
          await inFlightLoad.future.timeout(_inFlightLoadWaitTimeout);
        } catch (_) {
          // Ignore in-flight load failures here; caller can retry.
        }
      }
      return;
    }

    _isAdLoading = true;
    _adLoadCompleter = Completer<void>();

    try {
      _adLoader ??= _createRewardedAdLoader();
      final RewardedAdLoader adLoader = await _adLoader!;

      final Future<void> loadRequest = adLoader.loadAd(
        adRequestConfiguration: AdRequestConfiguration(
          adUnitId: rewardedAdUnitId,
        ),
      );

      unawaited(
        loadRequest.catchError((Object error) {
          _isAdLoading = false;
          _isAdReady = false;
          _completeLoadWithError(error);
          debugPrint('Rewarded ad load call failed: ${_describeError(error)}');
        }),
      );

      final Completer<void>? loadCompleter = _adLoadCompleter;
      if (loadCompleter != null) {
        await loadCompleter.future.timeout(_loadWaitTimeout);
      }
    } catch (e) {
      _isAdLoading = false;
      _isAdReady = false;
      _completeLoadWithError(e);
      debugPrint('Rewarded ad load request failed: ${_describeError(e)}');
    } finally {
      _adLoadCompleter = null;
    }
  }

  Future<void> _initializeMobileAds() async {
    await MobileAds.setUserConsent(false);
    await MobileAds.setLocationConsent(false);
    await MobileAds.initialize();
    if (kDebugMode) {
      await MobileAds.setLogging(true);
    }
    _adLoader = _createRewardedAdLoader();
    debugPrint('Yandex MobileAds initialized');
  }

  Future<void> _ensureSdkInitialized() async {
    _mobileAdsInitFuture ??= _initializeMobileAds();
    try {
      await _mobileAdsInitFuture;
    } catch (_) {
      // Allow retry on next attempt if SDK initialization fails.
      _mobileAdsInitFuture = null;
      rethrow;
    }
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

  Future<RewardedAdLoader> _createRewardedAdLoader() {
    return RewardedAdLoader.create(
      onAdLoaded: (RewardedAd rewardedAd) {
        _rewardedAd?.destroy();
        _rewardedAd = rewardedAd;
        _isAdReady = true;
        _isAdLoading = false;
        _completeLoadSuccessfully();
        debugPrint('Rewarded ad loaded successfully');
      },
      onAdFailedToLoad: (AdRequestError error) {
        _isAdReady = false;
        _isAdLoading = false;
        _completeLoadWithError(error);
        debugPrint('Rewarded ad failed to load: ${_describeError(error)}');
      },
    );
  }

  void _completeLoadSuccessfully() {
    final Completer<void>? loadCompleter = _adLoadCompleter;
    if (loadCompleter != null && !loadCompleter.isCompleted) {
      loadCompleter.complete();
    }
  }

  void _completeLoadWithError(Object error) {
    final Completer<void>? loadCompleter = _adLoadCompleter;
    if (loadCompleter != null && !loadCompleter.isCompleted) {
      loadCompleter.completeError(error);
    }
  }

  /// Show real Yandex rewarded ad
  Future<bool> _showRealAd() async {
    if (!_isAdReady || _rewardedAd == null) {
      await loadRewardedAd();
    }

    final RewardedAd? ad = _rewardedAd;
    if (ad == null) {
      debugPrint('No rewarded ad available');
      return false;
    }

    bool rewarded = false;
    final Completer<bool> showCompleter = Completer<bool>();

    await ad.setAdEventListener(
      eventListener: RewardedAdEventListener(
        onAdShown: () {
          debugPrint('Rewarded ad shown');
        },
        onAdFailedToShow: (AdError error) {
          debugPrint('Rewarded ad failed to show: ${_describeError(error)}');
          if (!showCompleter.isCompleted) {
            showCompleter.complete(false);
          }
        },
        onRewarded: (Reward reward) {
          rewarded = true;
          debugPrint('User earned reward: ${reward.amount} ${reward.type}');
        },
        onAdDismissed: () {
          if (!showCompleter.isCompleted) {
            showCompleter.complete(rewarded);
          }
        },
      ),
    );

    try {
      await ad.show();
      return await showCompleter.future.timeout(_showFlowTimeout);
    } on TimeoutException {
      debugPrint('Rewarded ad show timed out after $_showFlowTimeout');
      return false;
    } catch (e) {
      debugPrint('Rewarded ad show failed: ${_describeError(e)}');
      return false;
    } finally {
      _cleanupCurrentAd(preloadNext: true);
    }
  }

  String _describeError(Object error) {
    if (error is PlatformException) {
      return 'PlatformException(code: ${error.code}, message: ${error.message}, details: ${error.details})';
    }
    if (error is AdError) {
      return 'AdError(description: ${error.description})';
    }
    if (error is AdRequestError) {
      return 'AdRequestError(adUnitId: ${error.adUnitId}, code: ${error.code}, description: ${error.description})';
    }
    return error.toString();
  }

  void _cleanupCurrentAd({required bool preloadNext}) {
    _rewardedAd?.destroy();
    _rewardedAd = null;
    _isAdReady = false;
    _isAdLoading = false;

    if (preloadNext) {
      unawaited(loadRewardedAd());
    }
  }

  /// Dispose of loaded ad resources
  void dispose() {
    _rewardedAd?.destroy();
    _rewardedAd = null;
    _adLoadCompleter = null;
    _isAdReady = false;
    _isAdLoading = false;
  }
}
