import 'package:flutter/material.dart';

import '../../domain/home_models.dart';
import '../home_controller.dart';

/// Saved chats widget for the sidebar
class SavedChatsWidget extends StatelessWidget {
  const SavedChatsWidget({
    required this.controller,
    required this.onChatOpen,
    super.key,
  });

  final HomeController controller;
  final void Function(String chatRequestId) onChatOpen;

  @override
  Widget build(BuildContext context) {
    final List<SavedChat> savedChats = controller.savedChats;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Saved Chats',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: const Color(0xFF9F1239),
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        if (savedChats.isEmpty)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'No saved chats.',
              style: TextStyle(fontSize: 12, color: Color(0xFF9F1239)),
            ),
          )
        else
          ...savedChats.map((SavedChat saved) {
            final ChatRequest chat = saved.chatRequest;
            final UserProfile? other = controller.getOtherUser(chat);
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
                    await controller.removeSavedChat(saved.id);
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
                onTap: () => onChatOpen(chat.id),
              ),
            );
          }),
      ],
    );
  }
}
