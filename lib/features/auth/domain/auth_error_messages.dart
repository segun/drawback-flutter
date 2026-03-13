/// Standardized error messages for authentication operations.
///
/// This file contains all user-facing error messages to ensure consistent
/// capitalization, punctuation, and phrasing across the application.

class AuthErrorMessages {
  AuthErrorMessages._();

  // General errors
  static const String unexpectedError = 'Unexpected error. Please try again.';
  static const String networkUnavailable =
      'No internet connection. Please check your network and try again.';

  // Email validation errors
  static const String emailRequired = 'Email is required.';
  static const String emailRequiredForResend =
      'Email is required to resend activation.';
  static const String emailRequiredForPasskey =
      'Email is required before using passkey login.';

  // Authentication errors
  static const String loginRequired =
      'You need to be logged in before adding a passkey.';
  static const String sessionExpired =
      'Your session has expired. Please log in again.';

  // Token validation errors
  static const String tokenRequired =
      'A valid token is required to register a passkey.';
  static const String tokenFormatInvalid = 'Invalid authentication token format.';
  static const String tokenExpired =
      'Authentication token has expired. Please log in again.';

  // Rate limiting errors
  static const String tooManyPasskeyAttempts =
      'Too many passkey attempts. Please wait before trying again.';

  // Passkey-specific errors
  static const String passkeyAuthCancelled = 'Passkey authentication was cancelled.';
  static const String passkeyRegistrationCancelled =
      'Passkey registration was cancelled.';
  static const String passkeyNoCredential =
      'No matching passkey was found on this device. '
      'Sign in with password, then add a passkey on this device.';
  static const String passkeyNotSupported =
      'Passkey authentication is not supported on this device.';
  static const String passkeySecurityFailed =
      'Security verification failed. Please try again.';
  static const String passkeyAuthFailed =
      'Authentication failed. Please try password login.';
  static const String passkeyNetworkError =
      'Network unavailable. Please use password login '
      'or check your internet connection.';
  static const String passkeyRegistrationFailed =
      'Could not add passkey right now. Please try again.';
  static const String passkeyDuplicate =
      'This passkey is already registered. '
      'Try registering from a different device.';

  // Network errors for passkey operations
  static const String passkeyNetworkUnavailableLogin =
      'Network unavailable. Please use password login '
      'or check your internet connection.';
  static const String passkeyNetworkUnavailableRegistration =
      'Network unavailable. Please try again when you have '
      'a stable internet connection.';

  // Success messages
  static const String passkeyAdded = 'Passkey added successfully.';
  static String welcomeBack(String? displayName) =>
      'Welcome back, ${displayName ?? 'friend'}.';
}
