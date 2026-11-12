import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/auth_user.dart';
import 'auth_repository.dart';

/// Firebase Authentication adapter used by the auth Cubit.
///
/// This class translates provider-specific failures into stable user-facing
/// [AuthFailure] messages; it does not decide whether a Firestore profile is
/// valid or whether a room operation is authorized.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._firebaseAuth);

  final FirebaseAuth _firebaseAuth;

  @override
  bool get isSignedIn => _firebaseAuth.currentUser != null;

  @override
  AuthUser? get currentUser {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    return AuthUser(
      uid: user.uid,
      displayName: user.displayName,
      email: user.email,
      photoUrl: user.photoURL,
    );
  }

  @override
  Stream<bool> get authStateChanges =>
      _firebaseAuth.authStateChanges().map((user) => user != null).distinct();

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_messageFor(error));
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuthentication = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuthentication.accessToken,
        idToken: googleAuthentication.idToken,
      );
      await _firebaseAuth.signInWithCredential(credential);
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_messageFor(error));
    }
  }

  @override
  Future<void> register({
    required String displayName,
    required String email,
    required String password,
  }) async {
    try {
      // Create a new user with the provided email and password.
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user!;
      // Update the display name for the newly created user.
      await user.updateDisplayName(displayName.trim());
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_messageFor(error));
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error) {
      // Do not reveal whether an email is registered through this endpoint.
      if (error.code == 'user-not-found') return;
      throw AuthFailure(_messageFor(error));
    }
  }

  @override
  Future<void> signOut() => _firebaseAuth.signOut();

  String _messageFor(FirebaseAuthException error) => switch (error.code) {
    'invalid-email' => 'Enter a valid email address.',
    'user-disabled' => 'This account has been disabled.',
    'user-not-found' ||
    'wrong-password' ||
    'invalid-credential' => 'Email or password is incorrect.',
    'email-already-in-use' => 'An account already exists for this email.',
    'weak-password' => 'Choose a stronger password and try again.',
    'too-many-requests' => 'Too many attempts. Try again in a few minutes.',
    'network-request-failed' => 'Check your connection and try again.',
    'operation-not-allowed' => 'Google sign-in is not enabled for this app.',
    _ => 'Something went wrong. Please try again.',
  };
}
