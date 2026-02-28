import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth_controller.dart';
import '../widgets/auth_page_scaffold.dart';
import '../widgets/auth_text_styles.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/status_banner.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({required this.controller, super.key});

  final AuthController controller;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _checkingAvailability = false;
  bool? _isDisplayNameAvailable;

  @override
  void dispose() {
    _emailController.dispose();
    _displayNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _checkDisplayName() async {
    final String candidate = _displayNameController.text.trim();
    if (!_isValidDisplayName(candidate)) {
      setState(() => _isDisplayNameAvailable = false);
      return;
    }

    setState(() {
      _checkingAvailability = true;
      _isDisplayNameAvailable = null;
    });

    final bool available = await widget.controller
        .checkDisplayNameAvailability(candidate);

    if (!mounted) {
      return;
    }

    setState(() {
      _checkingAvailability = false;
      _isDisplayNameAvailable = available;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final String displayName = _displayNameController.text.trim();
    if (_isDisplayNameAvailable != true) {
      await _checkDisplayName();
      if (_isDisplayNameAvailable != true) {
        return;
      }
    }

    final bool ok = await widget.controller.register(
      email: _emailController.text,
      password: _passwordController.text,
      displayName: displayName,
    );

    if (mounted && ok) {
      context.go('/login');
    }
  }

  bool _isValidDisplayName(String value) {
    final RegExp pattern = RegExp(r'^@[A-Za-z0-9_]{2,29}$');
    return pattern.hasMatch(value);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (BuildContext context, _) {
        final String? error = widget.controller.error;
        final String? notice = widget.controller.notice;

        return AuthPageScaffold(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (error != null || notice != null) ...<Widget>[
                  StatusBanner(
                    text: error ?? notice ?? '',
                    kind: error != null ? BannerKind.error : BannerKind.success,
                  ),
                  const SizedBox(height: 12),
                ],
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCE7F3), // rose-100
                    border: Border.all(
                      color: const Color(0xFFFBE7EB), // rose-300
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFBE7EB).withValues(
                          alpha: 0.3,
                        ),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        'Create Account',
                        style: AuthTextStyles.header(context),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Register with email, password, and display name. Login is allowed only after email confirmation.',
                        style: AuthTextStyles.bodyText(context),
                      ),
                      const SizedBox(height: 12),
                      Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
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
                              controller: _displayNameController,
                              labelText: 'Display name',
                              hintText: '@alice',
                              maxLength: 32,
                              suffixIcon: IconButton(
                                onPressed: _checkingAvailability ||
                                        widget.controller.isBusy
                                    ? null
                                    : _checkDisplayName,
                                icon: _checkingAvailability
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.search),
                              ),
                              validator: (String? value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Display name is required.';
                                }
                                if (!_isValidDisplayName(value.trim())) {
                                  return 'Use @ plus 2-29 letters, numbers, or underscore.';
                                }
                                return null;
                              },
                              onChanged: (_) {
                                if (_isDisplayNameAvailable != null) {
                                  setState(() =>
                                      _isDisplayNameAvailable = null);
                                }
                              },
                            ),
                            if (_isDisplayNameAvailable != null)
                              ...<Widget>[
                                const SizedBox(height: 8),
                                StatusBanner(
                                  text: _isDisplayNameAvailable!
                                      ? 'Display name is available.'
                                      : 'Display name is not available.',
                                  kind: _isDisplayNameAvailable!
                                      ? BannerKind.success
                                      : BannerKind.error,
                                ),
                              ],
                            const SizedBox(height: 12),
                            CustomTextField(
                              controller: _passwordController,
                              labelText: 'Password',
                              obscureText: true,
                              maxLength: 72,
                              validator: (String? value) {
                                if (value == null || value.isEmpty) {
                                  return 'Password is required.';
                                }
                                if (value.length < 8) {
                                  return 'Password must be at least 8 characters.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 10),
                            CustomTextField(
                              controller: _confirmPasswordController,
                              labelText: 'Confirm password',
                              obscureText: true,
                              maxLength: 72,
                              errorText: _passwordController.text.isNotEmpty &&
                                      _confirmPasswordController
                                          .text.isNotEmpty &&
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
                                return null;
                              },
                              onChanged: (_) {
                                setState(() {});
                              },
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: widget.controller.isBusy ||
                                      (_passwordController.text.isNotEmpty &&
                                          _confirmPasswordController
                                              .text.isNotEmpty &&
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
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Create account', style: TextStyle(fontSize: 13)),
                            ),
                            const SizedBox(height: 6),
                            TextButton(
                              onPressed: () => context.go('/login'),
                              style: AuthTextStyles.linkButtonStyle(),
                              child: Text(
                                'Already have an account? Login',
                                style: AuthTextStyles.link(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

