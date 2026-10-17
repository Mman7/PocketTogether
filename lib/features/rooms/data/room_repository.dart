import '../models/room.dart';

abstract interface class RoomRepository {
  Future<List<Room>> getRooms(String ownerId);

  Future<Room> createRoom({
    required String ownerId,
    required String name,
    required String currency,
    String? description,
  });
}

class RoomFailure implements Exception {
  const RoomFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
