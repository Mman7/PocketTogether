import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'room.g.dart';

/// A room summary used by the room list and room-level screens.
///
/// `createdBy` is still accepted as the legacy owner field and normalized to
/// [ownerId] so existing room documents remain readable.
@JsonSerializable()
class Room {
  final String id;
  final String name;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? description;
  final String? currency;
  final String? ownerId;
  final List<String> memberIds;

  const Room({
    required this.id,
    required this.name,
    this.createdAt,
    this.updatedAt,
    this.description,
    this.currency,
    this.ownerId,
    this.memberIds = const [],
  });

  String? get createdBy => ownerId;

  Map<String, dynamic> toMap() {
    return toJson()..['createdBy'] = ownerId;
  }

  factory Room.fromMap(String id, Map<String, dynamic> data) {
    final room = tryFromMap(id, data);
    if (room == null) throw const FormatException('Invalid room document.');
    return room;
  }

  static Room? tryFromMap(String id, Map<String, dynamic> data) {
    final name = data['name'];
    if (name is! String || name.trim().isEmpty) return null;
    final memberIds = data['memberIds'];
    if (memberIds != null && memberIds is! List) return null;
    if (memberIds is List && memberIds.any((memberId) => memberId is! String)) {
      return null;
    }
    final parsedMemberIds = memberIds == null
        ? const <String>[]
        : memberIds.whereType<String>().toList(growable: false);
    return Room(
      id: id,
      name: name,
      createdAt: _dateValue(data['createdAt']),
      updatedAt: _dateValue(data['updatedAt']),
      description: _nullableString(data['description']),
      currency: _nullableString(data['currency']),
      ownerId: _nullableString(data['createdBy'] ?? data['ownerId']),
      memberIds: parsedMemberIds,
    );
  }

  factory Room.fromJson(Map<String, dynamic> json) => _$RoomFromJson(json);

  Map<String, dynamic> toJson() => _$RoomToJson(this);
}

String? _nullableString(Object? value) => value is String ? value : null;

DateTime? _dateValue(Object? value) {
  if (value is Timestamp) return value.toDate().toUtc();
  if (value is DateTime) return value.toUtc();
  if (value is String) return DateTime.tryParse(value)?.toUtc();
  return null;
}
