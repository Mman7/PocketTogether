import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'expense.g.dart';

@JsonSerializable()
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
    final normalized = Map<String, dynamic>.from(data)
      ..['id'] = id
      ..['expenseDate'] = _dateAsJson(data['expenseDate']);
    if (data['createdAt'] != null) {
      normalized['createdAt'] = _dateAsJson(data['createdAt']);
    }
    if (data['updatedAt'] != null) {
      normalized['updatedAt'] = _dateAsJson(data['updatedAt']);
    }
    final rawSplits = data['splitAmountsInCents'] as Map<String, dynamic>?;
    if (rawSplits != null) {
      normalized['splitAmountsInCents'] = rawSplits.map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      );
    }
    return Expense.fromJson(normalized);
  }

  Map<String, dynamic> toMap() {
    final data = toJson()
      ..['expenseDate'] = Timestamp.fromDate(expenseDate)
      ..['createdAt'] = createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!)
      ..['updatedAt'] = FieldValue.serverTimestamp();
    data.remove('id');
    return data;
  }

  factory Expense.fromJson(Map<String, dynamic> json) =>
      _$ExpenseFromJson(json);

  Map<String, dynamic> toJson() => _$ExpenseToJson(this);
}

String? _dateAsJson(Object? value) {
  if (value is Timestamp) return value.toDate().toIso8601String();
  if (value is DateTime) return value.toIso8601String();
  if (value is String) return value;
  return null;
}
