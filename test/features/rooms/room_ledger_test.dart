import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_together/features/expenses/models/expense.dart';
import 'package:pocket_together/features/rooms/models/room.dart';
import 'package:pocket_together/features/rooms/models/room_ledger.dart';
import 'package:pocket_together/features/rooms/presentation/cubit/room_ledger_state.dart';

void main() {
  test('aggregates total spend across rooms by currency', () {
    final date = DateTime(2026, 10, 24);
    final state = RoomLedgerState(
      ledgers: [
        RoomLedger(
          room: const Room(
            id: 'home-room',
            name: 'Home',
            currency: 'MYR',
            ownerId: 'user',
          ),
          members: const [],
          expenses: [
            Expense(
              id: 'groceries',
              amountInCents: 1250,
              category: 'Food',
              paidByUserId: 'user',
              createdByUserId: 'user',
              splitAmountsInCents: {},
              expenseDate: date,
            ),
          ],
        ),
        RoomLedger(
          room: const Room(
            id: 'trip-room',
            name: 'Trip',
            currency: 'JPY',
            ownerId: 'user',
          ),
          members: const [],
          expenses: [
            Expense(
              id: 'train',
              amountInCents: 3000,
              category: 'Transport',
              paidByUserId: 'user',
              createdByUserId: 'user',
              splitAmountsInCents: {},
              expenseDate: date,
            ),
          ],
        ),
      ],
    );

    expect(state.totalSpendByCurrency(), {'MYR': 1250, 'JPY': 3000});
  });
}
