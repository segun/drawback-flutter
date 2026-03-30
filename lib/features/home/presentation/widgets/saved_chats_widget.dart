import 'package:flutter/material.dart';

import '../../domain/home_models.dart';
import '../home_controller.dart';
import 'refresh_icon_button.dart';

/// Saved drawings widget for the sidebar
class SavedChatsWidget extends StatefulWidget {
  const SavedChatsWidget({
    required this.controller,
    required this.onChatOpen,
    super.key,
  });

  final HomeController controller;
  final void Function(String chatRequestId) onChatOpen;

  @override
  State<SavedChatsWidget> createState() => _SavedChatsWidgetState();
}

class _SavedChatsWidgetState extends State<SavedChatsWidget> {
  bool _isCollapsed = true;

  @override
  Widget build(BuildContext context) {
    final List<SavedChat> savedChats = widget.controller.savedChats;

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
                      'Saved Drawings',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: const Color(0xFF9F1239),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (_isCollapsed && savedChats.isNotEmpty)
                    Transform.translate(
                      offset: const Offset(3, -4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFBE123C),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${savedChats.length}',
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
              tooltip: 'Refresh saved drawings',
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
          ...savedChats.map((SavedChat saved) {
            final ChatRequest chat = saved.chatRequest;
            final UserProfile? other = widget.controller.getOtherUser(chat);
            if (other == null) {
              return const SizedBox.shrink();
            }

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
                  other.displayName,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF9F1239)),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFF9F1239)),
                  onPressed: () async {
                    final bool? confirmed = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Delete Saved Drawing'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Are you sure you want to delete your saved Drawing with ${other.displayName}?',
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'If you delete your Drawing with ${other.displayName}, you can still continue to Draw with them by selecting their name from Recent Drawings',
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
                      await widget.controller.removeSavedChat(saved.id);
                    }
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
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
