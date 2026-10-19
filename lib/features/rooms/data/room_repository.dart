import '../models/room.dart';
import '../models/room_invite.dart';
import '../models/room_operation_result.dart';
import '../models/room_member.dart';

abstract interface class RoomRepository {
  Stream<List<Room>> watchMyRooms(String userId);

  Future<List<RoomMember>> getRoomMembers(String roomId);

  Future<RoomInvite> createInvite({required String roomId});

  Future<void> removeMember({required String roomId, required String memberId});

  Future<void> deleteRoom({required String roomId});

  Future<RoomJoinResult> joinRoom({required String inviteCode});

  Future<RoomCreationResult> createRoom({
    required String name,
    required String currency,
  });
}

class RoomFailure implements Exception {
  const RoomFailure(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}
