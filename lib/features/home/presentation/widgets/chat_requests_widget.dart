import 'package:flutter/material.dart';

import '../../../../core/widgets/display_name_text_field.dart';
import '../../domain/home_models.dart';
import '../home_controller.dart';
import 'refresh_icon_button.dart';

/// Incoming draw requests widget for the sidebar
class ChatRequestsWidget extends StatefulWidget {
  const ChatRequestsWidget({
    required this.controller,
    super.key,
  });

  final HomeController controller;

  @override
  State<ChatRequestsWidget> createState() => _ChatRequestsWidgetState();
}

class _ChatRequestsWidgetState extends State<ChatRequestsWidget> {
  bool _isCollapsed = true;
  bool _showNewRequestForm = false;
  final TextEditingController _displayNameController = TextEditingController(text: '@');
  bool _isSubmitting = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    final String displayName = _displayNameController.text.trim().toLowerCase();
    if (displayName == '@' || displayName.length < 2) {
      return false;
    }

    // Check if it's the current user
    final String? currentDisplayName = widget.controller.profile?.displayName.toLowerCase();
    if (currentDisplayName != null && displayName == currentDisplayName) {
      return false;
    }

    // Check if already connected
    final bool alreadyConnected = widget.controller.recentChats.any((ChatRequest chat) {
      final UserProfile? other = widget.controller.getOtherUser(chat);
      return other?.displayName.toLowerCase() == displayName;
    });
    if (alreadyConnected) {
      return false;
    }

    // Check if pending request exists
    final bool hasPending = widget.controller.sentChatRequests.any((ChatRequest req) {
      return req.status == ChatRequestStatus.pending &&
          req.toUser.displayName.toLowerCase() == displayName;
    });
    if (hasPending) {
      return false;
    }

    return true;
  }

  String? get _validationMessage {
    final String displayName = _displayNameController.text.trim().toLowerCase();
    if (displayName == '@' || displayName.length < 2) {
      return null;
    }

    final String? currentDisplayName = widget.controller.profile?.displayName.toLowerCase();
    if (currentDisplayName != null && displayName == currentDisplayName) {
      return 'You cannot send a Draw request to yourself.';
    }

    final bool alreadyConnected = widget.controller.recentChats.any((ChatRequest chat) {
      final UserProfile? other = widget.controller.getOtherUser(chat);
      return other?.displayName.toLowerCase() == displayName;
    });
    if (alreadyConnected) {
      return 'You are already connected to this user.';
    }

    final bool hasPending = widget.controller.sentChatRequests.any((ChatRequest req) {
      return req.status == ChatRequestStatus.pending &&
          req.toUser.displayName.toLowerCase() == displayName;
    });
    if (hasPending) {
      return 'You already have a pending request to this user.';
    }

    return null;
  }

  Future<void> _submitRequest() async {
    if (!_canSubmit || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final bool success = await widget.controller.sendChatRequest(_displayNameController.text);

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        if (success) {
          _showNewRequestForm = false;
          _displayNameController.text = '@';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (BuildContext context, _) {
        final List<ChatRequest> allRequests = widget.controller.filteredChatRequests;
        final String? validationMsg = _validationMessage;
        final String? currentUserId = widget.controller.profile?.id;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isCollapsed = !_isCollapsed),
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Draw Requests',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: const Color(0xFF9F1239),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      if (_isCollapsed && allRequests.isNotEmpty)
                        Transform.translate(
                          offset: const Offset(3, -4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFBE123C),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${allRequests.length}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    RefreshIconButton(
                      onRefresh: () => widget.controller.loadDashboardData(showLoading: false),
                      tooltip: 'Refresh draw requests',
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add, size: 18),
                      onPressed: () {
                        setState(() {
                          _showNewRequestForm = !_showNewRequestForm;
                          _displayNameController.text = '@';
                        });
                      },
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                      color: const Color(0xFF9F1239),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFFDA4AF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: const BorderSide(color: Color(0xFFFDA4AF)),
                        ),
                      ),
                      tooltip: 'Send a new draw request',
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(
                        _isCollapsed ? Icons.expand_more : Icons.expand_less,
                        size: 18,
                        color: const Color(0xFF9F1239),
                      ),
                      onPressed: () => setState(() => _isCollapsed = !_isCollapsed),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                      tooltip: _isCollapsed ? 'Expand' : 'Collapse',
                    ),
                  ],
                ),
              ],
            ),
            if (!_isCollapsed) ...<Widget>[
            const SizedBox(height: 8),
            
            // New request form
            if (_showNewRequestForm) ...<Widget>[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  border: Border.all(color: const Color(0xFFFDA4AF)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: DisplayNameTextField(
                            controller: _displayNameController,
                            hintText: '@username',
                            onChanged: (_) {
                              setState(() {});
                            },
                            onSubmitted: (_) => _submitRequest(),
                            enabled: !_isSubmitting,
                            autofocus: true,
                            textStyle: const TextStyle(fontSize: 12, color: Color(0xFF9F1239)),
                            hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFFDA4AF)),
                            decoration: InputDecoration(
                              hintText: '@username',
                              hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFFDA4AF)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              border: const OutlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFFFDA4AF)),
                              ),
                              enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFFFDA4AF)),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFFBE123C), width: 2),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFFCE7F3),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.send, size: 16),
                          onPressed: _canSubmit && !_isSubmitting ? _submitRequest : null,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          constraints: const BoxConstraints(minHeight: 40),
                          color: Colors.white,
                          disabledColor: Colors.white54,
                          style: IconButton.styleFrom(
                            backgroundColor: _canSubmit && !_isSubmitting
                                ? const Color(0xFFBE123C)
                                : const Color(0xFFBE123C).withValues(alpha: 0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          tooltip: 'Send draw request',
                        ),
                      ],
                    ),
                    if (validationMsg != null) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        validationMsg,
                        style: const TextStyle(fontSize: 13, color: Color(0xFFDC2626)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            
            // Draw requests list (both incoming and outgoing)
            ...allRequests.map((ChatRequest request) {
                final UserProfile? other = widget.controller.getOtherUser(request);
                if (other == null) {
                  return const SizedBox.shrink();
                }
                final bool isOutgoing = request.fromUserId == currentUserId &&
                    request.status == ChatRequestStatus.pending;

                // Outgoing request: display with trash icon
                if (isOutgoing) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F2),
                      border: Border.all(color: const Color(0xFFFDA4AF)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      title: Text(
                        '${other.displayName} — ${request.status.value.toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF9F1239),
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFF9F1239)),
                        onPressed: () async {
                          await widget.controller.cancelChatRequest(request.id);
                          await widget.controller.loadDashboardData(showLoading: false);
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Cancel request',
                      ),
                    ),
                  );
                }

                // Incoming request: display with Accept/Reject icon buttons
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    border: Border.all(color: const Color(0xFFFDA4AF)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    title: Text(
                      '${other.displayName} — ${request.status.value.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF9F1239),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        IconButton(
                          icon: const Icon(Icons.check, size: 20, color: Color(0xFF15803D)),
                          onPressed: () async {
                            await widget.controller.respondToChatRequest(
                              chatRequestId: request.id,
                              accept: true,
                            );
                            await widget.controller.loadDashboardData(showLoading: false);
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Accept',
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFBE123C)),
                          onPressed: () async {
                            await widget.controller.respondToChatRequest(
                              chatRequestId: request.id,
                              accept: false,
                            );
                            await widget.controller.loadDashboardData(showLoading: false);
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Reject',
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],
        );
      },
    );
  }
}
