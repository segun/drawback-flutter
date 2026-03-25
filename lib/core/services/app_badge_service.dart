import 'dart:convert';
import 'dart:io';

import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppBadgeService {
  AppBadgeService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _seenIdsKey = 'app_badge_seen_request_ids';

  final FlutterSecureStorage _storage;
  bool? _isSupported;
  Set<String>? _seenIds;

  /// Computes and sets the badge count.
  ///
  /// Only incoming chat requests whose IDs are absent from the persisted
  /// seen-set count as unread. Waiting-peer room notifications are always
  /// treated as unread (they are real-time and ephemeral).
  Future<void> syncBadge({
    required List<String> incomingRequestIds,
    required int waitingPeersCount,
  }) async {
    final Set<String> seen = await _loadSeenIds();
    final int unread =
        incomingRequestIds.where((String id) => !seen.contains(id)).length;
    await _setBadge(unread + waitingPeersCount);
  }

  /// Marks the given request IDs as seen so they no longer contribute to
  /// the badge count.  Call this whenever the user is viewing the requests
  /// list (e.g. navigated to /home).
  Future<void> markSeen(Iterable<String> requestIds) async {
    final Set<String> seen = await _loadSeenIds();
    seen.addAll(requestIds);
    await _saveSeenIds(seen);
  }

  /// Clears the persisted seen-set.  Call on logout so a different user
  /// on the same device starts with a clean slate.
  Future<void> clearSeen() async {
    _seenIds = <String>{};
    await _storage.delete(key: _seenIdsKey);
  }

  /// Resets the badge to 0 without touching the seen-set.
  Future<void> clear() async {
    await _setBadge(0);
  }

  Future<Set<String>> _loadSeenIds() async {
    if (_seenIds != null) {
      return _seenIds!;
    }
    final String? raw = await _storage.read(key: _seenIdsKey);
    if (raw == null || raw.isEmpty) {
      _seenIds = <String>{};
      return _seenIds!;
    }
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      _seenIds = list.whereType<String>().toSet();
    } catch (_) {
      _seenIds = <String>{};
    }
    return _seenIds!;
  }

  Future<void> _saveSeenIds(Set<String> ids) async {
    _seenIds = ids;
    await _storage.write(key: _seenIdsKey, value: jsonEncode(ids.toList()));
  }

  Future<void> _setBadge(int count) async {
    final bool permissionGranted = await _ensureBadgePermission();
    if (!permissionGranted) {
      return;
    }
    final bool supported = await _isBadgeSupported();
    if (!supported) {
      return;
    }
    await AppBadgePlus.updateBadge(count <= 0 ? 0 : count);
  }

  Future<bool> _isBadgeSupported() async {
    final bool? cached = _isSupported;
    if (cached != null) {
      return cached;
    }
    final bool supported = await AppBadgePlus.isSupported();
    _isSupported = supported;
    return supported;
  }

  Future<bool> _ensureBadgePermission() async {
    if (kIsWeb || !Platform.isIOS) {
      return true;
    }

    final FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.getNotificationSettings();

    final bool authorized =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;

    if (authorized) {
      return true;
    }

    settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }
}
