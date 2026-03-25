import '../../features/auth/data/token_store.dart';
import '../network/api_client.dart';

class PushTokenRegistrationApi {
  PushTokenRegistrationApi({
    required ApiClient client,
    required TokenStore tokenStore,
  })  : _client = client,
        _tokenStore = tokenStore;

  final ApiClient _client;
  final TokenStore _tokenStore;

  Future<void> registerFcmToken({
    required String fcmToken,
    required String platform,
    required String deviceId,
  }) async {
    final headers = await _authHeaders();
    if (headers == null) {
      return;
    }

    await _client.postEmpty(
      '/notifications/tokens',
      headers: headers,
      body: <String, dynamic>{
        'provider': 'fcm',
        'token': fcmToken,
        'platform': platform,
        'deviceId': deviceId,
      },
    );
  }

  Future<void> deactivateFcmToken(String fcmToken) async {
    final headers = await _authHeaders();
    if (headers == null) {
      return;
    }

    await _client.postEmpty(
      '/notifications/tokens/deactivate',
      headers: headers,
      body: <String, dynamic>{
        'provider': 'fcm',
        'token': fcmToken,
      },
      triggerUnauthorizedCallback: false,
    );
  }

  Future<Map<String, String>?> _authHeaders() async {
    final token = await _tokenStore.readToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    return <String, String>{
      'Authorization': 'Bearer $token',
    };
  }
}
