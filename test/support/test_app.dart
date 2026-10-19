import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_together/app/app.dart';
import 'package:pocket_together/features/auth/data/auth_repository.dart';
import 'package:pocket_together/features/auth/models/auth_user.dart';
import 'package:pocket_together/features/expenses/data/expense_repository.dart';
import 'package:pocket_together/features/expenses/models/expense.dart';
import 'package:pocket_together/features/profile/data/profile_repository.dart';
import 'package:pocket_together/features/profile/models/user.dart';
import 'package:pocket_together/features/rooms/data/room_repository.dart';
import 'package:pocket_together/features/rooms/models/room.dart';
import 'package:pocket_together/features/rooms/models/room_member.dart';
import 'package:pocket_together/features/rooms/models/room_invite.dart';
import 'package:pocket_together/features/rooms/models/room_operation_result.dart';
import 'package:pocket_together/features/rooms/models/room_role.dart';

class TestAppHarness {
  TestAppHarness({bool signedIn = false})
    : authRepository = FakeAuthRepository(signedIn: signedIn),
      profileRepository = FakeProfileRepository(),
      roomRepository = FakeRoomRepository(),
      expenseRepository = FakeExpenseRepository() {
    addTearDown(authRepository.dispose);
  }

  final FakeAuthRepository authRepository;
  final FakeProfileRepository profileRepository;
  final FakeRoomRepository roomRepository;
  final FakeExpenseRepository expenseRepository;

  PocketTogetherApp get app => PocketTogetherApp(
    authRepository: authRepository,
    profileRepository: profileRepository,
    roomRepository: roomRepository,
    expenseRepository: expenseRepository,
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
  final roomMembers = <String, List<RoomMember>>{};
  final requestedOwners = <String>[];
  String? requestedName;
  String? requestedCurrency;
  String? requestedOwnerDisplayName;
  String? requestedOwnerEmail;
  Object? failure;
  Object? loadFailure;
  Completer<Room>? pendingCreate;
  final _roomsController = StreamController<List<Room>>.broadcast();
  String? lastInviteCode;

  void dispose() => _roomsController.close();

  @override
  Future<List<RoomMember>> getRoomMembers(String roomId) async =>
      roomMembers[roomId] ?? const [];

  @override
  Stream<List<Room>> watchMyRooms(String userId) async* {
    requestedOwners.add(userId);
    yield rooms
        .where(
          (room) => room.memberIds.contains(userId) || room.ownerId == userId,
        )
        .toList();
    yield* _roomsController.stream;
  }

  @override
  Future<RoomInvite> createInvite({required String roomId}) async {
    lastInviteCode = 'ABCD2345';
    return RoomInvite(
      inviteCode: lastInviteCode!,
      roomId: roomId,
      createdBy: 'test-user',
      createdAt: DateTime.utc(2026),
      expiresAt: DateTime.utc(2026, 1, 8),
      isActive: true,
    );
  }

  @override
  Future<void> removeMember({
    required String roomId,
    required String memberId,
  }) async {
    roomMembers[roomId]?.removeWhere((member) => member.userId == memberId);
  }

  @override
  Future<void> deleteRoom({required String roomId}) async {
    rooms.removeWhere((room) => room.id == roomId);
    roomMembers.remove(roomId);
    _roomsController.add(List.of(rooms));
  }

  @override
  Future<RoomJoinResult> joinRoom({required String inviteCode}) async {
    if (failure != null) throw failure!;
    if (inviteCode == 'BAD123' || inviteCode == 'EXPIRED') {
      throw const RoomFailure(
        'That invite code is invalid. Check it and try again.',
      );
    }
    final room = rooms.first;
    return RoomJoinResult(room: room, alreadyMember: false);
  }

  @override
  Future<RoomCreationResult> createRoom({
    required String name,
    required String currency,
  }) async {
    requestedName = name;
    requestedCurrency = currency;
    if (failure != null) throw failure!;
    final pending = pendingCreate;
    final room = pending == null
        ? Room(
            id: 'generated-room-id',
            name: name,
            currency: currency,
            ownerId: 'test-user',
            memberIds: const ['test-user'],
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
          )
        : await pending.future;
    rooms.add(room);
    _addOwnerMember(room, 'test-user', 'Alex Morgan', 'alex@example.com');
    _roomsController.add(List.of(rooms));
    return RoomCreationResult(
      room: room,
      invite: RoomInvite(
        inviteCode: 'ABCD2345',
        roomId: room.id,
        createdBy: 'test-user',
        createdAt: DateTime.utc(2026),
        expiresAt: DateTime.utc(2026, 1, 8),
        isActive: true,
      ),
    );
  }

  /* Legacy values retained for existing assertions. */
  Future<List<Room>> getRooms(String ownerId) async {
    requestedOwners.add(ownerId);
    if (loadFailure != null) throw loadFailure!;
    return rooms.where((room) => room.ownerId == ownerId).toList();
  }

  void _addOwnerMember(
    Room room,
    String ownerId,
    String displayName,
    String? email,
  ) {
    final members = roomMembers.putIfAbsent(room.id, () => []);
    members.removeWhere((member) => member.userId == ownerId);
    members.add(
      RoomMember(
        userId: ownerId,
        displayName: displayName,
        email: email,
        role: RoomRole.owner,
        joinedAt: DateTime.utc(2026),
      ),
    );
  }
}

class FakeExpenseRepository implements ExpenseRepository {
  final expensesByRoom = <String, List<Expense>>{};

  @override
  Future<List<Expense>> getExpenses(String roomId) async =>
      List.of(expensesByRoom[roomId] ?? const []);

  @override
  Future<Expense> createExpense({
    required String roomId,
    required Expense expense,
  }) async {
    final expenses = expensesByRoom.putIfAbsent(roomId, () => []);
    final created = expense.copyWith(id: 'expense-${expenses.length + 1}');
    expenses.add(created);
    return created;
  }

  @override
  Future<Expense> updateExpense({
    required String roomId,
    required Expense expense,
  }) async {
    final expenses = expensesByRoom.putIfAbsent(roomId, () => []);
    final index = expenses.indexWhere((item) => item.id == expense.id);
    if (index < 0) throw const ExpenseFailure('Expense not found.');
    expenses[index] = expense;
    return expense;
  }

  @override
  Future<void> deleteExpense({
    required String roomId,
    required String expenseId,
  }) async {
    expensesByRoom[roomId]?.removeWhere((item) => item.id == expenseId);
  }
}
