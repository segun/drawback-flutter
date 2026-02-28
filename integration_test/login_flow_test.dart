import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/mock_auth_api.dart';
import 'helpers/mock_token_store.dart';
import 'helpers/test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('User Login Flow', () {
    late MockAuthApi mockAuthApi;
    late MockTokenStore mockTokenStore;

    setUp(() {
      mockAuthApi = MockAuthApi();
      mockTokenStore = MockTokenStore();
      
      // Pre-register a test user
      mockAuthApi.preRegisterUser(
        'testuser@example.com',
        'SecurePass123!',
        '@testuser',
      );
    });

    testWidgets('Complete login flow with valid credentials', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestApp(
          initialRoute: '/login',
          mockAuthApi: mockAuthApi,
          mockTokenStore: mockTokenStore,
        ),
      );

      await tester.pumpAndSettle();

      // Verify we're on the login screen
      expect(find.text('Log In'), findsOneWidget);

      // Enter email
      final emailField = find.byKey(const Key('emailField'));
      expect(emailField, findsOneWidget);
      await tester.enterText(emailField, 'testuser@example.com');
      await tester.pumpAndSettle();

      // Enter password
      final passwordField = find.byKey(const Key('passwordField'));
      expect(passwordField, findsOneWidget);
      await tester.enterText(passwordField, 'SecurePass123!');
      await tester.pumpAndSettle();

      // Submit form
      final loginButton = find.widgetWithText(ElevatedButton, 'Log In');
      expect(loginButton, findsOneWidget);
      await tester.ensureVisible(loginButton);
      await tester.pumpAndSettle();
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Wait for navigation and auth state update
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify token was stored
      expect(mockTokenStore.hasToken, true);
      expect(mockTokenStore.currentToken, contains('mock_token_'));

      // Verify we navigated to home screen
      expect(find.text('Home'), findsOneWidget);
      expect(find.textContaining('@testuser'), findsOneWidget);
    });

    testWidgets('Login fails with invalid email', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestApp(
          initialRoute: '/login',
          mockAuthApi: mockAuthApi,
          mockTokenStore: mockTokenStore,
        ),
      );

      await tester.pumpAndSettle();

      // Enter invalid email
      final emailField = find.byKey(const Key('emailField'));
      await tester.enterText(emailField, 'invalid-email');
      await tester.pumpAndSettle();

      // Enter password
      final passwordField = find.byKey(const Key('passwordField'));
      await tester.enterText(passwordField, 'SecurePass123!');
      await tester.pumpAndSettle();

      // Try to submit
      final loginButton = find.widgetWithText(ElevatedButton, 'Log In');
      await tester.ensureVisible(loginButton);
      await tester.pumpAndSettle();
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Verify error message appears
      expect(
        find.textContaining('valid email'),
        findsOneWidget,
      );

      // Verify we're still on login screen
      expect(find.text('Log In'), findsOneWidget);

      // Verify token was not stored
      expect(mockTokenStore.hasToken, false);
    });

    testWidgets('Login fails with wrong credentials', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestApp(
          initialRoute: '/login',
          mockAuthApi: mockAuthApi,
          mockTokenStore: mockTokenStore,
        ),
      );

      await tester.pumpAndSettle();

      // Enter registered email but wrong password
      await tester.enterText(find.byKey(const Key('emailField')), 'testuser@example.com');
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('passwordField')), 'WrongPassword123!');
      await tester.pumpAndSettle();

      // Submit form
      final loginButton = find.widgetWithText(ElevatedButton, 'Log In');
      await tester.ensureVisible(loginButton);
      await tester.pumpAndSettle();
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Verify error message
      expect(
        find.textContaining('Invalid email or password'),
        findsOneWidget,
      );

      // Verify token was not stored
      expect(mockTokenStore.hasToken, false);
    });

    testWidgets('Login fails with unregistered email', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestApp(
          initialRoute: '/login',
          mockAuthApi: mockAuthApi,
          mockTokenStore: mockTokenStore,
        ),
      );

      await tester.pumpAndSettle();

      // Enter unregistered email
      await tester.enterText(find.byKey(const Key('emailField')), 'unknown@example.com');
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('passwordField')), 'SomePassword123!');
      await tester.pumpAndSettle();

      // Submit form
      final loginButton = find.widgetWithText(ElevatedButton, 'Log In');
      await tester.ensureVisible(loginButton);
      await tester.pumpAndSettle();
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Verify error message
      expect(
        find.textContaining('Invalid email or password'),
        findsOneWidget,
      );

      // Verify token was not stored
      expect(mockTokenStore.hasToken, false);
    });

    testWidgets('Navigate to registration screen from login', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestApp(
          initialRoute: '/login',
          mockAuthApi: mockAuthApi,
          mockTokenStore: mockTokenStore,
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap "Create an account" link
      final registerLink = find.textContaining('Create an account');
      expect(registerLink, findsOneWidget);
      await tester.tap(registerLink);
      await tester.pumpAndSettle();

      // Verify we're on registration screen
      expect(find.text('Create Account'), findsOneWidget);
    });

    testWidgets('Open forgot password modal from login', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestApp(
          initialRoute: '/login',
          mockAuthApi: mockAuthApi,
          mockTokenStore: mockTokenStore,
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap "Forgot password?" link
      final forgotPasswordLink = find.textContaining('Forgot password');
      expect(forgotPasswordLink, findsOneWidget);
      await tester.tap(forgotPasswordLink);
      await tester.pumpAndSettle();

      // Verify modal is shown
      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.byKey(const Key('resetEmailField')), findsOneWidget);
    });

    testWidgets('Forgot password flow from login screen', (WidgetTester tester) async {
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
      expect(resetEmailField, findsOneWidget);
      await tester.enterText(resetEmailField, 'testuser@example.com');
      await tester.pumpAndSettle();

      // Submit
      final sendButton = find.widgetWithText(ElevatedButton, 'Send Reset Link');
      expect(sendButton, findsOneWidget);
      await tester.tap(sendButton);
      await tester.pumpAndSettle();

      // Verify success message
      expect(
        find.textContaining('password reset link has been sent'),
        findsOneWidget,
      );
    });

    testWidgets('API error handling during login', (WidgetTester tester) async {
      // Configure mock to fail next request
      mockAuthApi.setNextFailure(
        message: 'Service temporarily unavailable',
        statusCode: 503,
      );

      await tester.pumpWidget(
        TestApp(
          initialRoute: '/login',
          mockAuthApi: mockAuthApi,
          mockTokenStore: mockTokenStore,
        ),
      );

      await tester.pumpAndSettle();

      // Enter valid credentials
      await tester.enterText(find.byKey(const Key('emailField')), 'testuser@example.com');
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('passwordField')), 'SecurePass123!');
      await tester.pumpAndSettle();

      // Try to login
      final loginButton = find.widgetWithText(ElevatedButton, 'Log In');
      await tester.ensureVisible(loginButton);
      await tester.pumpAndSettle();
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Verify error message is displayed
      expect(find.textContaining('Service temporarily unavailable'), findsOneWidget);

      // Verify token was not stored
      expect(mockTokenStore.hasToken, false);
    });

    testWidgets('Persistent login after app restart', (WidgetTester tester) async {
      // Simulate a token already stored from previous session
      await mockTokenStore.writeToken('mock_token_testuser@example.com');

      await tester.pumpWidget(
        TestApp(
          initialRoute: '/',
          mockAuthApi: mockAuthApi,
          mockTokenStore: mockTokenStore,
        ),
      );

      // Wait for bootstrap to complete
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should automatically navigate to home screen
      expect(find.text('Home'), findsOneWidget);
      expect(find.textContaining('@testuser'), findsOneWidget);
    });

    testWidgets('Required field validation on login', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestApp(
          initialRoute: '/login',
          mockAuthApi: mockAuthApi,
          mockTokenStore: mockTokenStore,
        ),
      );

      await tester.pumpAndSettle();

      // Try to submit empty form
      final loginButton = find.widgetWithText(ElevatedButton, 'Log In');
      await tester.ensureVisible(loginButton);
      await tester.pumpAndSettle();
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Verify validation errors appear
      expect(
        find.textContaining('required', findRichText: true),
        findsAtLeastNWidgets(1),
      );

      // Verify we're still on login screen
      expect(find.text('Log In'), findsOneWidget);
    });
  });
}
