import '../../models/expense.dart';

/// View state for the room expense stream and mutation actions.
///
/// [isLoading] applies to the initial stream subscription; [isMutating] keeps
/// create/update/delete actions from being submitted concurrently.
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
