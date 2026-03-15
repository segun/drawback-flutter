/// Domain models for home/social features
/// Maps to the React app's socialApi types
library;

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

/// Subscription information from backend
class Subscription {
  const Subscription({
    required this.tier,
    required this.platform,
    required this.endDate,
    required this.autoRenew,
  });

  final String tier; // 'monthly', 'quarterly', 'yearly'
  final String platform; // 'android', 'ios', 'mock'
  final DateTime endDate;
  final bool autoRenew;

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      tier: json['tier'] as String,
      platform: json['platform'] as String? ?? 'unknown',
      endDate: DateTime.parse(json['endDate'] as String),
      autoRenew: (json['autoRenew'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'tier': tier,
      'platform': platform,
      'endDate': endDate.toIso8601String(),
      'autoRenew': autoRenew,
    };
  }

  /// Get human-readable platform name for UI display
  String get platformDisplayName {
    switch (platform.toLowerCase()) {
      case 'android':
        return 'Google Play Store';
      case 'ios':
        return 'App Store';
      case 'mock':
        return 'Test Subscription';
      default:
        return platform;
    }
  }
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.mode,
    required this.appearInSearches,
    required this.appearInDiscoveryGame,
    required this.hasDiscoveryAccess,
    required this.createdAt,
    required this.updatedAt,
    this.subscription,
  });

  final String id;
  final String email;
  final String displayName;
  final UserMode mode;
  final bool appearInSearches;
  final bool appearInDiscoveryGame;
  final bool hasDiscoveryAccess;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Subscription? subscription;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      mode: UserMode.fromString(json['mode'] as String),
      appearInSearches: (json['appearInSearches'] as bool?) ?? false,
      appearInDiscoveryGame: (json['appearInDiscoveryGame'] as bool?) ?? false,
      hasDiscoveryAccess: (json['hasDiscoveryAccess'] as bool?) ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      subscription: json['subscription'] != null
          ? Subscription.fromJson(json['subscription'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'email': email,
      'displayName': displayName,
      'mode': mode.value,
      'appearInSearches': appearInSearches,
      'appearInDiscoveryGame': appearInDiscoveryGame,
      'hasDiscoveryAccess': hasDiscoveryAccess,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (subscription != null) 'subscription': subscription!.toJson(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    UserMode? mode,
    bool? appearInSearches,
    bool? appearInDiscoveryGame,
    bool? hasDiscoveryAccess,
    DateTime? createdAt,
    DateTime? updatedAt,
    Subscription? subscription,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      mode: mode ?? this.mode,
      appearInSearches: appearInSearches ?? this.appearInSearches,
      appearInDiscoveryGame: appearInDiscoveryGame ?? this.appearInDiscoveryGame,
      hasDiscoveryAccess: hasDiscoveryAccess ?? this.hasDiscoveryAccess,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      subscription: subscription ?? this.subscription,
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

class DiscoveryUser {
  const DiscoveryUser({
    required this.id,
    required this.displayName,
    this.discoveryImageUrl,
  });

  final String id;
  final String displayName;
  final String? discoveryImageUrl;

  factory DiscoveryUser.fromJson(Map<String, dynamic> json) {
    // Handle both wrapped {"user": {...}} and unwrapped {...} responses
    final Map<String, dynamic> userData =
        json.containsKey('user') ? json['user'] as Map<String, dynamic> : json;
    return DiscoveryUser(
      id: userData['id'] as String,
      displayName: userData['displayName'] as String,
      discoveryImageUrl: userData['discoveryImageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'displayName': displayName,
      'discoveryImageUrl': discoveryImageUrl,
    };
  }
}

enum ReportType {
  csae('CSAE'),
  harassment('HARASSMENT'),
  inappropriateContent('INAPPROPRIATE_CONTENT'),
  spam('SPAM'),
  impersonation('IMPERSONATION'),
  other('OTHER');

  const ReportType(this.value);
  final String value;

  static ReportType fromString(String value) {
    return ReportType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ReportType.other,
    );
  }
}

enum ReportStatus {
  pending('PENDING'),
  underReview('UNDER_REVIEW'),
  resolved('RESOLVED'),
  dismissed('DISMISSED');

  const ReportStatus(this.value);
  final String value;

  static ReportStatus fromString(String value) {
    return ReportStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ReportStatus.pending,
    );
  }
}

class UserSafetyReport {
  const UserSafetyReport({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    required this.reportType,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.chatRequestId,
    this.sessionContext,
  });

  final String id;
  final String reporterId;
  final String reportedUserId;
  final ReportType reportType;
  final String description;
  final String? chatRequestId;
  final String? sessionContext;
  final ReportStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory UserSafetyReport.fromJson(Map<String, dynamic> json) {
    return UserSafetyReport(
      id: json['id'] as String,
      reporterId: json['reporterId'] as String,
      reportedUserId: json['reportedUserId'] as String,
      reportType: ReportType.fromString(json['reportType'] as String),
      description: json['description'] as String,
      chatRequestId: json['chatRequestId'] as String?,
      sessionContext: json['sessionContext'] as String?,
      status: ReportStatus.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'reportType': reportType.value,
      'description': description,
      'chatRequestId': chatRequestId,
      'sessionContext': sessionContext,
      'status': status.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
