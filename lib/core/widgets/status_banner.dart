import 'dart:async';

import 'package:flutter/material.dart';

enum BannerKind { info, success, error }

class StatusBanner extends StatefulWidget {
  const StatusBanner({
    required this.text,
    required this.kind,
    this.onDismiss,
    this.autoDismissDuration = const Duration(seconds: 7),
    super.key,
  });

  final String text;
  final BannerKind kind;
  final VoidCallback? onDismiss;
  final Duration autoDismissDuration;

  @override
  State<StatusBanner> createState() => _StatusBannerState();
}

class _StatusBannerState extends State<StatusBanner> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.onDismiss != null) {
      _timer = Timer(widget.autoDismissDuration, () {
        if (mounted) {
          widget.onDismiss!();
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final (Color bg, Color fg) = switch (widget.kind) {
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
      padding: EdgeInsets.fromLTRB(8, 0, 4, 0),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              widget.text,
              style: TextStyle(color: fg, fontWeight: FontWeight.w500),
            ),
          ),
          if (widget.onDismiss != null)
            IconButton(
              icon: Icon(Icons.close, color: fg, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                _timer?.cancel();
                widget.onDismiss!();
              },
              tooltip: 'Dismiss',
            ),
        ],
      ),
    );
  }
}
