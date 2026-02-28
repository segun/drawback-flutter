import 'package:flutter/material.dart';

/// Reusable text styles for auth screens
class AuthTextStyles {
  // Header style for screen titles (Login, Create Account, Reset Password, etc.)
  static TextStyle header(BuildContext context) {
    return Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: const Color(0xFFBE185D), // rose-700
        ) ??
        const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFFBE185D),
        );
  }

  // Link style for navigation links (Forgot password?, Need an account?, etc.)
  static TextStyle link() {
    return const TextStyle(
      fontSize: 12,
      color: Color(0xFFBE185D), // rose-700      
    );
  }

  // Welcome message style
  static TextStyle welcome(BuildContext context) {
    return Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: const Color(0xFFBE185D), // rose-700
        ) ??
        const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFFBE185D),
        );
  }

  // Body text style for descriptions
  static TextStyle bodyText(BuildContext context) {
    return Theme.of(context).textTheme.labelMedium?.copyWith(
          color: const Color(0xFF9F1239), // rose-800
        ) ??
        const TextStyle(
          fontSize: 11,
          color: Color(0xFF9F1239),
        );
  }

  // Link button style
  static ButtonStyle linkButtonStyle() {
    return TextButton.styleFrom(
      foregroundColor: const Color(0xFFBE185D), // rose-700
      padding: EdgeInsets.zero,      
      minimumSize: const Size(0, 0),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,      
    );
  }
}
