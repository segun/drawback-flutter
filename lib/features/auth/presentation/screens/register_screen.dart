import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/display_name_text_field.dart';
import '../../../../core/widgets/legal_links_footer.dart';
import '../../validation_constants.dart';
import '../auth_controller.dart';
import '../widgets/auth_page_scaffold.dart';
import '../widgets/auth_text_styles.dart';

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
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _displayNameFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  late VoidCallback _emailFocusListener;
  late VoidCallback _displayNameFocusListener;
  late VoidCallback _passwordFocusListener;
  late VoidCallback _confirmPasswordFocusListener;

  bool _checkingAvailability = false;
  bool? _isDisplayNameAvailable;
  final Set<String> _blurredFields = <String>{};

  @override
  void initState() {
    super.initState();
    _emailFocusListener = () {
      if (!_emailFocus.hasFocus && !_blurredFields.contains('email')) {
        setState(() => _blurredFields.add('email'));
      }
    };
    _emailFocus.addListener(_emailFocusListener);

    _displayNameFocusListener = () {
      if (!_displayNameFocus.hasFocus &&
          !_blurredFields.contains('displayName')) {
        setState(() => _blurredFields.add('displayName'));
        _checkDisplayName();
      }
    };
    _displayNameFocus.addListener(_displayNameFocusListener);

    _passwordFocusListener = () {
      if (!_passwordFocus.hasFocus && !_blurredFields.contains('password')) {
        setState(() => _blurredFields.add('password'));
      }
    };
    _passwordFocus.addListener(_passwordFocusListener);

    _confirmPasswordFocusListener = () {
      if (!_confirmPasswordFocus.hasFocus &&
          !_blurredFields.contains('confirmPassword')) {
        setState(() => _blurredFields.add('confirmPassword'));
      }
    };
    _confirmPasswordFocus.addListener(_confirmPasswordFocusListener);
  }

  @override
  void dispose() {
    _emailFocus.removeListener(_emailFocusListener);
    _displayNameFocus.removeListener(_displayNameFocusListener);
    _passwordFocus.removeListener(_passwordFocusListener);
    _confirmPasswordFocus.removeListener(_confirmPasswordFocusListener);

    _emailController.dispose();
    _displayNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocus.dispose();
    _displayNameFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
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

    final bool available =
        await widget.controller.checkDisplayNameAvailability(candidate);

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

    // Mark all fields as blurred for final validation
    setState(() {
      _blurredFields.addAll(
          <String>['email', 'password', 'confirmPassword', 'displayName']);
    });

    // Validate email
    if (_emailController.text.trim().isEmpty) {
      return;
    }

    // Validate password
    if (_passwordController.text.isEmpty ||
        _passwordController.text.length < 8) {
      return;
    }

    // Validate confirm password
    if (_confirmPasswordController.text.isEmpty ||
        _confirmPasswordController.text != _passwordController.text) {
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
    return ValidationPatterns.displayNamePattern.hasMatch(value);
  }

  int _getCharacterCount(String value) {
    // Count characters after the @
    if (!value.startsWith('@')) return 0;
    return value.substring(1).length;
  }

  void _autoCheckAvailability(String value) {
    // Auto-check when 3+ characters entered after @
    if (_getCharacterCount(value) >= 2 && !_checkingAvailability) {
      _checkDisplayName();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (BuildContext context, _) {
        return AuthPageScaffold(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Container(
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
                          GestureDetector(
                            onTap: () => context.go('/'),
                            child: Image.asset(
                              'assets/images/logo_main.png',
                              width: 160,
                              height: 160,
                              fit: BoxFit.contain,
                            ),
                          ),
                          Text(
                            'Create Account',
                            style: AuthTextStyles.header(context),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Register with email, password, and display name. Login is allowed only after email confirmation.',
                            style: AuthTextStyles.bodyText(context),
                            textAlign: TextAlign.center,
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
                                  focusNode: _emailFocus,
                                  keyboardType: TextInputType.emailAddress,
                                  maxLength: 254,
                                  validator: (String? value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Email is required.';
                                    }
                                    if (!ValidationPatterns.emailPattern
                                        .hasMatch(value.trim())) {
                                      return 'Please enter a valid email address.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 10),
                                DisplayNameTextField(
                                  controller: _displayNameController,
                                  hintText: '@alice',
                                  focusNode: _displayNameFocus,
                                  enabled: !widget.controller.isBusy,
                                  validator: (String? value) {
                                    if (value == null ||
                                        value.trim().isEmpty ||
                                        value.trim() == '@') {
                                      return 'Display name is required.';
                                    }
                                    if (!_isValidDisplayName(value.trim())) {
                                      return 'Must start with @ followed by 2–29 letters, numbers or underscores';
                                    }
                                    return null;
                                  },
                                  onChanged: (String value) {
                                    setState(() {
                                      if (_isDisplayNameAvailable != null) {
                                        _isDisplayNameAvailable = null;
                                      }
                                    });
                                    if (_blurredFields
                                        .contains('displayName')) {
                                      _autoCheckAvailability(value);
                                    }
                                  },
                                  suffixIcon: _blurredFields
                                          .contains('displayName')
                                      ? _isDisplayNameAvailable == true
                                          ? Icon(Icons.check_circle_rounded,
                                              size: 20,
                                              color: Colors.green.shade600)
                                          : _isDisplayNameAvailable == false
                                              ? Icon(Icons.cancel_rounded,
                                                  size: 20,
                                                  color: Colors.red.shade600)
                                              : _checkingAvailability
                                                  ? const SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child:
                                                          CircularProgressIndicator(
                                                              strokeWidth: 2),
                                                    )
                                                  : null
                                      : null,
                                ),
                                if (_blurredFields.contains('displayName') &&
                                    _isDisplayNameAvailable ==
                                        false) ...<Widget>[
                                  const SizedBox(height: 4),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    child: Row(
                                      children: <Widget>[
                                        Icon(
                                          Icons.close_rounded,
                                          size: 14,
                                          color: Colors.red.shade600,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Display name is not available',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.red.shade700),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                CustomTextField(
                                  controller: _passwordController,
                                  labelText: 'Password',
                                  focusNode: _passwordFocus,
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
                                  focusNode: _confirmPasswordFocus,
                                  obscureText: true,
                                  maxLength: 72,
                                  errorText: _passwordController
                                              .text.isNotEmpty &&
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
                                          (_passwordController
                                                  .text.isNotEmpty &&
                                              _confirmPasswordController
                                                  .text.isNotEmpty &&
                                              _passwordController.text !=
                                                  _confirmPasswordController
                                                      .text)
                                      ? null
                                      : _submit,
                                  style: FilledButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFFBE185D), // rose-700
                                    foregroundColor:
                                        const Color(0xFFFCE7F3), // rose-100
                                    padding: const EdgeInsets.all(16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(1),
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
                                      : const Text('Create Account',
                                          style: TextStyle(fontSize: 13)),
                                ),
                                const SizedBox(height: 12),
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
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: const LegalLinksFooter(
                  fontSize: 13,
                  linkColor: Color(0xFFBE185D),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
