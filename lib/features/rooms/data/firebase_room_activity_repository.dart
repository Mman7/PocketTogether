import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/room_activity.dart';
import 'room_activity_repository.dart';

class FirebaseRoomActivityRepository implements RoomActivityRepository {
  FirebaseRoomActivityRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<RoomActivityPage> getPage({
    required String roomId,
    RoomActivity? after,
    int limit = 20,
  }) async {
    try {
      var query = _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('activityLogs')
          .orderBy('createdAt', descending: true)
          .orderBy(FieldPath.documentId)
          .limit(limit + 1);
      if (after?.createdAt != null) {
        query = query.startAfter([
          Timestamp.fromDate(after!.createdAt!),
          after.id,
        ]);
      }
      final snapshot = await query.get();
      final hasMore = snapshot.docs.length > limit;
      final documents = hasMore ? snapshot.docs.take(limit) : snapshot.docs;
      return RoomActivityPage(
        items: [
          for (final document in documents)
            RoomActivity.fromMap(document.id, document.data()),
        ],
        hasMore: hasMore,
      );
    } on FirebaseException {
      throw const RoomActivityFailure('Unable to load room activity.');
    }
  }
}
