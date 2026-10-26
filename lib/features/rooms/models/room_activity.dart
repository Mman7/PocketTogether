import 'package:cloud_firestore/cloud_firestore.dart';

class RoomActivity {
  const RoomActivity({
    required this.id,
    required this.type,
    required this.actorUserId,
    required this.createdAt,
    this.expenseId,
    this.metadata = const {},
  });

  final String id;
  final String type;
  final String actorUserId;
  final DateTime? createdAt;
  final String? expenseId;
  final Map<String, dynamic> metadata;

  factory RoomActivity.fromMap(String id, Map<String, dynamic> data) {
    final timestamp = data['createdAt'];
    return RoomActivity(
      id: id,
      type: data['type'] as String? ?? 'unknown',
      actorUserId: data['actorUserId'] as String? ?? '',
      createdAt: timestamp is Timestamp ? timestamp.toDate() : null,
      expenseId: data['expenseId'] as String?,
      metadata: data['metadata'] is Map
          ? Map<String, dynamic>.from(data['metadata'] as Map)
          : const {},
    );
  }
}

class RoomActivityPage {
  const RoomActivityPage({required this.items, required this.hasMore});

  final List<RoomActivity> items;
  final bool hasMore;
}
