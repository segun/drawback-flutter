import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/mock_auth_api.dart';
import 'helpers/mock_token_store.dart';
import 'helpers/test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Password Reset Flow', () {
    late MockAuthApi mockAuthApi;
    late MockTokenStore mockTokenStore;

    setUp(() {
      mockAuthApi = MockAuthApi();
      mockTokenStore = MockTokenStore();
      
      // Pre-register a test user
      mockAuthApi.preRegisterUser(
        'testuser@example.com',
        'OldPassword123!',
        '@testuser',
      );
    });

    testWidgets('Complete password reset flow with valid token', (WidgetTester tester) async {
      // Generate a reset token
      final resetToken = mockAuthApi.createResetToken('testuser@example.com');

      await tester.pumpWidget(
        TestApp(
          initialRoute: '/reset-password?token=$resetToken',
          mockAuthApi: mockAuthApi,
          mockTokenStore: mockTokenStore,
        ),
      );

      await tester.pumpAndSettle();

      // Verify we're on the reset password screen
      expect(find.text('Reset Your Password'), findsOneWidget);

      // Enter new password
      final newPasswordField = find.byKey(const Key('newPasswordField'));
      expect(newPasswordField, findsOneWidget);
      await tester.enterText(newPasswordField, 'NewSecurePass123!');
      await tester.pumpAndSettle();

      // Confirm new password
      final confirmPasswordField = find.byKey(const Key('confirmNewPasswordField'));
      expect(confirmPasswordField, findsOneWidget);
      await tester.enterText(confirmPasswordField, 'NewSecurePass123!');
      await tester.pumpAndSettle();

      // Submit form
      final resetButton = find.widgetWithText(ElevatedButton, 'Reset Password');
      expect(resetButton, findsOneWidget);
      await tester.ensureVisible(resetButton);
      await tester.pumpAndSettle();
      await tester.tap(resetButton);
      await tester.pumpAndSettle();

      // Verify success message
      expect(
        find.textContaining('Password reset successful'),
        findsOneWidget,
      );
    });

    testWidgets('Password reset fails with invalid token', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestApp(
          initialRoute: '/reset-password?token=invalid_token_123',
          mockAuthApi: mockAuthApi,
          mockTokenStore: mockTokenStore,
        ),
      );

      await tester.pumpAndSettle();

      // Enter new password
      await tester.enterText(find.byKey(const Key('newPasswordField')), 'NewSecurePass123!');
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('confirmNewPasswordField')), 'NewSecurePass123!');
      await tester.pumpAndSettle();

      // Submit form
      final resetButton = find.widgetWithText(ElevatedButton, 'Reset Password');
      await tester.ensureVisible(resetButton);
      await tester.pumpAndSettle();
      await tester.tap(resetButton);
      await tester.pumpAndSettle();

      // Verify error message
      expect(
        find.textContaining('Invalid or expired reset token'),
        findsOneWidget,
      );
    });

    testWidgets('Password reset fails when passwords do not match', (WidgetTester tester) async {
      final resetToken = mockAuthApi.createResetToken('testuser@example.com');

      await tester.pumpWidget(
        TestApp(
          initialRoute: '/reset-password?token=$resetToken',
          mockAuthApi: mockAuthApi,
          mockTokenStore: mockTokenStore,
        ),
      );

      await tester.pumpAndSettle();

      // Enter mismatched passwords
      await tester.enterText(find.byKey(const Key('newPasswordField')), 'NewSecurePass123!');
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('confirmNewPasswordField')), 'DifferentPass123!');
      await tester.pumpAndSettle();

      // Try to submit
      final resetButton = find.widgetWithText(ElevatedButton, 'Reset Password');
      await tester.ensureVisible(resetButton);
      await tester.pumpAndSettle();
      await tester.tap(resetButton);
      await tester.pumpAndSettle();

      // Verify validation error
      expect(
        find.textContaining('must match', findRichText: true),
        findsAny,
      );
    });

    testWidgets('Password reset fails with weak password', (WidgetTester tester) async {
      final resetToken = mockAuthApi.createResetToken('testuser@example.com');

      await tester.pumpWidget(
        TestApp(
          initialRoute: '/reset-password?token=$resetToken',
          mockAuthApi: mockAuthApi,
          mockTokenStore: mockTokenStore,
        ),
      );

      await tester.pumpAndSettle();

      // Enter weak password
      await tester.enterText(find.byKey(const Key('newPasswordField')), '123');
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('confirmNewPasswordField')), '123');
      await tester.pumpAndSettle();

      // Try to submit
      final resetButton = find.widgetWithText(ElevatedButton, 'Reset Password');
      await tester.ensureVisible(resetButton);
      await tester.pumpAndSettle();
      await tester.tap(resetButton);
      await tester.pumpAndSettle();

      // Verify validation error
      expect(
        find.textContaining('at least', findRichText: true),
        findsAny,
      );
    });

    testWidgets('Navigate to reset password screen without token', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestApp(
          initialRoute: '/reset-password',
          mockAuthApi: mockAuthApi,
          mockTokenStore: mockTokenStore,
        ),
      );

      await tester.pumpAndSettle();

      // Should show message about missing token
      expect(
        find.textContaining('token', findRichText: true),
        findsAny,
      );
    });

    testWidgets('Request password reset from login screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestApp(
          initialRoute: '/login',
          mockAuthApi: mockAuthApi,
          mockTokenStore: mockTokenStore,
        ),
      );

      await tester.pumpAndSettle();

      // Open forgot password modal
      final forgotPasswordLink = find.textContaining('Forgot password');
      await tester.tap(forgotPasswordLink);
      await tester.pumpAndSettle();

      // Enter email
      final resetEmailField = find.byKey(const Key('resetEmailField'));
      await tester.enterText(resetEmailField, 'testuser@example.com');
      await tester.pumpAndSettle();

      // Submit request
      final sendButton = find.widgetWithText(ElevatedButton, 'Send Reset Link');
      await tester.tap(sendButton);
      await tester.pumpAndSettle();

      // Verify success message
      expect(
        find.textContaining('password reset link has been sent'),
        findsOneWidget,
      );
    });

    testWidgets('Password reset request with invalid email format', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestApp(
          initialRoute: '/login',
          mockAuthApi: mockAuthApi,
          mockTokenStore: mockTokenStore,
        ),
      );

      await tester.pumpAndSettle();

      // Open forgot password modal
      final forgotPasswordLink = find.textContaining('Forgot password');
      await tester.tap(forgotPasswordLink);
      await tester.pumpAndSettle();

      // Enter invalid email
      final resetEmailField = find.byKey(const Key('resetEmailField'));
      await tester.enterText(resetEmailField, 'not-an-email');
      await tester.pumpAndSettle();

      // Try to submit
      final sendButton = find.widgetWithText(ElevatedButton, 'Send Reset Link');
      await tester.tap(sendButton);
      await tester.pumpAndSettle();

      // Verify validation error
      expect(
        find.textContaining('valid email'),
        findsOneWidget,
      );
    });

    testWidgets('Navigate back to login from reset password screen', (WidgetTester tester) async {
      final resetToken = mockAuthApi.createResetToken('testuser@example.com');

      await tester.pumpWidget(
        TestApp(
          initialRoute: '/reset-password?token=$resetToken',
          mockAuthApi: mockAuthApi,
          mockTokenStore: mockTokenStore,
        ),
      );

      await tester.pumpAndSettle();

      // Find back to login link
      final backLink = find.textContaining('Back to Log In');
      expect(backLink, findsOneWidget);
      await tester.tap(backLink);
      await tester.pumpAndSettle();

      // Verify we're on login screen
      expect(find.text('Log In'), findsOneWidget);
    });

    testWidgets('API error handling during password reset', (WidgetTester tester) async {
      final resetToken = mockAuthApi.createResetToken('testuser@example.com');
      
      // Configure mock to fail next request
      mockAuthApi.setNextFailure(
        message: 'Password reset service unavailable',
        statusCode: 503,
      );

      await tester.pumpWidget(
        TestApp(
          initialRoute: '/reset-password?token=$resetToken',
          mockAuthApi: mockAuthApi,
          mockTokenStore: mockTokenStore,
        ),
      );

      await tester.pumpAndSettle();

      // Enter valid passwords
      await tester.enterText(find.byKey(const Key('newPasswordField')), 'NewSecurePass123!');
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('confirmNewPasswordField')), 'NewSecurePass123!');
      await tester.pumpAndSettle();

      // Try to submit
      final resetButton = find.widgetWithText(ElevatedButton, 'Reset Password');
      await tester.ensureVisible(resetButton);
      await tester.pumpAndSettle();
      await tester.tap(resetButton);
      await tester.pumpAndSettle();

      // Verify error message is displayed
      expect(
        find.textContaining('Password reset service unavailable'),
        findsOneWidget,
      );
    });

    testWidgets('Successfully login with new password after reset', (WidgetTester tester) async {
      // First, reset the password
      final resetToken = mockAuthApi.createResetToken('testuser@example.com');

      await tester.pumpWidget(
        TestApp(
          initialRoute: '/reset-password?token=$resetToken',
          mockAuthApi: mockAuthApi,
          mockTokenStore: mockTokenStore,
        ),
      );

      await tester.pumpAndSettle();

      // Complete password reset
      await tester.enterText(find.byKey(const Key('newPasswordField')), 'NewSecurePass123!');
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('confirmNewPasswordField')), 'NewSecurePass123!');
      await tester.pumpAndSettle();

      final resetButton = find.widgetWithText(ElevatedButton, 'Reset Password');
      await tester.ensureVisible(resetButton);
      await tester.pumpAndSettle();
      await tester.tap(resetButton);
      await tester.pumpAndSettle();

      // Navigate to login
      final backLink = find.textContaining('Back to Log In');
      if (backLink.evaluate().isNotEmpty) {
        await tester.tap(backLink);
        await tester.pumpAndSettle();
      }

      // Now try to login with new password
      await tester.enterText(find.byKey(const Key('emailField')), 'testuser@example.com');
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('passwordField')), 'NewSecurePass123!');
      await tester.pumpAndSettle();

      final loginButton = find.widgetWithText(ElevatedButton, 'Log In');
      await tester.ensureVisible(loginButton);
      await tester.pumpAndSettle();
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify successful login
      expect(find.text('Home'), findsOneWidget);
      expect(mockTokenStore.hasToken, true);
    });
  });
}
