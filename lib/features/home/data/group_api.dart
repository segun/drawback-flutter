import '../../../core/network/api_client.dart';
import '../../auth/data/token_store.dart';
import '../domain/group_chat_models.dart';

/// API for group chat management
class GroupApi {
  GroupApi({required ApiClient client, required TokenStore tokenStore})
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

  Future<List<GroupChat>> listGroupChats() async {
    final dynamic response = await _client.get(
      '/chat/groups',
      headers: await _authHeaders(),
    );

    if (response is! List) {
      return <GroupChat>[];
    }

    return response
        .map((dynamic item) => GroupChat.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<GroupChat> createGroupChat({required String name}) async {
    final Map<String, dynamic> response = await _client.postJson(
      '/chat/groups',
      body: <String, dynamic>{'name': name.trim()},
      headers: await _authHeaders(),
    );
    return GroupChat.fromJson(response);
  }

  Future<GroupChat> getGroupChat({required String groupId}) async {
    final Map<String, dynamic> response = await _client.getJson(
      '/chat/groups/$groupId',
      headers: await _authHeaders(),
    );
    return GroupChat.fromJson(response);
  }

  Future<GroupChatInvitation> addGroupMember({
    required String groupId,
    required String displayName,
  }) async {
    final Map<String, dynamic> response = await _client.postJson(
      '/chat/groups/$groupId/members',
      body: <String, dynamic>{'displayName': displayName.trim()},
      headers: await _authHeaders(),
    );
    return GroupChatInvitation.fromJson(response);
  }

  Future<void> removeGroupMember({
    required String groupId,
    required String userId,
  }) async {
    await _client.deleteJson(
      '/chat/groups/$groupId/members/$userId',
      headers: await _authHeaders(),
    );
  }

  Future<void> deleteGroup({required String groupId}) async {
    await _client.deleteJson(
      '/chat/groups/$groupId',
      headers: await _authHeaders(),
    );
  }

  Future<List<GroupChatInvitation>> listPendingInvitations() async {
    final dynamic response = await _client.get(
      '/chat/groups/invitations/pending',
      headers: await _authHeaders(),
    );
    if (response is! List) {
      return <GroupChatInvitation>[];
    }
    return response
        .map((dynamic item) =>
            GroupChatInvitation.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<GroupChatInvitation> respondToInvitation({
    required String invitationId,
    required bool accept,
  }) async {
    final Map<String, dynamic> response = await _client.postJson(
      '/chat/groups/invitations/$invitationId/respond',
      body: <String, dynamic>{'accept': accept},
      headers: await _authHeaders(),
    );
    return GroupChatInvitation.fromJson(response);
  }
}
