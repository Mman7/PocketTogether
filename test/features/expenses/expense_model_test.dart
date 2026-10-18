import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_together/features/expenses/models/expense.dart';

void main() {
  test('round trips Firestore expense fields and split amounts', () {
    final createdAt = DateTime.utc(2026, 10, 17, 9, 30);
    final expense = Expense(
      id: 'expense-1',
      amountInCents: 1001,
      category: 'Food',
      note: 'Lunch',
      paidByUserId: 'user-1',
      createdByUserId: 'user-1',
      splitAmountsInCents: const {'user-1': 501, 'user-2': 500},
      expenseDate: DateTime.utc(2026, 10, 17),
      createdAt: createdAt,
      updatedAt: createdAt,
    );

    final decoded = Expense.fromMap(expense.id, expense.toMap());

    expect(decoded.amountInCents, 1001);
    expect(decoded.note, 'Lunch');
    expect(decoded.paidByUserId, 'user-1');
    expect(decoded.splitAmountsInCents, {'user-1': 501, 'user-2': 500});
    expect(decoded.expenseDate.toUtc(), DateTime.utc(2026, 10, 17));
  });

  test('detects split totals that do not equal the expense amount', () {
    final expense = Expense(
      id: 'expense-1',
      amountInCents: 1001,
      category: 'Food',
      paidByUserId: 'user-1',
      createdByUserId: 'user-1',
      splitAmountsInCents: {'user-1': 500, 'user-2': 500},
      expenseDate: DateTime.utc(2026, 10, 17),
    );

    expect(expense.hasValidSplit, isFalse);
  });
}
