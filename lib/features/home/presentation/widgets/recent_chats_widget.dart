import 'package:flutter/material.dart';

import '../../domain/home_models.dart';
import '../home_controller.dart';
import 'pulsing_indicator.dart';
import 'refresh_icon_button.dart';

/// Recent drawings list widget for the sidebar
class RecentChatsWidget extends StatefulWidget {
  const RecentChatsWidget({
    required this.controller,
    required this.onChatOpen,
    required this.selectedChatId,
    super.key,
  });

  final HomeController controller;
  final void Function(String chatRequestId) onChatOpen;
  final String? selectedChatId;

  @override
  State<RecentChatsWidget> createState() => _RecentChatsWidgetState();
}

class _RecentChatsWidgetState extends State<RecentChatsWidget> {
  bool _isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final List<ChatRequest> recentChats = widget.controller.recentChats;

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
                      'Recent Drawings',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: const Color(0xFF9F1239),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (_isCollapsed && recentChats.isNotEmpty)
                    Transform.translate(
                      offset: const Offset(3, -4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFBE123C),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${recentChats.length}',
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
            RefreshIconButton(
              onRefresh: () => widget.controller.loadDashboardData(showLoading: false),
              tooltip: 'Refresh recent drawings',
            ),
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
        if (!_isCollapsed) ...<Widget>[
          const SizedBox(height: 8),
          if (recentChats.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'No recent drawings.',
                style: TextStyle(fontSize: 12, color: Color(0xFF9F1239)),
              ),
            )
          else
            ...recentChats.map((ChatRequest chat) {
              final UserProfile? other = widget.controller.getOtherUser(chat);
              if (other == null) {
                return const SizedBox.shrink();
              }

              final bool isActive = widget.selectedChatId == chat.id;
              final bool isPeerWaiting = widget.controller.waitingPeerRequestIds.contains(chat.id);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFFBE123C) : const Color(0xFFFFF1F2),
                  border: Border.all(
                    color: isActive ? const Color(0xFFBE123C) : const Color(0xFFFDA4AF),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  title: Row(
                    children: <Widget>[
                      if (isPeerWaiting)
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: PulsingIndicator(size: 8),
                        ),
                      Expanded(
                        child: Text(
                          other.displayName,
                          style: TextStyle(
                            fontSize: 13,
                            color: isActive ? Colors.white : const Color(0xFF9F1239),
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: isActive ? Colors.white : const Color(0xFF9F1239),
                        ),
                        onPressed: () async {
                          final bool? confirmed = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Delete Drawing'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      'Are you sure you want to delete your Drawing with ${other.displayName}?',
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'You can start Drawing with ${other.displayName} again by sending them a Draw Request',
                                      style: const TextStyle(color: Color(0xFF6B7280)),
                                    ),
                                  ],
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('No'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFFB91C1C),
                                      padding: const EdgeInsets.all(16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(1),
                                      ),
                                    ),
                                    child: const Text('Yes, delete'),
                                  ),
                                ],
                              );
                            },
                          );

                          if (confirmed == true) {
                            await widget.controller.closeRecentChat(chat.id);
                          }
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Remove drawing',
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          Icons.block,
                          size: 20,
                          color: isActive ? Colors.white : const Color(0xFF9F1239),
                        ),
                        onPressed: () async {
                          final bool? confirmed = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Block User'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      'Are you sure you want to block ${other.displayName}?',
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'If you proceed, ${other.displayName} will not be able to Draw with you anymore until you unblock them',
                                      style: const TextStyle(color: Color(0xFF6B7280)),
                                    ),
                                  ],
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('No'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFFB91C1C),
                                      padding: const EdgeInsets.all(16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(1),
                                      ),
                                    ),
                                    child: const Text('Yes, block'),
                                  ),
                                ],
                              );
                            },
                          );

                          if (confirmed == true) {
                            await widget.controller.blockUser(other.id);
                          }
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Block user',
                      ),
                    ],
                  ),
                  onTap: () => widget.onChatOpen(chat.id),
                ),
              );
            }),
        ],
      ],
    );
  }
}
