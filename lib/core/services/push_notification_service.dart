import 'dart:async';

import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Intentionally empty: platform notifications are delivered by FCM when app is backgrounded.
}

class PushNotificationService {
  PushNotificationService({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _localNotifications =
            localNotifications ?? FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;

  bool _initialized = false;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedAppSubscription;
  final StreamController<String> _openedRequestController =
      StreamController<String>.broadcast();
  final StreamController<String> _openedGroupAddedController =
      StreamController<String>.broadcast();
  final StreamController<String> _openedGroupInviteController =
      StreamController<String>.broadcast();
  final Map<String, DateTime> _recentRequestSignals = <String, DateTime>{};

  static const Duration _requestSignalTtl = Duration(seconds: 15);

  static const AndroidNotificationChannel _defaultChannel =
      AndroidNotificationChannel(
    'request_alerts',
    'Request Alerts',
    description: 'Alerts for incoming draw requests.',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    await _requestPermissions();
    await _configureForegroundBehavior();
    await _initializeLocalNotifications();

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    _foregroundSubscription = FirebaseMessaging.onMessage.listen((message) {
      debugPrint('Received foreground message: ${message.messageId}');
      
      if (Platform.isAndroid) {
        // Android needs us to manually show the notification
        unawaited(_showForegroundNotification(message));
      }
    });

    _openedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      (message) {
        debugPrint('Received opened app message: ${message.messageId}');
        _handleOpenedMessage(message);
      },
    );

    final RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('Received initial message: ${initialMessage.messageId}');
      _handleOpenedMessage(initialMessage);
    }

    _initialized = true;
  }

  Future<String?> getToken() {
    return _messaging.getToken();
  }

  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;
  Stream<String> get onRequestNotificationOpened =>
      _openedRequestController.stream;
  Stream<String> get onGroupAddedNotificationOpened =>
      _openedGroupAddedController.stream;
  Stream<String> get onGroupInviteNotificationOpened =>
      _openedGroupInviteController.stream;

  void markRequestAsHandled(String requestId) {
    if (requestId.isEmpty) {
      return;
    }
    _recordRequestSignal(requestId);
  }

  Future<void> _requestPermissions() {
    return _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );
  }

  Future<void> _configureForegroundBehavior() {
    return _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _initializeLocalNotifications() async {
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(initializationSettings);

    final androidImplementation =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.createNotificationChannel(_defaultChannel);
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) {
      return;
    }

    final String requestId = _extractRequestId(message.data);
    if (requestId.isNotEmpty && _hasRecentRequestSignal(requestId)) {
      return;
    }

    if (requestId.isNotEmpty) {
      _recordRequestSignal(requestId);
    }

    const androidDetails = AndroidNotificationDetails(
      'request_alerts',
      'Request Alerts',
      channelDescription: 'Alerts for incoming draw requests.',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: requestId.isEmpty ? null : requestId,
    );
  }

  void _handleOpenedMessage(RemoteMessage message) {
    final String type = message.data['type'] as String? ?? '';

    if (type == 'group_member_added') {
      final String groupId = message.data['groupId'] as String? ?? '';
      if (groupId.isNotEmpty) {
        _openedGroupAddedController.add(groupId);
      }
      return;
    }

    if (type == 'group_invite') {
      final String invitationId = message.data['invitationId'] as String? ?? '';
      if (invitationId.isNotEmpty) {
        _openedGroupInviteController.add(invitationId);
      }
      return;
    }

    final String requestId = _extractRequestId(message.data);
    if (requestId.isEmpty) {
      return;
    }

    _recordRequestSignal(requestId);
    _openedRequestController.add(requestId);
  }

  String _extractRequestId(Map<String, dynamic> data) {
    final dynamic requestId = data['requestId'];
    if (requestId is String) {
      return requestId;
    }
    return '';
  }

  bool _hasRecentRequestSignal(String requestId) {
    _pruneStaleSignals();
    final DateTime? seenAt = _recentRequestSignals[requestId];
    if (seenAt == null) {
      return false;
    }
    return DateTime.now().difference(seenAt) <= _requestSignalTtl;
  }

  void _recordRequestSignal(String requestId) {
    _pruneStaleSignals();
    _recentRequestSignals[requestId] = DateTime.now();
  }

  void _pruneStaleSignals() {
    final DateTime now = DateTime.now();
    _recentRequestSignals.removeWhere(
      (_, DateTime seenAt) => now.difference(seenAt) > _requestSignalTtl,
    );
  }

  Future<void> dispose() async {
    await _foregroundSubscription?.cancel();
    await _openedAppSubscription?.cancel();
    await _openedRequestController.close();
    await _openedGroupAddedController.close();
    await _openedGroupInviteController.close();
  }
}
