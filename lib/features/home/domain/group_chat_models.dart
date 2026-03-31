/// Domain models for group chat feature
library;

enum GroupMemberRole {
  owner('OWNER'),
  member('MEMBER');

  const GroupMemberRole(this.value);
  final String value;

  static GroupMemberRole fromString(String value) {
    return GroupMemberRole.values.firstWhere(
      (GroupMemberRole r) => r.value == value,
      orElse: () => GroupMemberRole.member,
    );
  }
}

/// Minimal user reference embedded in group objects (id + displayName only)
class GroupUserRef {
  const GroupUserRef({
    required this.id,
    required this.displayName,
  });

  factory GroupUserRef.fromJson(Map<String, dynamic> json) {
    return GroupUserRef(
      id: json['id'] as String? ?? '',
      // group objects use 'name'; user objects use 'displayName'
      displayName: json['displayName'] as String? ?? json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'displayName': displayName,
    };
  }

  final String id;
  final String displayName;
}

class GroupMember {
  const GroupMember({
    required this.id,
    required this.groupChatId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    required this.user,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: json['id'] as String,
      groupChatId: json['groupChatId'] as String,
      userId: json['userId'] as String,
      role: GroupMemberRole.fromString(json['role'] as String),
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      user: GroupUserRef.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'groupChatId': groupChatId,
      'userId': userId,
      'role': role.value,
      'joinedAt': joinedAt.toIso8601String(),
      'user': user.toJson(),
    };
  }

  final String id;
  final String groupChatId;
  final String userId;
  final GroupMemberRole role;
  final DateTime joinedAt;
  final GroupUserRef user;
}

class GroupChat {
  const GroupChat({
    required this.id,
    required this.name,
    required this.createdByUserId,
    required this.createdBy,
    required this.members,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GroupChat.fromJson(Map<String, dynamic> json) {
    final List<dynamic> membersList = json['members'] as List<dynamic>? ?? <dynamic>[];
    return GroupChat(
      id: json['id'] as String,
      name: json['name'] as String,
      createdByUserId: json['createdByUserId'] as String,
      createdBy: GroupUserRef.fromJson(json['createdBy'] as Map<String, dynamic>),
      members: membersList
          .map((dynamic m) => GroupMember.fromJson(m as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'createdByUserId': createdByUserId,
      'createdBy': createdBy.toJson(),
      'members': members.map((GroupMember m) => m.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  final String id;
  final String name;
  final String createdByUserId;
  final GroupUserRef createdBy;
  final List<GroupMember> members;
  final DateTime createdAt;
  final DateTime updatedAt;
}

enum GroupInvitationStatus {
  pending('PENDING'),
  accepted('ACCEPTED'),
  rejected('REJECTED');

  const GroupInvitationStatus(this.value);
  final String value;

  static GroupInvitationStatus fromString(String value) {
    return GroupInvitationStatus.values.firstWhere(
      (GroupInvitationStatus s) => s.value == value,
      orElse: () => GroupInvitationStatus.pending,
    );
  }
}

class GroupChatInvitation {
  const GroupChatInvitation({
    required this.id,
    required this.groupChatId,
    required this.inviterUserId,
    required this.inviteeUserId,
    required this.status,
    required this.groupChat,
    required this.inviter,
    required this.invitee,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GroupChatInvitation.fromJson(Map<String, dynamic> json) {
    return GroupChatInvitation(
      id: json['id'] as String? ?? '',
      groupChatId: json['groupChatId'] as String? ?? '',
      inviterUserId: json['inviterUserId'] as String? ?? '',
      inviteeUserId: json['inviteeUserId'] as String? ?? '',
      status: GroupInvitationStatus.fromString(json['status'] as String? ?? ''),
      groupChat: GroupUserRef.fromJson(json['groupChat'] as Map<String, dynamic>? ?? <String, dynamic>{}),
      inviter: GroupUserRef.fromJson(json['inviter'] as Map<String, dynamic>? ?? <String, dynamic>{}),
      invitee: GroupUserRef.fromJson(json['invitee'] as Map<String, dynamic>? ?? <String, dynamic>{}),
      createdAt: DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  final String id;
  final String groupChatId;
  final String inviterUserId;
  final String inviteeUserId;
  final GroupInvitationStatus status;
  /// Minimal group info embedded in the invitation { id, displayName (= name) }
  final GroupUserRef groupChat;
  final GroupUserRef inviter;
  final GroupUserRef invitee;
  final DateTime createdAt;
  final DateTime updatedAt;
}
