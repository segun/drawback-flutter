import 'package:flutter/material.dart';

import '../../../../core/services/discovery_access_manager.dart';

/// Paywall screen shown when user doesn't have discovery access
/// Offers subscription tiers (monthly/quarterly/yearly) or temporary ad-based access
class DiscoveryPaywallScreen extends StatefulWidget {
  const DiscoveryPaywallScreen({
    required this.accessManager,
    required this.onAccessGranted,
    required this.onBack,
    required this.onProfileRefresh,
    super.key,
  });

  final DiscoveryAccessManager accessManager;
  final VoidCallback onAccessGranted;
  final VoidCallback onBack;
  final Future<bool> Function() onProfileRefresh;

  @override
  State<DiscoveryPaywallScreen> createState() => _DiscoveryPaywallScreenState();
}

class _DiscoveryPaywallScreenState extends State<DiscoveryPaywallScreen> {
  bool _isProcessing = false;
  String? _statusMessage;

  Future<void> _handlePurchase() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Processing purchase...';
    });

    try {
      final bool success = await widget.accessManager.purchaseDiscovery();

      if (success) {
        // Refresh profile to get updated hasDiscoveryAccess
        final bool hasAccess = await widget.onProfileRefresh();

        if (mounted) {
          setState(() {
            _statusMessage = 'Purchase successful!';
          });

          // Small delay to show success message
          await Future<void>.delayed(const Duration(milliseconds: 500));

          if (mounted && hasAccess) {
            widget.onAccessGranted();
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _statusMessage = widget.accessManager.error ?? 'Purchase failed';
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _handleWatchAd() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Loading ad...';
    });

    try {
      final bool success = await widget.accessManager.watchAdForAccess();

      if (success) {
        if (mounted) {
          setState(() {
            _statusMessage = 'Access granted!';
          });

          // Small delay to show success message
          await Future<void>.delayed(const Duration(milliseconds: 500));

          if (mounted) {
            widget.onAccessGranted();
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _statusMessage = widget.accessManager.error ?? 'Ad not completed';
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _handleRestorePurchases() async {
    debugPrint("Restoring purchases...");
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Restoring purchases...';
    });

    try {
      final String message = await widget.accessManager.restorePurchases();

      // Refresh profile to get updated hasDiscoveryAccess and subscription info
      final bool hasAccess = await widget.onProfileRefresh();

      if (mounted) {
        setState(() {
          _statusMessage = message;
        });

        // Check if restore was successful by verifying backend response
        if (hasAccess) {
          // Small delay to show success message
          await Future<void>.delayed(const Duration(milliseconds: 500));

          if (mounted) {
            widget.onAccessGranted();
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFDA4AF),
      child: SafeArea(
        child: Column(
          children: <Widget>[
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  IconButton(
                    icon:
                        const Icon(Icons.arrow_back, color: Color(0xFF9F1239)),
                    onPressed: widget.onBack,
                  ),
                  const Expanded(
                    child: Text(
                      'Back',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF9F1239),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 1, 24, 1),
                child: Column(
                  children: <Widget>[
                    const SizedBox(height: 1),

                    // Icon
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(51),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.palette,
                        size: 44,
                        color: Color(0xFF9F1239),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Title
                    const Text(
                      'Unlock Discovery Game',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF9F1239),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Description
                    const Text(
                      'Find random users and start drawing together! '
                      'Connect with artists from around the world.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF881337),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Purchase button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isProcessing ? null : _handlePurchase,
                        icon: const Icon(Icons.diamond),
                        label: const Text('Subscribe — \$1.49/month'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFE11D48),
                          disabledBackgroundColor:
                              const Color(0xFFE11D48).withAlpha(128),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Or divider
                    Row(
                      children: <Widget>[
                        const Expanded(
                          child: Divider(color: Color(0xFF9F1239)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'or',
                            style: TextStyle(
                              color: const Color(0xFF9F1239).withAlpha(179),
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Divider(color: Color(0xFF9F1239)),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Watch ad button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isProcessing ? null : _handleWatchAd,
                        icon: const Icon(Icons.play_circle_outline),
                        label: const Text('Watch Ad — 5 min access'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF9F1239),
                          side: const BorderSide(
                            color: Color(0xFF9F1239),
                            width: 2,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Status message
                    if (_statusMessage != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(128),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            if (_isProcessing)
                              const Padding(
                                padding: EdgeInsets.only(right: 12),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFFE11D48),
                                    ),
                                  ),
                                ),
                              ),
                            Flexible(
                              child: Text(
                                _statusMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF881337),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    SizedBox(height: _statusMessage != null ? 20 : 8),

                    // Restore purchases link
                    TextButton(
                      onPressed: _isProcessing ? null : _handleRestorePurchases,
                      child: const Text(
                        'Already purchased? Restore Purchases',
                        style: TextStyle(
                          color: Color(0xFF9F1239),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
