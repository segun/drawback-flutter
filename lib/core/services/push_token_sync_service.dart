import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/data/device_helper.dart';
import 'push_notification_service.dart';
import 'push_token_registration_api.dart';

class PushTokenSyncService {
  PushTokenSyncService({
    required PushNotificationService notificationService,
    required PushTokenRegistrationApi registrationApi,
    FlutterSecureStorage? secureStorage,
  })  : _notificationService = notificationService,
        _registrationApi = registrationApi,
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final PushNotificationService _notificationService;
  final PushTokenRegistrationApi _registrationApi;
  final FlutterSecureStorage _secureStorage;

  StreamSubscription<String>? _refreshSubscription;

  static const String _lastUploadedTokenKey = 'drawkcab-last-fcm-token';

  Future<void> syncTokenForCurrentSession() async {
    try {
      await _notificationService.initialize();
      _bindRefreshListenerIfNeeded();

      final token = await _notificationService.getToken();
      if (token == null || token.isEmpty) {
        return;
      }

      final lastUploadedToken = await _secureStorage.read(
        key: _lastUploadedTokenKey,
      );
      if (lastUploadedToken == token) {
        return;
      }

      final deviceId = await DeviceHelper.getDeviceId();
      final platform = DeviceHelper.getPlatformName();

      await _registrationApi.registerFcmToken(
        fcmToken: token,
        platform: platform,
        deviceId: deviceId,
      );

      await _secureStorage.write(key: _lastUploadedTokenKey, value: token);
    } catch (error) {
      debugPrint('Push token sync failed: $error');
    }
  }

  Future<void> deactivateCurrentTokenBinding() async {
    try {
      final token = await _notificationService.getToken();
      if (token == null || token.isEmpty) {
        await _clearLastUploadedToken();
        return;
      }

      await _registrationApi.deactivateFcmToken(token);
      await _clearLastUploadedToken();
    } catch (error) {
      debugPrint('Push token deactivation failed: $error');
    }
  }

  Future<void> dispose() async {
    await _refreshSubscription?.cancel();
    await _notificationService.dispose();
  }

  void _bindRefreshListenerIfNeeded() {
    if (_refreshSubscription != null) {
      return;
    }

    _refreshSubscription = _notificationService.onTokenRefresh.listen((token) {
      unawaited(_syncRefreshedToken(token));
    });
  }

  Future<void> _syncRefreshedToken(String token) async {
    if (token.isEmpty) {
      return;
    }

    try {
      final deviceId = await DeviceHelper.getDeviceId();
      final platform = DeviceHelper.getPlatformName();

      await _registrationApi.registerFcmToken(
        fcmToken: token,
        platform: platform,
        deviceId: deviceId,
      );

      await _secureStorage.write(key: _lastUploadedTokenKey, value: token);
    } catch (error) {
      debugPrint('Refreshed push token sync failed: $error');
    }
  }

  Future<void> _clearLastUploadedToken() {
    return _secureStorage.delete(key: _lastUploadedTokenKey);
  }
}
