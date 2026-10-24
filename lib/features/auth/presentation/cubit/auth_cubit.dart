import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/auth_repository.dart' as auth_data;
import '../../data/firebase_auth_repository.dart';
import '../../../profile/data/profile_repository.dart';
import '../../../profile/data/firebase_profile_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    FirebaseAuth? firebaseAuth,
    auth_data.AuthRepository? authRepository,
    ProfileRepository? profileRepository,
  }) : _firebaseAuth =
           firebaseAuth ??
           (authRepository == null ? FirebaseAuth.instance : null),
       _authRepository =
           authRepository ??
           FirebaseAuthRepository(firebaseAuth ?? FirebaseAuth.instance),
       _profileRepository =
           profileRepository ??
           FirebaseProfileRepository(FirebaseFirestore.instance),
       super(const AuthInitial()) {
    final auth = _firebaseAuth;
    if (auth != null) {
      _firebaseAuthSubscription = auth.authStateChanges().listen((_) {
        if (!_isPerformingAction) initialize(force: true);
      });
    } else {
      _authRepositorySubscription = _authRepository.authStateChanges.listen((
        _,
      ) {
        if (!_isPerformingAction) initialize(force: true);
      });
    }
  }

  final auth_data.AuthRepository _authRepository;
  final ProfileRepository _profileRepository;
  final FirebaseAuth? _firebaseAuth;
  StreamSubscription<User?>? _firebaseAuthSubscription;
  StreamSubscription<bool>? _authRepositorySubscription;
  Future<void>? _validationRequest;
  bool _isPerformingAction = false;

  Future<void> signIn({required String email, required String password}) =>
      _perform(
        () async {
          await _authRepository.signIn(email: email, password: password);
          await _ensureProfileExists();
        },
        'Unable to sign in. Try again.',
        validateSession: true,
      );

  Future<void> signInWithGoogle() => _perform(
    () async {
      await _authRepository.signInWithGoogle();
      await _ensureProfileExists();
    },
    'Unable to sign in with Google. Try again.',
    validateSession: true,
  );

  Future<void> register({
    required String displayName,
    required String email,
    required String password,
  }) => _perform(
    () async {
      // Register the user with the provided details.
      await _authRepository.register(
        displayName: displayName,
        email: email,
        password: password,
      );
      final user = _authRepository.currentUser;

      if (user == null) {
        throw const auth_data.AuthFailure(
          'Account created, but the user session is unavailable.',
        );
      }
      // Create a profile for the newly registered user.
      await _profileRepository.createProfile(
        uid: user.uid,
        displayName: displayName,
        email: email.trim(),
      );
    },
    'Unable to create your account. Try again.',
    validateSession: true,
  );

  Future<void> sendPasswordResetEmail({required String email}) => _perform(
    () => _authRepository.sendPasswordResetEmail(email: email),
    'Unable to send the reset link. Try again.',
  );

  Future<void> signOut() async {
    await _authRepository.signOut();
    emit(const Unauthenticated());
  }

  @override
  Future<void> close() async {
    await _firebaseAuthSubscription?.cancel();
    await _authRepositorySubscription?.cancel();
    return super.close();
  }

  Future<void> initialize({bool force = false}) async {
    if (!force && _validationRequest != null) return _validationRequest!;
    final request = _validateCurrentSession();
    _validationRequest = request;
    try {
      await request;
    } finally {
      if (identical(_validationRequest, request)) _validationRequest = null;
    }
  }

  Future<void> restoreSession() => initialize();

  Future<void> _validateCurrentSession() async {
    if (!_authRepository.isSignedIn) {
      emit(const Unauthenticated());
      return;
    }

    final currentUser = _authRepository.currentUser;
    if (currentUser == null) {
      emit(const AuthValidationError(message: 'Unable to read your account.'));
      return;
    }

    emit(const AuthValidatingProfile());
    try {
      final profile = await _profileRepository.getProfile(currentUser.uid);
      if (profile == null) {
        try {
          await _ensureProfileExists();
          final firebaseUser = _firebaseAuth?.currentUser;
          if (firebaseUser != null) {
            emit(Authenticated(firebaseUser));
          } else {
            emit(AuthenticatedSession(currentUser));
          }
        } catch (_) {
          emit(
            const AuthValidationError(
              message: 'Unable to restore your profile. Retry.',
            ),
          );
        }
        return;
      }

      final firebaseUser = _firebaseAuth?.currentUser;
      if (firebaseUser != null) {
        emit(Authenticated(firebaseUser));
      } else {
        emit(AuthenticatedSession(currentUser));
      }
    } on ProfileFailure catch (error) {
      emit(AuthValidationError(message: error.message));
    } catch (_) {
      emit(
        const AuthValidationError(
          message:
              'Unable to load your profile. Check your connection and retry.',
        ),
      );
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

  void reset() => emit(const AuthInitial());

  Future<void> _perform(
    Future<void> Function() action,
    String fallbackMessage, {
    bool validateSession = false,
  }) async {
    emit(const AuthLoading());
    _isPerformingAction = true;
    try {
      await action();
      _isPerformingAction = false;
      if (validateSession) {
        await initialize(force: true);
      } else {
        emit(const AuthState(isSuccess: true));
      }
    } on auth_data.AuthFailure catch (error) {
      emit(AuthFailure(errorMessage: error.message));
    } on ProfileFailure catch (error) {
      emit(AuthFailure(errorMessage: error.message));
    } catch (_) {
      emit(AuthFailure(errorMessage: fallbackMessage));
    } finally {
      _isPerformingAction = false;
    }
  }
}
