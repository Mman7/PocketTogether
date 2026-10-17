import '../../models/room.dart';

class RoomState {
  const RoomState({
    this.isLoading = false,
    this.isLoadingRooms = false,
    this.rooms = const [],
    this.createdRoom,
    this.errorMessage,
    this.roomsErrorMessage,
  });

  final bool isLoading;
  final bool isLoadingRooms;
  final List<Room> rooms;
  final Room? createdRoom;
  final String? errorMessage;
  final String? roomsErrorMessage;
}
