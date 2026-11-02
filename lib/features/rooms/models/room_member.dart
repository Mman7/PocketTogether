import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

import 'room_role.dart';

part 'room_member.g.dart';

/// A member snapshot returned by the room-members callable.
///
/// Membership mutations are performed by Cloud Functions. This model is a
/// read representation, so a missing or unrecognized role falls back to the
/// non-owner role rather than granting owner UI affordances.
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
    final member = tryFromMap(userId, data);
    if (member == null) {
      throw const FormatException('Invalid room member document.');
    }
    return member;
  }

  static RoomMember? tryFromMap(String userId, Map<String, dynamic> data) {
    if (userId.isEmpty) return null;
    final displayName = data['displayName'];
    return RoomMember(
      userId: userId,
      displayName: displayName is String && displayName.trim().isNotEmpty
          ? displayName
          : 'Unknown',
      email: _nullableString(data['email']),
      role: data['role'] == 'owner' ? RoomRole.owner : RoomRole.member,
      joinedAt: _dateValue(data['joinedAt']),
    );
  }

  Map<String, dynamic> toMap() => toJson();

  factory RoomMember.fromJson(Map<String, dynamic> json) =>
      _$RoomMemberFromJson(json);

  Map<String, dynamic> toJson() => _$RoomMemberToJson(this);
}

String? _nullableString(Object? value) => value is String ? value : null;

DateTime? _dateValue(Object? value) {
  if (value is String) return DateTime.tryParse(value)?.toUtc();
  if (value is DateTime) return value.toUtc();
  if (value is Timestamp) return value.toDate().toUtc();
  return null;
}
