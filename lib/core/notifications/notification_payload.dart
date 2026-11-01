enum NotificationType { expenseCreated, expenseUpdated, memberJoined }

class NotificationPayload {
  const NotificationPayload({
    required this.type,
    required this.roomId,
    this.expenseId,
  });

  final NotificationType type;
  final String roomId;
  final String? expenseId;

  static NotificationPayload? tryParse(Map<String, dynamic> data) {
    final type = switch (data['type']) {
      'expense_created' => NotificationType.expenseCreated,
      'expense_updated' => NotificationType.expenseUpdated,
      'member_joined' => NotificationType.memberJoined,
      _ => null,
    };
    final roomId = data['roomId'];
    if (type == null || roomId is! String || roomId.trim().isEmpty) {
      return null;
    }

    final expenseId = data['expenseId'];
    if ((type == NotificationType.expenseCreated ||
            type == NotificationType.expenseUpdated) &&
        (expenseId is! String || expenseId.trim().isEmpty)) {
      return null;
    }

    return NotificationPayload(
      type: type,
      roomId: roomId.trim(),
      expenseId: expenseId is String && expenseId.trim().isNotEmpty
          ? expenseId.trim()
          : null,
    );
  }
}
