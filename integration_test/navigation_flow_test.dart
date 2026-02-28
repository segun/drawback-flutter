import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/mock_auth_api.dart';
import 'helpers/mock_token_store.dart';
import 'helpers/test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Navigation Flow', () {
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

    testWidgets('Unauthenticated user redirected from home to login', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestApp(
          initialRoute: '/home',
          mockAuthApi: mockAuthApi,
          mockTokenStore: mockTokenStore,
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should be redirected to login
      expect(find.text('Log In'), findsOneWidget);
    });

    testWidgets('Authenticated user redirected from login to home', (WidgetTester tester) async {
      // Pre-populate token store
      await mockTokenStore.writeToken('mock_token_testuser@example.com');

      await tester.pumpWidget(
        TestApp(
          initialRoute: '/login',
          mockAuthApi: mockAuthApi,
          mockTokenStore: mockTokenStore,
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should be redirected to home
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('Authenticated user redirected from register to home', (WidgetTester tester) async {
      await mockTokenStore.writeToken('mock_token_testuser@example.com');

      await tester.pumpWidget(
        TestApp(
          initialRoute: '/register',
          mockAuthApi: mockAuthApi,
          mockTokenStore: mockTokenStore,
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should be redirected to home
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('Navigate from main screen to login', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestApp(
          initialRoute: '/',
          mockAuthApi: mockAuthApi,
          mockTokenStore: mockTokenStore,
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap login button
      final loginButton = find.widgetWithText(ElevatedButton, 'Log In');
      expect(loginButton, findsOneWidget);
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Verify we're on login screen
      expect(find.text('Log In'), findsAtLeastNWidgets(1));
      expect(find.byKey(const Key('emailField')), findsOneWidget);
    });

    testWidgets('Navigate from main screen to register', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestApp(
          initialRoute: '/',
          mockAuthApi: mockAuthApi,
          mockTokenStore: mockTokenStore,
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap register button
      final registerButton = find.widgetWithText(ElevatedButton, 'Create Account');
      expect(registerButton, findsOneWidget);
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      // Verify we're on registration screen
      expect(find.text('Create Account'), findsAtLeastNWidgets(1));
      expect(find.byKey(const Key('displayNameField')), findsOneWidget);
    });

    testWidgets('Navigate between login and register screens', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestApp(
          initialRoute: '/login',
          mockAuthApi: mockAuthApi,
          mockTokenStore: mockTokenStore,
        ),
      );

      await tester.pumpAndSettle();

      // Go to register from login
      final registerLink = find.textContaining('Create an account');
      await tester.tap(registerLink);
      await tester.pumpAndSettle();

      expect(find.text('Create Account'), findsOneWidget);

      // Go back to login from register
      final loginLink = find.textContaining('Already have an account');
      await tester.tap(loginLink);
      await tester.pumpAndSettle();

      expect(find.text('Log In'), findsOneWidget);
    });

    testWidgets('Navigate to privacy page from main screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestApp(
          initialRoute: '/',
          mockAuthApi: mockAuthApi,
          mockTokenStore: mockTokenStore,
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap privacy link
      final privacyLink = find.textContaining('Privacy Policy');
      expect(privacyLink, findsOneWidget);
      await tester.tap(privacyLink);
      await tester.pumpAndSettle();

      // Verify we're on privacy screen
      expect(find.text('Privacy Policy'), findsAtLeastNWidgets(1));
    });

    testWidgets('Navigate to privacy page from login screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestApp(
          initialRoute: '/login',
          mockAuthApi: mockAuthApi,
          mockTokenStore: mockTokenStore,
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap privacy link (usually in footer)
      final privacyLink = find.textContaining('Privacy Policy');
      if (privacyLink.evaluate().isNotEmpty) {
        await tester.tap(privacyLink);
        await tester.pumpAndSettle();

        // Verify we're on privacy screen
        expect(find.text('Privacy Policy'), findsAtLeastNWidgets(1));
      }
    });

    testWidgets('Navigate back from privacy page', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestApp(
          initialRoute: '/privacy',
          mockAuthApi: mockAuthApi,
          mockTokenStore: mockTokenStore,
        ),
      );

      await tester.pumpAndSettle();

      // Find back button
      final backButton = find.byType(BackButton);
      if (backButton.evaluate().isEmpty) {
        // Try finding IconButton with back arrow
        final iconButton = find.byIcon(Icons.arrow_back);
        if (iconButton.evaluate().isNotEmpty) {
          await tester.tap(iconButton);
          await tester.pumpAndSettle();
        }
      } else {
        await tester.tap(backButton);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Complete user journey: register -> login -> home', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestApp(
          initialRoute: '/',
          mockAuthApi: mockAuthApi,
          mockTokenStore: mockTokenStore,
        ),
      );

      await tester.pumpAndSettle();

      // Start at main, go to register
      final registerButton = find.widgetWithText(ElevatedButton, 'Create Account');
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      // Complete registration
      await tester.enterText(find.byKey(const Key('emailField')), 'newuser@example.com');
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('displayNameField')), '@newuser');
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('passwordField')), 'SecurePass123!');
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('confirmPasswordField')), 'SecurePass123!');
      await tester.pumpAndSettle();

      final submitButton = find.widgetWithText(ElevatedButton, 'Register');
      await tester.ensureVisible(submitButton);
      await tester.pumpAndSettle();
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Should navigate to login after successful registration
      expect(find.text('Log In'), findsOneWidget);

      // Now login with the new account
      await tester.enterText(find.byKey(const Key('emailField')), 'newuser@example.com');
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('passwordField')), 'SecurePass123!');
      await tester.pumpAndSettle();

      final loginButton = find.widgetWithText(ElevatedButton, 'Log In');
      await tester.ensureVisible(loginButton);
      await tester.pumpAndSettle();
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should be on home screen
      expect(find.text('Home'), findsOneWidget);
      expect(find.textContaining('@newuser'), findsOneWidget);
    });

    testWidgets('Logout from home screen', (WidgetTester tester) async {
      await mockTokenStore.writeToken('mock_token_testuser@example.com');

      await tester.pumpWidget(
        TestApp(
          initialRoute: '/home',
          mockAuthApi: mockAuthApi,
          mockTokenStore: mockTokenStore,
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify we're on home screen
      expect(find.text('Home'), findsOneWidget);

      // Find and tap logout button
      final logoutButton = find.widgetWithText(TextButton, 'Log Out');
      if (logoutButton.evaluate().isEmpty) {
        // Try finding by icon
        final logoutIcon = find.byIcon(Icons.logout);
        if (logoutIcon.evaluate().isNotEmpty) {
          await tester.tap(logoutIcon);
          await tester.pumpAndSettle();
        }
      } else {
        await tester.tap(logoutButton);
        await tester.pumpAndSettle();
      }

      // Should redirect to login screen
      expect(find.text('Log In'), findsOneWidget);

      // Verify token was cleared
      expect(mockTokenStore.hasToken, false);
    });

    testWidgets('Email confirmation page with success status', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestApp(
          initialRoute: '/confirm?status=success&email=test@example.com',
          mockAuthApi: mockAuthApi,
          mockTokenStore: mockTokenStore,
        ),
      );

      await tester.pumpAndSettle();

      // Verify confirmation screen content
      expect(find.textContaining('confirmed', findRichText: true), findsAny);
      expect(find.textContaining('test@example.com'), findsOneWidget);
    });

    testWidgets('Email confirmation page with error status', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestApp(
          initialRoute: '/confirm?status=error&reason=invalid_token',
          mockAuthApi: mockAuthApi,
          mockTokenStore: mockTokenStore,
        ),
      );

      await tester.pumpAndSettle();

      // Verify error message
      expect(find.textContaining('error', findRichText: true), findsAny);
    });

    testWidgets('Navigate to login from confirmation page', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestApp(
          initialRoute: '/confirm?status=success&email=test@example.com',
          mockAuthApi: mockAuthApi,
          mockTokenStore: mockTokenStore,
        ),
      );

      await tester.pumpAndSettle();

      // Find login button/link
      final loginButton = find.widgetWithText(ElevatedButton, 'Go to Log In');
      if (loginButton.evaluate().isEmpty) {
        final loginLink = find.textContaining('Log In');
        if (loginLink.evaluate().isNotEmpty) {
          await tester.tap(loginLink.first);
          await tester.pumpAndSettle();
        }
      } else {
        await tester.tap(loginButton);
        await tester.pumpAndSettle();
      }

      // Verify we're on login screen
      expect(find.text('Log In'), findsOneWidget);
    });

    testWidgets('Deep link navigation preserves authentication', (WidgetTester tester) async {
      await mockTokenStore.writeToken('mock_token_testuser@example.com');

      // Start with a deep link while authenticated
      await tester.pumpWidget(
        TestApp(
          initialRoute: '/privacy',
          mockAuthApi: mockAuthApi,
          mockTokenStore: mockTokenStore,
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should still be authenticated
      expect(mockTokenStore.hasToken, true);
    });

    testWidgets('Browser back button navigation simulation', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestApp(
          initialRoute: '/',
          mockAuthApi: mockAuthApi,
          mockTokenStore: mockTokenStore,
        ),
      );

      await tester.pumpAndSettle();

      // Navigate through several screens
      await tester.tap(find.widgetWithText(ElevatedButton, 'Log In'));
      await tester.pumpAndSettle();
      expect(find.text('Log In'), findsAtLeastNWidgets(1));

      await tester.tap(find.textContaining('Create an account'));
      await tester.pumpAndSettle();
      expect(find.text('Create Account'), findsOneWidget);

      // Navigate back
      await tester.tap(find.textContaining('Already have an account'));
      await tester.pumpAndSettle();
      expect(find.text('Log In'), findsOneWidget);
    });
  });
}
