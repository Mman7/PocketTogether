import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/expense.dart';

/// Converts between the domain expense and Firebase representations.
class ExpenseDto {
  const ExpenseDto._();

  static Expense fromMap(String id, Map<String, dynamic> data) {
    final expense = tryFromMap(id, data);
    if (expense == null) {
      throw const FormatException('Invalid expense document.');
    }
    return expense;
  }

  /// Parses an untrusted Firestore document without throwing.
  static Expense? tryFromMap(String id, Map<String, dynamic> data) {
    final amountInCents = _integerValue(data['amountInCents']);
    final category = _stringValue(data['category']);
    final paidByUserId = _stringValue(data['paidByUserId']);
    final createdByUserId = _stringValue(data['createdByUserId']);
    final expenseDate = _dateValue(data['expenseDate']);
    final splitAmountsInCents = _splitValues(data['splitAmountsInCents']);
    if (amountInCents == null ||
        category == null ||
        paidByUserId == null ||
        createdByUserId == null ||
        expenseDate == null ||
        splitAmountsInCents == null) {
      return null;
    }

    return Expense(
      id: id,
      amountInCents: amountInCents,
      category: category,
      note: _nullableString(data['note']),
      paidByUserId: paidByUserId,
      createdByUserId: createdByUserId,
      transferMethod: _nullableString(data['transferMethod']),
      transferToUserId: _nullableString(data['transferToUserId']),
      splitAmountsInCents: splitAmountsInCents,
      expenseDate: expenseDate,
      createdAt: _dateValue(data['createdAt']),
      updatedAt: _dateValue(data['updatedAt']),
    );
  }

  static Map<String, dynamic> toMap(Expense expense) {
    return {
      ...toJson(expense),
      'expenseDate': Timestamp.fromDate(expense.expenseDate),
      'createdAt': expense.createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(expense.createdAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    }..remove('id');
  }

  static Map<String, dynamic> toJson(Expense expense) {
    return {
      'id': expense.id,
      'amountInCents': expense.amountInCents,
      'category': expense.category,
      'note': expense.note,
      'paidByUserId': expense.paidByUserId,
      'createdByUserId': expense.createdByUserId,
      'transferMethod': expense.transferMethod,
      'transferToUserId': expense.transferToUserId,
      'splitAmountsInCents': expense.splitAmountsInCents,
      'expenseDate': expense.expenseDate.toIso8601String(),
      'createdAt': expense.createdAt?.toIso8601String(),
      'updatedAt': expense.updatedAt?.toIso8601String(),
    };
  }
}

String? _stringValue(Object? value) =>
    value is String && value.isNotEmpty ? value : null;

String? _nullableString(Object? value) => value is String ? value : null;

int? _integerValue(Object? value) {
  if (value is int) return value;
  if (value is! double || !value.isFinite) return null;
  final integer = value.toInt();
  return integer.toDouble() == value ? integer : null;
}

Map<String, int>? _splitValues(Object? value) {
  if (value is! Map) return null;
  final splits = <String, int>{};
  for (final entry in value.entries) {
    if (entry.key is! String) return null;
    final amount = _integerValue(entry.value);
    if (amount == null) return null;
    splits[entry.key as String] = amount;
  }
  return splits;
}

DateTime? _dateValue(Object? value) {
  if (value is Timestamp) return value.toDate().toUtc();
  if (value is DateTime) return value.toUtc();
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed.toUtc();
  }
  return null;
}
