import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final int amountInCents;
  final String category;
  final String? note;
  final String paidByUserId;
  final String createdByUserId;
  final Map<String, int> splitAmountsInCents;
  final DateTime expenseDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Expense({
    required this.id,
    required this.amountInCents,
    required this.category,
    this.note,
    required this.paidByUserId,
    required this.createdByUserId,
    required this.splitAmountsInCents,
    required this.expenseDate,
    this.createdAt,
    this.updatedAt,
  });

  bool get hasValidSplit {
    final totalSplit = splitAmountsInCents.values.fold<int>(
      0,
      (int sum, int amount) => sum + amount,
    );

    return totalSplit == amountInCents;
  }

  factory Expense.fromMap(String id, Map<String, dynamic> data) {
    DateTime? parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return null;
    }

    final rawSplits =
        data['splitAmountsInCents'] as Map<String, dynamic>? ?? {};

    return Expense(
      id: id,
      amountInCents: data['amountInCents'] as int,
      category: data['category'] as String,
      note: data['note'] as String?,
      paidByUserId: data['paidByUserId'] as String,
      createdByUserId: data['createdByUserId'] as String,
      splitAmountsInCents: rawSplits.map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      ),
      expenseDate: parseDate(data['expenseDate'])!,
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amountInCents': amountInCents,
      'category': category,
      'note': note,
      'paidByUserId': paidByUserId,
      'createdByUserId': createdByUserId,
      'splitAmountsInCents': splitAmountsInCents,
      'expenseDate': Timestamp.fromDate(expenseDate),
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
