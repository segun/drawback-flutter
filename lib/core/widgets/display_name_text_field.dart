import 'package:flutter/material.dart';

/// Text field for display name input with @ prefix protection
/// The @ symbol cannot be deleted and is always at the start
class DisplayNameTextField extends StatefulWidget {
  const DisplayNameTextField({
    required this.controller,
    this.labelText = 'Display Name',
    this.hintText = '@username',
    this.hintStyle,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.errorText,
    this.maxLength,
    this.autofocus = false,
    this.enabled = true,
    this.decoration,
    this.textStyle,
    this.suffixIcon,
    this.focusNode,
    super.key,
  });

  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final TextStyle? hintStyle;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final String? errorText;
  final int? maxLength;
  final bool autofocus;
  final bool enabled;
  final InputDecoration? decoration;
  final TextStyle? textStyle;
  final Widget? suffixIcon;
  final FocusNode? focusNode;

  @override
  State<DisplayNameTextField> createState() => _DisplayNameTextFieldState();
}

class _DisplayNameTextFieldState extends State<DisplayNameTextField> {
  @override
  void initState() {
    super.initState();
    // Ensure @ prefix exists on initialization
    if (widget.controller.text.isEmpty) {
      widget.controller.text = '@';
    }
  }

  String _normalizeDisplayName(String value) {
    final String trimmed = value.trimLeft();
    if (trimmed.isEmpty) {
      return '@';
    }
    return trimmed.startsWith('@') ? trimmed : '@$trimmed';
  }

  void _handleOnChanged(String value) {
    final String normalized = _normalizeDisplayName(value);
    final int cursorOffset = widget.controller.selection.baseOffset;
    final int adjustment = normalized.length - value.length;
    
    widget.controller.text = normalized;
    widget.controller.selection = TextSelection.fromPosition(
      TextPosition(
        offset: (cursorOffset + adjustment).clamp(1, normalized.length),
      ),
    );
    widget.onChanged?.call(normalized);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      keyboardType: widget.keyboardType,
      maxLength: widget.maxLength,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      validator: widget.validator,
      style: widget.textStyle ??
          const TextStyle(
            fontSize: 13,
          ),
      decoration: widget.decoration ??
          InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            counterText: '',
            suffixIcon: widget.suffixIcon,
            errorText: widget.errorText,
            hintStyle: widget.hintStyle ??
                const TextStyle(
                  fontSize: 13,
                ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            isDense: true,
          ),
      onChanged: _handleOnChanged,
      onFieldSubmitted: widget.onSubmitted,
    );
  }
}
