import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_together/app/app.dart';
import 'package:pocket_together/features/auth/data/auth_repository.dart';
import 'package:pocket_together/features/auth/models/auth_user.dart';
import 'package:pocket_together/features/profile/data/profile_repository.dart';
import 'package:pocket_together/features/profile/models/user.dart';
import 'package:pocket_together/features/rooms/data/room_repository.dart';
import 'package:pocket_together/features/rooms/models/room.dart';

class TestAppHarness {
  TestAppHarness({bool signedIn = false})
    : authRepository = FakeAuthRepository(signedIn: signedIn),
      profileRepository = FakeProfileRepository(),
      roomRepository = FakeRoomRepository() {
    addTearDown(authRepository.dispose);
  }

  final FakeAuthRepository authRepository;
  final FakeProfileRepository profileRepository;
  final FakeRoomRepository roomRepository;

  PocketTogetherApp get app => PocketTogetherApp(
    authRepository: authRepository,
    profileRepository: profileRepository,
    roomRepository: roomRepository,
  );
}

Future<void> pumpTestApp(WidgetTester tester, TestAppHarness harness) async {
  await tester.pumpWidget(harness.app);
  await tester.pumpAndSettle();
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.signedIn = false});

  final StreamController<bool> _authState = StreamController<bool>.broadcast(
    sync: true,
  );
  bool signedIn;
  String? registeredName;
  String? resetEmail;
  bool googleSignInRequested = false;

  @override
  bool get isSignedIn => signedIn;

  @override
  AuthUser? get currentUser => signedIn
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
    signedIn = true;
    _authState.add(true);
  }

  @override
  Future<void> signInWithGoogle() async {
    googleSignInRequested = true;
    signedIn = true;
    _authState.add(true);
  }

  @override
  Future<void> register({
    required String displayName,
    required String email,
    required String password,
  }) async {
    registeredName = displayName;
    signedIn = true;
    _authState.add(true);
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    resetEmail = email;
  }

  @override
  Future<void> signOut() async {
    signedIn = false;
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

class FakeRoomRepository implements RoomRepository {
  final rooms = <Room>[];
  final requestedOwners = <String>[];
  String? requestedName;
  String? requestedCurrency;
  Object? failure;
  Object? loadFailure;
  Completer<Room>? pendingCreate;

  @override
  Future<List<Room>> getRooms(String ownerId) async {
    requestedOwners.add(ownerId);
    if (loadFailure != null) throw loadFailure!;
    return rooms.where((room) => room.ownerId == ownerId).toList();
  }

  @override
  Future<Room> createRoom({
    required String ownerId,
    required String name,
    required String currency,
    String? description,
  }) async {
    requestedName = name;
    requestedCurrency = currency;
    final pending = pendingCreate;
    if (pending != null) {
      final room = await pending.future;
      rooms.add(room);
      return room;
    }
    if (failure != null) throw failure!;

    final room = Room(
      id: 'generated-room-id',
      name: name,
      currency: currency,
      description: description,
      ownerId: ownerId,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
    rooms.add(room);
    return room;
  }
}
