import '../../expenses/models/expense.dart';

enum SpendingPeriod {
  day('Day', 'Today'),
  week('Week', 'This week'),
  month('Month', 'This month'),
  sixMonths('6 Months', 'Last 6 months');

  const SpendingPeriod(this.toggleLabel, this.pillLabel);

  final String toggleLabel;
  final String pillLabel;
}

/// Aggregated spending for one room over a [SpendingPeriod].
///
/// Transfers are settlements, not spending, so they are excluded.
class SpendingSummary {
  const SpendingSummary({
    required this.totalInCents,
    required this.transactionCount,
    required this.dayCount,
    required this.byCategory,
    required this.byMember,
  });

  final int totalInCents;
  final int transactionCount;

  /// Number of days the period covers, used for the daily average.
  final int dayCount;

  /// Category totals in cents, largest first.
  final List<MapEntry<String, int>> byCategory;

  /// Each member's consumed share in cents (their split of every expense),
  /// largest first.
  final List<MapEntry<String, int>> byMember;

  int get dailyAverageInCents => dayCount == 0 ? 0 : totalInCents ~/ dayCount;

  factory SpendingSummary.forPeriod({
    required Iterable<Expense> expenses,
    required SpendingPeriod period,
    DateTime? now,
    DateTime? selectedMonth,
  }) {
    final today = _dateOnly(now ?? DateTime.now());
    final month = selectedMonth == null
        ? DateTime(today.year, today.month, 1)
        : DateTime(selectedMonth.year, selectedMonth.month, 1);
    final monthEnd = month.year == today.year && month.month == today.month
        ? today
        : DateTime(month.year, month.month + 1, 0);
    final start = switch (period) {
      SpendingPeriod.day => today,
      SpendingPeriod.week => DateTime(today.year, today.month, today.day - 6),
      SpendingPeriod.month => month,
      SpendingPeriod.sixMonths => DateTime(today.year, today.month - 5, 1),
    };
    final end = period == SpendingPeriod.month ? monthEnd : today;
    final dayCount = switch (period) {
      SpendingPeriod.day => 1,
      SpendingPeriod.week => 7,
      SpendingPeriod.month => end.difference(start).inDays + 1,
      SpendingPeriod.sixMonths => today.difference(start).inDays + 1,
    };

    var total = 0;
    var count = 0;
    final categoryTotals = <String, int>{};
    final memberTotals = <String, int>{};
    for (final expense in expenses) {
      if (expense.category == 'Transfer') continue;
      final date = _dateOnly(expense.expenseDate);
      if (date.isBefore(start) || date.isAfter(end)) continue;

      total += expense.amountInCents;
      count++;
      categoryTotals.update(
        expense.category,
        (value) => value + expense.amountInCents,
        ifAbsent: () => expense.amountInCents,
      );
      memberTotals.update(
        expense.paidByUserId,
        (value) => value + expense.amountInCents,
        ifAbsent: () => expense.amountInCents,
      );
    }

    final byCategory = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final byMember = memberTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SpendingSummary(
      totalInCents: total,
      transactionCount: count,
      dayCount: dayCount,
      byCategory: byCategory,
      byMember: byMember,
    );
  }
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
