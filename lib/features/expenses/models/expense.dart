import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final int amountInCents;
  final String category;
  final String? note;
  final String paidByUserId;
  final String createdByUserId;
  final String? transferMethod;
  final String? transferToUserId;
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
    this.transferMethod,
    this.transferToUserId,
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

  Expense copyWith({
    String? id,
    int? amountInCents,
    String? category,
    String? note,
    String? paidByUserId,
    String? createdByUserId,
    String? transferMethod,
    String? transferToUserId,
    Map<String, int>? splitAmountsInCents,
    DateTime? expenseDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      amountInCents: amountInCents ?? this.amountInCents,
      category: category ?? this.category,
      note: note ?? this.note,
      paidByUserId: paidByUserId ?? this.paidByUserId,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      transferMethod: transferMethod ?? this.transferMethod,
      transferToUserId: transferToUserId ?? this.transferToUserId,
      splitAmountsInCents: splitAmountsInCents ?? this.splitAmountsInCents,
      expenseDate: expenseDate ?? this.expenseDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
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
      transferMethod: data['transferMethod'] as String?,
      transferToUserId: data['transferToUserId'] as String?,
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
      'transferMethod': transferMethod,
      'transferToUserId': transferToUserId,
      'splitAmountsInCents': splitAmountsInCents,
      'expenseDate': Timestamp.fromDate(expenseDate),
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
