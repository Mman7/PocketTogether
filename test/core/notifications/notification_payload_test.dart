import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_together/core/notifications/notification_payload.dart';

void main() {
  test('parses supported expense payloads', () {
    final payload = NotificationPayload.tryParse({
      'type': 'expense_updated',
      'roomId': ' room-1 ',
      'expenseId': 'expense-1',
    });

    expect(payload?.type, NotificationType.expenseUpdated);
    expect(payload?.roomId, 'room-1');
    expect(payload?.expenseId, 'expense-1');
  });

  test('rejects unknown, incomplete, and malformed payloads', () {
    expect(NotificationPayload.tryParse({}), isNull);
    expect(
      NotificationPayload.tryParse({
        'type': 'expense_created',
        'roomId': 'room-1',
      }),
      isNull,
    );
    expect(
      NotificationPayload.tryParse({'type': 'unknown', 'roomId': 'room-1'}),
      isNull,
    );
  });
}
