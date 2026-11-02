import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_together/features/rooms/models/room.dart';
import 'package:pocket_together/features/rooms/models/room_member.dart';
import 'package:pocket_together/features/rooms/models/room_role.dart';

void main() {
  test('parses Room timestamps and legacy owner field', () {
    final room = Room.fromMap('room-1', {
      'name': 'Trip',
      'createdBy': 'owner-1',
      'createdAt': Timestamp.fromDate(DateTime.utc(2026, 11, 1)),
      'memberIds': ['owner-1', 'member-1'],
    });

    expect(room.ownerId, 'owner-1');
    expect(room.memberIds, ['owner-1', 'member-1']);
    expect(room.createdAt, DateTime.utc(2026, 11, 1));
  });

  test('rejects malformed Room data without throwing in tryFromMap', () {
    expect(
      Room.tryFromMap('room-2', {'name': 42, 'memberIds': 'not-a-list'}),
      isNull,
    );
  });

  test('keeps RoomMember defaults and safely parses invalid dates', () {
    final member = RoomMember.fromMap('user-1', {
      'displayName': null,
      'role': 'unexpected-role',
      'joinedAt': 'invalid-date',
    });

    expect(member.displayName, 'Unknown');
    expect(member.role, RoomRole.member);
    expect(member.joinedAt, isNull);
  });
}
