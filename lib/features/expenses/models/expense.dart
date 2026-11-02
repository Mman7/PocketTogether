import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'expense.g.dart';

/// A room expense represented entirely in integer cents.
///
/// Split amounts must add up exactly to [amountInCents]. Dates are normalized
/// to UTC at the Firestore boundary, while serialization continues to support
/// the existing generated JSON representation.
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
    // Integer cents avoid floating-point rounding when validating who owes
    // each share of an expense.
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
    final expense = tryFromMap(id, data);
    if (expense == null) {
      throw const FormatException('Invalid expense document.');
    }
    return expense;
  }

  /// Parses an untrusted Firestore document without throwing.
  ///
  /// Repositories use this method to ignore malformed documents while still
  /// showing valid expenses from the same collection. Use [fromMap] when a
  /// malformed document should be reported to the caller instead.
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
    // Do not coerce strings or fractional numbers into cents: doing so would
    // hide corrupt persisted data and change the recorded total.
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
