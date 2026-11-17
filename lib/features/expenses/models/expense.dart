/// A room expense represented entirely in integer cents.
///
/// Split amounts must add up exactly to [amountInCents]. Dates are normalized
/// to UTC at the Firestore boundary, while serialization continues to support
/// the existing generated JSON representation.
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
}
