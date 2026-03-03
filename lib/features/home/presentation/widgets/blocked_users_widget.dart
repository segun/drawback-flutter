import 'package:flutter/material.dart';

import '../../domain/home_models.dart';
import '../home_controller.dart';

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
        Text(
          'Blocked Users',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: const Color(0xFF9F1239),
                fontWeight: FontWeight.w600,
              ),
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
                subtitle: Text(
                  user.email,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF9F1239)),
                ),
                trailing: TextButton(
                  onPressed: () async {
                    await controller.unblockUser(user.id);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFBE123C),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Unblock', style: TextStyle(fontSize: 11)),
                ),
              ),
            );
          }),
      ],
    );
  }
}
