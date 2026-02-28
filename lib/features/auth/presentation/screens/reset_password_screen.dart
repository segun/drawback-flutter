import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth_controller.dart';
import '../widgets/auth_page_scaffold.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/status_banner.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({
    required this.controller,
    this.tokenFromQuery,
    super.key,
  });

  final AuthController controller;
  final String? tokenFromQuery;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String? _resultStatus; // 'success' or 'error' or null
  String? _resultMessage;

  @override
  void initState() {
    super.initState();
    if (widget.tokenFromQuery != null && widget.tokenFromQuery!.isNotEmpty) {
      _tokenController.text = widget.tokenFromQuery!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      widget.controller.clearError();
      return;
    }

    final bool ok = await widget.controller.resetPassword(
      token: _tokenController.text.trim(),
      password: _passwordController.text,
    );

    if (mounted) {
      setState(() {
        _resultStatus = ok ? 'success' : 'error';
        _resultMessage = widget.controller.notice ?? widget.controller.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (BuildContext context, _) {
        if (_resultStatus != null) {
          final bool success = _resultStatus == 'success';
          return AuthPageScaffold(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                StatusBanner(
                  text: success ? 'Success' : 'Error',
                  kind: success ? BannerKind.success : BannerKind.error,
                ),
                const SizedBox(height: 12),
                Text(_resultMessage ?? 'No message provided.'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Go to log in'),
                ),
              ],
            ),
          );
        }

        final String? error = widget.controller.error;
        final String? notice = widget.controller.notice;

        return AuthPageScaffold(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (error != null) ...<Widget>[
                  StatusBanner(text: error, kind: BannerKind.error),
                  const SizedBox(height: 12),
                ],
                if (notice != null) ...<Widget>[
                  StatusBanner(text: notice, kind: BannerKind.success),
                  const SizedBox(height: 12),
                ],
                CustomTextField(
                  controller: _emailController,
                  labelText: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  maxLength: 254,
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                CustomTextField(
                  controller: _tokenController,
                  labelText: 'Reset token',
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Reset token is required.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                CustomTextField(
                  controller: _passwordController,
                  labelText: 'New password',
                  obscureText: true,
                  maxLength: 72,
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required.';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters.';
                    }
                    if (value.length > 72) {
                      return 'Password must be at most 72 characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _confirmPasswordController,
                  labelText: 'Confirm password',
                  obscureText: true,
                  maxLength: 72,
                  errorText: _passwordController.text.isNotEmpty &&
                          _confirmPasswordController.text.isNotEmpty &&
                          _passwordController.text !=
                              _confirmPasswordController.text
                      ? 'Passwords do not match'
                      : null,
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirm password is required.';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters.';
                    }
                    if (value.length > 72) {
                      return 'Password must be at most 72 characters.';
                    }
                    return null;
                  },
                  onChanged: (_) {
                    setState(() {});
                  },
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: widget.controller.isBusy ||
                          (_passwordController.text.isNotEmpty &&
                              _confirmPasswordController.text.isNotEmpty &&
                              _passwordController.text !=
                                  _confirmPasswordController.text)
                      ? null
                      : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFBE185D), // rose-700
                    foregroundColor: const Color(0xFFFCE7F3), // rose-100
                    padding: const EdgeInsets.symmetric(
                      vertical: 9,
                    ),
                  ),
                  child: widget.controller.isBusy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Reset password', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
