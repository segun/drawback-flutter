import 'package:flutter/material.dart';

import '../../domain/home_models.dart';
import '../home_controller.dart';

/// User search widget for the sidebar
class UserSearchWidget extends StatelessWidget {
  const UserSearchWidget({
    required this.controller,
    required this.onChatRequest,
    super.key,
  });

  final HomeController controller;
  final void Function(String chatRequestId) onChatRequest;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Search input
        TextField(
          onChanged: (String value) => controller.searchUsers(value),
          decoration: InputDecoration(
            hintText: 'Search users by display name',
            hintStyle: const TextStyle(fontSize: 13),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFFDA4AF)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFFDA4AF)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFBE123C), width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFFFFF1F2),
          ),
          style: const TextStyle(fontSize: 13),
        ),

        if (controller.searchQuery.trim().isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          Text(
            'Users',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF9F1239),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          if (controller.isSearching)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (controller.searchResults.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'No users found.',
                style: TextStyle(fontSize: 12, color: Color(0xFF9F1239)),
              ),
            )
          else
            ...controller.searchResults.map((UserProfile user) {
              final bool isConnected =
                  controller.connectedUserIds.contains(user.id);
              final bool isPending =
                  controller.pendingOutgoingUserIds.contains(user.id);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  border: Border.all(color: const Color(0xFFFDA4AF)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  dense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  title: Text(
                    user.displayName,
                    style:
                        const TextStyle(fontSize: 13, color: Color(0xFF9F1239)),
                  ),
                  trailing: isConnected
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFCE7F3),
                            border: Border.all(color: const Color(0xFFFDA4AF)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Connected',
                            style: TextStyle(
                                fontSize: 11, color: Color(0xFF9F1239)),
                          ),
                        )
                      : FilledButton(                        
                          onPressed: isPending
                              ? null
                              : () async {
                                  final bool success = await controller
                                      .sendChatRequest(user.displayName);
                                  if (success) {
                                    final String? chatId = controller
                                        .acceptedChatByUserId[user.id];
                                    if (chatId != null) {
                                      onChatRequest(chatId);
                                    }
                                  }
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFBE123C),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(16),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          child: Text(
                            isPending ? 'Sent' : 'Request',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                  onTap: isConnected
                      ? () {
                          final String? chatId =
                              controller.acceptedChatByUserId[user.id];
                          if (chatId != null) {
                            onChatRequest(chatId);
                          }
                        }
                      : null,
                ),
              );
            }),
        ],
      ],
    );
  }
}
