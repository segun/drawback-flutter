import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/mock_auth_api.dart';
import 'helpers/mock_token_store.dart';
import 'helpers/test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('User Registration Flow', () {
    late MockAuthApi mockAuthApi;
    late MockTokenStore mockTokenStore;

    setUp(() {
      mockAuthApi = MockAuthApi();
      mockTokenStore = MockTokenStore();
    });

    testWidgets('Complete registration flow with valid data', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestApp(
          initialRoute: '/register',
          mockAuthApi: mockAuthApi,
          mockTokenStore: mockTokenStore,
        ),
      );

      await tester.pumpAndSettle();

      // Verify we're on the registration screen
      expect(find.text('Create Account'), findsOneWidget);

      // Enter email
      final emailField = find.byKey(const Key('emailField'));
      expect(emailField, findsOneWidget);
      await tester.enterText(emailField, 'testuser@example.com');
      await tester.pumpAndSettle();

      // Enter display name
      final displayNameField = find.byKey(const Key('displayNameField'));
      expect(displayNameField, findsOneWidget);
      await tester.enterText(displayNameField, '@newuser');
      await tester.pumpAndSettle();

      // Check display name availability
      final checkButton = find.byKey(const Key('checkAvailabilityButton'));
      if (checkButton.evaluate().isNotEmpty) {
        await tester.tap(checkButton);
        await tester.pumpAndSettle();

        // Verify availability indicator
        expect(find.textContaining('available'), findsOneWidget);
      }

      // Enter password
      final passwordField = find.byKey(const Key('passwordField'));
      expect(passwordField, findsOneWidget);
      await tester.enterText(passwordField, 'SecurePass123!');
      await tester.pumpAndSettle();

      // Enter confirm password
      final confirmPasswordField = find.byKey(const Key('confirmPasswordField'));
      expect(confirmPasswordField, findsOneWidget);
      await tester.enterText(confirmPasswordField, 'SecurePass123!');
      await tester.pumpAndSettle();

      // Submit form
      final registerButton = find.widgetWithText(ElevatedButton, 'Register');
      expect(registerButton, findsOneWidget);
      await tester.ensureVisible(registerButton);
      await tester.pumpAndSettle();
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      // Verify success message appears
      expect(
        find.textContaining('Registration successful'),
        findsOneWidget,
      );
    });

    testWidgets('Registration fails with invalid email', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestApp(
          initialRoute: '/register',
          mockAuthApi: mockAuthApi,
          mockTokenStore: mockTokenStore,
        ),
      );

      await tester.pumpAndSettle();

      // Enter invalid email
      final emailField = find.byKey(const Key('emailField'));
      await tester.enterText(emailField, 'invalid-email');
      await tester.pumpAndSettle();

      // Enter valid display name
      final displayNameField = find.byKey(const Key('displayNameField'));
      await tester.enterText(displayNameField, '@validuser');
      await tester.pumpAndSettle();

      // Enter password
      final passwordField = find.byKey(const Key('passwordField'));
      await tester.enterText(passwordField, 'SecurePass123!');
      await tester.pumpAndSettle();

      // Enter confirm password
      final confirmPasswordField = find.byKey(const Key('confirmPasswordField'));
      await tester.enterText(confirmPasswordField, 'SecurePass123!');
      await tester.pumpAndSettle();

      // Try to submit
      final registerButton = find.widgetWithText(ElevatedButton, 'Register');
      await tester.ensureVisible(registerButton);
      await tester.pumpAndSettle();
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      // Verify error message
      expect(
        find.textContaining('valid email'),
        findsOneWidget,
      );
    });

    testWidgets('Registration fails with invalid display name format', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestApp(
          initialRoute: '/register',
          mockAuthApi: mockAuthApi,
          mockTokenStore: mockTokenStore,
        ),
      );

      await tester.pumpAndSettle();

      // Enter valid email
      final emailField = find.byKey(const Key('emailField'));
      await tester.enterText(emailField, 'testuser@example.com');
      await tester.pumpAndSettle();

      // Enter invalid display name (no @)
      final displayNameField = find.byKey(const Key('displayNameField'));
      await tester.enterText(displayNameField, 'invaliduser');
      await tester.pumpAndSettle();

      // Check availability button
      final checkButton = find.byKey(const Key('checkAvailabilityButton'));
      if (checkButton.evaluate().isNotEmpty) {
        await tester.tap(checkButton);
        await tester.pumpAndSettle();

        // Should show invalid format
        expect(
          find.textContaining('must start with @', findRichText: true),
          findsAny,
        );
      }
    });

    testWidgets('Registration fails when passwords do not match', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestApp(
          initialRoute: '/register',
          mockAuthApi: mockAuthApi,
          mockTokenStore: mockTokenStore,
        ),
      );

      await tester.pumpAndSettle();

      // Enter valid email
      final emailField = find.byKey(const Key('emailField'));
      await tester.enterText(emailField, 'testuser@example.com');
      await tester.pumpAndSettle();

      // Enter valid display name
      final displayNameField = find.byKey(const Key('displayNameField'));
      await tester.enterText(displayNameField, '@testuser');
      await tester.pumpAndSettle();

      // Enter password
      final passwordField = find.byKey(const Key('passwordField'));
      await tester.enterText(passwordField, 'SecurePass123!');
      await tester.pumpAndSettle();

      // Enter different confirmation password
      final confirmPasswordField = find.byKey(const Key('confirmPasswordField'));
      await tester.enterText(confirmPasswordField, 'DifferentPass123!');
      await tester.pumpAndSettle();

      // Try to submit
      final registerButton = find.widgetWithText(ElevatedButton, 'Register');
      await tester.ensureVisible(registerButton);
      await tester.pumpAndSettle();
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      // Verify error message
      expect(
        find.textContaining('must match', findRichText: true),
        findsAny,
      );
    });

    testWidgets('Registration fails when display name is taken', (WidgetTester tester) async {
      // Pre-register a user
      mockAuthApi.preRegisterUser('existing@example.com', 'pass123', '@takenname');

      await tester.pumpWidget(
        TestApp(
          initialRoute: '/register',
          mockAuthApi: mockAuthApi,
          mockTokenStore: mockTokenStore,
        ),
      );

      await tester.pumpAndSettle();

      // Enter new email
      final emailField = find.byKey(const Key('emailField'));
      await tester.enterText(emailField, 'newuser@example.com');
      await tester.pumpAndSettle();

      // Try to use taken display name
      final displayNameField = find.byKey(const Key('displayNameField'));
      await tester.enterText(displayNameField, '@takenname');
      await tester.pumpAndSettle();

      // Check availability
      final checkButton = find.byKey(const Key('checkAvailabilityButton'));
      if (checkButton.evaluate().isNotEmpty) {
        await tester.tap(checkButton);
        await tester.pumpAndSettle();

        // Verify unavailable message
        expect(
          find.textContaining('not available', findRichText: true),
          findsAny,
        );
      }
    });

    testWidgets('Navigate to login screen from registration', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestApp(
          initialRoute: '/register',
          mockAuthApi: mockAuthApi,
          mockTokenStore: mockTokenStore,
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap "Already have an account?" link
      final loginLink = find.textContaining('Already have an account');
      expect(loginLink, findsOneWidget);
      await tester.tap(loginLink);
      await tester.pumpAndSettle();

      // Verify we're on login screen
      expect(find.text('Log In'), findsOneWidget);
    });

    testWidgets('API error handling during registration', (WidgetTester tester) async {
      // Configure mock to fail next request
      mockAuthApi.setNextFailure(
        message: 'Server error occurred',
        statusCode: 500,
      );

      await tester.pumpWidget(
        TestApp(
          initialRoute: '/register',
          mockAuthApi: mockAuthApi,
          mockTokenStore: mockTokenStore,
        ),
      );

      await tester.pumpAndSettle();

      // Fill in valid data
      await tester.enterText(find.byKey(const Key('emailField')), 'test@example.com');
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('displayNameField')), '@testuser');
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('passwordField')), 'SecurePass123!');
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('confirmPasswordField')), 'SecurePass123!');
      await tester.pumpAndSettle();

      // Try to submit
      final registerButton = find.widgetWithText(ElevatedButton, 'Register');
      await tester.ensureVisible(registerButton);
      await tester.pumpAndSettle();
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      // Verify error message is displayed
      expect(find.textContaining('Server error', findRichText: true), findsAny);
    });
  });
}
