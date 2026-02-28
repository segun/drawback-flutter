import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/drawback_app_bar.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF5F5), // rose-50
      appBar: const DrawbackAppBar(),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Welcome to DrawkcaB',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFBE185D), // rose-700
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'A real-time collaborative drawing chat app. Register, confirm your email, and start drawing with friends!',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF9F1239), // rose-800
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: FilledButton(
                                  onPressed: () => context.go('/register'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFFBE185D), // rose-700
                                    foregroundColor: const Color(0xFFFCE7F3), // rose-100
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6), // md radius
                                    ),
                                  ),
                                  child: const Text(
                                    'Get Started',
                                    style: TextStyle(
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
                                      color: Color(0xFFFBE7EB), // rose-300
                                    ),
                                    foregroundColor: const Color(0xFF9F1239), // rose-800
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6), // md radius
                                    ),
                                  ),
                                  child: const Text(
                                    'Login',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: TextButton(
                              onPressed: () => context.go('/privacy'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFFE11D48), // rose-600
                              ),
                              child: const Text(
                                'Privacy Policy',
                                style: TextStyle(
                                  fontSize: 12,
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
            ),
          ),
        ),
      ),
    );
  }
}
