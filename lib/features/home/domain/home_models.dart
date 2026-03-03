/// Domain models for home/social features
/// Maps to the React app's socialApi types

enum UserMode {
  public('PUBLIC'),
  private('PRIVATE');

  const UserMode(this.value);
  final String value;

  static UserMode fromString(String value) {
    return UserMode.values.firstWhere(
      (mode) => mode.value == value,
      orElse: () => UserMode.private,
    );
  }
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.mode,
    required this.appearInSearches,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String email;
  final String displayName;
  final UserMode mode;
  final bool appearInSearches;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      mode: UserMode.fromString(json['mode'] as String),
      appearInSearches: json['appearInSearches'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'email': email,
      'displayName': displayName,
      'mode': mode.value,
      'appearInSearches': appearInSearches,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    UserMode? mode,
    bool? appearInSearches,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      mode: mode ?? this.mode,
      appearInSearches: appearInSearches ?? this.appearInSearches,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum ChatRequestStatus {
  pending('PENDING'),
  accepted('ACCEPTED'),
  rejected('REJECTED');

  const ChatRequestStatus(this.value);
  final String value;

  static ChatRequestStatus fromString(String value) {
    return ChatRequestStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ChatRequestStatus.pending,
    );
  }
}

class ChatRequest {
  const ChatRequest({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.fromUser,
    required this.toUser,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String fromUserId;
  final String toUserId;
  final UserProfile fromUser;
  final UserProfile toUser;
  final ChatRequestStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ChatRequest.fromJson(Map<String, dynamic> json) {
    final dynamic fromUserData = json['fromUser'];
    final dynamic toUserData = json['toUser'];

    if (fromUserData == null) {
      throw FormatException('ChatRequest.fromJson: fromUser is null in response: $json');
    }
    if (toUserData == null) {
      throw FormatException('ChatRequest.fromJson: toUser is null in response: $json');
    }
    if (fromUserData is! Map<String, dynamic>) {
      throw FormatException('ChatRequest.fromJson: fromUser is not a Map: $fromUserData');
    }
    if (toUserData is! Map<String, dynamic>) {
      throw FormatException('ChatRequest.fromJson: toUser is not a Map: $toUserData');
    }

    return ChatRequest(
      id: json['id'] as String,
      fromUserId: json['fromUserId'] as String,
      toUserId: json['toUserId'] as String,
      fromUser: UserProfile.fromJson(fromUserData),
      toUser: UserProfile.fromJson(toUserData),
      status: ChatRequestStatus.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'fromUser': fromUser.toJson(),
      'toUser': toUser.toJson(),
      'status': status.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class SavedChat {
  const SavedChat({
    required this.id,
    required this.chatRequestId,
    required this.savedByUserId,
    required this.chatRequest,
    required this.savedBy,
    required this.savedAt,
  });

  final String id;
  final String chatRequestId;
  final String savedByUserId;
  final ChatRequest chatRequest;
  final UserProfile savedBy;
  final DateTime savedAt;

  factory SavedChat.fromJson(Map<String, dynamic> json) {
    return SavedChat(
      id: json['id'] as String,
      chatRequestId: json['chatRequestId'] as String,
      savedByUserId: json['savedByUserId'] as String,
      chatRequest: ChatRequest.fromJson(json['chatRequest'] as Map<String, dynamic>),
      savedBy: UserProfile.fromJson(json['savedBy'] as Map<String, dynamic>),
      savedAt: DateTime.parse(json['savedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'chatRequestId': chatRequestId,
      'savedByUserId': savedByUserId,
      'chatRequest': chatRequest.toJson(),
      'savedBy': savedBy.toJson(),
      'savedAt': savedAt.toIso8601String(),
    };
  }
}

class RespondToChatRequestResponse {
  const RespondToChatRequestResponse({
    required this.request,
    this.roomId,
  });

  final ChatRequest request;
  final String? roomId;

  factory RespondToChatRequestResponse.fromJson(Map<String, dynamic> json) {
    return RespondToChatRequestResponse(
      request: ChatRequest.fromJson(json['request'] as Map<String, dynamic>),
      roomId: json['roomId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'request': request.toJson(),
      'roomId': roomId,
    };
  }
}
