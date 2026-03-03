import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/realtime/socket_service.dart';
import '../data/social_api.dart';
import '../domain/home_models.dart';

/// State controller for home/dashboard functionality
/// Maps to React app's AuthModule state management for post-login features
class HomeController extends ChangeNotifier {
  HomeController({
    required SocialApi socialApi,
    required String backendUrl,
  })  : _socialApi = socialApi,
        _backendUrl = backendUrl;

  final SocialApi _socialApi;
  final String _backendUrl;
  final SocketService _socketService = SocketService();

  bool _socketInitialized = false;

  bool _isBusy = false;
  bool _isLoadingDashboard = false;
  bool _isSearching = false;
  String? _notice;
  String? _error;

  // User profile
  UserProfile? _profile;
  String _profileDisplayName = '@';
  UserMode _profileMode = UserMode.private;
  bool _appearInSearches = false;

  // Search
  String _searchQuery = '';
  List<UserProfile> _searchResults = <UserProfile>[];

  // Chat requests
  List<ChatRequest> _chatRequests = <ChatRequest>[];
  List<ChatRequest> _sentChatRequests = <ChatRequest>[];

  // Saved chats
  List<SavedChat> _savedChats = <SavedChat>[];

  // Blocked users
  List<UserProfile> _blockedUsers = <UserProfile>[];

  // Selected chat for drawing
  String? _selectedChatRequestId;
  String? _joinedChatRequestId;
  bool _peerPresent = false;

  // Pending actions (for UI feedback)
  final Set<String> _pendingOutgoingUserIds = <String>{};
  final Set<String> _connectedUserIds = <String>{};
  final Map<String, String> _acceptedChatByUserId = <String, String>{};

  // Getters
  bool get isBusy => _isBusy;
  bool get isLoadingDashboard => _isLoadingDashboard;
  bool get isSearching => _isSearching;
  String? get notice => _notice;
  String? get error => _error;

  UserProfile? get profile => _profile;
  String get profileDisplayName => _profileDisplayName;
  UserMode get profileMode => _profileMode;
  bool get appearInSearches => _appearInSearches;

  String get searchQuery => _searchQuery;
  List<UserProfile> get searchResults => _searchResults;

  List<ChatRequest> get chatRequests => _chatRequests;
  List<ChatRequest> get sentChatRequests => _sentChatRequests;
  List<SavedChat> get savedChats => _savedChats;
  List<UserProfile> get blockedUsers => _blockedUsers;

  String? get selectedChatRequestId => _selectedChatRequestId;
  String? get joinedChatRequestId => _joinedChatRequestId;
  bool get peerPresent => _peerPresent;

  Set<String> get pendingOutgoingUserIds => _pendingOutgoingUserIds;
  Set<String> get connectedUserIds => _connectedUserIds;
  Map<String, String> get acceptedChatByUserId => _acceptedChatByUserId;

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
    return _runGuarded<bool>(
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

        // Build connected user sets
        _connectedUserIds.clear();
        _acceptedChatByUserId.clear();
        _pendingOutgoingUserIds.clear();

        for (final ChatRequest req in _chatRequests) {
          if (req.status == ChatRequestStatus.accepted) {
            final String otherId =
                req.fromUserId == _profile!.id ? req.toUserId : req.fromUserId;
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
  }

  /// Initialize socket connection with access token
  void initializeSocket(String accessToken) {
    if (_socketInitialized) {
      return;
    }

    try {
      _socketService.getOrCreateSocket(_backendUrl, accessToken);
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

    socket.on('connect_error', (dynamic error) {
      _error = 'Realtime connection failed';
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

  /// Disconnect socket and clean up
  void disconnectSocket() {
    _socketService.disconnect();
    _socketInitialized = false;
  }

  @override
  void dispose() {
    disconnectSocket();
    super.dispose();
  }

  /// Search for public users
  Future<void> searchUsers(String query) async {
    _searchQuery = query;
    notifyListeners();

    if (query.trim().isEmpty) {
      _searchResults = <UserProfile>[];
      notifyListeners();
      return;
    }

    await _runGuarded<void>(
      () async {
        _isSearching = true;
        notifyListeners();

        _searchResults = await _socialApi.searchPublicUsers(query);
      },
      fallback: null,
      mutateBusyState: false,
      clearMessagesBefore: false,
      customBusyFlag: () {
        _isSearching = false;
        notifyListeners();
      },
    );
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
        final int index = _chatRequests.indexWhere((ChatRequest r) => r.id == chatRequestId);
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
        await _socialApi.deleteSavedChat(savedChatId: savedChatId);
        _savedChats.removeWhere((SavedChat s) => s.id == savedChatId);
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
        await _socialApi.blockUser(blockedUserId: blockedUserId);

        // Reload blocked users list
        _blockedUsers = await _socialApi.listBlockedUsers();

        // Remove any chat requests with this user
        _chatRequests.removeWhere(
            (ChatRequest r) => r.fromUserId == blockedUserId || r.toUserId == blockedUserId);
        _sentChatRequests.removeWhere(
            (ChatRequest r) => r.fromUserId == blockedUserId || r.toUserId == blockedUserId);

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
        _blockedUsers.removeWhere((UserProfile u) => u.id == blockedUserId);
        _notice = 'User unblocked';
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
        final UserProfile updated =
            await _socialApi.updateAppearInSearches(appearInSearches: appearInSearches);
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
        _notice = 'Account deleted successfully';
        return true;
      },
      fallback: false,
    );
  }

  /// Open a chat (for drawing)
  void openChat(String chatRequestId) {
    _selectedChatRequestId = chatRequestId;
    notifyListeners();
  }

  /// Close a recent chat (permanently remove from recent list)
  Future<bool> closeRecentChat(String chatRequestId) async {
    return _runGuarded<bool>(
      () async {
        await _socialApi.removeRecentChat(chatRequestId: chatRequestId);

        // Remove from local state
        _chatRequests.removeWhere((ChatRequest req) => req.id == chatRequestId);
        
        if (_selectedChatRequestId == chatRequestId) {
          _selectedChatRequestId = null;
        }
        
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
    return request.fromUserId == _profile!.id ? request.toUser : request.fromUser;
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
