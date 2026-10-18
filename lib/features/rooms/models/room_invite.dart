class RoomInvite {
  final String inviteCode;
  final String roomId;
  final String createdBy;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isActive;

  RoomInvite({
    required this.inviteCode,
    required this.roomId,
    required this.createdBy,
    required this.createdAt,
    required this.expiresAt,
    required this.isActive,
  });
}
