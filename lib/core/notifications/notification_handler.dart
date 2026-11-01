import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';
import 'notification_payload.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error) {
    debugPrint('Unable to initialize Firebase for background message: $error');
  }
}

class NotificationHandler {
  NotificationHandler({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  Future<void>? _initialMessageRequest;
  Future<void> Function(RemoteMessage message)? _onForegroundMessage;
  Future<void> Function(NotificationPayload payload)? _onNotificationTap;
  final Set<String> _handledMessageIds = <String>{};
  bool _initialized = false;

  Future<void> initialize({
    Future<void> Function(RemoteMessage message)? onForegroundMessage,
    required Future<void> Function(NotificationPayload payload)
    onNotificationTap,
  }) async {
    _onForegroundMessage = onForegroundMessage;
    _onNotificationTap = onNotificationTap;
    if (_initialized) return;
    _initialized = true;

    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      _handleForeground,
    );
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      _handleTap,
    );
    _initialMessageRequest = _loadInitialMessage();
    await _initialMessageRequest;
  }

  Future<void> dispose() async {
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
  }

  Future<void> _loadInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    if (message != null) await _handleTap(message);
  }

  Future<void> _handleForeground(RemoteMessage message) async {
    final payload = NotificationPayload.tryParse(message.data);
    if (payload == null) return;
    await _onForegroundMessage?.call(message);
  }

  Future<void> _handleTap(RemoteMessage message) async {
    final messageId = message.messageId;
    if (messageId != null && !_handledMessageIds.add(messageId)) return;
    final payload = NotificationPayload.tryParse(message.data);
    if (payload == null) return;
    await _onNotificationTap?.call(payload);
  }
}
