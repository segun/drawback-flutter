import 'package:drawback_flutter/core/network/api_exception.dart';
import 'package:drawback_flutter/features/auth/data/auth_api.dart';
import 'package:drawback_flutter/features/auth/data/token_store.dart';
import 'package:drawback_flutter/features/auth/domain/auth_models.dart';
import 'package:drawback_flutter/features/auth/presentation/auth_controller.dart';
import 'package:flutter_test/flutter_test.dart';

// Fake implementations for testing
class FakeAuthApi implements AuthApi {
  Exception? registerException;
  Exception? loginException;
  Exception? meException;
  Exception? forgotPasswordException;
  Exception? resendConfirmationException;
  Exception? resetPasswordException;
  Exception? checkDisplayNameException;

  String? registerResult;
  AuthResult? loginResult;
  AuthUser? meResult;
  String? forgotPasswordResult;
  String? resendConfirmationResult;
  ResetPasswordResult? resetPasswordResult;
  bool? checkDisplayNameResult;

  @override
  Future<String> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (registerException != null) throw registerException!;
    return registerResult ?? 'Success';
  }

  @override
  Future<AuthResult> login(
      {required String email,
      required String password,
      required String deviceId}) async {
    if (loginException != null) throw loginException!;
    return loginResult ?? AuthResult(accessToken: 'token');
  }

  @override
  Future<Map<String, dynamic>> startPasskeyRegistration({
    required String bearerToken,
  }) async {
    if (loginException != null) {
      throw loginException!;
    }
    return <String, dynamic>{
      'challenge': 'challenge',
      'rp': <String, dynamic>{'name': 'Drawback', 'id': 'drawback.chat'},
      'user': <String, dynamic>{
        'id': 'dXNlcg',
        'name': 'test@example.com',
        'displayName': '@testuser',
      },
      'pubKeyCredParams': <Map<String, dynamic>>[
        <String, dynamic>{'type': 'public-key', 'alg': -7},
      ],
      'authenticatorSelection': <String, dynamic>{
        'requireResidentKey': false,
        'residentKey': 'preferred',
        'userVerification': 'preferred',
      },
      'excludeCredentials': <Map<String, dynamic>>[],
    };
  }

  @override
  Future<void> finishPasskeyRegistration({
    required String bearerToken,
    required Map<String, dynamic> credentialData,
    required String deviceId,
    required String platform,
  }) async {
    if (loginException != null) {
      throw loginException!;
    }
  }

  @override
  Future<Map<String, dynamic>> startPasskeyLogin(
      {required String email}) async {
    if (loginException != null) {
      throw loginException!;
    }

    return <String, dynamic>{
      'challenge': 'challenge',
      'rpId': 'drawback.chat',
      'allowCredentials': <Map<String, dynamic>>[],
      'userVerification': 'preferred',
    };
  }

  @override
  Future<AuthResult> finishPasskeyLogin({
    required Map<String, dynamic> credentialData,
  }) async {
    if (loginException != null) {
      throw loginException!;
    }

    return loginResult ?? AuthResult(accessToken: 'token');
  }

  @override
  Future<bool> checkDisplayNameAvailability(String name) async {
    if (checkDisplayNameException != null) throw checkDisplayNameException!;
    return checkDisplayNameResult ?? false;
  }

  @override
  Future<String> forgotPassword(String email) async {
    if (forgotPasswordException != null) throw forgotPasswordException!;
    return forgotPasswordResult ?? 'Email sent';
  }

  @override
  Future<String> resendConfirmation(String email) async {
    if (resendConfirmationException != null) {
      throw resendConfirmationException!;
    }
    return resendConfirmationResult ?? 'Confirmation email sent';
  }

  @override
  Future<AuthUser> me(String accessToken) async {
    if (meException != null) throw meException!;
    return meResult ??
        AuthUser(
          id: 'id',
          email: 'email@example.com',
          displayName: '@user',
          mode: 'PUBLIC',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        );
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
  late FakeAuthApi fakeAuthApi;
  late FakeTokenStore fakeTokenStore;
  late AuthController authController;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    fakeAuthApi = FakeAuthApi();
    fakeTokenStore = FakeTokenStore();
    authController = AuthController(
      authApi: fakeAuthApi,
      tokenStore: fakeTokenStore,
    );
  });

  group('AuthController.bootstrap', () {
    test('should set isBootstrapping to false when no token exists', () async {
      expect(authController.isBootstrapping, true);
      await authController.bootstrap();
      expect(authController.isBootstrapping, false);
      expect(authController.isAuthenticated, false);
      expect(authController.currentUser, null);
    });

    test('should load current user when token exists and is valid', () async {
      const token = 'valid-token-123';
      final mockUser = AuthUser(
        id: 'user123',
        email: 'test@example.com',
        displayName: '@testuser',
        mode: 'PUBLIC',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      await fakeTokenStore.writeToken(token);
      fakeAuthApi.meResult = mockUser;

      await authController.bootstrap();

      expect(authController.isBootstrapping, false);
      expect(authController.isAuthenticated, true);
      expect(authController.currentUser, mockUser);
    });

    test('should clear token when /users/me call fails', () async {
      const token = 'invalid-token-123';
      await fakeTokenStore.writeToken(token);
      fakeAuthApi.meException = ApiException(401, 'Unauthorized');

      await authController.bootstrap();

      expect(authController.isBootstrapping, false);
      expect(authController.isAuthenticated, false);
      expect(authController.currentUser, null);
      expect(await fakeTokenStore.readToken(), null);
    });

    test('should handle empty token string', () async {
      await fakeTokenStore.writeToken('');
      await authController.bootstrap();
      expect(authController.isBootstrapping, false);
      expect(authController.isAuthenticated, false);
    });
  });

  group('AuthController.login', () {
    test('should update state on successful login', () async {
      const email = 'test@example.com';
      const password = 'password123';
      const token = 'new-token-123';
      final mockUser = AuthUser(
        id: 'user123',
        email: email,
        displayName: '@testuser',
        mode: 'PUBLIC',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      fakeAuthApi.loginResult = AuthResult(accessToken: token);
      fakeAuthApi.meResult = mockUser;

      var notificationCount = 0;
      authController.addListener(() {
        notificationCount++;
      });

      final result = await authController.login(
        email: email,
        password: password,
      );

      expect(result, true);
      expect(authController.isAuthenticated, true);
      expect(authController.currentUser, mockUser);
      expect(authController.notice, 'Welcome back, @testuser.');
      expect(notificationCount, greaterThan(0));
    });

    test('should set error on login failure', () async {
      fakeAuthApi.loginException = ApiException(401, 'Invalid credentials');

      final result = await authController.login(
        email: 'test@example.com',
        password: 'wrongpassword',
      );

      expect(result, false);
      expect(authController.isAuthenticated, false);
      expect(authController.error, 'Invalid credentials');
      expect(authController.canResendActivationEmail, false);
      expect(authController.isBusy, false);
    });

    test(
        'should expose resend activation option for account not activated login errors',
        () async {
      fakeAuthApi.loginException = ApiException(
        401,
        'Account not activated. Please check your email.',
      );

      final result = await authController.login(
        email: 'test@example.com',
        password: 'wrongpassword',
      );

      expect(result, false);
      expect(authController.error,
          'Account not activated. Please check your email.');
      expect(authController.canResendActivationEmail, true);
    });

    test('should include empty displayName in welcome notice', () async {
      const token = 'token123';
      final mockUser = AuthUser(
        id: 'user123',
        email: 'test@example.com',
        displayName: '',
        mode: 'PUBLIC',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      fakeAuthApi.loginResult = AuthResult(accessToken: token);
      fakeAuthApi.meResult = mockUser;

      await authController.login(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(authController.notice, 'Welcome back, .');
    });

    test('should set isBusy correctly during login', () async {
      fakeAuthApi.loginResult = AuthResult(accessToken: 'token');
      fakeAuthApi.meResult = AuthUser(
        id: 'id',
        email: 'e@e.com',
        displayName: '@user',
        mode: 'PUBLIC',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      var busyStateChanged = false;
      authController.addListener(() {
        if (authController.isBusy) {
          busyStateChanged = true;
        }
      });

      await authController.login(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(authController.isBusy, false);
      expect(busyStateChanged, true);
    });
  });

  group('AuthController.register', () {
    test('should return true and set notice on successful registration',
        () async {
      const email = 'newuser@example.com';
      const password = 'password123';
      const displayName = '@newuser';
      const message = 'Account created. Please confirm your email.';

      fakeAuthApi.registerResult = message;

      final result = await authController.register(
        email: email,
        password: password,
        displayName: displayName,
      );

      expect(result, true);
      expect(authController.notice, message);
      expect(authController.isAuthenticated, false);
    });

    test('should return false and set error on registration failure', () async {
      fakeAuthApi.registerException = ApiException(400, 'Email already exists');

      final result = await authController.register(
        email: 'existing@example.com',
        password: 'password123',
        displayName: '@user',
      );

      expect(result, false);
      expect(authController.error, 'Email already exists');
    });
  });

  group('AuthController.forgotPassword', () {
    test('should return true and set notice on successful request', () async {
      const email = 'test@example.com';
      const message = 'Password reset link sent to your email.';

      fakeAuthApi.forgotPasswordResult = message;

      final result = await authController.forgotPassword(email);

      expect(result, true);
      expect(authController.notice, message);
    });

    test('should return false and set error on failure', () async {
      fakeAuthApi.forgotPasswordException = ApiException(404, 'User not found');

      final result =
          await authController.forgotPassword('nonexistent@example.com');

      expect(result, false);
      expect(authController.error, 'User not found');
    });
  });

  group('AuthController.resendActivationEmail', () {
    test('should return true and set notice on successful resend', () async {
      fakeAuthApi.resendConfirmationResult =
          'If that email exists and is unactivated, a new confirmation link has been sent.';

      final result =
          await authController.resendActivationEmail('test@example.com');

      expect(result, true);
      expect(
        authController.notice,
        'If that email exists and is unactivated, a new confirmation link has been sent.',
      );
      expect(authController.error, null);
    });

    test('should return false when resend is requested without email',
        () async {
      final result = await authController.resendActivationEmail('   ');

      expect(result, false);
      expect(authController.error, 'Email is required to resend activation.');
      expect(authController.isBusy, false);
    });

    test('should return false and set error on resend failure', () async {
      fakeAuthApi.resendConfirmationException =
          ApiException(500, 'Server error');

      final result =
          await authController.resendActivationEmail('test@example.com');

      expect(result, false);
      expect(authController.error, 'Server error');
    });
  });

  group('AuthController.checkDisplayNameAvailability', () {
    test('should return true if displayName is available', () async {
      const displayName = '@newuser';
      fakeAuthApi.checkDisplayNameResult = true;

      final available =
          await authController.checkDisplayNameAvailability(displayName);

      expect(available, true);
    });

    test('should return false if displayName is taken', () async {
      const displayName = '@existinguser';
      fakeAuthApi.checkDisplayNameResult = false;

      final available =
          await authController.checkDisplayNameAvailability(displayName);

      expect(available, false);
    });

    test('should not set isBusy during availability check', () async {
      fakeAuthApi.checkDisplayNameResult = true;

      await authController.checkDisplayNameAvailability('@user');

      expect(authController.isBusy, false);
    });
  });

  group('AuthController.logout', () {
    test('should clear authentication state on logout', () async {
      const token = 'token123';
      final mockUser = AuthUser(
        id: 'user123',
        email: 'test@example.com',
        displayName: '@testuser',
        mode: 'PUBLIC',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      fakeAuthApi.loginResult = AuthResult(accessToken: token);
      fakeAuthApi.meResult = mockUser;

      await authController.login(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(authController.isAuthenticated, true);

      await authController.logout();

      expect(authController.isAuthenticated, false);
      expect(authController.currentUser, null);
      expect(authController.notice, null);
      expect(authController.error, null);
      expect(await fakeTokenStore.readToken(), null);
    });
  });

  group('AuthController.clearError', () {
    test('should clear error message', () async {
      fakeAuthApi.loginException = ApiException(401, 'Invalid credentials');

      await authController.login(
        email: 'test@example.com',
        password: 'wrongpassword',
      );

      expect(authController.error, isNotNull);

      authController.clearError();

      expect(authController.error, null);
    });

    test('should not notify if error is already null', () async {
      var notificationCount = 0;
      authController.addListener(() {
        notificationCount++;
      });

      expect(authController.error, null);

      authController.clearError();

      expect(notificationCount, 0);
    });
  });

  group('AuthController.clearNotice', () {
    test('should clear notice message', () async {
      fakeAuthApi.registerResult = 'Success message';

      await authController.register(
        email: 'test@example.com',
        password: 'password123',
        displayName: '@testuser',
      );

      expect(authController.notice, isNotNull);

      authController.clearNotice();

      expect(authController.notice, null);
    });

    test('should not notify if notice is already null', () async {
      var notificationCount = 0;
      authController.addListener(() {
        notificationCount++;
      });

      expect(authController.notice, null);

      authController.clearNotice();

      expect(notificationCount, 0);
    });
  });
}
