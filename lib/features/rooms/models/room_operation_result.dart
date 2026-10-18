import 'room.dart';
import 'room_invite.dart';

class RoomCreationResult {
  const RoomCreationResult({required this.room, required this.invite});

  final Room room;
  final RoomInvite invite;
}

class RoomJoinResult {
  const RoomJoinResult({required this.room, required this.alreadyMember});

  final Room room;
  final bool alreadyMember;
}
