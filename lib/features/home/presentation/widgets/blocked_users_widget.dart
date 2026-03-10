import 'package:flutter/material.dart';

import '../../domain/home_models.dart';
import '../home_controller.dart';
import 'refresh_icon_button.dart';

/// Blocked users widget for the sidebar
class BlockedUsersWidget extends StatelessWidget {
  const BlockedUsersWidget({
    required this.controller,
    super.key,
  });

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final List<UserProfile> blockedUsers = controller.blockedUsers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Text(
                'Blocked Users',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: const Color(0xFF9F1239),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            RefreshIconButton(
              onRefresh: () => controller.loadDashboardData(showLoading: false),
              tooltip: 'Refresh blocked users',
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (blockedUsers.isEmpty)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'No blocked users.',
              style: TextStyle(fontSize: 12, color: Color(0xFF9F1239)),
            ),
          )
        else
          ...blockedUsers.map((UserProfile user) {
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
                  user.displayName,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF9F1239)),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.check_circle_outline, size: 20, color: Color(0xFF9F1239)),
                  onPressed: () async {
                    final bool? confirmed = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Unblock User'),
                          content: Text(
                            'Are you sure you want to unblock ${user.displayName}?',
                          ),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('No'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF16A34A),
                                padding: const EdgeInsets.all(16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                              child: const Text('Yes, unblock'),
                            ),
                          ],
                        );
                      },
                    );

                    if (confirmed == true) {
                      await controller.unblockUser(user.id);
                    }
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Unblock user',
                ),
              ),
            );
          }),
      ],
    );
  }
}
