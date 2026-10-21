import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/expense.dart';
import 'expense_repository.dart';

class FirebaseExpenseRepository implements ExpenseRepository {
  FirebaseExpenseRepository(this._firestore);

  final FirebaseFirestore _firestore;

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
      await document.set(savedExpense.toMap());
      return savedExpense;
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
      await _expenses(roomId).doc(expense.id).update(updatedExpense.toMap());
      return updatedExpense;
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
      await _expenses(roomId).doc(expenseId).delete();
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
}
