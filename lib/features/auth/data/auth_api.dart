import '../../../core/network/api_client.dart';
import '../domain/auth_models.dart';
import 'token_store.dart';

class AuthApi {
  AuthApi({required ApiClient client, required TokenStore tokenStore})
      : _client = client,
        _tokenStore = tokenStore;

  final ApiClient _client;
  final TokenStore _tokenStore;

  Future<String> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final Map<String, dynamic> response = await _client.postJson(
      '/auth/register',
      body: <String, dynamic>{
        'email': email.trim(),
        'password': password,
        'displayName': displayName.trim(),
      },
    );

    return response['message'] as String;
  }

  Future<AuthResult> login({required String email, required String password}) async {
    final Map<String, dynamic> response = await _client.postJson(
      '/auth/login',
      body: <String, dynamic>{
        'email': email.trim(),
        'password': password,
      },
    );

    final String token = response['accessToken'] as String;
    await _tokenStore.writeToken(token);
    return AuthResult(accessToken: token);
  }

  Future<bool> checkDisplayNameAvailability(String name) async {
    final Map<String, dynamic> response = await _client.getJson(
      '/auth/display-name/check?name=${Uri.encodeQueryComponent(name.trim())}',
    );

    return (response['available'] as bool?) ?? false;
  }

  Future<String> forgotPassword(String email) async {
    final Map<String, dynamic> response = await _client.postJson(
      '/auth/forgot-password',
      body: <String, dynamic>{'email': email.trim()},
    );
    return response['message'] as String;
  }

  Future<ResetPasswordResult> resetPassword({
    required String token,
    required String password,
  }) async {
    final Map<String, dynamic> response = await _client.postJson(
      '/auth/reset-password',
      body: <String, dynamic>{
        'token': token,
        'password': password,
      },
    );
    return ResetPasswordResult.fromJson(response);
  }

  Future<AuthUser> me(String accessToken) async {
    final Map<String, dynamic> response = await _client.getJson(
      '/users/me',
      headers: <String, String>{
        'Authorization': 'Bearer $accessToken',
      },
    );

    return AuthUser.fromJson(response);
  }
}
