import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'room.g.dart';

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
    final normalized = Map<String, dynamic>.from(data)
      ..['id'] = id
      ..['createdAt'] = _dateAsJson(data['createdAt'])
      ..['updatedAt'] = _dateAsJson(data['updatedAt'])
      ..['ownerId'] = data['createdBy'] ?? data['ownerId'];
    return Room.fromJson(normalized);
  }

  factory Room.fromJson(Map<String, dynamic> json) => _$RoomFromJson(json);

  Map<String, dynamic> toJson() => _$RoomToJson(this);
}

String? _dateAsJson(Object? value) {
  if (value is Timestamp) return value.toDate().toIso8601String();
  if (value is DateTime) return value.toIso8601String();
  if (value is String) return value;
  return null;
}
