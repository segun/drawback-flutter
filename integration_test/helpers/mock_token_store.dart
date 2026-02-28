import 'package:drawback_flutter/features/auth/data/token_store.dart';

/// Mock TokenStore for integration testing
class MockTokenStore implements TokenStore {
  String? _token;

  @override
  Future<String?> readToken() async {
    return _token;
  }

  @override
  Future<void> writeToken(String token) async {
    _token = token;
  }

  @override
  Future<void> clearToken() async {
    _token = null;
  }

  /// Helper method to check if token is stored
  bool get hasToken => _token != null;

  /// Helper method to get current token
  String? get currentToken => _token;

  /// Helper method to reset the store
  void reset() {
    _token = null;
  }
}
