import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/room.dart';
import '../models/room_invite.dart';
import '../models/room_member.dart';
import '../models/room_operation_result.dart';
import 'room_repository.dart';

class FirebaseRoomRepository implements RoomRepository {
  FirebaseRoomRepository(this._firestore, {FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> get _rooms =>
      _firestore.collection('rooms');

  @override
  Stream<List<Room>> watchMyRooms(String userId) {
    return _rooms
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          final rooms = snapshot.docs
              .map((document) => Room.fromMap(document.id, document.data()))
              .toList();
          rooms.sort((first, second) {
            final firstCreatedAt = first.createdAt;
            final secondCreatedAt = second.createdAt;
            if (firstCreatedAt == null) return 1;
            if (secondCreatedAt == null) return -1;
            return secondCreatedAt.compareTo(firstCreatedAt);
          });
          return rooms;
        })
        .transform(
          StreamTransformer.fromHandlers(
            handleError: (error, stackTrace, sink) {
              sink.addError(
                RoomFailure(
                  error is FirebaseException
                      ? 'Unable to load rooms. Please try again.'
                      : 'Unable to load rooms.',
                ),
                stackTrace,
              );
            },
          ),
        );
  }

  @override
  Future<List<RoomMember>> getRoomMembers(String roomId) async {
    try {
      final result = await _functions
          .httpsCallable('getRoomMembers')
          .call<List<dynamic>>({'roomId': roomId});
      final members = result.data
          .whereType<Map>()
          .map(
            (data) => RoomMember.fromMap(
              data['userId'] as String,
              Map<String, dynamic>.from(data),
            ),
          )
          .toList();
      members.sort((first, second) {
        if (first.isOwner == second.isOwner) {
          return first.displayName.compareTo(second.displayName);
        }
        return first.isOwner ? -1 : 1;
      });
      return members;
    } on FirebaseFunctionsException catch (error) {
      throw _roomFailureFromFunction(error);
    } on FirebaseException {
      throw const RoomFailure('Unable to load room members. Please try again.');
    }
  }

  @override
  Future<RoomInvite> createInvite({required String roomId}) async {
    try {
      final result = await _functions
          .httpsCallable('createRoomInvite')
          .call<Map<String, dynamic>>({'roomId': roomId});
      final data = result.data;
      return RoomInvite(
        inviteCode: _requiredString(data, 'inviteCode'),
        roomId: roomId,
        createdBy: '',
        createdAt: DateTime.now().toUtc(),
        expiresAt: DateTime.parse(_requiredString(data, 'expiresAt')),
        isActive: true,
      );
    } on FirebaseFunctionsException catch (error) {
      if (error.code == 'not-found') {
        throw const RoomFailure(
          'The createRoom Function is unavailable. Restart the Firebase Functions emulator.',
          code: 'function-not-found',
        );
      }
      throw _roomFailureFromFunction(error);
    } on FirebaseException {
      throw const RoomFailure('Unable to create an invite. Please try again.');
    } on FormatException {
      throw const RoomFailure('The server returned an invalid invite.');
    }
  }

  @override
  Future<void> removeMember({
    required String roomId,
    required String memberId,
  }) async {
    try {
      await _functions.httpsCallable('removeRoomMember').call<void>({
        'roomId': roomId,
        'memberId': memberId,
      });
    } on FirebaseFunctionsException catch (error) {
      throw _roomFailureFromFunction(error);
    } on FirebaseException {
      throw const RoomFailure(
        'Unable to remove that member. Please try again.',
      );
    }
  }

  @override
  Future<void> deleteRoom({required String roomId}) async {
    try {
      await _functions.httpsCallable('deleteRoom').call<void>({
        'roomId': roomId,
      });
    } on FirebaseFunctionsException catch (error) {
      throw _roomFailureFromFunction(error);
    } on FirebaseException {
      throw const RoomFailure('Unable to delete the room. Please try again.');
    }
  }

  @override
  Future<RoomCreationResult> createRoom({
    required String name,
    required String currency,
  }) async {
    try {
      final result = await _functions
          .httpsCallable('createRoom')
          .call<Map<String, dynamic>>({
            'name': name.trim(),
            'currency': currency,
          });
      final data = result.data;
      final roomId = _requiredString(data, 'roomId');
      final inviteCode = _requiredString(data, 'inviteCode');
      final expiresAt = DateTime.parse(_requiredString(data, 'expiresAt'));
      final roomSnapshot = await _rooms.doc(roomId).get();
      final roomData = roomSnapshot.data();
      if (roomData == null) {
        throw const RoomFailure('The created room could not be loaded.');
      }
      final room = Room.fromMap(roomSnapshot.id, roomData);
      return RoomCreationResult(
        room: room,
        invite: RoomInvite(
          inviteCode: inviteCode,
          roomId: roomId,
          createdBy: room.createdBy ?? '',
          createdAt: room.createdAt ?? DateTime.now().toUtc(),
          expiresAt: expiresAt,
          isActive: true,
        ),
      );
    } on FirebaseFunctionsException catch (error) {
      throw _roomFailureFromFunction(error);
    } on FirebaseException {
      throw const RoomFailure('Unable to create the room. Please try again.');
    } on FormatException {
      throw const RoomFailure('The server returned invalid room details.');
    }
  }

  @override
  Future<RoomJoinResult> joinRoom({required String inviteCode}) async {
    try {
      final result = await _functions
          .httpsCallable('joinRoom')
          .call<Map<String, dynamic>>({
            'inviteCode': inviteCode.trim().toUpperCase(),
          });
      final data = result.data;
      final roomId = _requiredString(data, 'roomId');
      final status = data['status'];
      final roomSnapshot = await _rooms.doc(roomId).get();
      final roomData = roomSnapshot.data();
      if (roomData == null) {
        throw const RoomFailure('The joined room could not be loaded.');
      }
      return RoomJoinResult(
        room: Room.fromMap(roomSnapshot.id, roomData),
        alreadyMember: status == 'already-member',
      );
    } on FirebaseFunctionsException catch (error) {
      throw _roomFailureFromFunction(error);
    } on FirebaseException {
      throw const RoomFailure('Unable to join this room. Please try again.');
    } on FormatException {
      throw const RoomFailure('The server returned invalid room details.');
    }
  }

  String _requiredString(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! String || value.isEmpty) {
      throw const FormatException('Missing callable result field.');
    }
    return value;
  }

  RoomFailure _roomFailureFromFunction(FirebaseFunctionsException error) {
    final message = switch (error.code) {
      'unauthenticated' => 'Sign in to continue.',
      'invalid-argument' => error.message ?? 'Check the information and retry.',
      'not-found' => error.message ?? 'The room or invite could not be found.',
      'deadline-exceeded' => error.message ?? 'This invite has expired.',
      'permission-denied' => error.message ?? 'You are not allowed to do that.',
      'failed-precondition' =>
        error.message ?? 'This invite is no longer active.',
      'resource-exhausted' => error.message ?? 'Please try again in a moment.',
      _ => 'Unable to complete the room request. Please try again.',
    };
    return RoomFailure(message, code: error.code);
  }
}
