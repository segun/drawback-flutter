import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class LoginHintStore {
  Future<void> writeRememberedEmail(String email);
  Future<String?> readRememberedEmail();
}

class SecureLoginHintStore implements LoginHintStore {
  static const String _rememberedEmailKey = 'drawkcab-remembered-email';

  SecureLoginHintStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<void> writeRememberedEmail(String email) {
    return _storage.write(key: _rememberedEmailKey, value: email.trim());
  }

  @override
  Future<String?> readRememberedEmail() {
    return _storage.read(key: _rememberedEmailKey);
  }
}
