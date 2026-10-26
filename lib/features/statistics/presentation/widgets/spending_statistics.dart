import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../shared/presentation/money_format.dart';
import '../../../../shared/presentation/widgets/flow_widgets.dart';
import '../../../expenses/models/expense.dart';
import '../../../rooms/models/room_member.dart';
import '../../domain/spending_summary.dart';

/// Spending breakdown for one room, with a Day / Week / Month selector.
class SpendingStatistics extends StatefulWidget {
  const SpendingStatistics({
    required this.currency,
    required this.members,
    required this.expenses,
    super.key,
  });

  final String? currency;
  final List<RoomMember> members;
  final List<Expense> expenses;

  @override
  State<SpendingStatistics> createState() => _SpendingStatisticsState();
}

class _SpendingStatisticsState extends State<SpendingStatistics> {
  SpendingPeriod _period = SpendingPeriod.month;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  static const _categoryColors = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.cyan,
    AppColors.success,
    AppColors.danger,
  ];

  @override
  Widget build(BuildContext context) {
    final summary = SpendingSummary.forPeriod(
      expenses: widget.expenses,
      period: _period,
      selectedMonth: _selectedMonth,
    );
    final currency = widget.currency;
    final nameById = {
      for (final member in widget.members) member.userId: member.displayName,
    };
    final total = summary.totalInCents;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PeriodToggle(
          selected: _period,
          onChanged: (period) => setState(() => _period = period),
        ),
        if (_period == SpendingPeriod.month) ...[
          const SizedBox(height: 10),
          _MonthSelector(
            month: _selectedMonth,
            onChanged: (month) => setState(() => _selectedMonth = month),
          ),
        ],
        const SizedBox(height: 14),
        SurfaceCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Total spending',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ),
                  StatusPill(
                    label: _period.pillLabel,
                    color: AppColors.paleBlue,
                    textColor: Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                formatCurrency(total, currency: currency),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  _SummaryMetric(
                    label: 'Daily average',
                    value: formatCurrency(
                      summary.dailyAverageInCents,
                      currency: currency,
                    ),
                  ),
                  const SizedBox(width: 24),
                  _SummaryMetric(
                    label: 'Transactions',
                    value: '${summary.transactionCount}',
                  ),
                ],
              ),
              if (total > 0) ...[
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      for (
                        var index = 0;
                        index < summary.byCategory.length;
                        index++
                      ) ...[
                        if (index > 0) const SizedBox(width: 2),
                        Expanded(
                          flex: summary.byCategory[index].value,
                          child: ColoredBox(
                            color: _categoryColor(index),
                            child: const SizedBox(height: 10),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SpendingTrendChart(
          expenses: widget.expenses,
          currency: currency,
          period: _period,
          anchorMonth: _selectedMonth,
        ),
        const SizedBox(height: 14),
        _CategoryPieChart(
          categories: summary.byCategory,
          total: total,
          currency: currency,
          colorForIndex: _categoryColor,
        ),
        const SizedBox(height: 14),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeading(
                'Spending by member',
                icon: Icons.person_rounded,
              ),
              const SizedBox(height: 14),
              if (summary.byMember.isEmpty)
                const _EmptyLine('No spending in this period.')
              else
                for (final entry in summary.byMember)
                  _MemberRow(
                    name: nameById[entry.key] ?? 'Unknown member',
                    amountInCents: entry.value,
                    share: total == 0 ? 0 : entry.value / total,
                    currency: currency,
                  ),
            ],
          ),
        ),
      ],
    );
  }

  Color _categoryColor(int index) =>
      _categoryColors[index % _categoryColors.length];
}

class _CategoryPieChart extends StatelessWidget {
  const _CategoryPieChart({
    required this.categories,
    required this.total,
    required this.currency,
    required this.colorForIndex,
  });

  final List<MapEntry<String, int>> categories;
  final int total;
  final String? currency;
  final Color Function(int index) colorForIndex;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeading(
            'Spending distribution',
            icon: Icons.pie_chart_rounded,
          ),
          const SizedBox(height: 5),
          const Text(
            'What the room spent money on',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 18),
          if (total == 0 || categories.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 34),
              child: Center(child: _EmptyLine('No category spending yet.')),
            )
          else ...[
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: 52,
                  sectionsSpace: 3,
                  sections: [
                    for (var index = 0; index < categories.length; index++)
                      PieChartSectionData(
                        value: categories[index].value.toDouble(),
                        color: colorForIndex(index),
                        radius: 66,
                        title:
                            '${(categories[index].value / total * 100).round()}%',
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                  pieTouchData: PieTouchData(
                    enabled: true,
                    touchCallback: (event, response) {},
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            for (var index = 0; index < categories.length; index++)
              _CategoryLegendRow(
                category: categories[index].key,
                amountInCents: categories[index].value,
                percentage: categories[index].value / total,
                currency: currency,
                color: colorForIndex(index),
              ),
          ],
        ],
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({required this.month, required this.onChanged});

  final DateTime month;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => onChanged(DateTime(month.year, month.month - 1)),
          icon: const Icon(Icons.chevron_left_rounded),
          tooltip: 'Previous month',
        ),
        Expanded(
          child: Text(
            _label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        IconButton(
          onPressed: _isCurrentMonth
              ? null
              : () => onChanged(DateTime(month.year, month.month + 1)),
          icon: const Icon(Icons.chevron_right_rounded),
          tooltip: 'Next month',
        ),
      ],
    );
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return month.year == now.year && month.month == now.month;
  }

  String get _label {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${names[month.month - 1]} ${month.year}';
  }
}

class _CategoryLegendRow extends StatelessWidget {
  const _CategoryLegendRow({
    required this.category,
    required this.amountInCents,
    required this.percentage,
    required this.currency,
    required this.color,
  });

  final String category;
  final int amountInCents;
  final double percentage;
  final String? currency;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              category,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            '${(percentage * 100).toStringAsFixed(1)}%',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formatCurrency(amountInCents, currency: currency),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _TrendBucket {
  const _TrendBucket(this.label, this.total);

  final String label;
  final int total;
}

class _SpendingTrendChart extends StatelessWidget {
  const _SpendingTrendChart({
    required this.expenses,
    required this.currency,
    required this.period,
    required this.anchorMonth,
  });

  final List<Expense> expenses;
  final String? currency;
  final SpendingPeriod period;
  final DateTime anchorMonth;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final buckets = _buckets(now);
    final maximum = buckets.fold<int>(
      0,
      (value, bucket) => bucket.total > value ? bucket.total : value,
    );

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeading('Spending trend', icon: Icons.bar_chart_rounded),
          const SizedBox(height: 5),
          Text(
            _subtitle,
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 18),
          if (maximum == 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 34),
              child: Center(child: _EmptyLine('No spending in this period.')),
            )
          else
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  maxY: maximum * 1.2,
                  minY: 0,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _interval(maximum),
                    getDrawingHorizontalLine: (_) =>
                        const FlLine(color: AppColors.paleBlue, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= buckets.length) {
                            return const SizedBox.shrink();
                          }
                          if (period == SpendingPeriod.month &&
                              index % 5 != 0 &&
                              index != buckets.length - 1) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              buckets[index].label,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${buckets[groupIndex].label}\n${formatCurrency(buckets[groupIndex].total, currency: currency)}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      },
                    ),
                  ),
                  barGroups: [
                    for (var index = 0; index < buckets.length; index++)
                      BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: buckets[index].total.toDouble(),
                            width: period == SpendingPeriod.month ? 9 : 20,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(5),
                            ),
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  double _interval(int maximum) {
    final interval = maximum / 4;
    return interval < 1 ? 1 : interval;
  }

  String get _subtitle => switch (period) {
    SpendingPeriod.day => 'Last seven days',
    SpendingPeriod.week => 'Last six weeks',
    SpendingPeriod.month => 'Current month by day',
    SpendingPeriod.sixMonths => 'Last six months',
  };

  List<_TrendBucket> _buckets(DateTime now) {
    final dates = switch (period) {
      SpendingPeriod.day => List.generate(
        7,
        (index) => DateTime(now.year, now.month, now.day - 6 + index),
      ),
      SpendingPeriod.week => List.generate(
        6,
        (index) => DateTime(
          now.year,
          now.month,
          now.day - (now.weekday - 1) - 35 + index * 7,
        ),
      ),
      SpendingPeriod.month => List.generate(
        _daysInSelectedMonth(now),
        (index) => DateTime(anchorMonth.year, anchorMonth.month, index + 1),
      ),
      SpendingPeriod.sixMonths => List.generate(
        6,
        (index) => DateTime(now.year, now.month - 5 + index),
      ),
    };

    return [
      for (final start in dates)
        _TrendBucket(
          _labelFor(start),
          expenses
              .where(
                (expense) =>
                    expense.category != 'Transfer' &&
                    _belongsToBucket(expense.expenseDate, start),
              )
              .fold<int>(0, (sum, expense) => sum + expense.amountInCents),
        ),
    ];
  }

  bool _belongsToBucket(DateTime date, DateTime start) {
    if (period == SpendingPeriod.day || period == SpendingPeriod.month) {
      return date.year == start.year &&
          date.month == start.month &&
          date.day == start.day;
    }
    if (period == SpendingPeriod.week) {
      final end = start.add(const Duration(days: 7));
      return !date.isBefore(start) && date.isBefore(end);
    }
    return date.year == start.year && date.month == start.month;
  }

  String _labelFor(DateTime date) {
    if (period == SpendingPeriod.day || period == SpendingPeriod.month) {
      return '${date.month}/${date.day}';
    }
    if (period == SpendingPeriod.week) return '${date.month}/${date.day}';
    const labels = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return labels[date.month - 1];
  }

  int _daysInSelectedMonth(DateTime now) {
    final isCurrentMonth =
        anchorMonth.year == now.year && anchorMonth.month == now.month;
    if (isCurrentMonth) return now.day;
    return DateTime(anchorMonth.year, anchorMonth.month + 1, 0).day;
  }
}

class _PeriodToggle extends StatelessWidget {
  const _PeriodToggle({required this.selected, required this.onChanged});

  final SpendingPeriod selected;
  final ValueChanged<SpendingPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.paleBlue,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final period in SpendingPeriod.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(period),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected == period
                        ? AppColors.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    period.toggleLabel,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: selected == period
                          ? AppColors.white
                          : AppColors.muted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.muted),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.name,
    required this.amountInCents,
    required this.share,
    required this.currency,
  });

  final String name;
  final int amountInCents;
  final double share;
  final String? currency;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              MemberAvatar(
                name: name,
                size: 25,
                color: AppColors.paleBlue,
                border: false,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                formatCurrency(amountInCents, currency: currency),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: share,
              minHeight: 7,
              backgroundColor: AppColors.paleBlue,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        message,
        style: const TextStyle(fontSize: 12, color: AppColors.muted),
      ),
    );
  }
}
