import '../../features/auth/data/token_store.dart';
import '../../features/home/domain/home_models.dart';
import '../network/api_client.dart';

class RewardedDiscoveryAccessGrant {
  const RewardedDiscoveryAccessGrant({
    required this.isGranted,
    this.temporaryAccessExpiresAt,
    this.profile,
  });

  final bool isGranted;
  final DateTime? temporaryAccessExpiresAt;
  final UserProfile? profile;

  factory RewardedDiscoveryAccessGrant.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? nestedUserJson = _asObject(json['user']);

    // Extract expiry from top level or nested user object
    final DateTime? expiresAt = _parseDateTime(
            json['temporaryDiscoveryAccessExpiresAt']) ??
        _parseDateTime(nestedUserJson?['temporaryDiscoveryAccessExpiresAt']);

    // The rewarded ad endpoint returns only a partial user object.
    // We'll get the full profile from the normal profile refresh.
    // Just check if the grant was successful.
    final bool isGranted = json['granted'] == true ||
        json['success'] == true ||
        json['hasDiscoveryAccess'] == true ||
        nestedUserJson?['hasDiscoveryAccess'] == true ||
        expiresAt != null;

    return RewardedDiscoveryAccessGrant(
      isGranted: isGranted,
      temporaryAccessExpiresAt: expiresAt,
      profile: null, // Full profile will be fetched via normal refresh
    );
  }

  static Map<String, dynamic>? _asObject(dynamic value) {
    return value is Map<String, dynamic> ? value : null;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is! String || value.trim().isEmpty) {
      return null;
    }

    return DateTime.tryParse(value)?.toLocal();
  }
}

class DiscoveryAccessApi {
  DiscoveryAccessApi(
      {required ApiClient client, required TokenStore tokenStore})
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

  Future<RewardedDiscoveryAccessGrant> claimRewardedAdAccess({
    required int durationMinutes,
  }) async {
    final Map<String, dynamic> response = await _client.postJson(
      '/users/me/discovery-access/rewarded-ad',
      body: <String, dynamic>{
        'grantType': 'rewarded_ad',
        'durationMinutes': durationMinutes,
      },
      headers: await _authHeaders(),
    );

    return RewardedDiscoveryAccessGrant.fromJson(response);
  }
}
