import 'package:flutter/material.dart';

import '../../domain/home_models.dart';
import '../home_controller.dart';
import 'refresh_icon_button.dart';

/// Blocked users widget for the sidebar
class BlockedUsersWidget extends StatefulWidget {
  const BlockedUsersWidget({
    required this.controller,
    super.key,
  });

  final HomeController controller;

  @override
  State<BlockedUsersWidget> createState() => _BlockedUsersWidgetState();
}

class _BlockedUsersWidgetState extends State<BlockedUsersWidget> {
  bool _isCollapsed = true;

  @override
  Widget build(BuildContext context) {
    final List<UserProfile> blockedUsers = widget.controller.blockedUsers;

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
                      'Blocked Users',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: const Color(0xFF9F1239),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (_isCollapsed && blockedUsers.isNotEmpty)
                    Transform.translate(
                      offset: const Offset(3, -4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFBE123C),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${blockedUsers.length}',
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
              tooltip: 'Refresh blocked users',
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
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Are you sure you want to unblock ${user.displayName}?',
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'If you unblock ${user.displayName}, they will be able to send you Draw requests and Draw with you',
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
                      await widget.controller.unblockUser(user.id);
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
      ],
    );
  }
}
