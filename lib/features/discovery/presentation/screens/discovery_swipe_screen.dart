import 'package:flutter/material.dart';

import '../../../../core/realtime/socket_service.dart';
import '../../../../core/services/discovery_access_manager.dart';
import '../../../../core/widgets/cross_origin_image.dart';
import '../../../home/domain/home_models.dart';
import '../discovery_controller.dart';
import '../widgets/access_timer_widget.dart';

/// Discovery swipe screen showing random users
class DiscoverySwipeScreen extends StatefulWidget {
  const DiscoverySwipeScreen({
    required this.controller,
    required this.accessManager,
    required this.onBackToDashboard,
    required this.onSendChatRequest,
    required this.onAcceptChatRequest,
    required this.onOpenChat,
    required this.onExitGame,
    required this.onAccessExpired,
    required this.connectedUserIds,
    required this.pendingOutgoingUserIds,
    required this.acceptedChatByUserId,
    required this.incomingChatRequests,
    required this.hasPermanentAccess,
    super.key,
  });

  final DiscoveryController controller;
  final DiscoveryAccessManager accessManager;
  final VoidCallback onBackToDashboard;
  final Future<void> Function(String displayName) onSendChatRequest;
  final Future<bool> Function(String chatRequestId) onAcceptChatRequest;
  final void Function(String chatRequestId) onOpenChat;
  final Future<void> Function() onExitGame;
  final VoidCallback onAccessExpired;
  final Set<String> connectedUserIds;
  final Set<String> pendingOutgoingUserIds;
  final Map<String, String> acceptedChatByUserId;
  final List<ChatRequest> incomingChatRequests;
  final bool hasPermanentAccess;

  @override
  State<DiscoverySwipeScreen> createState() => _DiscoverySwipeScreenState();
}

class _DiscoverySwipeScreenState extends State<DiscoverySwipeScreen> {
  DiscoveryUser? _currentUser;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRandomUser();
  }

  Future<void> _loadRandomUser() async {
    SocketService().emitDrawLeave();
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final DiscoveryUser? user = await widget.controller.getRandomDiscoveryUser();

    if (!mounted) {
      return;
    }

    setState(() {
      _currentUser = user;
      _isLoading = false;
      if (user == null) {
        _error = 'No users found in discovery game';
      }
    });
  }

  Future<void> _handleStartDrawing() async {
    if (_currentUser == null) {
      return;
    }

    final String targetUserId = _currentUser!.id;
    final String targetDisplayName = _currentUser!.displayName;

    // Case 1: Check if there's an existing accepted chat with this user
    if (widget.connectedUserIds.contains(targetUserId)) {
      final String? chatRequestId = widget.acceptedChatByUserId[targetUserId];
      if (chatRequestId != null) {
        widget.onOpenChat(chatRequestId);
        return;
      }
    }

    // Case 2: Check if there's an incoming pending request from this user
    // (They sent us a request - accept it and open chat)
    final ChatRequest? incomingRequest = widget.incomingChatRequests
        .where((ChatRequest req) => req.fromUserId == targetUserId)
        .firstOrNull;
    if (incomingRequest != null) {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final bool accepted = await widget.onAcceptChatRequest(incomingRequest.id);
      
      if (!mounted) {
        return;
      }

      if (accepted) {
        widget.onOpenChat(incomingRequest.id);
      } else {
        setState(() {
          _isLoading = false;
          _error = 'Failed to accept chat request';
        });
      }
      return;
    }

    // Case 3: Check if there's already a pending request sent to this user
    if (widget.pendingOutgoingUserIds.contains(targetUserId)) {
      await showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Request Already Sent'),
            content: Text(
              'You already have a pending chat request to $targetDisplayName.',
            ),
            actions: <Widget>[
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE11D48),
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      // Load next user
      if (mounted) {
        await _loadRandomUser();
      }
      return;
    }

    // Case 4: No existing chat or pending request - send new request
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Send chat request
      await widget.onSendChatRequest(targetDisplayName);

      if (!mounted) {
        return;
      }

      // Show success message
      await showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Chat Request Sent!'),
            content: Text(
              'Your chat request has been sent to $targetDisplayName.',
            ),
            actions: <Widget>[
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      // Load next user
      if (mounted) {
        await _loadRandomUser();
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = 'Failed to send chat request: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show timer if using temporary access (not permanent)
    final bool showTimer = !widget.hasPermanentAccess && 
        widget.accessManager.hasTemporaryAccess;

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
                  const Expanded(
                    child: Text(
                      'Discovery Game',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF9F1239),
                      ),
                    ),
                  ),
                  // Timer widget for temporary access
                  if (showTimer)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: AccessTimerWidget(
                        accessManager: widget.accessManager,
                        onExpired: widget.onAccessExpired,
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.exit_to_app, color: Color(0xFF9F1239)),
                    onPressed: widget.onExitGame,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF9F1239)),
                    onPressed: widget.onBackToDashboard,
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE11D48)),
                      ),
                    )
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                const Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Color(0xFF9F1239),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF9F1239),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                FilledButton(
                                  onPressed: _loadRandomUser,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFFE11D48),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(1),
                                    ),
                                  ),
                                  child: const Text('Try Again'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _currentUser != null
                          ? _buildUserCard(_currentUser!)
                          : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(DiscoveryUser user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // User image
          Container(
            constraints: const BoxConstraints(
              maxHeight: 400,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFF9F1239), width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: user.discoveryImageUrl != null
                  ? CrossOriginImage(
                      imageUrl: user.discoveryImageUrl!,
                      fit: BoxFit.contain,
                      height: 400,
                      disableCache: true,
                      errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                        return Container(
                          height: 400,
                          color: const Color(0xFFFFF1F2),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Icon(
                                  Icons.broken_image,
                                  size: 64,
                                  color: Color(0xFFFDA4AF),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Failed to load image',
                                  style: TextStyle(
                                    color: Color(0xFF9F1239),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      height: 400,
                      color: const Color(0xFFFFF1F2),
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 64,
                          color: Color(0xFFFDA4AF),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),

          // Display name
          Text(
            user.displayName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF9F1239),
            ),
          ),
          const SizedBox(height: 40),

          // Action buttons - horizontal row with icons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              // Cancel/Back button
              _buildActionButton(
                onPressed: widget.onBackToDashboard,
                icon: Icons.close,
                color: const Color(0xFF9F1239),
                backgroundColor: Colors.white,
                tooltip: 'Back',
              ),
              // Start Drawing button (main action)
              _buildActionButton(
                onPressed: _isLoading ? null : _handleStartDrawing,
                icon: Icons.brush,
                color: Colors.white,
                backgroundColor: const Color(0xFFE11D48),
                size: 72,
                iconSize: 36,
                tooltip: 'Start Drawing',
              ),
              // Next button
              _buildActionButton(
                onPressed: _isLoading ? null : _loadRandomUser,
                icon: Icons.arrow_forward,
                color: const Color(0xFF9F1239),
                backgroundColor: Colors.white,
                tooltip: 'Next',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required Color color,
    required Color backgroundColor,
    double size = 56,
    double iconSize = 28,
    String? tooltip,
  }) {
    final Widget button = Material(
      elevation: 4,
      shape: const CircleBorder(),
      color: onPressed == null ? backgroundColor.withValues(alpha: 0.5) : backgroundColor,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            size: iconSize,
            color: onPressed == null ? color.withValues(alpha: 0.5) : color,
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip,
        child: button,
      );
    }
    return button;
  }
}
