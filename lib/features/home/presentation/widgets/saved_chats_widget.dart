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
                    final bool? confirmed = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Delete Saved Chat'),
                          content: Text(
                            'Are you sure you want to delete your saved chat with ${other.displayName}?',
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
                      await controller.removeSavedChat(saved.id);
                    }
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
