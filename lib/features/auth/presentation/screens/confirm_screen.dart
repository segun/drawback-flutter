import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';

import '../widgets/status_banner.dart';

class ConfirmScreen extends StatefulWidget {
  const ConfirmScreen({
    required this.status,
    required this.email,
    required this.reason,
    super.key,
  });

  final String? status;
  final String? email;
  final String? reason;

  @override
  State<ConfirmScreen> createState() => _ConfirmScreenState();
}

class _ConfirmScreenState extends State<ConfirmScreen> {
  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _processConfirmation();
    });
  }

  void _processConfirmation() {
    final String normalizedStatus = (widget.status ?? '').toLowerCase();

    if (normalizedStatus == 'success') {
      if (mounted) {
        context.go('/login');
      }
      return;
    }

    if (normalizedStatus == 'error') {
      if (mounted) {
        context.go('/login');
      }
      return;
    }

    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final String normalizedStatus = (widget.status ?? '').toLowerCase();
    final bool success = normalizedStatus == 'success';
    final String title = success ? 'Email confirmed' : 'Confirmation issue';
    final String details;

    if (success) {
      details = widget.email == null || widget.email!.isEmpty
          ? 'Your account is now active. You can log in.'
          : '${widget.email} is confirmed. You can now log in.';
    } else {
      details = widget.reason == null || widget.reason!.isEmpty
          ? 'This confirmation link is invalid or expired.'
          : widget.reason!;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAF5F5), // rose-50
      appBar: AppBar(
        title: const Text('DrawkcaB'),
        backgroundColor: const Color(0xFFFAF5F5),
        elevation: 0,
        foregroundColor: const Color(0xFF9F1239), // rose-800
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        StatusBanner(
                          text: title,
                          kind: success ? BannerKind.success : BannerKind.error,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          details,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => context.go('/login'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFBE185D), // rose-700
                            foregroundColor: const Color(0xFFFCE7F3), // rose-100
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                          ),
                          child: const Text('Go to login'),
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
    );
  }
}

