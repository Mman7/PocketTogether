import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/room.dart';
import 'room_repository.dart';

class FirebaseRoomRepository implements RoomRepository {
  FirebaseRoomRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _rooms =>
      _firestore.collection('rooms');

  @override
  Future<List<Room>> getRooms(String ownerId) async {
    try {
      final snapshot = await _rooms.where('ownerId', isEqualTo: ownerId).get();
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
    } on FirebaseException {
      throw const RoomFailure('Unable to load rooms. Please try again.');
    }
  }

  @override
  Future<Room> createRoom({
    required String ownerId,
    required String name,
    required String currency,
    String? description,
  }) async {
    try {
      final document = _rooms.doc();
      final now = DateTime.now().toUtc();
      final room = Room(
        id: document.id,
        name: name.trim(),
        description: description?.trim(),
        currency: currency,
        ownerId: ownerId,
        createdAt: now,
        updatedAt: now,
      );
      await document.set(room.toMap());
      return room;
    } on FirebaseException {
      throw const RoomFailure('Unable to create room. Please try again.');
    }
  }
}
