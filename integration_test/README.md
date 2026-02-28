# Integration Tests for DrawkcaB Flutter

This directory contains comprehensive integration tests for the DrawkcaB Flutter client, covering critical user journeys including registration, login, password reset, and navigation flows.

## Overview

Integration tests simulate real user interactions with the application, providing end-to-end coverage of authentication and user flows. These tests complement unit tests to achieve comprehensive code coverage.

### Test Suites

1. **Registration Flow** (`registration_flow_test.dart`)
   - Complete registration with valid data
   - Email validation
   - Display name format validation and availability checking
   - Password matching validation
   - Duplicate display name detection
   - Navigation between registration and login screens
   - API error handling

2. **Login Flow** (`login_flow_test.dart`)
   - Complete login with valid credentials
   - Email validation
   - Invalid credential detection
   - Unregistered user handling
   - Navigation to registration and forgot password screens
   - Persistent login across sessions
   - API error handling

3. **Password Reset Flow** (`password_reset_flow_test.dart`)
   - Complete password reset with valid token
   - Invalid token detection
   - Password validation and matching
   - Weak password detection
   - Password reset request from login screen
   - Navigation flows
   - Successful login with new password

4. **Navigation Flow** (`navigation_flow_test.dart`)
   - Authentication-based redirects (unauthenticated to login, authenticated to home)
   - Navigation between all screens
   - Deep linking
   - Email confirmation page handling
   - Logout functionality
   - Complete user journeys

## Test Helpers

The `helpers/` directory contains utilities for integration testing:

- **`mock_auth_api.dart`**: Mock implementation of AuthApi with configurable behavior for testing various scenarios
- **`mock_token_store.dart`**: Mock implementation of TokenStore for testing authentication state
- **`test_app.dart`**: Test wrapper providing a configured DrawkcaB app instance with mock dependencies

## Running Integration Tests

### Prerequisite: Setup a Device/Emulator

Integration tests require a connected device or emulator:

```bash
# For Chrome/Web testing
flutter run -d chrome

# For iOS Simulator
open -a Simulator

# For Android Emulator
~/Android/Sdk/emulator/emulator -avd <emulator_name>
```

### Run All Integration Tests

```bash
# Run all integration tests
flutter test integration_test/

# Run with specific device
flutter test integration_test/ -d chrome
```

### Run Specific Test Suite

```bash
# Registration flow tests
flutter test integration_test/registration_flow_test.dart

# Login flow tests
flutter test integration_test/login_flow_test.dart

# Password reset flow tests
flutter test integration_test/password_reset_flow_test.dart

# Navigation flow tests
flutter test integration_test/navigation_flow_test.dart
```

### Run with Coverage

```bash
# Generate coverage including integration tests
./scripts/coverage.sh

# Run integration tests with coverage
flutter test integration_test/ --coverage

# View HTML coverage report
./scripts/coverage.sh --view
```

## Test Architecture

### Mock Dependencies

Rather than making real HTTP requests, integration tests use mocked API classes:

```dart
// Mock API is pre-configured with test users
final mockAuthApi = MockAuthApi();
mockAuthApi.preRegisterUser(
  'testuser@example.com',
  'SecurePass123!',
  '@testuser',
);

// Mock token store tracks authentication state
final mockTokenStore = MockTokenStore();

// Create test app with mocks
await tester.pumpWidget(
  TestApp(
    initialRoute: '/login',
    mockAuthApi: mockAuthApi,
    mockTokenStore: mockTokenStore,
  ),
);
```

### Simulating API Failures

Tests can simulate various failure scenarios:

```dart
// Configure mock to fail next request
mockAuthApi.setNextFailure(
  message: 'Server error occurred',
  statusCode: 500,
);
```

## Key Test Patterns

### Validation Testing

Tests verify that all input validation works correctly:

```dart
testWidgets('Registration fails with invalid email', (WidgetTester tester) async {
  // Enter invalid email
  await tester.enterText(emailField, 'invalid-email');
  await tester.tap(registerButton);
  
  // Verify validation error appears
  expect(find.textContaining('valid email'), findsOneWidget);
});
```

### Navigation Testing

Tests verify correct navigation based on authentication state:

```dart
testWidgets('Unauthenticated user redirected from home to login', (WidgetTester tester) async {
  await tester.pumpWidget(
    TestApp(initialRoute: '/home', mockAuthApi: mockAuthApi, mockTokenStore: mockTokenStore),
  );
  
  // Should redirect to login
  expect(find.text('Log In'), findsOneWidget);
});
```

### State Persistence Testing

Tests verify that authentication state persists across navigation:

```dart
testWidgets('Persistent login after app restart', (WidgetTester tester) async {
  // Simulate token already stored
  await mockTokenStore.writeToken('mock_token_testuser@example.com');
  
  await tester.pumpWidget(TestApp(initialRoute: '/'));
  
  // Should automatically navigate to home
  expect(find.text('Home'), findsOneWidget);
});
```

## Widget Key Identifiers

Integration tests identify widgets using these keys. Ensure these keys exist in your UI:

- `emailField` - Email input field
- `displayNameField` - Display name input field
- `passwordField` - Password input field
- `confirmPasswordField` - Confirm password input field
- `newPasswordField` - New password in reset form
- `confirmNewPasswordField` - Confirm new password in reset form
- `resetEmailField` - Email field in forgot password modal
- `checkAvailabilityButton` - Display name availability check button

Example implementation:

```dart
TextField(
  key: const Key('emailField'),
  decoration: InputDecoration(labelText: 'Email'),
)
```

## Coverage Goals

The test suite targets the following coverage metrics:

- **Unit Tests**: Core business logic and API clients (65% current coverage)
- **Integration Tests**: User journeys, navigation, and state management
- **Combined**: 80% overall coverage target

Run coverage check:

```bash
./scripts/coverage.sh --check --threshold 80
```

## Debugging Integration Tests

### View Test Output

```bash
# Show verbose test output
flutter test integration_test/ -v

# Capture screenshots on failure
flutter test integration_test/ --verbose --ci
```

### Debug Specific Test

```bash
flutter test integration_test/login_flow_test.dart -v --dart-define=BACKEND_URL=http://localhost:3000/api
```

### Print Debug Information

Add debug output in tests:

```dart
testWidgets('Test description', (WidgetTester tester) async {
  print('Current route: ${tester.binding.window.defaultRouteName}');
  print('Auth state: ${controller.isAuthenticated}');
});
```

## Common Issues & Solutions

### Tests hang on `pumpAndSettle()`

Increase timeout or use a specific duration:

```dart
await tester.pumpAndSettle(const Duration(seconds: 3));
```

### Widget not found errors

Ensure the widget has the correct Key identifier:

```dart
// In your widget
TextFormField(
  key: const Key('emailField'),  // <- Must match test expectations
)
```

### Navigation not working

Verify GoRouter is properly configured in TestApp and routes are defined:

```dart
// Check TestApp has all required routes
GoRoute(
  path: '/login',
  builder: (context, state) => LoginScreen(controller: controller),
)
```

## Best Practices

1. **Use meaningful test names** that describe the user scenario
2. **Isolate tests** with `setUp()` to reset mocks between tests
3. **Test both happy and sad paths** (success and error scenarios)
4. **Verify user feedback** (error messages, success notifications)
5. **Keep tests focused** on user-visible behavior, not implementation details
6. **Use helper methods** to reduce code duplication
7. **Mock external dependencies** (API, storage) consistently

## Contributing

When adding new features that affect user flows:

1. Write integration tests covering the new flow
2. Test both success and failure scenarios
3. Test navigation to/from the feature
4. Update this README with test descriptions
5. Ensure coverage remains above 80%

## Resources

- [Flutter Integration Testing Guide](https://docs.flutter.dev/testing/integration-tests)
- [WidgetTester API Reference](https://api.flutter.dev/flutter/flutter_test/WidgetTester-class.html)
- [GoRouter Documentation](https://pub.dev/packages/go_router)
