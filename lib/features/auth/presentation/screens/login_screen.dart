import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth_controller.dart';
import '../widgets/auth_page_scaffold.dart';
import '../widgets/auth_text_styles.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/status_banner.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({required this.controller, super.key});

  final AuthController controller;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final bool ok = await widget.controller.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (mounted && ok) {
      context.go('/home');
    }
  }

  Future<void> _openForgotPasswordDialog() async {
    final TextEditingController emailController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset password'),
          content: TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final String email = emailController.text.trim();
                if (email.isEmpty) {
                  return;
                }
                await widget.controller.forgotPassword(email);
                if (mounted && context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Send link'),
            ),
          ],
        );
      },
    );
    emailController.dispose();
    if (mounted) {
      setState(() {});
    }
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
                        'Login',
                        style: AuthTextStyles.header(context),
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
                              controller: _passwordController,
                              labelText: 'Password',
                              obscureText: true,
                              maxLength: 72,
                              validator: (String? value) {
                                if (value == null || value.isEmpty) {
                                  return 'Password is required.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: widget.controller.isBusy ? null : _submit,
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
                                  : const Text('Login', style: TextStyle(fontSize: 13)),
                            ),
                            const SizedBox(height: 6),
                            TextButton(
                              onPressed: widget.controller.isBusy
                                  ? null
                                  : _openForgotPasswordDialog,
                              style: AuthTextStyles.linkButtonStyle(),
                              child: Text(
                                'Forgot password?',
                                style: AuthTextStyles.link(),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: Divider(
                                height: 8,
                                thickness: 1,
                                color: Color.fromARGB(255, 234, 12, 57), // rose-300
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.go('/register'),
                              style: AuthTextStyles.linkButtonStyle(),
                              child: Text(
                                'Need an account? Register',
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

