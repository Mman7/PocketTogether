import '../../expenses/models/expense.dart';

enum SpendingPeriod {
  day('Day', 'Today'),
  week('Week', 'This week'),
  month('Month', 'This month');

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
  }) {
    final today = _dateOnly(now ?? DateTime.now());
    final start = switch (period) {
      SpendingPeriod.day => today,
      SpendingPeriod.week => DateTime(today.year, today.month, today.day - 6),
      SpendingPeriod.month => DateTime(today.year, today.month, 1),
    };
    final dayCount = switch (period) {
      SpendingPeriod.day => 1,
      SpendingPeriod.week => 7,
      SpendingPeriod.month => today.day,
    };

    var total = 0;
    var count = 0;
    final categoryTotals = <String, int>{};
    final memberTotals = <String, int>{};
    for (final expense in expenses) {
      if (expense.category == 'Transfer') continue;
      final date = _dateOnly(expense.expenseDate);
      if (date.isBefore(start) || date.isAfter(today)) continue;

      total += expense.amountInCents;
      count++;
      categoryTotals.update(
        expense.category,
        (value) => value + expense.amountInCents,
        ifAbsent: () => expense.amountInCents,
      );
      for (final split in expense.splitAmountsInCents.entries) {
        memberTotals.update(
          split.key,
          (value) => value + split.value,
          ifAbsent: () => split.value,
        );
      }
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
