import 'package:flutter/material.dart';

enum BannerKind { info, success, error }

class StatusBanner extends StatelessWidget {
  const StatusBanner({
    required this.text,
    required this.kind,
    super.key,
  });

  final String text;
  final BannerKind kind;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final (Color bg, Color fg) = switch (kind) {
      BannerKind.error => (scheme.errorContainer, scheme.onErrorContainer),
      BannerKind.success => (
          Colors.green.withValues(alpha: 0.15),
          Colors.green.shade900,
        ),
      BannerKind.info => (scheme.secondaryContainer, scheme.onSecondaryContainer),
    };

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        text,
        style: TextStyle(color: fg, fontWeight: FontWeight.w500),
      ),
    );
  }
}
