import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/status_banner.dart';
import '../auth_controller.dart';
import '../widgets/auth_page_scaffold.dart';
import '../widgets/auth_text_styles.dart';

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
  final TextEditingController _forgotPasswordEmailController =
      TextEditingController();
  String _lastPrefilledEmail = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _forgotPasswordEmailController.dispose();
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
      await widget.controller.refreshPasskeyAvailability(notify: false);
      context.go('/home', extra: widget.controller.canAddPasskey);
    }
  }

  Future<void> _submitPasskey() async {
    final String email = _emailController.text.trim().isNotEmpty
        ? _emailController.text.trim()
        : widget.controller.rememberedEmail;
    final bool ok = await widget.controller.loginWithPasskey(email: email);
    if (mounted && ok) {
      context.go('/home');
    }
  }

  void _prefillRememberedEmailIfNeeded(String rememberedEmail) {
    if (rememberedEmail.isEmpty || rememberedEmail == _lastPrefilledEmail) {
      return;
    }

    if (_emailController.text.trim().isNotEmpty) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      if (_emailController.text.trim().isNotEmpty) {
        return;
      }

      _emailController.text = rememberedEmail;
      _emailController.selection = TextSelection.collapsed(
        offset: rememberedEmail.length,
      );
    });

    _lastPrefilledEmail = rememberedEmail;
  }

  Future<void> _openForgotPasswordDialog() async {
    _forgotPasswordEmailController.text = _emailController.text.trim();
    _forgotPasswordEmailController.selection = TextSelection.collapsed(
      offset: _forgotPasswordEmailController.text.length,
    );

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset password'),
          content: TextField(
            controller: _forgotPasswordEmailController,
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
                final String email = _forgotPasswordEmailController.text.trim();
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
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (BuildContext context, _) {
        final String? error = widget.controller.error;
        final String? notice = widget.controller.notice;
        _prefillRememberedEmailIfNeeded(widget.controller.rememberedEmail);

        return AuthPageScaffold(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Image.asset(
                        'assets/images/logo_main.png',
                        width: 160,
                        height: 160,
                        fit: BoxFit.contain,
                      ),
                      Text(
                        'Login',
                        style: AuthTextStyles.header(context),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      if (error != null || notice != null) ...<Widget>[
                        const SizedBox(height: 12),
                        StatusBanner(
                          text: error ?? notice ?? '',
                          kind: error != null
                              ? BannerKind.error
                              : BannerKind.success,
                          key: ValueKey('${error ?? notice}'),
                          onDismiss: () {
                            widget.controller.clearMessages();
                          },
                        ),
                        if (error != null &&
                            widget.controller
                                .canResendActivationEmail) ...<Widget>[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: widget.controller.isBusy
                                ? null
                                : () async {
                                    await widget.controller
                                        .resendActivationEmail(
                                      _emailController.text,
                                    );
                                  },
                            style: AuthTextStyles.linkButtonStyle(),
                            child: Text(
                              'Resend activation email',
                              style: AuthTextStyles.link(),
                            ),
                          ),
                        ],
                      ],
                      Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            CustomTextField(
                              key: const Key('emailField'),
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
                              key: const Key('passwordField'),
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
                            const SizedBox(height: 16),
                            ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _emailController,
                              builder: (BuildContext context,
                                  TextEditingValue value, _) {
                                final bool hasEnteredEmail =
                                    value.text.trim().isNotEmpty;
                                final bool hasRememberedEmail = widget
                                    .controller.rememberedEmail
                                    .trim()
                                    .isNotEmpty;
                                final bool canUsePasswordLogin =
                                    !widget.controller.isBusy &&
                                        hasEnteredEmail;
                                final bool canUsePasskey =
                                    widget.controller.isPasskeyAvailable &&
                                        !widget.controller.isBusy &&
                                        (hasEnteredEmail || hasRememberedEmail);

                                return Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: FilledButton(
                                        onPressed: canUsePasswordLogin
                                            ? _submit
                                            : null,
                                        style: FilledButton.styleFrom(
                                          backgroundColor: const Color(
                                              0xFFBE185D), // rose-700
                                          foregroundColor: const Color(
                                              0xFFFCE7F3), // rose-100
                                          padding: const EdgeInsets.all(16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(1),
                                          ),
                                        ),
                                        child: widget.controller.isBusy
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : const Text(
                                                'Login',
                                                style: TextStyle(fontSize: 13),
                                              ),
                                      ),
                                    ),
                                    if (widget.controller
                                        .isPasskeyAvailable) ...<Widget>[
                                      const SizedBox(width: 8),
                                      OutlinedButton.icon(
                                        onPressed: canUsePasskey
                                            ? _submitPasskey
                                            : null,
                                        icon: const Icon(Icons.fingerprint),
                                        label: const Text('Biometric'),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(1),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 12),
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
                            const SizedBox(height: 12),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: Divider(
                                height: 8,
                                thickness: 1,
                                color: Color.fromARGB(
                                    255, 234, 12, 57), // rose-300
                              ),
                            ),
                            const SizedBox(height: 12),
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
