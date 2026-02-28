import 'package:flutter/material.dart';

import '../widgets/drawback_app_bar.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF5F5), // rose-50
      appBar: const DrawbackAppBar(),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 896), // max-w-4xl
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48), // py-12 pb-20
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Privacy Policy',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF7C2D12), // rose-900
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Last Updated: February 25, 2026',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFE11D48), // rose-600
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    context,
                    title: '1. Introduction',
                    content:
                        'Drawback ("we," "us," "our," or "Company") operates a real-time collaborative drawing platform. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our service, including our website, mobile application, and related services (collectively, the "Service").\n\nPlease read this Privacy Policy carefully. If you do not agree with our policies and practices, please do not use our Service.',
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    context,
                    title: '2. Information We Collect',
                    content:
                        'We collect various types of information in connection with the services we provide, including:',
                  ),
                  const SizedBox(height: 16),
                  _buildSubsection(
                    context,
                    title: '2.1 Information You Provide Directly',
                    items: const <String>[
                      'Email address (required for account creation and identity verification)',
                      'Display name (used for profile identification and search)',
                      'Password (securely hashed, never stored in plain text)',
                    ],
                  ),
                  const SizedBox(height: 48), // pb-20
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF7C2D12), // rose-900
          ),
        ),
        const SizedBox(height: 16),
        Text(
          content,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF9F1239), // rose-800
          ),
        ),
      ],
    );
  }

  Widget _buildSubsection(
    BuildContext context, {
    required String title,
    required List<String> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF9F1239), // rose-800
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.map((String item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('• ', style: TextStyle(fontSize: 16)),
                    Expanded(
                      child: Text(
                        item,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF9F1239), // rose-800
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
