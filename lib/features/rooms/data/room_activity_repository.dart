import '../models/room_activity.dart';

abstract interface class RoomActivityRepository {
  Future<RoomActivityPage> getPage({
    required String roomId,
    RoomActivity? after,
    int limit = 20,
  });
}

class RoomActivityFailure implements Exception {
  const RoomActivityFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
