import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/widgets/display_name_text_field.dart';
import '../../domain/group_chat_models.dart';
import '../home_controller.dart';
import 'refresh_icon_button.dart';

/// Group Drawings sidebar section widget
class GroupChatsWidget extends StatefulWidget {
  const GroupChatsWidget({
    required this.controller,
    required this.onGroupOpen,
    super.key,
  });

  final HomeController controller;
  final void Function(String groupId) onGroupOpen;

  @override
  State<GroupChatsWidget> createState() => _GroupChatsWidgetState();
}

class _GroupChatsWidgetState extends State<GroupChatsWidget> {
  bool _isCollapsed = true;
  bool _showNewGroupForm = false;
  final TextEditingController _groupNameController = TextEditingController();
  bool _isSubmitting = false;

  // Per-group expansion state (keyed by groupId)
  final Map<String, bool> _expandedGroups = <String, bool>{};

  // Per-group add-member form state
  final Map<String, bool> _showAddMemberForm = <String, bool>{};
  final Map<String, TextEditingController> _addMemberControllers =
      <String, TextEditingController>{};

  @override
  void dispose() {
    _groupNameController.dispose();
    for (final TextEditingController c in _addMemberControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _memberController(String groupId) {
    return _addMemberControllers.putIfAbsent(
      groupId,
      () => TextEditingController(text: '@'),
    );
  }

  Future<void> _submitCreateGroup() async {
    final String name = _groupNameController.text.trim();
    if (name.isEmpty || _isSubmitting) {
      return;
    }
    setState(() => _isSubmitting = true);
    final bool success = await widget.controller.createGroupChat(name);
    if (mounted) {
      setState(() {
        _isSubmitting = false;
        if (success) {
          _showNewGroupForm = false;
          _groupNameController.clear();
        }
      });
    }
  }

  Future<bool?> _confirmDialog({
    required BuildContext context,
    required String title,
    required String content,
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE11D48),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleGroupAction(
    BuildContext context,
    GroupChat group,
    String myUserId,
  ) async {
    final bool isOwner = group.createdByUserId == myUserId;
    if (isOwner) {
      final bool? confirmed = await _confirmDialog(
        context: context,
        title: 'Delete group?',
        content:
            'Are you sure you want to delete "${group.name}"? All members will be removed.',
        confirmLabel: 'Delete',
      );
      if (confirmed == true) {
        await widget.controller.deleteGroup(groupId: group.id);
      }
    } else {
      final bool? confirmed = await _confirmDialog(
        context: context,
        title: 'Leave group?',
        content: 'Are you sure you want to leave "${group.name}"?',
        confirmLabel: 'Leave',
      );
      if (confirmed == true) {
        await widget.controller.removeGroupMember(
          groupId: group.id,
          userId: myUserId,
        );
      }
    }
  }

  Future<void> _handleRemoveMember(
    BuildContext context,
    GroupChat group,
    GroupMember member,
  ) async {
    final bool? confirmed = await _confirmDialog(
      context: context,
      title: 'Remove member?',
      content:
          'Are you sure you want to remove ${member.user.displayName} from "${group.name}"?',
      confirmLabel: 'Remove',
    );
    if (confirmed == true) {
      await widget.controller.removeGroupMember(
        groupId: group.id,
        userId: member.userId,
      );
    }
  }

  Future<void> _submitAddMember(String groupId) async {
    final TextEditingController ctrl = _memberController(groupId);
    final String displayName = ctrl.text.trim();
    if (displayName == '@' || displayName.length < 2) {
      return;
    }
    final bool success = await widget.controller.addGroupMember(
      groupId: groupId,
      displayName: displayName,
    );
    if (mounted && success) {
      setState(() {
        _showAddMemberForm[groupId] = false;
        ctrl.text = '@';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (BuildContext context, _) {
        final List<GroupChat> groups = widget.controller.groupChats;
        final String? myUserId = widget.controller.profile?.id;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Section header
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
                          'Group Drawings',
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: const Color(0xFF9F1239),
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        if (_isCollapsed && groups.isNotEmpty)
                          Transform.translate(
                            offset: const Offset(3, -4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 3, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFBE123C),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${groups.length}',
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
                      onRefresh: () =>
                          widget.controller.loadDashboardData(showLoading: false),
                      tooltip: 'Refresh group drawings',
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add, size: 18),
                      onPressed: () {
                        setState(() {
                          _isCollapsed = false;
                          _showNewGroupForm = !_showNewGroupForm;
                          _groupNameController.clear();
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
                      tooltip: 'Create a new group',
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _isCollapsed = !_isCollapsed),
                      child: Icon(
                        _isCollapsed
                            ? Icons.expand_more
                            : Icons.expand_less,
                        size: 20,
                        color: const Color(0xFF9F1239),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // New group form
            if (!_isCollapsed && _showNewGroupForm) ...<Widget>[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFDA4AF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    TextField(
                      controller: _groupNameController,
                      autofocus: true,
                      enabled: !_isSubmitting,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Group name',
                        hintText: 'e.g. Weekend painters',
                        isDense: true,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                      ),
                      onSubmitted: (_) => unawaited(_submitCreateGroup()),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        TextButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => setState(() {
                                    _showNewGroupForm = false;
                                    _groupNameController.clear();
                                  }),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => unawaited(_submitCreateGroup()),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFE11D48),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white),
                                )
                              : const Text('Create'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            // Group list
            if (!_isCollapsed) ...<Widget>[
              const SizedBox(height: 4),
              ...groups.map((GroupChat group) {
                  final bool isOwner = group.createdByUserId == myUserId;
                  final bool isExpanded =
                      _expandedGroups[group.id] ?? false;
                  final bool showAddMember =
                      _showAddMemberForm[group.id] ?? false;

                  return _buildGroupItem(
                    context: context,
                    group: group,
                    myUserId: myUserId ?? '',
                    isOwner: isOwner,
                    isExpanded: isExpanded,
                    showAddMember: showAddMember,
                  );
                }),
            ],
          ],
        );
      },
    );
  }

  Widget _buildGroupItem({
    required BuildContext context,
    required GroupChat group,
    required String myUserId,
    required bool isOwner,
    required bool isExpanded,
    required bool showAddMember,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFFDA4AF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Group row
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
            child: Row(
              children: <Widget>[
                // Expand/collapse per-group
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _expandedGroups[group.id] = !isExpanded;
                    });
                  },
                  child: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 24,
                    color: const Color(0xFF9F1239),
                  ),
                ),
                const SizedBox(width: 4),
                // Group name (tappable)
                Expanded(
                  child: GestureDetector(
                    onTap: () => widget.onGroupOpen(group.id),
                    child: Text(
                      group.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF9F1239),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                // Member count badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDA4AF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${group.members.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9F1239),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Add member button (owner only)
                if (isOwner)
                  IconButton(
                    icon: const Icon(Icons.person_add_outlined, size: 20),
                    onPressed: () {
                      setState(() {
                        _showAddMemberForm[group.id] = !showAddMember;
                        if (!showAddMember) {
                          _memberController(group.id).text = '@';
                        }
                      });
                    },
                    padding: const EdgeInsets.all(2),
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                    color: const Color(0xFF9F1239),
                    tooltip: 'Add member',
                  ),
                if (isOwner) const SizedBox(width: 2),
                // Delete (owner) / Leave (member) button
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => unawaited(
                    _handleGroupAction(context, group, myUserId),
                  ),
                  padding: const EdgeInsets.all(2),
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                  color: const Color(0xFF9F1239),
                  tooltip: isOwner ? 'Delete group' : 'Leave group',
                ),
              ],
            ),
          ),

          // Add member form
          if (showAddMember) ...<Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: DisplayNameTextField(
                      controller: _memberController(group.id),
                      labelText: 'Display name',
                      hintText: '@username',
                      autofocus: true,
                      onSubmitted: (_) =>
                          unawaited(_submitAddMember(group.id)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  FilledButton(
                    onPressed: () => unawaited(_submitAddMember(group.id)),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE11D48),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text('Add'),
                  ),
                ],
              ),
            ),
          ],

          // Member list (expanded)
          if (isExpanded) ...<Widget>[
            const Divider(height: 1, color: Color(0xFFFDA4AF)),
            ...group.members.map((GroupMember member) {
              final bool isSelf = member.userId == myUserId;
              final bool memberIsOwner =
                  member.userId == group.createdByUserId;
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                child: Row(
                  children: <Widget>[
                    Icon(
                      memberIsOwner
                          ? Icons.star_outline
                          : Icons.person_outline,
                      size: 14,
                      color: const Color(0xFF9F1239),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${member.user.displayName}${isSelf ? ' (you)' : ''}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9F1239),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Owner can remove non-owner members
                    if (isOwner && !memberIsOwner)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            size: 20),
                        onPressed: () => unawaited(
                          _handleRemoveMember(context, group, member),
                        ),
                        padding: const EdgeInsets.all(2),
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                        color: const Color(0xFF9F1239),
                        tooltip: 'Remove member',
                      ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}
