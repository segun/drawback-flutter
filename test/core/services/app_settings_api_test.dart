import 'package:drawback_flutter/core/network/api_client.dart';
import 'package:drawback_flutter/core/services/app_settings_api.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient({required this.payload})
      : super(baseUrl: 'https://example.com');

  final Map<String, dynamic> payload;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? headers,
  }) async {
    expect(path, '/app/config');
    return payload;
  }
}

void main() {
  test('reads provider from app config ads.provider', () async {
    final AppSettingsApi api = AppSettingsApi(
      client: _FakeApiClient(
        payload: <String, dynamic>{
          'ads': <String, dynamic>{'provider': 'admob'},
          'temporaryDiscoveryAccessDurationMinutes': 12,
        },
      ),
    );

    final config = await api.fetchDiscoveryAdProviderConfig();

    expect(config.providerKey, 'admob');
    expect(config.tempAccessMinutes, 12);
  });

  test('falls back to admob when app config provider is unknown', () async {
    final AppSettingsApi api = AppSettingsApi(
      client: _FakeApiClient(
        payload: <String, dynamic>{
          'ads': <String, dynamic>{'provider': 'liftoff'},
          'temporaryDiscoveryAccessDurationMinutes': 7,
        },
      ),
    );

    final config = await api.fetchDiscoveryAdProviderConfig();

    expect(config.providerKey, 'admob');
    expect(config.tempAccessMinutes, 7);
  });
}
