import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../auth_controller.dart';
import '../widgets/auth_page_scaffold.dart';
import '../widgets/auth_text_styles.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({required this.controller, super.key});

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? child) {
        // Show loading screen while checking for existing token
        if (controller.isBootstrapping) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Image.asset(
                    'assets/images/logo_main.png',
                    width: 160,
                    height: 160,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(
                    color: Color(0xFFE11D48), // rose-600
                  ),
                ],
              ),
            ),
          );
        }

        // Show main screen with Get Started/Login only if not authenticated
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
                  width: 1,
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
                    'Welcome to DrawkcaB',
                    style: AuthTextStyles.welcome(context),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'A real-time collaborative drawing chat app. Register, confirm your email, and start drawing with friends!',
                    style: AuthTextStyles.bodyText(context),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: FilledButton(
                          onPressed: () => context.go('/register'),
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
                          child: const Text(
                            'Get Started',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.go('/login'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFF9F1239), // rose-300
                            ),
                            foregroundColor:
                                const Color(0xFF9F1239), // rose-800
                            padding: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/privacy'),
                      style: TextButton.styleFrom(
                        foregroundColor:
                            const Color(0xFFE11D48), // rose-600
                      ),
                      child: const Text(
                        'Privacy Policy',
                        style: TextStyle(
                          fontSize: 11,
                          decoration: TextDecoration.underline,
                        ),
                      ),
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
