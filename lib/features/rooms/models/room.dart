import 'package:cloud_firestore/cloud_firestore.dart';

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
    return {
      'id': id,
      'name': name,
      'description': description,
      'updatedAt': updatedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'currency': currency,
      'ownerId': ownerId,
      'createdBy': ownerId,
      'memberIds': memberIds,
    };
  }

  factory Room.fromMap(String id, Map<String, dynamic> data) {
    return Room(
      id: id,
      name: data['name'] as String,
      createdAt: _parseDate(data['createdAt']),
      updatedAt: _parseDate(data['updatedAt']),
      description: data['description'] as String?,
      currency: data['currency'] as String?,
      ownerId: data['createdBy'] as String? ?? data['ownerId'] as String?,
      memberIds:
          (data['memberIds'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
