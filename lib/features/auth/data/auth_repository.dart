import '../models/auth_user.dart';

abstract interface class AuthRepository {
  bool get isSignedIn;

  AuthUser? get currentUser;

  Stream<bool> get authStateChanges;

  Future<void> signIn({required String email, required String password});

  Future<void> signInWithGoogle();

  Future<void> register({
    required String displayName,
    required String email,
    required String password,
  });

  Future<void> sendPasswordResetEmail({required String email});

  Future<void> signOut();
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
