import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/user.dart';
import 'profile_repository.dart';

/// Firestore adapter for `users/{uid}` profile documents.
///
/// Every request is bounded by [_requestTimeout] and Firestore errors are
/// translated into [ProfileFailure] so callers never hang on an unreachable
/// backend.
class FirebaseProfileRepository implements ProfileRepository {
  FirebaseProfileRepository(this._firestore);

  static const _requestTimeout = Duration(seconds: 15);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  @override
  Future<void> createProfile({
    required String uid,
    required String displayName,
    required String email,
  }) => _run(
    'create profile',
    () => _users.doc(uid).set(_newProfileData(displayName, email)),
  );

  @override
  Future<void> ensureProfileExists({
    required String uid,
    required String displayName,
    required String email,
  }) => _run('ensure profile', () async {
    final document = _users.doc(uid);
    // Server read: cached data must not prove the profile exists during recovery.
    final snapshot = await document.get(GetOptions(source: Source.server));
    if (!snapshot.exists) {
      await document.set(_newProfileData(displayName, email));
      return;
    }

    final trimmedEmail = email.trim();
    if (trimmedEmail.isNotEmpty && snapshot.data()?['email'] != trimmedEmail) {
      await document.set({'email': trimmedEmail}, SetOptions(merge: true));
    }
  });

  @override
  Future<UserProfile?> getProfile(String uid) => _run('load profile', () async {
    final snapshot = await _users.doc(uid).get();
    final data = snapshot.data();
    if (data == null) return null;

    return UserProfile(
      uid: uid,
      displayName: _string(data['displayName']) ?? '',
      email: _string(data['email']),
      createdAt: _dateValue(data['createdAt']),
      updatedAt: _dateValue(data['updatedAt']),
    );
  });

  @override
  Future<void> updateDisplayName({
    required String uid,
    required String displayName,
  }) => _run(
    'update display name',
    () => _users.doc(uid).update({'displayName': displayName.trim()}),
  );

  Future<T> _run<T>(String operation, Future<T> Function() request) async {
    try {
      return await request().timeout(_requestTimeout);
    } on TimeoutException {
      debugPrint('[Profile] $operation timed out.');
      throw const ProfileFailure(
        'Profile request timed out. Check your connection and try again.',
      );
    } on FirebaseException catch (error) {
      debugPrint('[Profile] $operation failed: code=${error.code}');
      throw ProfileFailure(_messageFor(error));
    }
  }

  String _messageFor(FirebaseException error) => switch (error.code) {
    'permission-denied' => 'You do not have access to this profile.',
    'unavailable' ||
    'deadline-exceeded' => 'Check your connection and try again.',
    _ => 'Unable to save or load your profile. Try again.',
  };

  Map<String, Object?> _newProfileData(String displayName, String email) => {
    'displayName': displayName.trim(),
    'email': email.trim(),
    'createdAt': FieldValue.serverTimestamp(),
  };

  String? _string(Object? value) => value is String ? value : null;
}

DateTime? _dateValue(Object? value) {
  if (value is Timestamp) return value.toDate().toUtc();
  if (value is DateTime) return value.toUtc();
  if (value is String) return DateTime.tryParse(value)?.toUtc();
  return null;
}
