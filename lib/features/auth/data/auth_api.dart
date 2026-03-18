import 'package:flutter/cupertino.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
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

  Future<AuthResult> login({
    required String email,
    required String password,
    required String deviceId,
  }) async {
    final Map<String, dynamic> response = await _client.postJson(
      '/auth/login',
      body: <String, dynamic>{
        'email': email.trim(),
        'password': password,
        'deviceId': deviceId,
      },
    );

    final String token = response['accessToken'] as String;
    debugPrint('Login received token: $token');
    final bool canAddPasskey = response['canAddPasskey'] as bool? ?? false;
    await _tokenStore.writeToken(token);
    return AuthResult(
      accessToken: token,
      canAddPasskey: canAddPasskey,
    );
  }

  Future<Map<String, dynamic>> startPasskeyRegistration({
    required String bearerToken,
  }) {
    return _client.postJson(
      '/auth/passkey/register/start',
      triggerUnauthorizedCallback: false,
      headers: <String, String>{
        'Authorization': 'Bearer $bearerToken',
      },
    );
  }

  Future<void> finishPasskeyRegistration({
    required String bearerToken,
    required Map<String, dynamic> credentialData,
    required String deviceId,
    required String platform,
  }) {
    return _client.postEmpty(
      '/auth/passkey/register/finish',
      triggerUnauthorizedCallback: false,
      headers: <String, String>{
        'Authorization': 'Bearer $bearerToken',
      },
      body: <String, dynamic>{
        'data': credentialData,
        'deviceId': deviceId,
        'platform': platform,
      },
    );
  }

  Future<Map<String, dynamic>> startPasskeyLogin({required String email}) {
    return _client.postJson(
      '/auth/passkey/login/start',
      body: <String, dynamic>{
        'email': email.trim(),
      },
    );
  }

  Future<AuthResult> finishPasskeyLogin({
    required Map<String, dynamic> credentialData,
  }) async {
    final Map<String, dynamic> response = await _client.postJson(
      '/auth/passkey/login/finish',
      body: <String, dynamic>{
        'data': credentialData,
      },
    );

    final String? token = response['accessToken'] as String?;

    if (token == null || token.isEmpty) {
      throw ApiException(
        500,
        'Server returned invalid authentication response.',
      );
    }

    await _tokenStore.writeToken(token);

    final bool canAddPasskey = response['canAddPasskey'] as bool? ?? false;
    return AuthResult(
      accessToken: token,
      canAddPasskey: canAddPasskey,
    );
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

  Future<String> resendConfirmation(String email) async {
    final Map<String, dynamic> response = await _client.postJson(
      '/auth/resend-confirmation',
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
