import 'package:flutter/material.dart';
import 'drawback_app_bar.dart';

class AuthPageScaffold extends StatelessWidget {
  const AuthPageScaffold({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DrawbackAppBar(),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
