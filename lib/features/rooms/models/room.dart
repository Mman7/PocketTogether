class Room {
  final String id;
  final String name;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? description;
  final String? currency;
  final String? ownerId;

  const Room({
    required this.id,
    required this.name,
    this.createdAt,
    this.updatedAt,
    this.description,
    this.currency,
    this.ownerId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'updatedAt': updatedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'currency': currency,
      'ownerId': ownerId,
    };
  }

  factory Room.fromMap(String id, Map<String, dynamic> data) {
    return Room(
      id: id,
      name: data['name'] as String,
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'] as String)
          : null,
      updatedAt: data['updatedAt'] != null
          ? DateTime.parse(data['updatedAt'] as String)
          : null,
      description: data['description'] as String?,
      currency: data['currency'] as String?,
      ownerId: data['ownerId'] as String?,
    );
  }
}
