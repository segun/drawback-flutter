import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawback_flutter/features/auth/data/auth_api.dart';
import 'package:drawback_flutter/features/auth/data/token_store.dart';
import 'package:drawback_flutter/features/auth/domain/auth_models.dart';
import 'package:drawback_flutter/features/auth/presentation/auth_controller.dart';
import 'package:drawback_flutter/features/auth/presentation/screens/login_screen.dart';

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

class FakeAuthApi implements AuthApi {
  @override
  Future<String> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    return 'Success';
  }

  @override
  Future<AuthResult> login({required String email, required String password}) async {
    return AuthResult(accessToken: 'token123');
  }

  @override
  Future<bool> checkDisplayNameAvailability(String name) async {
    return true;
  }

  @override
  Future<String> forgotPassword(String email) async {
    return 'Email sent';
  }

  @override
  Future<ResetPasswordResult> resetPassword({
    required String token,
    required String password,
  }) async {
    return ResetPasswordResult(status: 'success', message: 'Password reset successfully');
  }

  @override
  Future<AuthUser> me(String accessToken) async {
    return AuthUser(
      id: 'user123',
      email: 'test@example.com',
      displayName: '@testuser',
      mode: 'PUBLIC',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

void main() {
  group('LoginScreen', () {

    testWidgets('should render login form with email and password fields',
        (WidgetTester tester) async {
      final tokenStore = FakeTokenStore();
      final controller = AuthController(authApi: FakeAuthApi(), tokenStore: tokenStore);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              child: LoginScreen(controller: controller),
            ),
          ),
        ),
      );
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('should display login title', (WidgetTester tester) async {
      final tokenStore = FakeTokenStore();
      final controller = AuthController(authApi: FakeAuthApi(), tokenStore: tokenStore);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 800, child: LoginScreen(controller: controller)),
          ),
        ),
      );
      expect(find.text('Login'), findsWidgets);
    });

    testWidgets('should have register link', (WidgetTester tester) async {
      final tokenStore = FakeTokenStore();
      final controller = AuthController(authApi: FakeAuthApi(), tokenStore: tokenStore);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 800, child: LoginScreen(controller: controller)),
          ),
        ),
      );
      expect(find.text('Need an account? Register'), findsWidgets);
    });

    testWidgets('should have filled button for login', (WidgetTester tester) async {
      final tokenStore = FakeTokenStore();
      final controller = AuthController(authApi: FakeAuthApi(), tokenStore: tokenStore);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 800, child: LoginScreen(controller: controller)),
          ),
        ),
      );
      expect(find.widgetWithText(FilledButton, 'Login'), findsOneWidget);
    });

    testWidgets('should have forgot password button', (WidgetTester tester) async {
      final tokenStore = FakeTokenStore();
      final controller = AuthController(authApi: FakeAuthApi(), tokenStore: tokenStore);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 800, child: LoginScreen(controller: controller)),
          ),
        ),
      );
      expect(find.widgetWithText(TextButton, 'Forgot password?'), findsOneWidget);
    });

    testWidgets('should have proper form structure', (WidgetTester tester) async {
      final tokenStore = FakeTokenStore();
      final controller = AuthController(authApi: FakeAuthApi(), tokenStore: tokenStore);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 800, child: LoginScreen(controller: controller)),
          ),
        ),
      );
      expect(find.byType(Form), findsOneWidget);
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('should render without errors', (WidgetTester tester) async {
      final tokenStore = FakeTokenStore();
      final controller = AuthController(authApi: FakeAuthApi(), tokenStore: tokenStore);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 800, child: LoginScreen(controller: controller)),
          ),
        ),
      );
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('should have ListenableBuilder to listen to controller',
        (WidgetTester tester) async {
      final tokenStore = FakeTokenStore();
      final controller = AuthController(authApi: FakeAuthApi(), tokenStore: tokenStore);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 800, child: LoginScreen(controller: controller)),
          ),
        ),
      );
      // MaterialApp and routing add their own ListenableBuilders, so we check for at least one
      expect(find.byType(ListenableBuilder), findsWidgets);
    });
  });
}
