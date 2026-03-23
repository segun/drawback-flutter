import 'package:flutter/foundation.dart';

enum DiscoveryAdProvider {
  admob('admob'),
  yandex('yandex');

  const DiscoveryAdProvider(this.key);
  final String key;

  static DiscoveryAdProvider fromServerValue(String? raw) {
    final String normalized = raw?.trim().toLowerCase() ?? '';
    switch (normalized) {
      case 'admob':
        return DiscoveryAdProvider.admob;
      case 'yandex':
        return DiscoveryAdProvider.yandex;
      default:
        return DiscoveryAdProvider.admob;
    }
  }
}

@immutable
class DiscoveryAdProviderConfig {
  const DiscoveryAdProviderConfig({
    required this.provider,
    required this.tempAccessMinutes,
  });

  final DiscoveryAdProvider provider;
  final int tempAccessMinutes;

  static const int defaultTempAccessMinutes = 5;

  static const DiscoveryAdProviderConfig fallback = DiscoveryAdProviderConfig(
    provider: DiscoveryAdProvider.admob,
    tempAccessMinutes: defaultTempAccessMinutes,
  );

  String get providerKey => provider.key;

  DiscoveryAdProviderConfig copyWith({
    DiscoveryAdProvider? provider,
    int? tempAccessMinutes,
  }) {
    return DiscoveryAdProviderConfig(
      provider: provider ?? this.provider,
      tempAccessMinutes: tempAccessMinutes ?? this.tempAccessMinutes,
    );
  }
}
