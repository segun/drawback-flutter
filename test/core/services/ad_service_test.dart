import 'package:drawback_flutter/core/services/ad_service.dart';
import 'package:drawback_flutter/core/services/ad_provider_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('defaults to AdMob provider', () {
    final AdService adService = AdService(initializeOnCreate: false);

    expect(adService.providerKey, 'admob');
    expect(adService.tempAccessMinutes, 5);

    adService.dispose();
  });

  test('applies temp access minutes from server config', () async {
    final AdService adService = AdService(initializeOnCreate: false);

    await adService.setConfigFromServer(
      const DiscoveryAdProviderConfig(
        provider: DiscoveryAdProvider.yandex,
        tempAccessMinutes: 14,
      ),
    );

    expect(adService.providerKey, 'yandex');
    expect(adService.tempAccessMinutes, 14);

    adService.dispose();
  });

  test('switches to AdMob when server sends admob provider', () async {
    final AdService adService = AdService(initializeOnCreate: false);

    await adService.setProviderFromServer('admob');

    expect(adService.providerKey, 'admob');

    adService.dispose();
  });

  test('switches to Yandex when server sends yandex provider', () async {
    final AdService adService = AdService(initializeOnCreate: false);

    await adService.setProviderFromServer('yandex');

    expect(adService.providerKey, 'yandex');

    adService.dispose();
  });

  test('falls back to AdMob for unknown provider', () async {
    final AdService adService = AdService(initializeOnCreate: false);

    await adService.setProviderFromServer('liftoff');

    expect(adService.providerKey, 'admob');

    adService.dispose();
  });
}
