import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../shared/presentation/category_emoji.dart';
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
        SurfaceCard(
          child: Column(
            children: [
              const SectionHeading('Spending by category'),
              const SizedBox(height: 12),
              if (summary.byCategory.isEmpty)
                const _EmptyLine('No spending in this period.')
              else
                for (var index = 0; index < summary.byCategory.length; index++)
                  _CategoryRow(
                    category: summary.byCategory[index].key,
                    amountInCents: summary.byCategory[index].value,
                    share: total == 0
                        ? 0
                        : summary.byCategory[index].value / total,
                    color: _categoryColor(index),
                    currency: currency,
                  ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeading('Spending by member'),
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

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.amountInCents,
    required this.share,
    required this.color,
    required this.currency,
  });

  final String category;
  final int amountInCents;
  final double share;
  final Color color;
  final String? currency;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.paleBlue,
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Icon(
              categoryIcon(category),
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: share,
                    minHeight: 5,
                    backgroundColor: AppColors.paleBlue,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 84,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatCurrency(amountInCents, currency: currency),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${(share * 100).round()}% share',
                  style: const TextStyle(fontSize: 10, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
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
