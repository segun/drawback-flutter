import 'package:flutter/material.dart';

import '../../../../core/services/discovery_access_manager.dart';

/// Widget showing countdown timer for temporary discovery access
class AccessTimerWidget extends StatelessWidget {
  const AccessTimerWidget({
    required this.accessManager,
    required this.onExpired,
    super.key,
  });

  final DiscoveryAccessManager accessManager;
  final VoidCallback onExpired;

  String _formatDuration(Duration duration) {
    final int minutes = duration.inMinutes;
    final int seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: accessManager,
      builder: (BuildContext context, Widget? child) {
        final Duration? remaining = accessManager.remainingTime;

        if (remaining == null) {
          // Access expired, notify parent
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onExpired();
          });
          return const SizedBox.shrink();
        }

        // Determine color based on time remaining
        final bool isWarning = remaining.inMinutes < 1;
        final Color timerColor = isWarning
            ? const Color(0xFFDC2626) // Red when < 1 minute
            : const Color(0xFF9F1239); // Rose otherwise

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(204),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: timerColor.withAlpha(128),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.timer,
                size: 16,
                color: timerColor,
              ),
              const SizedBox(width: 6),
              Text(
                _formatDuration(remaining),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: timerColor,
                ),
              ),
              if (isWarning) ...<Widget>[
                const SizedBox(width: 6),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: timerColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Dialog shown when temporary access expires
class AccessExpiredDialog extends StatelessWidget {
  const AccessExpiredDialog({
    required this.onWatchAd,
    required this.onPurchase,
    required this.onDismiss,
    super.key,
  });

  final VoidCallback onWatchAd;
  final VoidCallback onPurchase;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      title: const Row(
        children: <Widget>[
          Icon(
            Icons.timer_off,
            color: Color(0xFF9F1239),
          ),
          SizedBox(width: 12),
          Text(
            "Time's Up!",
            style: TextStyle(
              color: Color(0xFF9F1239),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: const Text(
        'Your temporary access has expired. '
        'Watch another ad or subscribe to continue.',
        style: TextStyle(
          color: Color(0xFF881337),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: onDismiss,
          child: const Text(
            'Go Back',
            style: TextStyle(color: Color(0xFF9F1239)),
          ),
        ),
        OutlinedButton.icon(
          onPressed: onWatchAd,
          icon: const Icon(Icons.play_circle_outline),
          label: const Text('Watch Ad'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF9F1239),
            side: const BorderSide(
              color: Color(0xFF9F1239),
            ),
          ),
        ),
        FilledButton.icon(
          onPressed: onPurchase,
          icon: const Icon(Icons.diamond),
          label: const Text('Unlock'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFE11D48),
          ),
        ),
      ],
    );
  }
}
