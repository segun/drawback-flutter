import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth_controller.dart';
import '../widgets/auth_page_scaffold.dart';
import '../widgets/status_banner.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.controller, super.key});

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, _) {
        final user = controller.currentUser;
        final notice = controller.notice;
        final error = controller.error;

        return AuthPageScaffold(
          title: 'Home',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (notice != null) ...<Widget>[
                StatusBanner(text: notice, kind: BannerKind.success),
                const SizedBox(height: 12),
              ],
              if (error != null) ...<Widget>[
                StatusBanner(text: error, kind: BannerKind.error),
                const SizedBox(height: 12),
              ],
              Text(
                'Welcome',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              Text(user?.displayName ?? 'Authenticated user'),
              if (user?.email != null) ...<Widget>[
                const SizedBox(height: 4),
                Text(user!.email),
              ],
              const SizedBox(height: 4),
              Text('Mode: ${user?.mode ?? 'UNKNOWN'}'),
              const SizedBox(height: 18),
              FilledButton.tonal(
                onPressed: () async {
                  await controller.logout();
                  if (context.mounted) {
                    // ignore: use_build_context_synchronously
                    context.go('/login');
                  }
                },
                child: const Text('Log out'),
              ),
            ],
          ),
        );
      },
    );
  }
}
