import 'package:flutter/material.dart';

import '../../domain/home_models.dart';
import '../home_controller.dart';

/// Recent chats list widget for the sidebar
class RecentChatsWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final List<ChatRequest> recentChats = controller.recentChats;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Recent Chats',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: const Color(0xFF9F1239),
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        if (recentChats.isEmpty)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'No recent chats.',
              style: TextStyle(fontSize: 12, color: Color(0xFF9F1239)),
            ),
          )
        else
          ...recentChats.map((ChatRequest chat) {
            final UserProfile? other = controller.getOtherUser(chat);
            if (other == null) {
              return const SizedBox.shrink();
            }

            final bool isActive = selectedChatId == chat.id;

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
                title: Text(
                  other.displayName,
                  style: TextStyle(
                    fontSize: 13,
                    color: isActive ? Colors.white : const Color(0xFF9F1239),
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
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
                        await controller.closeRecentChat(chat.id);
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Remove chat',
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        Icons.block,
                        size: 20,
                        color: isActive ? Colors.white : const Color(0xFF9F1239),
                      ),
                      onPressed: () async {
                        await controller.blockUser(other.id);
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Block user',
                    ),
                  ],
                ),
                onTap: () => onChatOpen(chat.id),
              ),
            );
          }),
      ],
    );
  }
}
