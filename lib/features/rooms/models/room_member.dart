import 'room_role.dart';

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
    final rawJoinedAt = data['joinedAt'];
    final joinedAt = rawJoinedAt is String
        ? DateTime.tryParse(rawJoinedAt)
        : (rawJoinedAt as dynamic)?.toDate() as DateTime?;
    return RoomMember(
      userId: userId,
      displayName: data['displayName'] as String? ?? 'Unknown',
      email: data['email'] as String?,
      role: data['role'] == 'owner' ? RoomRole.owner : RoomRole.member,
      joinedAt: joinedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      if (email != null) 'email': email,
      'joinedAt': joinedAt,
    };
  }
}
