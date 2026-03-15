import 'package:flutter/material.dart';

import '../../domain/home_models.dart';

/// Widget to display subscription information with cross-platform awareness
/// Shows where the subscription was purchased and how to manage it
class SubscriptionInfoWidget extends StatelessWidget {
  const SubscriptionInfoWidget({
    required this.subscription,
    required this.hasDiscoveryAccess,
    super.key,
  });

  final Subscription? subscription;
  final bool hasDiscoveryAccess;

  @override
  Widget build(BuildContext context) {
    if (subscription == null) {
      return _buildNoSubscription(context);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        border: Border.all(color: const Color(0xFFFDA4AF)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.check_circle,
                color: Color(0xFF9F1239),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Discovery Access Active',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: const Color(0xFF9F1239),
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            context,
            'Plan',
            _formatTier(subscription!.tier),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            context,
            'Subscribed via',
            subscription!.platformDisplayName,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            context,
            'Expires',
            _formatDate(subscription!.endDate),
          ),
          if (!subscription!.autoRenew) ...<Widget>[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(51),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.info_outline,
                    size: 14,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Auto-renewal is off',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange.shade900,
                        ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'To manage your subscription, use ${subscription!.platformDisplayName} settings',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF9F1239),
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSubscription(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        border: Border.all(color: const Color(0xFFFDA4AF)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Discovery Access',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF9F1239),
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'No active subscription',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF9F1239),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Subscribe to unlock the Discovery Game and find random users to draw with.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF9F1239).withAlpha(179),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF9F1239).withAlpha(179),
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF9F1239),
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  String _formatTier(String tier) {
    switch (tier.toLowerCase()) {
      case 'monthly':
        return 'Monthly';
      case 'quarterly':
        return 'Quarterly';
      case 'yearly':
        return 'Yearly';
      default:
        return tier;
    }
  }

  String _formatDate(DateTime date) {
    final DateTime now = DateTime.now();
    final Duration difference = date.difference(now);

    if (difference.inDays > 30) {
      final int months = (difference.inDays / 30).round();
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} (~$months months)';
    } else if (difference.inDays > 0) {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} (~${difference.inDays} days)';
    } else {
      return 'Expired';
    }
  }
}
