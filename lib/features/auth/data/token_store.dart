abstract class TokenStore {
  Future<void> writeToken(String token);
  Future<String?> readToken();
  Future<void> clearToken();
}
