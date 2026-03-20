import '../network/api_client.dart';
import 'ad_provider_config.dart';

class AppSettingsApi {
  AppSettingsApi({required ApiClient client}) : _client = client;

  final ApiClient _client;

  Future<DiscoveryAdProviderConfig> fetchDiscoveryAdProviderConfig() async {
    final Map<String, dynamic> response = await _client.getJson('/app/config');

    final String? providerRaw = _readProviderValue(response);

    return DiscoveryAdProviderConfig(
      provider: DiscoveryAdProvider.fromServerValue(providerRaw),
      tempAccessMinutes: DiscoveryAdProviderConfig.defaultTempAccessMinutes,
    );
  }

  String? _readProviderValue(Map<String, dynamic> json) {
    final dynamic ads = json['ads'];
    if (ads is Map<String, dynamic>) {
      final dynamic adsProvider = ads['provider'];
      if (adsProvider is String && adsProvider.trim().isNotEmpty) {
        return adsProvider;
      }
    }

    return null;
  }
}
