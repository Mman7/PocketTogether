import 'package:flutter/foundation.dart';
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
    RoomActivityFilter filter = RoomActivityFilter.all,
    int limit = 20,
  }) async {
    debugPrint(
      '[RoomActivity] Loading room=$roomId filter=${filter.name} '
      'types=${filter.types} limit=$limit after=${after?.id}',
    );
    try {
      var query = _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('activityLogs')
          .orderBy('createdAt', descending: true)
          .orderBy(FieldPath.documentId);
      final types = filter.types;
      if (types != null) query = query.where('type', whereIn: types);
      query = query.limit(limit + 1);
      if (after?.createdAt != null) {
        query = query.startAfter([
          Timestamp.fromDate(after!.createdAt!),
          after.id,
        ]);
      }
      debugPrint('[RoomActivity] Executing Firestore activityLogs query.');
      final snapshot = await query.get();
      debugPrint(
        '[RoomActivity] Query succeeded: documents=${snapshot.docs.length}',
      );
      final hasMore = snapshot.docs.length > limit;
      final documents = hasMore ? snapshot.docs.take(limit) : snapshot.docs;
      return RoomActivityPage(
        items: [
          for (final document in documents)
            RoomActivity.fromMap(document.id, document.data()),
        ],
        hasMore: hasMore,
      );
    } on FirebaseException catch (error, stackTrace) {
      debugPrint(
        '[RoomActivity] FirebaseException code=${error.code} '
        'message=${error.message}',
      );
      debugPrintStack(stackTrace: stackTrace);
      throw const RoomActivityFailure('Unable to load room activity.');
    } catch (error, stackTrace) {
      debugPrint('[RoomActivity] Unexpected error: $error');
      debugPrintStack(stackTrace: stackTrace);
      throw const RoomActivityFailure('Unable to load room activity.');
    }
  }
}
