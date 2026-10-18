import '../../models/room.dart';
import '../../models/room_operation_result.dart';

class RoomState {
  const RoomState({
    this.isLoading = false,
    this.isJoining = false,
    this.isLoadingRooms = false,
    this.rooms = const [],
    this.createdRoom,
    this.joinedRoom,
    this.errorMessage,
    this.joinErrorMessage,
    this.roomsErrorMessage,
  });

  final bool isLoading;
  final bool isJoining;
  final bool isLoadingRooms;
  final List<Room> rooms;
  final RoomCreationResult? createdRoom;
  final RoomJoinResult? joinedRoom;
  final String? errorMessage;
  final String? joinErrorMessage;
  final String? roomsErrorMessage;

  RoomState copyWith({
    bool? isLoading,
    bool? isJoining,
    bool? isLoadingRooms,
    List<Room>? rooms,
    RoomCreationResult? createdRoom,
    RoomJoinResult? joinedRoom,
    String? errorMessage,
    String? joinErrorMessage,
    String? roomsErrorMessage,
    bool clearCreatedRoom = false,
    bool clearJoinedRoom = false,
    bool clearErrorMessage = false,
    bool clearJoinErrorMessage = false,
    bool clearRoomsErrorMessage = false,
  }) {
    return RoomState(
      isLoading: isLoading ?? this.isLoading,
      isJoining: isJoining ?? this.isJoining,
      isLoadingRooms: isLoadingRooms ?? this.isLoadingRooms,
      rooms: rooms ?? this.rooms,
      createdRoom: clearCreatedRoom ? null : createdRoom ?? this.createdRoom,
      joinedRoom: clearJoinedRoom ? null : joinedRoom ?? this.joinedRoom,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
      joinErrorMessage: clearJoinErrorMessage
          ? null
          : joinErrorMessage ?? this.joinErrorMessage,
      roomsErrorMessage: clearRoomsErrorMessage
          ? null
          : roomsErrorMessage ?? this.roomsErrorMessage,
    );
  }
}
