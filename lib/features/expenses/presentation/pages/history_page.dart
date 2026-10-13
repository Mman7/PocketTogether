import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/mock_data.dart';
import '../../../../shared/presentation/widgets/empty_panel.dart';
import '../../../../shared/presentation/widgets/flow_widgets.dart';
import '../../../../shared/presentation/widgets/page_header.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final _searchController = TextEditingController();
  String _category = 'All';
  String _member = 'Everyone';
  String _date = 'October 2026';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expenses = householdExpenses.where((expense) {
      final matchesSearch =
          '${expense.title} ${expense.category} ${expense.paidBy}'
              .toLowerCase()
              .contains(_searchController.text.toLowerCase());
      final matchesCategory =
          _category == 'All' || expense.category == _category;
      final matchesMember = _member == 'Everyone' || expense.paidBy == _member;
      final matchesDate =
          _date == 'October 2026' ||
          (_date == 'Today' && expense.dateGroup == 'Today') ||
          (_date == 'This week' && expense.dateGroup != 'Earlier');
      return matchesSearch && matchesCategory && matchesMember && matchesDate;
    }).toList();

    return CustomScrollView(
      key: const PageStorageKey('history-page'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          sliver: SliverList.list(
            children: [
              const PageHeader(
                title: 'History',
                subtitle: 'Every shared expense, in one clear ledger.',
              ),
              const SizedBox(height: 18),
              SurfaceCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.receipt_long_rounded,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Monthly Household',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Total spending · October',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'RM 2,340',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search expenses',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final category in [
                      'All',
                      'Food',
                      'Transport',
                      'Travel',
                      'Coffee',
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category),
                          selected: _category == category,
                          onSelected: (_) =>
                              setState(() => _category = category),
                          showCheckmark: false,
                          side: BorderSide(
                            color: _category == category
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                          backgroundColor: AppColors.white,
                          selectedColor: AppColors.paleBlue,
                          labelStyle: TextStyle(
                            color: _category == category
                                ? AppColors.primary
                                : AppColors.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    PopupMenuButton<String>(
                      tooltip: 'Filter by member',
                      initialValue: _member,
                      onSelected: (value) => setState(() => _member = value),
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'Everyone',
                          child: Text('Everyone'),
                        ),
                        PopupMenuItem(value: 'Eric', child: Text('Eric')),
                        PopupMenuItem(value: 'John', child: Text('John')),
                        PopupMenuItem(value: 'Amy', child: Text('Amy')),
                      ],
                      child: Chip(
                        avatar: const Icon(
                          Icons.person_outline_rounded,
                          size: 16,
                        ),
                        label: Text(_member),
                        backgroundColor: AppColors.white,
                        side: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_month_outlined,
                    size: 17,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 7),
                  PopupMenuButton<String>(
                    tooltip: 'Filter by date',
                    onSelected: (value) => setState(() => _date = value),
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'October 2026',
                        child: Text('October 2026'),
                      ),
                      PopupMenuItem(
                        value: 'This week',
                        child: Text('This week'),
                      ),
                      PopupMenuItem(value: 'Today', child: Text('Today')),
                    ],
                    child: Row(
                      children: [
                        Text(
                          _date,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${expenses.length} expenses',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (expenses.isEmpty)
                const EmptyPanel(
                  icon: Icons.search_off_rounded,
                  title: 'No matching expenses',
                  message: 'Try another search or clear your filters.',
                )
              else
                for (final group in ['Today', 'Yesterday', 'Earlier'])
                  ..._buildExpenseGroup(group, expenses),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildExpenseGroup(String group, List<ExpenseMock> expenses) {
    final grouped = expenses
        .where((expense) => expense.dateGroup == group)
        .toList();
    if (grouped.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(
          group,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ),
      SurfaceCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (var index = 0; index < grouped.length; index++) ...[
              _ExpenseRow(expense: grouped[index]),
              if (index != grouped.length - 1)
                const Divider(height: 1, indent: 68, color: AppColors.paleBlue),
            ],
          ],
        ),
      ),
    ];
  }
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({required this.expense});

  final ExpenseMock expense;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.paleBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(expense.emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  'Paid by ${expense.paidBy} · ${expense.time}',
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatMoney(expense.amount, currency: 'RM'),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                expense.category,
                style: const TextStyle(fontSize: 10, color: AppColors.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
