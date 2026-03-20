import 'package:drawback_flutter/features/home/domain/home_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('UserProfile reads ads.provider from /users/me payload', () {
    final UserProfile profile = UserProfile.fromJson(
      <String, dynamic>{
        'id': 'u1',
        'email': 'u1@example.com',
        'displayName': 'u1',
        'mode': 'PUBLIC',
        'appearInSearches': true,
        'appearInDiscoveryGame': false,
        'hasDiscoveryAccess': false,
        'createdAt': '2026-03-20T10:00:00.000Z',
        'updatedAt': '2026-03-20T10:00:00.000Z',
        'ads': <String, dynamic>{'provider': 'admob'},
      },
    );

    expect(profile.discoveryAdsProvider, 'admob');
  });

  test('UserProfile toJson writes ads.provider when available', () {
    final DateTime now = DateTime.parse('2026-03-20T10:00:00.000Z');
    final UserProfile profile = UserProfile(
      id: 'u2',
      email: 'u2@example.com',
      displayName: 'u2',
      mode: UserMode.public,
      appearInSearches: true,
      appearInDiscoveryGame: false,
      hasDiscoveryAccess: false,
      createdAt: now,
      updatedAt: now,
      discoveryAdsProvider: 'admob',
    );

    final Map<String, dynamic> json = profile.toJson();

    expect(json['ads'], isA<Map<String, dynamic>>());
    expect((json['ads'] as Map<String, dynamic>)['provider'], 'admob');
  });
}
