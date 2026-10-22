import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/auth_repository.dart';
import '../../../profile/data/profile_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._authRepository, this._profileRepository)
    : super(const AuthState());

  final AuthRepository _authRepository;
  final ProfileRepository _profileRepository;

  Future<void> signIn({required String email, required String password}) =>
      _perform(() async {
        await _authRepository.signIn(email: email, password: password);
        await _ensureProfileExists();
      }, 'Unable to sign in. Try again.');

  Future<void> signInWithGoogle() => _perform(() async {
    await _authRepository.signInWithGoogle();
    await _ensureProfileExists();
  }, 'Unable to sign in with Google. Try again.');

  Future<void> register({
    required String displayName,
    required String email,
    required String password,
  }) => _perform(() async {
    // Register the user with the provided details.
    await _authRepository.register(
      displayName: displayName,
      email: email,
      password: password,
    );
    final user = _authRepository.currentUser;

    if (user == null) {
      throw const AuthFailure(
        'Account created, but the user session is unavailable.',
      );
    }
    // Create a profile for the newly registered user.
    await _profileRepository.createProfile(
      uid: user.uid,
      displayName: displayName,
      email: email.trim(),
    );
  }, 'Unable to create your account. Try again.');

  Future<void> sendPasswordResetEmail({required String email}) => _perform(
    () => _authRepository.sendPasswordResetEmail(email: email),
    'Unable to send the reset link. Try again.',
  );

  Future<void> signOut() => _authRepository.signOut();

  Future<void> restoreSession() async {
    if (!_authRepository.isSignedIn) return;
    try {
      await _ensureProfileExists();
    } on ProfileFailure {
      // Keep the Firebase session; the next data request can show the retry state.
    }
  }

  Future<void> _ensureProfileExists() async {
    final user = _authRepository.currentUser;
    if (user == null) return;

    final authName = user.displayName?.trim();
    final emailName = user.email?.split('@').first.trim();
    await _profileRepository.ensureProfileExists(
      uid: user.uid,
      displayName: authName?.isNotEmpty == true
          ? authName!
          : emailName?.isNotEmpty == true
          ? emailName!
          : 'PocketTogether member',
      email: user.email ?? '',
    );
  }

  void reset() => emit(const AuthState());

  Future<void> _perform(
    Future<void> Function() action,
    String fallbackMessage,
  ) async {
    emit(const AuthState(status: AuthStatus.loading));
    try {
      await action();
      emit(const AuthState(status: AuthStatus.success));
    } on AuthFailure catch (error) {
      emit(AuthState(status: AuthStatus.failure, errorMessage: error.message));
    } on ProfileFailure catch (error) {
      emit(AuthState(status: AuthStatus.failure, errorMessage: error.message));
    } catch (_) {
      emit(
        AuthState(status: AuthStatus.failure, errorMessage: fallbackMessage),
      );
    }
  }
}
