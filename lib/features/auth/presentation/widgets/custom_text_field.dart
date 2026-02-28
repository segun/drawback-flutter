import 'package:flutter/material.dart';

/// Reusable text field widget for auth screens with consistent styling
class CustomTextField extends StatelessWidget {
  const CustomTextField({
    required this.controller,
    required this.labelText,
    this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.maxLength,
    this.validator,
    this.onChanged,
    this.suffixIcon,
    this.errorText,
    super.key,
  });

  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLength;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final Widget? suffixIcon;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLength: maxLength,
      style: const TextStyle(
        fontSize: 13, // Smaller text size
      ),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        counterText: '',
        suffixIcon: suffixIcon,
        errorText: errorText,
        labelStyle: const TextStyle(
          fontSize: 13, // Smaller label size
        ),
        hintStyle: const TextStyle(
          fontSize: 13, // Smaller hint size
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8, // Smaller padding for compact fields
        ),
        isDense: true, // More compact
      ),
      validator: validator,
      onChanged: onChanged,
    );
  }
}
