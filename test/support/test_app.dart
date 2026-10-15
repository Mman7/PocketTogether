import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_together/app/app.dart';
import 'package:pocket_together/features/auth/data/auth_repository.dart';
import 'package:pocket_together/features/auth/models/auth_user.dart';
import 'package:pocket_together/features/profile/data/profile_repository.dart';
import 'package:pocket_together/features/profile/models/user.dart';

class TestAppHarness {
  TestAppHarness({bool signedIn = false})
    : authRepository = FakeAuthRepository(signedIn: signedIn),
      profileRepository = FakeProfileRepository() {
    addTearDown(authRepository.dispose);
  }

  final FakeAuthRepository authRepository;
  final FakeProfileRepository profileRepository;

  PocketTogetherApp get app => PocketTogetherApp(
    authRepository: authRepository,
    profileRepository: profileRepository,
  );
}

Future<void> pumpTestApp(WidgetTester tester, TestAppHarness harness) async {
  await tester.pumpWidget(harness.app);
  await tester.pumpAndSettle();
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({bool signedIn = false}) : _signedIn = signedIn;

  final StreamController<bool> _authState = StreamController<bool>.broadcast(
    sync: true,
  );
  bool _signedIn;
  String? registeredName;
  String? resetEmail;
  bool googleSignInRequested = false;

  @override
  bool get isSignedIn => _signedIn;

  @override
  AuthUser? get currentUser => _signedIn
      ? const AuthUser(
          uid: 'test-user',
          displayName: 'Alex Morgan',
          email: 'alex@example.com',
        )
      : null;

  @override
  Stream<bool> get authStateChanges => _authState.stream;

  @override
  Future<void> signIn({required String email, required String password}) async {
    _signedIn = true;
    _authState.add(true);
  }

  @override
  Future<void> signInWithGoogle() async {
    googleSignInRequested = true;
    _signedIn = true;
    _authState.add(true);
  }

  @override
  Future<void> register({
    required String displayName,
    required String email,
    required String password,
  }) async {
    registeredName = displayName;
    _signedIn = true;
    _authState.add(true);
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    resetEmail = email;
  }

  @override
  Future<void> signOut() async {
    _signedIn = false;
    _authState.add(false);
  }

  Future<void> dispose() => _authState.close();
}

class FakeProfileRepository implements ProfileRepository {
  final profiles = <String, UserProfile>{};

  @override
  Future<void> createProfile({
    required String uid,
    required String displayName,
    required String email,
  }) async {
    profiles[uid] = UserProfile(
      uid: uid,
      displayName: displayName.trim(),
      email: email.trim(),
    );
  }

  @override
  Future<void> ensureProfileExists({
    required String uid,
    required String displayName,
    required String email,
  }) async {
    profiles.putIfAbsent(
      uid,
      () => UserProfile(
        uid: uid,
        displayName: displayName.trim(),
        email: email.trim(),
      ),
    );
  }

  @override
  Future<UserProfile?> getProfile(String uid) async => profiles[uid];

  @override
  Future<void> updateDisplayName({
    required String uid,
    required String displayName,
  }) async {
    final profile = profiles[uid];
    if (profile != null) {
      profiles[uid] = UserProfile(
        uid: uid,
        displayName: displayName.trim(),
        email: profile.email,
        createdAt: profile.createdAt,
      );
    }
  }
}
