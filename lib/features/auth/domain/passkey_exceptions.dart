/// Custom exceptions for passkey authentication operations.
///
/// These exceptions provide type-safe error handling for passkey-related
/// operations, replacing fragile string-based error matching.

/// Exception thrown when a user cancels the passkey authentication flow.
///
/// This typically occurs when the user dismisses the biometric prompt
/// or cancels the passkey selection dialog.
class PasskeyAuthCancelledException implements Exception {
  const PasskeyAuthCancelledException([this.message]);

  final String? message;

  @override
  String toString() =>
      message ?? 'Passkey authentication was cancelled by the user.';
}

/// Exception thrown when no matching passkey credential is found.
///
/// This occurs when attempting to authenticate with a passkey, but the device
/// has no registered passkey for the requested account.
class PasskeyNoCredentialException implements Exception {
  const PasskeyNoCredentialException([this.message]);

  final String? message;

  @override
  String toString() =>
      message ?? 'No matching passkey credential found on this device.';
}

/// Exception thrown when passkey authentication is not supported.
///
/// This can occur if the device doesn't support passkeys, the OS version
/// is too old, or required hardware (e.g., biometric sensors) is unavailable.
class PasskeyNotSupportedException implements Exception {
  const PasskeyNotSupportedException([this.message]);

  final String? message;

  @override
  String toString() =>
      message ?? 'Passkey authentication is not supported on this device.';
}

/// Exception thrown when passkey security verification fails.
///
/// This can occur due to tampering, invalid signatures, or other
/// security-related failures during the passkey authentication process.
class PasskeySecurityException implements Exception {
  const PasskeySecurityException([this.message]);

  final String? message;

  @override
  String toString() =>
      message ?? 'Passkey security verification failed.';
}

/// Exception thrown when the passkey platform is unavailable.
///
/// This occurs when the underlying platform authenticator service
/// cannot be accessed or is not responding.
class PasskeyPlatformException implements Exception {
  const PasskeyPlatformException([this.message]);

  final String? message;

  @override
  String toString() =>
      message ?? 'Passkey platform service is unavailable.';
}

/// Exception thrown when passkey request times out.
///
/// This occurs when the user doesn't respond to the biometric prompt
/// within the allowed time window.
class PasskeyTimeoutException implements Exception {
  const PasskeyTimeoutException([this.message]);

  final String? message;

  @override
  String toString() =>
      message ?? 'Passkey authentication timed out.';
}
