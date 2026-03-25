import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' as gma;
import 'package:yandex_mobileads/mobile_ads.dart' as yma;

import 'ad_consent_service.dart';
import 'ad_provider_config.dart';

/// Service for handling rewarded ads.
class AdService {
  /// Toggle for development vs production
  /// Set to true to bypass ad SDK calls while testing paywall flow
  static const bool useMockAds = false;

  static const String admobAndroidRewardedAdUnitId =
      'ca-app-pub-9528764047064163/6787228876';
  static const String admobIosRewardedAdUnitId =
      'ca-app-pub-9528764047064163/6292404859';
  static const String yandexAndroidRewardedAdUnitId = String.fromEnvironment(
    'YANDEX_ANDROID_REWARDED_AD_UNIT_ID',
    defaultValue: 'R-M-18953743-1',
  );
  static const String yandexIosRewardedAdUnitId = String.fromEnvironment(
    'YANDEX_IOS_REWARDED_AD_UNIT_ID',
    defaultValue: 'R-M-18953743-1',
  );

  AdService({
    DiscoveryAdProviderConfig initialConfig =
        DiscoveryAdProviderConfig.fallback,
    bool initializeOnCreate = true,
    AdConsentService? consentService,
  })  : _config = initialConfig,
        _adConsentService = consentService ?? AdConsentService(),
        _initializeOnCreate = initializeOnCreate {
    _provider = _buildProvider(initialConfig.provider);

    if (useMockAds || !initializeOnCreate) {
      return;
    }

    unawaited(_provider.loadRewardedAd());
  }

  final bool _initializeOnCreate;
  final AdConsentService _adConsentService;
  late RewardedAdProviderClient _provider;
  DiscoveryAdProviderConfig _config;

  DiscoveryAdProviderConfig get config => _config;
  int get tempAccessMinutes => _config.tempAccessMinutes;
  String get providerKey => _provider.provider.key;

  String get admobRewardedAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return admobIosRewardedAdUnitId;
    }
    return admobAndroidRewardedAdUnitId;
  }

  String get yandexRewardedAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return yandexIosRewardedAdUnitId;
    }
    return yandexAndroidRewardedAdUnitId;
  }

  /// Whether an ad is currently loading
  bool get isAdLoading => _provider.isAdLoading;

  /// Whether an ad is ready to be shown
  bool get isAdReady => useMockAds || _provider.isAdReady;

  Future<void> setProviderFromServer(String? providerKey) async {
    final DiscoveryAdProvider provider =
        DiscoveryAdProvider.fromServerValue(providerKey);

    final DiscoveryAdProviderConfig nextConfig = _config.copyWith(
      provider: provider,
    );

    await _applyConfig(nextConfig);
  }

  Future<void> setConfigFromServer(DiscoveryAdProviderConfig config) async {
    await _applyConfig(config);
  }

  Future<void> _applyConfig(DiscoveryAdProviderConfig nextConfig) async {
    if (nextConfig.provider == _config.provider &&
        nextConfig.tempAccessMinutes == _config.tempAccessMinutes) {
      return;
    }

    _config = nextConfig;

    _provider.dispose();
    _provider = _buildProvider(_config.provider);

    if (_initializeOnCreate && !useMockAds) {
      await _provider.loadRewardedAd();
    }
  }

  RewardedAdProviderClient _buildProvider(DiscoveryAdProvider provider) {
    switch (provider) {
      case DiscoveryAdProvider.admob:
        return _AdmobRewardedAdProvider(
          rewardedAdUnitId: admobRewardedAdUnitId,
          consentService: _adConsentService,
        );
      case DiscoveryAdProvider.yandex:
        return _YandexRewardedAdProvider(
          rewardedAdUnitId: yandexRewardedAdUnitId,
        );
    }
  }

  /// Pre-load a rewarded ad (call early so it's ready when needed)
  Future<void> loadRewardedAd() async {
    if (useMockAds) {
      return;
    }

    await _provider.loadRewardedAd();
  }

  /// Show a rewarded ad for temporary discovery access
  /// Returns true if user earned the reward (watched the ad completely)
  Future<bool> showRewardedAdForAccess() async {
    if (useMockAds) {
      return _showMockAd();
    }

    return _provider.showRewardedAdForAccess();
  }

  /// Mock ad experience for development
  Future<bool> _showMockAd() async {
    debugPrint('Mock ad: Simulating ad viewing...');

    // Simulate watching a 2-second ad
    await Future<void>.delayed(const Duration(seconds: 2));

    debugPrint('Mock ad: User watched ad successfully');
    return true;
  }

  /// Dispose of loaded ad resources
  void dispose() {
    _provider.dispose();
  }
}

abstract class RewardedAdProviderClient {
  DiscoveryAdProvider get provider;
  bool get isAdLoading;
  bool get isAdReady;

  Future<void> loadRewardedAd();
  Future<bool> showRewardedAdForAccess();
  void dispose();
}

class _AdmobRewardedAdProvider implements RewardedAdProviderClient {
  _AdmobRewardedAdProvider({
    required String rewardedAdUnitId,
    required AdConsentService consentService,
  })  : _rewardedAdUnitId = rewardedAdUnitId,
        _consentService = consentService;

  static const Duration _loadWaitTimeout = Duration(seconds: 15);
  static const Duration _showFlowTimeout = Duration(seconds: 90);

  final String _rewardedAdUnitId;
  final AdConsentService _consentService;

  Future<void>? _mobileAdsInitFuture;
  Completer<void>? _adLoadCompleter;
  gma.RewardedAd? _rewardedAd;
  bool _isAdLoading = false;
  bool _isAdReady = false;

  @override
  DiscoveryAdProvider get provider => DiscoveryAdProvider.admob;

  @override
  bool get isAdLoading => _isAdLoading;

  @override
  bool get isAdReady => _isAdReady;

  @override
  Future<void> loadRewardedAd() async {
    if (kIsWeb) {
      return;
    }

    final bool canRequestAds = await _ensureCanRequestAds();
    if (!canRequestAds) {
      debugPrint(
        'AdMob consent is not available yet; skipping rewarded ad request.',
      );
      _isAdReady = false;
      _isAdLoading = false;
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
          await inFlightLoad.future.timeout(_loadWaitTimeout);
        } catch (_) {
          // Ignore in-flight load failures here; caller can retry.
        }
      }
      return;
    }

    _isAdLoading = true;
    _adLoadCompleter = Completer<void>();

    gma.RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const gma.AdRequest(),
      rewardedAdLoadCallback: gma.RewardedAdLoadCallback(
        onAdLoaded: (gma.RewardedAd ad) {
          _rewardedAd?.dispose();
          _rewardedAd = ad;
          _isAdReady = true;
          _isAdLoading = false;

          final Completer<void>? completer = _adLoadCompleter;
          if (completer != null && !completer.isCompleted) {
            completer.complete();
          }
        },
        onAdFailedToLoad: (gma.LoadAdError error) {
          _isAdReady = false;
          _isAdLoading = false;

          final Completer<void>? completer = _adLoadCompleter;
          if (completer != null && !completer.isCompleted) {
            completer.completeError(error);
          }

          debugPrint('AdMob rewarded ad failed to load: $error');
        },
      ),
    );

    try {
      final Completer<void>? completer = _adLoadCompleter;
      if (completer != null) {
        await completer.future.timeout(_loadWaitTimeout);
      }
    } catch (e) {
      debugPrint('AdMob rewarded ad load failed: $e');
      _isAdReady = false;
      _isAdLoading = false;
    } finally {
      _adLoadCompleter = null;
    }
  }

  Future<void> _initializeMobileAds() async {
    await gma.MobileAds.instance.initialize();
    await gma.MobileAds.instance.updateRequestConfiguration(
      gma.RequestConfiguration(
          testDeviceIds: ["686ABEF8F2D34D1F7A5F3B5AC5CB005E"]),
    );
    debugPrint('Google Mobile Ads initialized');
  }

  Future<bool> _ensureCanRequestAds() async {
    final bool canRequestAdsNow = await _consentService.canRequestAds();
    if (canRequestAdsNow) {
      return true;
    }

    try {
      await _consentService.gatherConsent();
    } catch (error) {
      debugPrint('Failed to gather AdMob consent: $error');
    }

    return _consentService.canRequestAds();
  }

  Future<void> _ensureSdkInitialized() async {
    _mobileAdsInitFuture ??= _initializeMobileAds();
    try {
      await _mobileAdsInitFuture;
    } catch (_) {
      _mobileAdsInitFuture = null;
      rethrow;
    }
  }

  @override
  Future<bool> showRewardedAdForAccess() async {
    if (kIsWeb) {
      return false;
    }

    if (!_isAdReady || _rewardedAd == null) {
      await loadRewardedAd();
    }

    final gma.RewardedAd? ad = _rewardedAd;
    if (ad == null) {
      debugPrint('No AdMob rewarded ad available');
      return false;
    }

    bool rewarded = false;
    final Completer<bool> showCompleter = Completer<bool>();

    ad.fullScreenContentCallback = gma.FullScreenContentCallback(
      onAdShowedFullScreenContent: (gma.Ad ad) {
        debugPrint('AdMob rewarded ad shown');
      },
      onAdDismissedFullScreenContent: (gma.Ad ad) {
        if (!showCompleter.isCompleted) {
          showCompleter.complete(rewarded);
        }
      },
      onAdFailedToShowFullScreenContent: (
        gma.Ad ad,
        gma.AdError error,
      ) {
        debugPrint('AdMob rewarded ad failed to show: $error');
        if (!showCompleter.isCompleted) {
          showCompleter.complete(false);
        }
      },
    );

    try {
      ad.show(
        onUserEarnedReward: (gma.Ad ad, gma.RewardItem reward) {
          rewarded = true;
          debugPrint(
            'User earned AdMob reward: ${reward.amount} ${reward.type}',
          );
        },
      );

      return await showCompleter.future.timeout(_showFlowTimeout);
    } on TimeoutException {
      debugPrint('AdMob rewarded ad show timed out after $_showFlowTimeout');
      return false;
    } catch (e) {
      debugPrint('AdMob rewarded ad show failed: $e');
      return false;
    } finally {
      _cleanupCurrentAd(preloadNext: true);
    }
  }

  void _cleanupCurrentAd({required bool preloadNext}) {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isAdReady = false;
    _isAdLoading = false;

    if (preloadNext) {
      unawaited(loadRewardedAd());
    }
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _adLoadCompleter = null;
    _isAdReady = false;
    _isAdLoading = false;
  }
}

class _YandexRewardedAdProvider implements RewardedAdProviderClient {
  _YandexRewardedAdProvider({
    required String rewardedAdUnitId,
  }) : _rewardedAdUnitId = rewardedAdUnitId;

  static const Duration _loadWaitTimeout = Duration(seconds: 15);
  static const Duration _showFlowTimeout = Duration(seconds: 90);

  final String _rewardedAdUnitId;

  Future<void>? _mobileAdsInitFuture;
  Future<yma.RewardedAdLoader>? _adLoaderFuture;
  Completer<void>? _adLoadCompleter;
  yma.RewardedAd? _rewardedAd;
  bool _isAdLoading = false;
  bool _isAdReady = false;

  @override
  DiscoveryAdProvider get provider => DiscoveryAdProvider.yandex;

  @override
  bool get isAdLoading => _isAdLoading;

  @override
  bool get isAdReady => _isAdReady;

  @override
  Future<void> loadRewardedAd() async {
    if (kIsWeb) {
      return;
    }

    if (_rewardedAdUnitId.trim().isEmpty) {
      debugPrint(
        'Yandex rewarded ad unit id is missing. Set YANDEX_*_REWARDED_AD_UNIT_ID via --dart-define.',
      );
      _isAdReady = false;
      _isAdLoading = false;
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
          await inFlightLoad.future.timeout(_loadWaitTimeout);
        } catch (_) {
          // Ignore in-flight load failures here; caller can retry.
        }
      }
      return;
    }

    _isAdLoading = true;
    _adLoadCompleter = Completer<void>();

    try {
      final yma.RewardedAdLoader adLoader = await _ensureAdLoader();
      await adLoader.loadAd(
        adRequestConfiguration: yma.AdRequestConfiguration(
          adUnitId: _rewardedAdUnitId,
        ),
      );

      final Completer<void>? completer = _adLoadCompleter;
      if (completer != null) {
        await completer.future.timeout(_loadWaitTimeout);
      }
    } catch (error) {
      debugPrint('Yandex rewarded ad load failed: $error');
      _isAdReady = false;
      _isAdLoading = false;
    } finally {
      _adLoadCompleter = null;
    }
  }

  Future<void> _initializeMobileAds() async {
    await yma.MobileAds.setAgeRestrictedUser(true);
    await yma.MobileAds.initialize();
    debugPrint('Yandex Mobile Ads initialized');
  }

  Future<void> _ensureSdkInitialized() async {
    _mobileAdsInitFuture ??= _initializeMobileAds();
    try {
      await _mobileAdsInitFuture;
    } catch (_) {
      _mobileAdsInitFuture = null;
      rethrow;
    }
  }

  Future<yma.RewardedAdLoader> _createRewardedAdLoader() {
    return yma.RewardedAdLoader.create(
      onAdLoaded: (yma.RewardedAd ad) {
        _destroyRewardedAd();
        _rewardedAd = ad;
        _isAdReady = true;
        _isAdLoading = false;

        final Completer<void>? completer = _adLoadCompleter;
        if (completer != null && !completer.isCompleted) {
          completer.complete();
        }
      },
      onAdFailedToLoad: (yma.AdRequestError error) {
        _isAdReady = false;
        _isAdLoading = false;

        final Completer<void>? completer = _adLoadCompleter;
        if (completer != null && !completer.isCompleted) {
          completer.completeError(error);
        }

        debugPrint('Yandex rewarded ad failed to load: $error');
      },
    );
  }

  Future<yma.RewardedAdLoader> _ensureAdLoader() {
    _adLoaderFuture ??= _createRewardedAdLoader();

    return _adLoaderFuture!.catchError((Object error) {
      _adLoaderFuture = null;
      throw error;
    });
  }

  @override
  Future<bool> showRewardedAdForAccess() async {
    if (kIsWeb) {
      return false;
    }

    if (!_isAdReady || _rewardedAd == null) {
      await loadRewardedAd();
    }

    final yma.RewardedAd? ad = _rewardedAd;
    if (ad == null) {
      debugPrint('No Yandex rewarded ad available');
      return false;
    }

    bool rewarded = false;
    final Completer<bool> showCompleter = Completer<bool>();

    await ad.setAdEventListener(
      eventListener: yma.RewardedAdEventListener(
        onAdShown: () {
          debugPrint('Yandex rewarded ad shown');
        },
        onAdFailedToShow: (yma.AdError error) {
          debugPrint('Yandex rewarded ad failed to show: $error');
          if (!showCompleter.isCompleted) {
            showCompleter.complete(false);
          }
        },
        onAdDismissed: () {
          if (!showCompleter.isCompleted) {
            showCompleter.complete(rewarded);
          }
        },
        onRewarded: (yma.Reward reward) {
          rewarded = true;
          debugPrint(
            'User earned Yandex reward: ${reward.amount} ${reward.type}',
          );
        },
      ),
    );

    try {
      await ad.show();
      return await showCompleter.future.timeout(_showFlowTimeout);
    } on TimeoutException {
      debugPrint('Yandex rewarded ad show timed out after $_showFlowTimeout');
      return false;
    } catch (error) {
      debugPrint('Yandex rewarded ad show failed: $error');
      return false;
    } finally {
      await _cleanupCurrentAd(preloadNext: true);
    }
  }

  Future<void> _cleanupCurrentAd({required bool preloadNext}) async {
    final yma.RewardedAd? ad = _rewardedAd;
    _rewardedAd = null;
    _isAdReady = false;
    _isAdLoading = false;

    if (ad != null) {
      try {
        await ad.destroy();
      } catch (error) {
        debugPrint('Failed to destroy Yandex rewarded ad: $error');
      }
    }

    if (preloadNext) {
      unawaited(loadRewardedAd());
    }
  }

  void _destroyRewardedAd() {
    final yma.RewardedAd? ad = _rewardedAd;
    _rewardedAd = null;
    if (ad == null) {
      return;
    }

    unawaited(
      ad.destroy().catchError((Object error) {
        debugPrint('Failed to destroy stale Yandex rewarded ad: $error');
      }),
    );
  }

  @override
  void dispose() {
    _destroyRewardedAd();

    final Future<yma.RewardedAdLoader>? loaderFuture = _adLoaderFuture;
    if (loaderFuture != null) {
      unawaited(
        loaderFuture.then((yma.RewardedAdLoader loader) {
          return loader.destroy();
        }).catchError((Object error) {
          debugPrint('Failed to destroy Yandex rewarded ad loader: $error');
        }),
      );
    }

    _adLoaderFuture = null;
    _adLoadCompleter = null;
    _isAdReady = false;
    _isAdLoading = false;
  }
}
