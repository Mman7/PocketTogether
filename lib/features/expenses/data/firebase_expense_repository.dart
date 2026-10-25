import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/expense.dart';
import 'expense_repository.dart';

class FirebaseExpenseRepository implements ExpenseRepository {
  FirebaseExpenseRepository(this._firestore, {FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> _expenses(String roomId) =>
      _firestore.collection('rooms').doc(roomId).collection('expenses');

  @override
  Stream<List<Expense>> watchExpenses(String roomId) {
    return _expenses(roomId)
        .orderBy('expenseDate', descending: true)
        .snapshots(includeMetadataChanges: true)
        .where((snapshot) => !snapshot.metadata.isFromCache)
        .map(
          (snapshot) => snapshot.docs
              .map((document) => Expense.fromMap(document.id, document.data()))
              .toList(),
        )
        .transform(
          StreamTransformer.fromHandlers(
            handleError: (error, stackTrace, sink) {
              sink.addError(
                const ExpenseFailure(
                  'Unable to load expenses. Please try again.',
                ),
                stackTrace,
              );
            },
          ),
        );
  }

  @override
  Future<List<Expense>> getExpenses(String roomId) async {
    try {
      final snapshot = await _expenses(roomId)
          .orderBy('expenseDate', descending: true)
          .get();
      return snapshot.docs
          .map((document) => Expense.fromMap(document.id, document.data()))
          .toList();
    } on FirebaseException {
      throw const ExpenseFailure('Unable to load expenses. Please try again.');
    }
  }

  @override
  Future<Expense> createExpense({
    required String roomId,
    required Expense expense,
  }) async {
    _validate(expense);
    try {
      final document = _expenses(roomId).doc();
      final now = DateTime.now().toUtc();
      final savedExpense = expense.copyWith(
        id: document.id,
        createdAt: now,
        updatedAt: now,
      );
      await _functions.httpsCallable('createExpense').call<void>({
        'roomId': roomId,
        'expenseId': document.id,
        ..._callableData(savedExpense),
      });
      return savedExpense;
    } on FirebaseFunctionsException catch (error) {
      throw ExpenseFailure(_functionMessage(error, 'Unable to save expense.'));
    } on FirebaseException {
      throw const ExpenseFailure('Unable to save expense. Please try again.');
    }
  }

  @override
  Future<Expense> updateExpense({
    required String roomId,
    required Expense expense,
  }) async {
    _validate(expense);
    if (expense.id.isEmpty) {
      throw const ExpenseFailure('Expense ID is required.');
    }
    try {
      final updatedExpense = expense.copyWith(
        updatedAt: DateTime.now().toUtc(),
      );
      await _functions.httpsCallable('updateExpense').call<void>({
        'roomId': roomId,
        'expenseId': expense.id,
        ..._callableData(updatedExpense),
      });
      return updatedExpense;
    } on FirebaseFunctionsException catch (error) {
      throw ExpenseFailure(
        _functionMessage(error, 'Unable to update expense.'),
      );
    } on FirebaseException {
      throw const ExpenseFailure('Unable to update expense. Please try again.');
    }
  }

  @override
  Future<void> deleteExpense({
    required String roomId,
    required String expenseId,
  }) async {
    try {
      await _functions.httpsCallable('deleteExpense').call<void>({
        'roomId': roomId,
        'expenseId': expenseId,
      });
    } on FirebaseFunctionsException catch (error) {
      throw ExpenseFailure(
        _functionMessage(error, 'Unable to delete expense.'),
      );
    } on FirebaseException {
      throw const ExpenseFailure('Unable to delete expense. Please try again.');
    }
  }

  void _validate(Expense expense) {
    if (expense.amountInCents <= 0 ||
        expense.paidByUserId.isEmpty ||
        expense.createdByUserId.isEmpty ||
        expense.splitAmountsInCents.isEmpty ||
        expense.splitAmountsInCents.values.any((amount) => amount <= 0) ||
        !expense.hasValidSplit) {
      throw const ExpenseFailure('Expense amount or split is invalid.');
    }
  }

  Map<String, dynamic> _callableData(Expense expense) {
    final data = expense.toJson()..remove('id');
    // Callable arguments must be JSON-compatible; generated DateTime values
    // are ISO strings and are parsed by the backend.
    return data;
  }

  String _functionMessage(FirebaseFunctionsException error, String fallback) {
    return switch (error.code) {
      'unauthenticated' => 'Sign in to continue.',
      'permission-denied' =>
        'You do not have permission to change this expense.',
      'invalid-argument' => error.message ?? 'The expense is invalid.',
      'not-found' => 'The expense or room could not be found.',
      'already-exists' =>
        'This expense was already submitted. Please refresh and try again.',
      'failed-precondition' =>
        error.message ?? 'The stored expense data is invalid.',
      _ => fallback,
    };
  }
}
