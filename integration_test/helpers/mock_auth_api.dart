import 'package:drawback_flutter/core/network/api_exception.dart';
import 'package:drawback_flutter/features/auth/data/auth_api.dart';
import 'package:drawback_flutter/features/auth/domain/auth_models.dart';

/// Mock AuthApi for integration testing
class MockAuthApi implements AuthApi {
  final Map<String, String> _registeredUsers = {};
  final Map<String, String> _displayNames = {};
  final Set<String> _unavailableDisplayNames = {'@admin', '@test'};
  final Map<String, String> _resetTokens = {};
  
  bool shouldFailNextRequest = false;
  String? nextFailureMessage;
  int? nextFailureStatusCode;

  @override
  Future<String> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (shouldFailNextRequest) {
      shouldFailNextRequest = false;
      throw ApiException(
        nextFailureStatusCode ?? 400,
        nextFailureMessage ?? 'Registration failed',
      );
    }

    if (_registeredUsers.containsKey(email)) {
      throw ApiException(400, 'Email already registered');
    }

    if (_displayNames.containsValue(displayName)) {
      throw ApiException(400, 'Display name already taken');
    }

    _registeredUsers[email] = password;
    _displayNames[email] = displayName;

    return 'Registration successful! Please check your email to confirm your account.';
  }

  @override
  Future<bool> checkDisplayNameAvailability(String displayName) async {
    if (shouldFailNextRequest) {
      shouldFailNextRequest = false;
      throw ApiException(
        nextFailureStatusCode ?? 500,
        nextFailureMessage ?? 'Check failed',
      );
    }

    return !_displayNames.containsValue(displayName) &&
           !_unavailableDisplayNames.contains(displayName);
  }

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    if (shouldFailNextRequest) {
      shouldFailNextRequest = false;
      throw ApiException(
        nextFailureStatusCode ?? 401,
        nextFailureMessage ?? 'Invalid credentials',
      );
    }

    if (!_registeredUsers.containsKey(email)) {
      throw ApiException(401, 'Invalid email or password');
    }

    if (_registeredUsers[email] != password) {
      throw ApiException(401, 'Invalid email or password');
    }

    return AuthResult(
      accessToken: 'mock_token_$email',
      message: 'Login successful',
    );
  }

  @override
  Future<AuthUser> me(String accessToken) async {
    if (shouldFailNextRequest) {
      shouldFailNextRequest = false;
      throw ApiException(
        nextFailureStatusCode ?? 401,
        nextFailureMessage ?? 'Unauthorized',
      );
    }

    final email = accessToken.replaceFirst('mock_token_', '');
    
    if (!_registeredUsers.containsKey(email)) {
      throw ApiException(401, 'Invalid token');
    }

    return AuthUser(
      id: 'user_id_$email',
      email: email,
      displayName: _displayNames[email] ?? '@unknown',
      mode: 'PUBLIC',
      createdAt: DateTime.now().toString(),
    );
  }

  @override
  Future<String> forgotPassword(String email) async {
    if (shouldFailNextRequest) {
      shouldFailNextRequest = false;
      throw ApiException(
        nextFailureStatusCode ?? 400,
        nextFailureMessage ?? 'Request failed',
      );
    }

    final token = 'reset_token_${DateTime.now().millisecondsSinceEpoch}';
    _resetTokens[token] = email;

    return 'If an account exists for $email, a password reset link has been sent.';
  }

  @override
  Future<ResetPasswordResult> resetPassword({
    required String token,
    required String password,
  }) async {
    if (shouldFailNextRequest) {
      shouldFailNextRequest = false;
      throw ApiException(
        nextFailureStatusCode ?? 400,
        nextFailureMessage ?? 'Reset failed',
      );
    }

    if (!_resetTokens.containsKey(token)) {
      return ResetPasswordResult(
        status: 'error',
        message: 'Invalid or expired reset token',
      );
    }

    final email = _resetTokens[token]!;
    _registeredUsers[email] = password;
    _resetTokens.remove(token);

    return ResetPasswordResult(
      status: 'success',
      message: 'Password reset successful. You can now log in with your new password.',
    );
  }

  /// Helper method to pre-register a user for testing
  void preRegisterUser(String email, String password, String displayName) {
    _registeredUsers[email] = password;
    _displayNames[email] = displayName;
  }

  /// Helper method to simulate API failures
  void setNextFailure({String? message, int? statusCode}) {
    shouldFailNextRequest = true;
    nextFailureMessage = message;
    nextFailureStatusCode = statusCode;
  }

  /// Helper method to reset all data
  void reset() {
    _registeredUsers.clear();
    _displayNames.clear();
    _resetTokens.clear();
    shouldFailNextRequest = false;
    nextFailureMessage = null;
    nextFailureStatusCode = null;
  }

  /// Helper method to get a reset token for testing
  String createResetToken(String email) {
    final token = 'reset_token_${DateTime.now().millisecondsSinceEpoch}';
    _resetTokens[token] = email;
    return token;
  }
}
