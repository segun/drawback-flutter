import '../../../core/network/api_client.dart';
import '../../auth/data/token_store.dart';
import '../domain/home_models.dart';

/// Social API for managing user profiles, chat requests, saved chats, and blocked users
/// Maps to the React app's socialApi
class SocialApi {
  SocialApi({required ApiClient client, required TokenStore tokenStore})
      : _client = client,
        _tokenStore = tokenStore;

  final ApiClient _client;
  final TokenStore _tokenStore;

  Future<Map<String, String>> _authHeaders() async {
    final String? token = await _tokenStore.readToken();
    if (token == null || token.isEmpty) {
      throw Exception('No access token available');
    }
    return <String, String>{
      'Authorization': 'Bearer $token',
    };
  }

  // User Profile Management

  Future<UserProfile> getMyProfile() async {
    final Map<String, dynamic> response = await _client.getJson(
      '/users/me',
      headers: await _authHeaders(),
    );
    return UserProfile.fromJson(response);
  }

  Future<UserProfile> updateMyProfile({required String displayName}) async {
    final Map<String, dynamic> response = await _client.patchJson(
      '/users/me',
      body: <String, dynamic>{'displayName': displayName.trim()},
      headers: await _authHeaders(),
    );
    return UserProfile.fromJson(response);
  }

  Future<UserProfile> updateMyMode({required UserMode mode}) async {
    final Map<String, dynamic> response = await _client.patchJson(
      '/users/me/mode',
      body: <String, dynamic>{'mode': mode.value},
      headers: await _authHeaders(),
    );
    return UserProfile.fromJson(response);
  }

  Future<UserProfile> updateAppearInSearches({required bool appearInSearches}) async {
    final Map<String, dynamic> response = await _client.patchJson(
      '/users/me/appear-in-searches',
      body: <String, dynamic>{'appearInSearches': appearInSearches},
      headers: await _authHeaders(),
    );
    return UserProfile.fromJson(response);
  }

  Future<void> deleteMyAccount() async {
    await _client.deleteJson(
      '/users/me',
      headers: await _authHeaders(),
    );
  }

  // User Search and Discovery

  Future<List<UserProfile>> listPublicUsers() async {
    final dynamic response = await _client.get(
      '/users/public',
      headers: await _authHeaders(),
    );

    if (response is! List) {
      return <UserProfile>[];
    }

    return response
        .map((dynamic item) => UserProfile.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // Chat Request Management

  Future<List<ChatRequest>> listSentChatRequests() async {
    final dynamic response = await _client.get(
      '/chat/requests/sent',
      headers: await _authHeaders(),
    );

    if (response is! List) {
      return <ChatRequest>[];
    }

    return response
        .map((dynamic item) => ChatRequest.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<ChatRequest>> listReceivedChatRequests() async {
    final dynamic response = await _client.get(
      '/chat/requests/received',
      headers: await _authHeaders(),
    );

    if (response is! List) {
      return <ChatRequest>[];
    }

    return response
        .map((dynamic item) => ChatRequest.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> sendChatRequest({required String toDisplayName}) async {
    await _client.postJson(
      '/chat/requests',
      body: <String, dynamic>{'toDisplayName': toDisplayName.trim()},
      headers: await _authHeaders(),
    );
    // Note: POST response doesn't include fromUser/toUser objects
    // Caller should reload dashboard data to get complete request info
  }

  Future<RespondToChatRequestResponse> respondToChatRequest({
    required String chatRequestId,
    required bool accept,
  }) async {
    final Map<String, dynamic> response = await _client.postJson(
      '/chat/requests/$chatRequestId/respond',
      body: <String, dynamic>{'accept': accept},
      headers: await _authHeaders(),
    );
    return RespondToChatRequestResponse.fromJson(response);
  }

  Future<void> cancelChatRequest({required String chatRequestId}) async {
    await _client.deleteJson(
      '/chat/requests/$chatRequestId',
      headers: await _authHeaders(),
    );
  }

  Future<void> removeRecentChat({required String chatRequestId}) async {
    await _client.deleteJson(
      '/chat/requests/$chatRequestId/remove',
      headers: await _authHeaders(),
    );
  }

  // Saved Chats Management

  Future<List<SavedChat>> listSavedChats() async {
    final dynamic response = await _client.get(
      '/chat/saved',
      headers: await _authHeaders(),
    );

    if (response is! List) {
      return <SavedChat>[];
    }

    return response
        .map((dynamic item) => SavedChat.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveChat({required String chatRequestId}) async {
    await _client.postJson(
      '/chat/requests/$chatRequestId/save',
      headers: await _authHeaders(),
    );
  }

  Future<void> deleteSavedChat({required String savedChatId}) async {
    await _client.deleteJson(
      '/chat/saved/$savedChatId',
      headers: await _authHeaders(),
    );
  }

  // Blocked Users Management

  Future<List<UserProfile>> listBlockedUsers() async {
    final dynamic response = await _client.get(
      '/users/me/blocked',
      headers: await _authHeaders(),
    );

    if (response is! List) {
      return <UserProfile>[];
    }

    return response
        .map((dynamic item) => UserProfile.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> blockUser({required String blockedUserId}) async {
    await _client.postEmpty(
      '/users/$blockedUserId/block',
      headers: await _authHeaders(),
    );
  }

  Future<void> unblockUser({required String blockedUserId}) async {
    await _client.deleteJson(
      '/users/$blockedUserId/block',
      headers: await _authHeaders(),
    );
  }

  Future<UserSafetyReport> submitReport({
    required String reportedUserId,
    required ReportType reportType,
    required String description,
    String? chatRequestId,
    String? sessionContext,
  }) async {
    final Map<String, dynamic> response = await _client.postJson(
      '/reports',
      body: <String, dynamic>{
        'reportedUserId': reportedUserId,
        'reportType': reportType.value,
        'description': description.trim(),
        if (chatRequestId != null && chatRequestId.isNotEmpty)
          'chatRequestId': chatRequestId,
        if (sessionContext != null && sessionContext.trim().isNotEmpty)
          'sessionContext': sessionContext.trim(),
      },
      headers: await _authHeaders(),
    );

    return UserSafetyReport.fromJson(response);
  }

  // Discovery Game Management

  Future<UserProfile> updateDiscoveryGameStatus({
    required bool appearInDiscoveryGame,
    String? base64Image,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'appearInDiscoveryGame': appearInDiscoveryGame,
    };
    
    if (base64Image != null) {
      body['base64Image'] = 'data:image/png;base64,$base64Image';
    }
    
    final Map<String, dynamic> response = await _client.patchJson(
      '/users/me/discovery-game',
      body: body,
      headers: await _authHeaders(),
    );
    
    return UserProfile.fromJson(response);
  }

  Future<DiscoveryUser?> getRandomDiscoveryUser() async {
    final Map<String, dynamic> response = await _client.getJson(
      '/users/discovery/random',
      headers: await _authHeaders(),
    );

    final dynamic wrappedUser = response['user'];
    if (wrappedUser == null && !response.containsKey('id')) {
      return null;
    }

    return DiscoveryUser.fromJson(response);
  }
}
