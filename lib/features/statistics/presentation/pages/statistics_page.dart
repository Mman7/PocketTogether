import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/mock_data.dart';
import '../../../../shared/presentation/widgets/empty_panel.dart';
import '../../../../shared/presentation/widgets/flow_widgets.dart';
import '../../../../shared/presentation/widgets/page_header.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  String _period = 'Month';

  @override
  Widget build(BuildContext context) {
    final periods = ['Day', 'Week', 'Month'];
    const categories = [
      _CategoryStat('Food & dining', '🍜', 452, 35, AppColors.primary),
      _CategoryStat('Transport', '🚆', 284, 22, AppColors.secondary),
      _CategoryStat('Travel', '🏨', 327, 25, AppColors.cyan),
      _CategoryStat('Shopping', '🛍️', 221, 18, Color(0xFFCBD4F7)),
    ];

    return CustomScrollView(
      key: const PageStorageKey('statistics-page'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          sliver: SliverList.list(
            children: [
              const PageHeader(
                title: 'Statistics',
                subtitle: 'A clearer picture of where it goes.',
              ),
              const SizedBox(height: 17),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.paleBlue,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    for (final period in periods)
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _period = period),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _period == period
                                  ? AppColors.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Text(
                              period,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: _period == period
                                    ? AppColors.white
                                    : AppColors.muted,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
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
                            'Monthly household',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        StatusPill(
                          label: switch (_period) {
                            'Day' => 'Today',
                            'Week' => 'This week',
                            _ => 'October',
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _period == 'Day'
                          ? 'RM 75.50'
                          : _period == 'Week'
                          ? 'RM 684'
                          : 'RM 2,340',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Row(
                      children: [
                        _SummaryMetric(
                          label: 'Daily average',
                          value: 'RM 75.50',
                        ),
                        SizedBox(width: 24),
                        _SummaryMetric(label: 'Transactions', value: '28'),
                      ],
                    ),
                    const SizedBox(height: 18),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: const Row(
                        children: [
                          Expanded(
                            flex: 35,
                            child: ColoredBox(
                              color: AppColors.primary,
                              child: SizedBox(height: 10),
                            ),
                          ),
                          SizedBox(width: 2),
                          Expanded(
                            flex: 22,
                            child: ColoredBox(
                              color: AppColors.secondary,
                              child: SizedBox(height: 10),
                            ),
                          ),
                          SizedBox(width: 2),
                          Expanded(
                            flex: 25,
                            child: ColoredBox(
                              color: AppColors.cyan,
                              child: SizedBox(height: 10),
                            ),
                          ),
                          SizedBox(width: 2),
                          Expanded(
                            flex: 18,
                            child: ColoredBox(
                              color: Color(0xFFCBD4F7),
                              child: SizedBox(height: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SurfaceCard(
                child: Column(
                  children: [
                    const SectionHeading(
                      'Spending by category',
                      trailing: Text(
                        'October',
                        style: TextStyle(fontSize: 11, color: AppColors.muted),
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final category in categories)
                      _CategoryRow(stat: category, maximum: 452),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeading(
                      'Spending by member',
                      trailing: Text(
                        'Total RM 2,340',
                        style: TextStyle(fontSize: 11, color: AppColors.muted),
                      ),
                    ),
                    const SizedBox(height: 14),
                    for (final member in roomMembers.take(3))
                      _MemberSpendingRow(member: member, maximum: 512),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const EmptyPanel(
                icon: Icons.insights_outlined,
                title: 'Room budgets are looking good',
                message: 'No spending limits have been set for this month.',
                compact: true,
              ),
            ],
          ),
        ),
      ],
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

class _CategoryStat {
  const _CategoryStat(
    this.name,
    this.emoji,
    this.total,
    this.share,
    this.color,
  );

  final String name;
  final String emoji;
  final double total;
  final int share;
  final Color color;
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.stat, required this.maximum});

  final _CategoryStat stat;
  final double maximum;

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
            child: Text(stat.emoji, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: stat.total / maximum,
                    minHeight: 5,
                    backgroundColor: AppColors.paleBlue,
                    color: stat.color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 74,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'RM ${stat.total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${stat.share}% share',
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

class _MemberSpendingRow extends StatelessWidget {
  const _MemberSpendingRow({required this.member, required this.maximum});

  final MemberMock member;
  final double maximum;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Column(
        children: [
          Row(
            children: [
              MemberAvatar(
                name: member.name,
                size: 25,
                color: member.color,
                border: false,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  member.name.split(' ').first,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                'RM ${member.spending.toStringAsFixed(0)}',
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
              value: member.spending / maximum,
              minHeight: 7,
              backgroundColor: AppColors.paleBlue,
              color: member.color.computeLuminance() > 0.8
                  ? AppColors.secondary
                  : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
