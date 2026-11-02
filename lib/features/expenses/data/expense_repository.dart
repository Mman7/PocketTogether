import '../models/expense.dart';

abstract interface class ExpenseRepository {
  Future<List<Expense>> getExpenses(String roomId);

  Stream<List<Expense>> watchExpenses(String roomId);

  Future<Expense> createExpense({
    required String roomId,
    required Expense expense,
  });

  Future<Expense> updateExpense({
    required String roomId,
    required Expense expense,
  });

  Future<void> deleteExpense({
    required String roomId,
    required String expenseId,
  });
}

/// User-facing failure produced by the expense data layer.
class ExpenseFailure implements Exception {
  const ExpenseFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
