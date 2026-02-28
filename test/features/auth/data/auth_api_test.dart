import 'package:drawback_flutter/core/network/api_client.dart';
import 'package:drawback_flutter/core/network/api_exception.dart';
import 'package:drawback_flutter/features/auth/data/auth_api.dart';
import 'package:drawback_flutter/features/auth/data/token_store.dart';
import 'package:flutter_test/flutter_test.dart';

// Fake implementations for testing
class FakeApiClient implements ApiClient {
  late Future<Map<String, dynamic>> Function(String path, {Map<String, String>? headers})
      getJsonFn;
  late Future<Map<String, dynamic>> Function(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) postJsonFn;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? headers,
  }) async {
    return getJsonFn(path, headers: headers);
  }

  @override
  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    return postJsonFn(path, body: body, headers: headers);
  }

  @override
  Future<void> postEmpty(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    throw UnimplementedError();
  }
}

class FakeTokenStore implements TokenStore {
  String? _token;

  @override
  Future<void> writeToken(String token) async {
    _token = token;
  }

  @override
  Future<String?> readToken() async {
    return _token;
  }

  @override
  Future<void> clearToken() async {
    _token = null;
  }
}

void main() {
  late FakeApiClient fakeApiClient;
  late FakeTokenStore fakeTokenStore;
  late AuthApi authApi;

  setUp(() {
    fakeApiClient = FakeApiClient();
    fakeTokenStore = FakeTokenStore();
    authApi = AuthApi(
      client: fakeApiClient,
      tokenStore: fakeTokenStore,
    );
  });

  group('AuthApi.register', () {
    test('should return success message on successful registration', () async {
      // Arrange
      const email = 'test@example.com';
      const password = 'password123';
      const displayName = '@testuser';
      const expectedMessage = 'Account created. Please confirm your email.';

      fakeApiClient.postJsonFn = (path, {body, headers}) async {
        expect(path, '/auth/register');
        return <String, dynamic>{'message': expectedMessage};
      };

      // Act
      final message = await authApi.register(
        email: email,
        password: password,
        displayName: displayName,
      );

      // Assert
      expect(message, expectedMessage);
    });

    test('should trim email and displayName before sending', () async {
      // Arrange
      const email = '  test@example.com  ';
      const password = 'password123';
      const displayName = '  @testuser  ';

      fakeApiClient.postJsonFn = (path, {body, headers}) async {
        expect(body?['email'], 'test@example.com');
        expect(body?['displayName'], '@testuser');
        return <String, dynamic>{'message': 'Success'};
      };

      // Act
      await authApi.register(
        email: email,
        password: password,
        displayName: displayName,
      );

      // Assert - verification happens in the fakeApiClient.postJsonFn
    });

    test('should throw ApiException on network error', () async {
      // Arrange
      fakeApiClient.postJsonFn = (path, {body, headers}) async {
        throw ApiException(500, 'Server error');
      };

      // Act & Assert
      expect(
        () => authApi.register(
          email: 'test@example.com',
          password: 'password123',
          displayName: '@testuser',
        ),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('AuthApi.login', () {
    test('should return AuthResult and store token on successful login', () async {
      // Arrange
      const email = 'test@example.com';
      const password = 'password123';
      const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9';

      fakeApiClient.postJsonFn = (path, {body, headers}) async {
        return <String, dynamic>{'accessToken': token};
      };

      // Act
      final result = await authApi.login(
        email: email,
        password: password,
      );

      // Assert
      expect(result.accessToken, token);
      expect(await fakeTokenStore.readToken(), token);
    });

    test('should trim email before sending', () async {
      // Arrange
      const email = '  test@example.com  ';
      const password = 'password123';
      const token = 'token123';

      fakeApiClient.postJsonFn = (path, {body, headers}) async {
        expect(body?['email'], 'test@example.com');
        return <String, dynamic>{'accessToken': token};
      };

      // Act
      await authApi.login(email: email, password: password);

      // Assert - verification happens in fakeApiClient
    });

    test('should throw ApiException if login fails', () async {
      // Arrange
      fakeApiClient.postJsonFn = (path, {body, headers}) async {
        throw ApiException(401, 'Invalid credentials');
      };

      // Act & Assert
      expect(
        () => authApi.login(email: 'test@example.com', password: 'wrong'),
        throwsA(isA<ApiException>()),
      );
      expect(await fakeTokenStore.readToken(), isNull);
    });
  });

  group('AuthApi.checkDisplayNameAvailability', () {
    test('should return true if display name is available', () async {
      // Arrange
      const displayName = '@newuser';

      fakeApiClient.getJsonFn = (path, {headers}) async {
        expect(path, contains('display-name/check'));
        return <String, dynamic>{'available': true};
      };

      // Act
      final available = await authApi.checkDisplayNameAvailability(displayName);

      // Assert
      expect(available, true);
    });

    test('should return false if display name is taken', () async {
      // Arrange
      const displayName = '@existinguser';

      fakeApiClient.getJsonFn = (path, {headers}) async {
        return <String, dynamic>{'available': false};
      };

      // Act
      final available = await authApi.checkDisplayNameAvailability(displayName);

      // Assert
      expect(available, false);
    });

    test('should return false if response has no available field', () async {
      // Arrange
      fakeApiClient.getJsonFn = (path, {headers}) async {
        return <String, dynamic>{};
      };

      // Act
      final available = await authApi.checkDisplayNameAvailability('@user');

      // Assert
      expect(available, false);
    });

    test('should trim display name before checking', () async {
      // Arrange
      const displayName = '  @newuser  ';

      fakeApiClient.getJsonFn = (path, {headers}) async {
        expect(path, contains('name=%40newuser')); // Should be trimmed and URL encoded
        return <String, dynamic>{'available': true};
      };

      // Act
      await authApi.checkDisplayNameAvailability(displayName);

      // Assert - verification in fake
    });
  });

  group('AuthApi.forgotPassword', () {
    test('should return message on successful password reset request', () async {
      // Arrange
      const email = 'test@example.com';
      const expectedMessage = 'Password reset link sent to your email.';

      fakeApiClient.postJsonFn = (path, {body, headers}) async {
        return <String, dynamic>{'message': expectedMessage};
      };

      // Act
      final message = await authApi.forgotPassword(email);

      // Assert
      expect(message, expectedMessage);
    });

    test('should trim email before sending', () async {
      // Arrange
      const email = '  test@example.com  ';

      fakeApiClient.postJsonFn = (path, {body, headers}) async {
        expect(body?['email'], 'test@example.com');
        return <String, dynamic>{'message': 'Success'};
      };

      // Act
      await authApi.forgotPassword(email);

      // Assert - verification in fake
    });
  });

  group('AuthApi.resetPassword', () {
    test('should return ResetPasswordResult on successful password reset', () async {
      // Arrange
      const token = 'reset-token-123';
      const password = 'newpassword123';

      fakeApiClient.postJsonFn = (path, {body, headers}) async {
        return <String, dynamic>{
          'status': 'success',
          'message': 'Password reset successfully.',
          'email': 'user@example.com',
        };
      };

      // Act
      final result = await authApi.resetPassword(
        token: token,
        password: password,
      );

      // Assert
      expect(result.status, 'success');
      expect(result.message, 'Password reset successfully.');
      expect(result.email, 'user@example.com');
    });

    test('should handle null email in response', () async {
      // Arrange
      fakeApiClient.postJsonFn = (path, {body, headers}) async {
        return <String, dynamic>{
          'status': 'success',
          'message': 'Done',
        };
      };

      // Act
      final result = await authApi.resetPassword(
        token: 'token',
        password: 'password',
      );

      // Assert
      expect(result.email, null);
    });
  });

  group('AuthApi.me', () {
    test('should return AuthUser with valid token', () async {
      // Arrange
      const token = 'valid-token-123';

      fakeApiClient.getJsonFn = (path, {headers}) async {
        expect(path, '/users/me');
        expect(headers?['Authorization'], 'Bearer $token');
        return <String, dynamic>{
          'id': 'user123',
          'email': 'test@example.com',
          'displayName': '@testuser',
          'mode': 'PUBLIC',
          'createdAt': '2026-02-28T12:00:00Z',
          'updatedAt': '2026-02-28T12:00:00Z',
        };
      };

      // Act
      final user = await authApi.me(token);

      // Assert
      expect(user.id, 'user123');
      expect(user.email, 'test@example.com');
      expect(user.displayName, '@testuser');
      expect(user.mode, 'PUBLIC');
    });

    test('should throw ApiException with invalid token', () async {
      // Arrange
      fakeApiClient.getJsonFn = (path, {headers}) async {
        throw ApiException(401, 'Unauthorized');
      };

      // Act & Assert
      expect(
        () => authApi.me('invalid-token'),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
