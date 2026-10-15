import '../models/user.dart';

abstract interface class ProfileRepository {
  Future<void> createProfile({
    required String uid,
    required String displayName,
    required String email,
  });

  Future<void> ensureProfileExists({
    required String uid,
    required String displayName,
    required String email,
  });

  Future<UserProfile?> getProfile(String uid);

  Future<void> updateDisplayName({
    required String uid,
    required String displayName,
  });
}

class ProfileFailure implements Exception {
  const ProfileFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
