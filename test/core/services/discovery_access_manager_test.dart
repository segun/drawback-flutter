import 'package:drawback_flutter/core/network/api_client.dart';
import 'package:drawback_flutter/core/network/api_exception.dart';
import 'package:drawback_flutter/core/services/ad_service.dart';
import 'package:drawback_flutter/core/services/discovery_access_api.dart';
import 'package:drawback_flutter/core/services/discovery_access_manager.dart';
import 'package:drawback_flutter/core/services/purchase_service.dart';
import 'package:drawback_flutter/features/auth/data/token_store.dart';
import 'package:drawback_flutter/features/home/domain/home_models.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeTokenStore implements TokenStore {
  @override
  Future<void> clearToken() async {}

  @override
  Future<String?> readToken() async => 'token';

  @override
  Future<void> writeToken(String token) async {}
}

class FakePurchaseService extends PurchaseService {
  FakePurchaseService()
      : super(
          client: ApiClient(baseUrl: 'https://example.com'),
          tokenStore: FakeTokenStore(),
        );

  @override
  Future<bool> purchaseDiscovery({
    SubscriptionTier tier = SubscriptionTier.monthly,
  }) async {
    return false;
  }

  @override
  Future<String> restorePurchases() async {
    return 'No purchases to restore';
  }
}

class FakeAdService extends AdService {
  FakeAdService() : super(initializeOnCreate: false);

  bool earnedReward = true;

  @override
  Future<void> loadRewardedAd() async {}

  @override
  Future<bool> showRewardedAdForAccess() async {
    return earnedReward;
  }

  @override
  void dispose() {}
}

class FakeDiscoveryAccessApi extends DiscoveryAccessApi {
  FakeDiscoveryAccessApi()
      : super(
          client: ApiClient(baseUrl: 'https://example.com'),
          tokenStore: FakeTokenStore(),
        );

  late Future<RewardedDiscoveryAccessGrant> Function({
    required int durationMinutes,
  }) claimFn;
  int? lastDurationMinutes;

  @override
  Future<RewardedDiscoveryAccessGrant> claimRewardedAdAccess({
    required int durationMinutes,
  }) {
    lastDurationMinutes = durationMinutes;
    return claimFn(durationMinutes: durationMinutes);
  }
}

UserProfile _buildProfile({
  required String id,
  required bool hasDiscoveryAccess,
  DateTime? temporaryDiscoveryAccessExpiresAt,
}) {
  final DateTime now = DateTime.now();
  return UserProfile(
    id: id,
    email: '$id@example.com',
    displayName: '@$id',
    mode: UserMode.public,
    appearInSearches: true,
    appearInDiscoveryGame: false,
    hasDiscoveryAccess: hasDiscoveryAccess,
    createdAt: now,
    updatedAt: now,
    temporaryDiscoveryAccessExpiresAt: temporaryDiscoveryAccessExpiresAt,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakePurchaseService purchaseService;
  late FakeAdService adService;
  late FakeDiscoveryAccessApi discoveryAccessApi;
  late DiscoveryAccessManager manager;

  setUp(() {
    purchaseService = FakePurchaseService();
    adService = FakeAdService();
    discoveryAccessApi = FakeDiscoveryAccessApi();
    manager = DiscoveryAccessManager(
      purchaseService: purchaseService,
      adService: adService,
      discoveryAccessApi: discoveryAccessApi,
    );
  });

  tearDown(() {
    manager.dispose();
  });

  test('watchAdForAccess grants temporary access after backend confirmation',
      () async {
    final DateTime expiresAt = DateTime.now().add(const Duration(minutes: 5));
    discoveryAccessApi.claimFn = ({required durationMinutes}) async {
      return RewardedDiscoveryAccessGrant(
        isGranted: true,
        temporaryAccessExpiresAt: expiresAt,
      );
    };

    final bool success = await manager.watchAdForAccess();

    expect(success, isTrue);
    expect(
      discoveryAccessApi.lastDurationMinutes,
      manager.tempAccessMinutes,
    );
    expect(manager.hasTemporaryAccess, isTrue);
    expect(manager.remainingTime, isNotNull);
    expect(manager.error, isNull);
  });

  test('watchAdForAccess fails closed when backend claim fails', () async {
    discoveryAccessApi.claimFn = ({required durationMinutes}) async {
      throw const ApiException(500, 'Server unavailable');
    };

    final bool success = await manager.watchAdForAccess();

    expect(success, isFalse);
    expect(manager.hasTemporaryAccess, isFalse);
    expect(
      manager.error,
      'The server could not activate discovery access right now. Please try again.',
    );
  });

  test('syncWithProfile restores temporary access from backend expiry', () {
    final DateTime expiresAt = DateTime.now().add(const Duration(minutes: 4));

    manager.syncWithProfile(
      _buildProfile(
        id: 'user-a',
        hasDiscoveryAccess: true,
        temporaryDiscoveryAccessExpiresAt: expiresAt,
      ),
    );

    expect(manager.hasTemporaryAccess, isTrue);
    expect(manager.remainingTime, isNotNull);
  });

  test(
      'syncWithProfile clears stale local access when backend says access is gone',
      () {
    manager.grantTemporaryAccess();

    manager.syncWithProfile(
      _buildProfile(
        id: 'user-a',
        hasDiscoveryAccess: false,
      ),
    );

    expect(manager.hasTemporaryAccess, isFalse);
    expect(manager.remainingTime, isNull);
  });
}
