import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/expense_repository.dart';
import '../../models/expense.dart';
import 'expense_state.dart';

class ExpenseCubit extends Cubit<ExpenseState> {
  ExpenseCubit(this._repository) : super(const ExpenseState());

  final ExpenseRepository _repository;

  Future<void> loadExpenses(String roomId) async {
    emit(ExpenseState(expenses: state.expenses, isLoading: true));
    try {
      final expenses = await _repository.getExpenses(roomId);
      emit(ExpenseState(expenses: expenses));
    } on ExpenseFailure catch (error) {
      emit(ExpenseState(expenses: state.expenses, errorMessage: error.message));
    } catch (_) {
      emit(
        ExpenseState(
          expenses: state.expenses,
          errorMessage: 'Unable to load expenses.',
        ),
      );
    }
  }

  Future<Expense?> createExpense(String roomId, Expense expense) async {
    if (state.isMutating) return null;
    emit(ExpenseState(expenses: state.expenses, isMutating: true));
    try {
      final savedExpense = await _repository.createExpense(
        roomId: roomId,
        expense: expense,
      );
      emit(
        ExpenseState(
          expenses: _sorted([
            ...state.expenses.where((item) => item.id != savedExpense.id),
            savedExpense,
          ]),
        ),
      );
      return savedExpense;
    } on ExpenseFailure catch (error) {
      emit(ExpenseState(expenses: state.expenses, errorMessage: error.message));
    } catch (_) {
      emit(
        ExpenseState(
          expenses: state.expenses,
          errorMessage: 'Unable to save expense.',
        ),
      );
    }
    return null;
  }

  Future<Expense?> updateExpense(String roomId, Expense expense) async {
    if (state.isMutating) return null;
    emit(ExpenseState(expenses: state.expenses, isMutating: true));
    try {
      final updatedExpense = await _repository.updateExpense(
        roomId: roomId,
        expense: expense,
      );
      emit(
        ExpenseState(
          expenses: _sorted([
            for (final item in state.expenses)
              if (item.id != updatedExpense.id) item,
            updatedExpense,
          ]),
        ),
      );
      return updatedExpense;
    } on ExpenseFailure catch (error) {
      emit(ExpenseState(expenses: state.expenses, errorMessage: error.message));
    } catch (_) {
      emit(
        ExpenseState(
          expenses: state.expenses,
          errorMessage: 'Unable to update expense.',
        ),
      );
    }
    return null;
  }

  Future<bool> deleteExpense(String roomId, String expenseId) async {
    if (state.isMutating) return false;
    emit(ExpenseState(expenses: state.expenses, isMutating: true));
    try {
      await _repository.deleteExpense(roomId: roomId, expenseId: expenseId);
      emit(
        ExpenseState(
          expenses: state.expenses
              .where((expense) => expense.id != expenseId)
              .toList(),
        ),
      );
      return true;
    } on ExpenseFailure catch (error) {
      emit(ExpenseState(expenses: state.expenses, errorMessage: error.message));
    } catch (_) {
      emit(
        ExpenseState(
          expenses: state.expenses,
          errorMessage: 'Unable to delete expense.',
        ),
      );
    }
    return false;
  }

  List<Expense> _sorted(List<Expense> expenses) {
    expenses.sort(
      (first, second) => second.expenseDate.compareTo(first.expenseDate),
    );
    return expenses;
  }
}
