import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/expense_repository.dart';
import '../../models/expense.dart';
import 'expense_state.dart';

class ExpenseCubit extends Cubit<ExpenseState> {
  ExpenseCubit(this._repository) : super(const ExpenseState());

  final ExpenseRepository _repository;
  StreamSubscription<List<Expense>>? _expensesSubscription;
  String? _watchedRoomId;

  Future<void> loadExpenses(String roomId) async {
    if (_watchedRoomId == roomId && _expensesSubscription != null) return;
    await _expensesSubscription?.cancel();
    _watchedRoomId = roomId;
    emit(ExpenseState(expenses: state.expenses, isLoading: true));
    try {
      _expensesSubscription = _repository
          .watchExpenses(roomId)
          .listen(
            (expenses) {
              if (!isClosed) {
                emit(ExpenseState(expenses: _sorted(expenses)));
              }
            },
            onError: (Object error) {
              if (!isClosed) {
                emit(
                  ExpenseState(
                    expenses: state.expenses,
                    errorMessage: error is ExpenseFailure
                        ? error.message
                        : 'Unable to load expenses.',
                  ),
                );
              }
            },
          );
    } catch (_) {
      if (!isClosed) {
        emit(
          ExpenseState(
            expenses: state.expenses,
            errorMessage: 'Unable to load expenses.',
          ),
        );
      }
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
    expenses.sort((first, second) {
      final firstCreatedAt = first.createdAt;
      final secondCreatedAt = second.createdAt;
      if (firstCreatedAt != null && secondCreatedAt != null) {
        return secondCreatedAt.compareTo(firstCreatedAt);
      }
      if (firstCreatedAt != null) return -1;
      if (secondCreatedAt != null) return 1;
      return second.expenseDate.compareTo(first.expenseDate);
    });
    return expenses;
  }

  @override
  Future<void> close() async {
    await _expensesSubscription?.cancel();
    await super.close();
  }
}
