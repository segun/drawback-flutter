import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/realtime/socket_service.dart';
import '../../../core/services/push_notification_service.dart';
import '../data/group_api.dart';
import '../data/social_api.dart';
import '../domain/group_chat_models.dart';
import '../domain/home_models.dart';

/// State controller for home/dashboard functionality
/// Maps to React app's AuthModule state management for post-login features
class HomeController extends ChangeNotifier {
  HomeController({
    required SocialApi socialApi,
    required GroupApi groupApi,
    required String backendUrl,
    void Function()? onUnauthorized,
    PushNotificationService? pushNotificationService,
  })  : _socialApi = socialApi,
        _groupApi = groupApi,
        _backendUrl = backendUrl,
        _onUnauthorized = onUnauthorized,
        _pushNotificationService = pushNotificationService;

  final SocialApi _socialApi;
  final GroupApi _groupApi;
  final String _backendUrl;
  final void Function()? _onUnauthorized;
  final SocketService _socketService = SocketService();
  final PushNotificationService? _pushNotificationService;

  bool _socketInitialized = false;

  bool _isBusy = false;
  bool _isLoadingDashboard = false;
  bool _isLoadingDashboardInProgress = false;
  int _sidebarOpenRequestNonce = 0;
  String? _notice;
  String? _error;

  // User profile
  UserProfile? _profile;
  String _profileDisplayName = '@';
  UserMode _profileMode = UserMode.private;
  bool _appearInSearches = false;

  // Chat requests
  List<ChatRequest> _chatRequests = <ChatRequest>[];
  List<ChatRequest> _sentChatRequests = <ChatRequest>[];

  // Saved chats
  List<SavedChat> _savedChats = <SavedChat>[];

  // Blocked users
  List<UserProfile> _blockedUsers = <UserProfile>[];

  // Group chats
  List<GroupChat> _groupChats = <GroupChat>[];
  String? _selectedGroupChatId;
  List<GroupChatInvitation> _pendingGroupInvitations = <GroupChatInvitation>[];

  // Selected chat for drawing
  String? _selectedChatRequestId;
  String? _joinedChatRequestId;
  final bool _peerPresent = false;

  // Pending actions (for UI feedback)
  final Set<String> _pendingOutgoingUserIds = <String>{};
  final Set<String> _connectedUserIds = <String>{};
  final Map<String, String> _acceptedChatByUserId = <String, String>{};

  // Waiting peers (chat request IDs where peer is waiting)
  final Set<String> _waitingPeerRequestIds = <String>{};

  // Getters
  bool get isBusy => _isBusy;
  bool get isLoadingDashboard => _isLoadingDashboard;
  int get sidebarOpenRequestNonce => _sidebarOpenRequestNonce;
  String? get notice => _notice;
  String? get error => _error;

  UserProfile? get profile => _profile;
  String get profileDisplayName => _profileDisplayName;
  UserMode get profileMode => _profileMode;
  bool get appearInSearches => _appearInSearches;
  bool get isInDiscoveryGame => _profile?.appearInDiscoveryGame ?? false;

  List<ChatRequest> get chatRequests => _chatRequests;
  List<ChatRequest> get sentChatRequests => _sentChatRequests;
  List<SavedChat> get savedChats => _savedChats;
  List<UserProfile> get blockedUsers => _blockedUsers;

  List<GroupChat> get groupChats => _groupChats;
  String? get selectedGroupChatId => _selectedGroupChatId;
  List<GroupChatInvitation> get pendingGroupInvitations => _pendingGroupInvitations;

  String? get selectedChatRequestId => _selectedChatRequestId;
  String? get joinedChatRequestId => _joinedChatRequestId;
  bool get peerPresent => _peerPresent;

  Set<String> get pendingOutgoingUserIds => _pendingOutgoingUserIds;
  Set<String> get connectedUserIds => _connectedUserIds;
  Map<String, String> get acceptedChatByUserId => _acceptedChatByUserId;
  Set<String> get waitingPeerRequestIds => _waitingPeerRequestIds;

  /// Get filtered recent chats (accepted chats)
  List<ChatRequest> get recentChats {
    return _chatRequests
        .where((ChatRequest req) => req.status == ChatRequestStatus.accepted)
        .toList();
  }

  /// Get filtered incoming chat requests (pending requests to current user)
  List<ChatRequest> get incomingChatRequests {
    return _chatRequests
        .where((ChatRequest req) =>
            req.status == ChatRequestStatus.pending &&
            req.toUserId == _profile?.id)
        .toList();
  }

  /// Get all pending chat requests (both incoming and outgoing)
  /// Excludes accepted and rejected requests
  List<ChatRequest> get filteredChatRequests {
    return _chatRequests
        .where((ChatRequest req) =>
            req.status != ChatRequestStatus.accepted &&
            req.status != ChatRequestStatus.rejected)
        .toList();
  }

  /// Load all dashboard data
  Future<bool> loadDashboardData({bool showLoading = true}) async {
    if (_isLoadingDashboardInProgress) {
      return false;
    }
    _isLoadingDashboardInProgress = true;

    try {
      return await _runGuarded<bool>(
        () async {
          if (showLoading) {
            _isLoadingDashboard = true;
            notifyListeners();
          }

          final List<dynamic> results = await Future.wait(<Future<dynamic>>[
            _socialApi.getMyProfile(),
            _socialApi.listReceivedChatRequests(),
            _socialApi.listSentChatRequests(),
            _socialApi.listSavedChats(),
            _socialApi.listBlockedUsers(),
            _groupApi.listGroupChats(),
            _groupApi.listPendingInvitations(),
          ]);

          _profile = results[0] as UserProfile;
          _profileDisplayName = _profile!.displayName;
          _profileMode = _profile!.mode;
          _appearInSearches = _profile!.appearInSearches;

          final List<ChatRequest> received = results[1] as List<ChatRequest>;
          final List<ChatRequest> sent = results[2] as List<ChatRequest>;
          _chatRequests = <ChatRequest>[...received, ...sent];
          _sentChatRequests = sent;

          _savedChats = results[3] as List<SavedChat>;
          _blockedUsers = results[4] as List<UserProfile>;
          _groupChats = results[5] as List<GroupChat>;
          _pendingGroupInvitations = results[6] as List<GroupChatInvitation>;

          // Build connected user sets
          _connectedUserIds.clear();
          _acceptedChatByUserId.clear();
          _pendingOutgoingUserIds.clear();

          for (final ChatRequest req in _chatRequests) {
            if (req.status == ChatRequestStatus.accepted) {
              final String otherId = req.fromUserId == _profile!.id
                  ? req.toUserId
                  : req.fromUserId;
              _connectedUserIds.add(otherId);
              _acceptedChatByUserId[otherId] = req.id;
            } else if (req.status == ChatRequestStatus.pending &&
                req.fromUserId == _profile!.id) {
              _pendingOutgoingUserIds.add(req.toUserId);
            }
          }

          return true;
        },
        fallback: false,
        customBusyFlag: showLoading
            ? () {
                _isLoadingDashboard = false;
                notifyListeners();
              }
            : null,
      );
    } finally {
      _isLoadingDashboardInProgress = false;
    }
  }

  /// Initialize socket connection with access token
  void initializeSocket(String accessToken) {
    if (_socketInitialized) {
      return;
    }

    try {
      _socketService.getOrCreateSocket(
        _backendUrl,
        accessToken,
        onUnauthorized: _onUnauthorized,
      );
      _setupSocketListeners();
      _socketInitialized = true;
    } catch (error) {
      _error = 'Failed to initialize realtime connection: $error';
      notifyListeners();
    }
  }

  void _setupSocketListeners() {
    final socket = _socketService.socket;
    if (socket == null) {
      return;
    }

    socket.on('chat.requested', (dynamic data) {
      _onChatRequested(data);
    });

    socket.on('chat.response', (dynamic data) {
      _onChatResponse(data);
    });

    socket.on('draw.peer.waiting', (dynamic data) {
      _onDrawPeerWaiting(data);
    });

    socket.on('group.invite', (dynamic data) {
      _onGroupInvite(data);
    });

    socket.on('group.invite.response', (dynamic data) {
      _onGroupInviteResponse(data);
    });

    socket.on('group.member.added', (dynamic data) {
      _onGroupMemberAdded(data);
    });

    socket.on('group.removed', (dynamic data) {
      _onGroupRemoved(data);
    });

    socket.on('group.deleted', (dynamic data) {
      _onGroupDeleted(data);
    });

    socket.on('draw.room.closed', (dynamic data) {
      _onDrawRoomClosed(data);
    });

    socket.on('connect_error', (dynamic error) {
      _error = _socketService.mapConnectionErrorMessage(error);
      notifyListeners();
    });
  }

  void _onChatRequested(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return;
    }

    final ChatRequestedPayload payload = ChatRequestedPayload.fromJson(data);
    _notice = '${payload.fromUser.displayName} sent you a chat request';
    notifyListeners();

    // Reload dashboard data to get the new request
    loadDashboardData(showLoading: false);
  }

  Future<void> handleNotificationOpen(String requestId) async {
    if (requestId.trim().isEmpty) {
      return;
    }

    _pushNotificationService?.markRequestAsHandled(requestId);
    _sidebarOpenRequestNonce++;
    notifyListeners();
    await loadDashboardData(showLoading: false);
  }

  void _onChatResponse(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return;
    }

    final ChatResponsePayload payload = ChatResponsePayload.fromJson(data);
    if (payload.accepted) {
      _socketService.emitChatJoin(payload.requestId);
    }

    // Reload dashboard data
    loadDashboardData(showLoading: false);
  }

  void _onDrawPeerWaiting(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return;
    }

    try {
      final DrawPeerWaitingPayload payload =
          DrawPeerWaitingPayload.fromJson(data);
      if (payload.requestId.isNotEmpty) {
        _waitingPeerRequestIds.add(payload.requestId);
        notifyListeners();
      }
    } catch (e) {
      // Log error but don't crash
      if (kDebugMode) {
        print('Error parsing draw.peer.waiting payload: $e');
      }
    }
  }

  void _onGroupInvite(dynamic data) {
    if (data is! Map<String, dynamic>) return;
    try {
      final GroupInvitePayload payload = GroupInvitePayload.fromJson(data);
      _notice =
          '${payload.inviterName} invited you to ${payload.groupName}';
      // Refresh so the new invitation appears in the sidebar
      loadDashboardData(showLoading: false);
    } catch (_) {}
  }

  void _onGroupInviteResponse(dynamic data) {
    if (data is! Map<String, dynamic>) return;
    try {
      final GroupInviteResponsePayload payload =
          GroupInviteResponsePayload.fromJson(data);
      if (payload.accepted) {
        _notice =
            '${payload.inviteeName} accepted your invitation to "${payload.groupName}"';
        // Refresh group list so the new member shows up
        loadDashboardData(showLoading: false);
      } else {
        _notice =
            '${payload.inviteeName} declined your invitation to "${payload.groupName}"';
        notifyListeners();
      }
    } catch (_) {}
  }

  void _onGroupMemberAdded(dynamic data) {
    if (data is! Map<String, dynamic>) return;
    final String? groupId = data['groupId'] as String?;
    if (groupId == null || groupId.isEmpty) return;
    // Refresh the group list then navigate into the new group
    loadDashboardData(showLoading: false).then((_) {
      openGroupChat(groupId);
    });
  }

  Future<void> handleGroupAddedNotificationOpen(String groupId) async {
    if (groupId.trim().isEmpty) return;
    await loadDashboardData(showLoading: false);
    openGroupChat(groupId);
  }

  void _onGroupRemoved(dynamic data) {
    String reason = 'You were removed from the group.';
    if (data is Map<String, dynamic>) {
      try {
        final GroupRemovedPayload payload = GroupRemovedPayload.fromJson(data);
        if (payload.reason.isNotEmpty) {
          reason = payload.reason;
        }
      } catch (_) {
        // keep default reason
      }
    }
    _notice = reason;
    _selectedGroupChatId = null;
    notifyListeners();
  }

  void _onGroupDeleted(dynamic data) {
    String? groupId;
    if (data is Map<String, dynamic>) {
      try {
        final GroupDeletedPayload payload = GroupDeletedPayload.fromJson(data);
        if (payload.groupId.isNotEmpty) groupId = payload.groupId;
      } catch (_) {}
    }
    if (groupId != null) {
      _groupChats.removeWhere((GroupChat g) => g.id == groupId);
      if (_selectedGroupChatId == groupId) {
        _selectedGroupChatId = null;
      }
    } else {
      // No groupId in payload — clear current selection as fallback.
      _selectedGroupChatId = null;
    }
    _notice = 'This group was deleted by the owner.';
    notifyListeners();
  }

  void _onDrawRoomClosed(dynamic data) {
    // group.deleted handles group chat deletion exclusively.
    // This handles 1:1 chat room closure (e.g. the peer terminates the session).
    if (_selectedChatRequestId != null) {
      _selectedChatRequestId = null;
      _notice = 'The other peer left the room.';
      notifyListeners();
    }
  }

  /// Disconnect socket and clean up
  void disconnectSocket() {
    _socketService.disconnect();
    _socketInitialized = false;
  }

  void _removeSocketListeners() {
    final socket = _socketService.socket;
    if (socket == null) {
      return;
    }

    socket.off('chat.requested');
    socket.off('chat.response');
    socket.off('draw.peer.waiting');
    socket.off('group.invite');
    socket.off('group.invite.response');
    socket.off('group.member.added');
    socket.off('group.removed');
    socket.off('group.deleted');
    socket.off('draw.room.closed');
    socket.off('connect_error');
  }

  @override
  void dispose() {
    _removeSocketListeners();
    disconnectSocket();
    super.dispose();
  }

  /// Send a chat request to another user
  Future<bool> sendChatRequest(String toDisplayName) async {
    return _runGuarded<bool>(
      () async {
        // Send the request - response may not include full user objects
        await _socialApi.sendChatRequest(toDisplayName: toDisplayName);

        // Reload dashboard to get complete request data from GET endpoint
        await loadDashboardData(showLoading: false);

        _notice = 'Chat request sent to $toDisplayName';
        return true;
      },
      fallback: false,
    );
  }

  /// Respond to an incoming chat request
  Future<bool> respondToChatRequest({
    required String chatRequestId,
    required bool accept,
  }) async {
    return _runGuarded<bool>(
      () async {
        final RespondToChatRequestResponse response =
            await _socialApi.respondToChatRequest(
          chatRequestId: chatRequestId,
          accept: accept,
        );

        // Update the request in our local state
        final int index =
            _chatRequests.indexWhere((ChatRequest r) => r.id == chatRequestId);
        if (index != -1) {
          _chatRequests[index] = response.request;
        }

        if (accept) {
          _notice = 'Chat request accepted';
          // If room is ready, could auto-open chat here
          if (response.roomId != null) {
            // Room is ready for drawing
          }
        } else {
          _notice = 'Chat request rejected';
        }

        return true;
      },
      fallback: false,
    );
  }

  /// Cancel a sent chat request
  Future<bool> cancelChatRequest(String chatRequestId) async {
    return _runGuarded<bool>(
      () async {
        await _socialApi.cancelChatRequest(chatRequestId: chatRequestId);

        _chatRequests.removeWhere((ChatRequest r) => r.id == chatRequestId);
        _sentChatRequests.removeWhere((ChatRequest r) => r.id == chatRequestId);

        _notice = 'Chat request cancelled';
        return true;
      },
      fallback: false,
    );
  }

  /// Save a chat for later
  Future<bool> saveChat(String chatRequestId) async {
    return _runGuarded<bool>(
      () async {
        await _socialApi.saveChat(chatRequestId: chatRequestId);
        _savedChats = await _socialApi.listSavedChats();
        _notice = 'Chat saved';
        return true;
      },
      fallback: false,
    );
  }

  /// Remove a saved chat
  Future<bool> removeSavedChat(String savedChatId) async {
    return _runGuarded<bool>(
      () async {
        // Find the saved chat to get its chatRequestId before removing
        final SavedChat? savedChat = _savedChats.cast<SavedChat?>().firstWhere(
              (SavedChat? s) => s?.id == savedChatId,
              orElse: () => null,
            );

        await _socialApi.deleteSavedChat(savedChatId: savedChatId);

        // Clear selected chat if it matches the deleted saved chat
        if (savedChat != null &&
            _selectedChatRequestId == savedChat.chatRequestId) {
          _selectedChatRequestId = null;
        }

        // Reload dashboard to sync with backend state
        await loadDashboardData(showLoading: false);

        _notice = 'Saved chat removed';
        return true;
      },
      fallback: false,
    );
  }

  /// Block a user
  Future<bool> blockUser(String blockedUserId) async {
    return _runGuarded<bool>(
      () async {
        // Clear selected chat if it involves the blocked user
        if (_selectedChatRequestId != null) {
          final ChatRequest? selectedChat =
              _chatRequests.cast<ChatRequest?>().firstWhere(
                    (ChatRequest? r) => r?.id == _selectedChatRequestId,
                    orElse: () => null,
                  );
          if (selectedChat != null &&
              (selectedChat.fromUserId == blockedUserId ||
                  selectedChat.toUserId == blockedUserId)) {
            _selectedChatRequestId = null;
          }
        }

        await _socialApi.blockUser(blockedUserId: blockedUserId);

        // Reload dashboard to sync with backend state
        await loadDashboardData(showLoading: false);

        _notice = 'User blocked';
        return true;
      },
      fallback: false,
    );
  }

  /// Unblock a user
  Future<bool> unblockUser(String blockedUserId) async {
    return _runGuarded<bool>(
      () async {
        await _socialApi.unblockUser(blockedUserId: blockedUserId);

        // Reload dashboard to sync with backend state
        // This rebuilds _connectedUserIds and _acceptedChatByUserId maps
        await loadDashboardData(showLoading: false);

        _notice = 'User unblocked';
        return true;
      },
      fallback: false,
    );
  }

  /// Submit a safety report against another user.
  Future<bool> submitReport({
    required String reportedUserId,
    required ReportType reportType,
    required String description,
    String? chatRequestId,
    String? sessionContext,
  }) async {
    return _runGuarded<bool>(
      () async {
        await _socialApi.submitReport(
          reportedUserId: reportedUserId,
          reportType: reportType,
          description: description,
          chatRequestId: chatRequestId,
          sessionContext: sessionContext,
        );

        _notice = reportType == ReportType.csae
            ? 'CSAE report submitted. Our safety team will review it urgently.'
            : 'Report submitted. Thank you for helping keep Drawback safe.';
        return true;
      },
      fallback: false,
    );
  }

  /// Update user profile
  Future<bool> updateProfile(String displayName) async {
    return _runGuarded<bool>(
      () async {
        final UserProfile updated =
            await _socialApi.updateMyProfile(displayName: displayName);
        _profile = updated;
        _profileDisplayName = updated.displayName;
        _notice = 'Profile updated successfully';
        return true;
      },
      fallback: false,
    );
  }

  /// Update user mode
  Future<bool> updateMode(UserMode mode) async {
    return _runGuarded<bool>(
      () async {
        final UserProfile updated = await _socialApi.updateMyMode(mode: mode);
        _profile = updated;
        _profileMode = updated.mode;
        _notice = 'Privacy mode updated';
        return true;
      },
      fallback: false,
    );
  }

  /// Update appear in searches setting
  Future<bool> updateAppearInSearches(bool appearInSearches) async {
    return _runGuarded<bool>(
      () async {
        final UserProfile updated = await _socialApi.updateAppearInSearches(
            appearInSearches: appearInSearches);
        _profile = updated;
        _appearInSearches = updated.appearInSearches;
        _notice = 'Search visibility updated';
        return true;
      },
      fallback: false,
    );
  }

  /// Delete user account
  Future<bool> deleteAccount() async {
    return _runGuarded<bool>(
      () async {
        await _socialApi.deleteMyAccount();
        _notice =
            'Please check your email to confirm account deletion. If you do not receive an email, please contact support.';
        return true;
      },
      fallback: false,
    );
  }

  // ─── Group Chat Methods ────────────────────────────────────────────────────

  /// Open a group chat room
  void openGroupChat(String groupId) {
    _selectedGroupChatId = groupId;
    notifyListeners();
  }

  /// Close the currently selected group chat
  void closeGroupChat() {
    _selectedGroupChatId = null;
    notifyListeners();
  }

  /// Create a new group chat
  Future<bool> createGroupChat(String name) async {
    return _runGuarded<bool>(
      () async {
        final GroupChat group = await _groupApi.createGroupChat(name: name);
        _groupChats = <GroupChat>[group, ..._groupChats];
        _notice = 'Group "${group.name}" created';
        return true;
      },
      fallback: false,
    );
  }

  /// Refresh a single group chat from the server
  Future<void> refreshGroupChat(String groupId) async {
    try {
      final GroupChat updated = await _groupApi.getGroupChat(groupId: groupId);
      final int index = _groupChats.indexWhere((GroupChat g) => g.id == groupId);
      if (index != -1) {
        _groupChats[index] = updated;
      } else {
        _groupChats = <GroupChat>[updated, ..._groupChats];
      }
      notifyListeners();
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        // Group was deleted; remove it from local state silently.
        _groupChats.removeWhere((GroupChat g) => g.id == groupId);
        if (_selectedGroupChatId == groupId) {
          _selectedGroupChatId = null;
        }
        notifyListeners();
      } else {
        _error = e.message;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Unexpected error: $e';
      notifyListeners();
    }
  }

  /// Add a member to a group by display name (owner only) — sends an invitation
  Future<bool> addGroupMember({
    required String groupId,
    required String displayName,
  }) async {
    return _runGuarded<bool>(
      () async {
        await _groupApi.addGroupMember(
          groupId: groupId,
          displayName: displayName,
        );
        _notice = 'Invitation sent';
        return true;
      },
      fallback: false,
    );
  }

  /// Accept or reject a group chat invitation
  Future<bool> respondToGroupInvitation({
    required String invitationId,
    required bool accept,
  }) async {
    return _runGuarded<bool>(
      () async {
        await _groupApi.respondToInvitation(
          invitationId: invitationId,
          accept: accept,
        );
        // Remove from local pending list immediately
        _pendingGroupInvitations.removeWhere(
            (GroupChatInvitation i) => i.id == invitationId);
        if (accept) {
          _notice = 'You joined the group';
          await loadDashboardData(showLoading: false);
        } else {
          _notice = 'Invitation declined';
          notifyListeners();
        }
        return true;
      },
      fallback: false,
    );
  }

  /// Remove a member from a group, or leave if it's the current user
  Future<bool> removeGroupMember({
    required String groupId,
    required String userId,
  }) async {
    return _runGuarded<bool>(
      () async {
        await _groupApi.removeGroupMember(groupId: groupId, userId: userId);
        // If the current user left, remove the group from the list
        if (userId == _profile?.id) {
          _groupChats.removeWhere((GroupChat g) => g.id == groupId);
          if (_selectedGroupChatId == groupId) {
            _selectedGroupChatId = null;
          }
          _notice = 'You left the group';
        } else {
          await refreshGroupChat(groupId);
          _notice = 'Member removed';
        }
        return true;
      },
      fallback: false,
    );
  }

  /// Delete a group (owner only)
  Future<bool> deleteGroup({required String groupId}) async {
    return _runGuarded<bool>(
      () async {
        await _groupApi.deleteGroup(groupId: groupId);
        _groupChats.removeWhere((GroupChat g) => g.id == groupId);
        if (_selectedGroupChatId == groupId) {
          _selectedGroupChatId = null;
        }
        _notice = 'Group deleted';
        return true;
      },
      fallback: false,
    );
  }

  // ─── Chat Methods ──────────────────────────────────────────────────────────

  /// Open a chat (for drawing)
  void openChat(String chatRequestId) {
    _selectedChatRequestId = chatRequestId;
    // Clear waiting state when user opens the chat
    _waitingPeerRequestIds.remove(chatRequestId);
    notifyListeners();
  }

  /// Close the currently selected chat (just clears selection)
  void closeChat() {
    _selectedChatRequestId = null;
    notifyListeners();
  }

  /// Close a recent chat (permanently remove from recent list)
  Future<bool> closeRecentChat(String chatRequestId) async {
    return _runGuarded<bool>(
      () async {
        await _socialApi.removeRecentChat(chatRequestId: chatRequestId);

        // Clear waiting state
        _waitingPeerRequestIds.remove(chatRequestId);

        if (_selectedChatRequestId == chatRequestId) {
          _selectedChatRequestId = null;
        }

        // Reload dashboard to sync with backend state
        await loadDashboardData(showLoading: false);

        return true;
      },
      fallback: false,
    );
  }

  /// Get the other user in a chat request
  UserProfile? getOtherUser(ChatRequest request) {
    if (_profile == null) {
      return null;
    }
    return request.fromUserId == _profile!.id
        ? request.toUser
        : request.fromUser;
  }

  /// Clear messages
  void clearMessages() {
    _clearMessages();
    notifyListeners();
  }

  void clearError() {
    if (_error == null) {
      return;
    }
    _error = null;
    notifyListeners();
  }

  void clearNotice() {
    if (_notice == null) {
      return;
    }
    _notice = null;
    notifyListeners();
  }

  /// Set user profile (called from discovery controller)
  void setProfile(UserProfile profile) {
    _profile = profile;
    _profileDisplayName = profile.displayName;
    _profileMode = profile.mode;
    _appearInSearches = profile.appearInSearches;
    notifyListeners();
  }

  void _clearMessages() {
    _notice = null;
    _error = null;
  }

  Future<T> _runGuarded<T>(
    Future<T> Function() action, {
    required T fallback,
    bool mutateBusyState = true,
    bool clearMessagesBefore = true,
    void Function()? customBusyFlag,
  }) async {
    try {
      if (clearMessagesBefore) {
        _clearMessages();
      }
      if (mutateBusyState) {
        _isBusy = true;
        notifyListeners();
      }
      final T result = await action();
      return result;
    } on ApiException catch (error) {
      _error = error.message;
      return fallback;
    } catch (error) {
      _error = 'Unexpected error: $error';
      return fallback;
    } finally {
      if (mutateBusyState) {
        _isBusy = false;
      }
      if (customBusyFlag != null) {
        customBusyFlag();
      }
      notifyListeners();
    }
  }
}
