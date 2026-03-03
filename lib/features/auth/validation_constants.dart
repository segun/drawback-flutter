/// Validation regex patterns for authentication
class ValidationPatterns {
  /// Email validation pattern
  /// Matches: user@example.com
  static final RegExp emailPattern = RegExp(
    r'^[^\s@]+@(?:[A-Za-z0-9-]+\.)+[A-Za-z]{2,}$',
  );

  /// Display name validation pattern
  /// Matches: @ followed by 3-29 letters, numbers, or underscores
  static final RegExp displayNamePattern = RegExp(
    r'^@[A-Za-z0-9_]{2,29}$',
  );
}
