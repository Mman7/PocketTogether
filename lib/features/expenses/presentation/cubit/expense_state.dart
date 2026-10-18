import '../../models/expense.dart';

class ExpenseState {
  const ExpenseState({
    this.expenses = const [],
    this.isLoading = false,
    this.isMutating = false,
    this.errorMessage,
  });

  final List<Expense> expenses;
  final bool isLoading;
  final bool isMutating;
  final String? errorMessage;
}
