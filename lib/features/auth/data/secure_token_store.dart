import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'token_store.dart';

class SecureTokenStore implements TokenStore {
  static const String _tokenKey = 'drawkcab-access-token';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  Future<void> writeToken(String token) => _storage.write(key: _tokenKey, value: token);

  @override
  Future<String?> readToken() => _storage.read(key: _tokenKey);

  @override
  Future<void> clearToken() => _storage.delete(key: _tokenKey);
}


