import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user.dart';
import 'profile_repository.dart';

class FirebaseProfileRepository implements ProfileRepository {
  FirebaseProfileRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  @override
  Future<void> createProfile({
    required String uid,
    required String displayName,
    required String email,
  }) async {
    try {
      await _users.doc(uid).set(_newProfileData(displayName, email));
    } on FirebaseException {
      throw const ProfileFailure('Unable to save your profile. Try again.');
    }
  }

  @override
  Future<void> ensureProfileExists({
    required String uid,
    required String displayName,
    required String email,
  }) async {
    try {
      final document = _users.doc(uid);
      final snapshot = await document.get(GetOptions(source: Source.server));
      if (!snapshot.exists) {
        return;
      } else if (snapshot.data()?['email'] != email.trim()) {
        await document.set({'email': email.trim()}, SetOptions(merge: true));
      }
    } on FirebaseException {
      throw const ProfileFailure('Unable to load your profile. Try again.');
    }
  }

  @override
  Future<UserProfile?> getProfile(String uid) async {
    try {
      final snapshot = await _users.doc(uid).get();
      final data = snapshot.data();
      if (data == null) return null;

      final createdAt = data['createdAt'];
      return UserProfile(
        uid: uid,
        displayName: data['displayName'] as String? ?? '',
        email: data['email'] as String?,
        createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
      );
    } on FirebaseException {
      throw const ProfileFailure('Unable to load your profile. Try again.');
    }
  }

  @override
  Future<void> updateDisplayName({
    required String uid,
    required String displayName,
  }) async {
    try {
      await _users.doc(uid).update({'displayName': displayName.trim()});
    } on FirebaseException {
      throw const ProfileFailure('Unable to update your profile. Try again.');
    }
  }

  Map<String, Object?> _newProfileData(String displayName, String email) => {
    'displayName': displayName.trim(),
    'email': email.trim(),
    'createdAt': FieldValue.serverTimestamp(),
  };
}
