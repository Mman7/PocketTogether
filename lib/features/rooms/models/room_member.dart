import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

import 'room_role.dart';

part 'room_member.g.dart';

@JsonSerializable()
class RoomMember {
  final String userId;
  final String displayName;
  final String? email;
  final RoomRole role;
  final DateTime? joinedAt;

  const RoomMember({
    required this.userId,
    required this.displayName,
    this.email,
    required this.role,
    this.joinedAt,
  });

  bool get isOwner => role == RoomRole.owner;

  factory RoomMember.fromMap(String userId, Map<String, dynamic> data) {
    return RoomMember.fromJson({
      ...data,
      'userId': userId,
      'displayName': data['displayName'] ?? 'Unknown',
      'role': data['role'] == 'owner' ? 'owner' : 'member',
      'joinedAt': _dateAsJson(data['joinedAt']),
    });
  }

  Map<String, dynamic> toMap() => toJson();

  factory RoomMember.fromJson(Map<String, dynamic> json) =>
      _$RoomMemberFromJson(json);

  Map<String, dynamic> toJson() => _$RoomMemberToJson(this);
}

String? _dateAsJson(Object? value) {
  if (value is String) return value;
  if (value is DateTime) return value.toIso8601String();
  if (value is Timestamp) return value.toDate().toIso8601String();
  return null;
}
