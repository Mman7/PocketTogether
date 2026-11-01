import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FcmService {
  FcmService({
    FirebaseMessaging? messaging,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseMessaging _messaging;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<String>? _tokenSubscription;
  Future<void> _operation = Future<void>.value();
  String? _currentUid;
  String? _currentToken;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final settings = await _messaging.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
        await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: true,
        );
      }
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      _authSubscription = _auth.authStateChanges().listen(_enqueueAuthChange);
      _tokenSubscription = _messaging.onTokenRefresh.listen(
        _enqueueTokenChange,
      );
      await _enqueue(() => _handleAuthChange(_auth.currentUser));
    } catch (error, stackTrace) {
      debugPrint('FCM initialization failed: $error\n$stackTrace');
    }
  }

  Future<void> dispose() async {
    await _authSubscription?.cancel();
    await _tokenSubscription?.cancel();
  }

  void _enqueueAuthChange(User? user) {
    unawaited(_enqueue(() => _handleAuthChange(user)));
  }

  void _enqueueTokenChange(String token) {
    unawaited(_enqueue(() => _handleTokenChange(token)));
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    _operation = _operation.then((_) => operation()).catchError((
      error,
      stackTrace,
    ) {
      debugPrint('FCM operation failed: $error\n$stackTrace');
    });
    return _operation;
  }

  Future<void> _handleAuthChange(User? user) async {
    if (_currentUid != null && _currentUid != user?.uid) {
      await _deleteToken(_currentUid!, _currentToken);
    }
    _currentUid = user?.uid;
    _currentToken = null;
    if (user == null) return;

    final token = await _messaging.getToken();
    if (token != null) await _saveToken(user.uid, token);
  }

  Future<void> _handleTokenChange(String token) async {
    final uid = _currentUid ?? _auth.currentUser?.uid;
    if (uid == null) return;
    await _saveToken(uid, token);
  }

  Future<void> _saveToken(String uid, String token) async {
    _currentUid = uid;
    _currentToken = token;
    final tokens = _firestore
        .collection('users')
        .doc(uid)
        .collection('fcmTokens');
    final existing = await tokens
        .where('token', isEqualTo: token)
        .limit(1)
        .get();
    final reference = existing.docs.isEmpty
        ? tokens.doc()
        : existing.docs.first.reference;
    await reference.set({
      'token': token,
      'platform': _platform,
      'updatedAt': FieldValue.serverTimestamp(),
      if (existing.docs.isEmpty) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _deleteToken(String uid, String? token) async {
    if (token == null) return;
    final tokens = _firestore
        .collection('users')
        .doc(uid)
        .collection('fcmTokens');
    final matches = await tokens.where('token', isEqualTo: token).get();
    for (final document in matches.docs) {
      await document.reference.delete();
    }
  }

  String get _platform {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name;
  }
}
