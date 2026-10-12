import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/mock_data.dart';
import '../../../../shared/presentation/widgets/flow_widgets.dart';

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
              const _PageHeader(
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
                const _EmptyPanel(
                  icon: Icons.search_off_rounded,
                  title: 'No matching expenses',
                  message: 'Try another search or clear your filters.',
                )
              else
                for (final group in ['Today', 'Yesterday', 'Earlier']) ...[
                  ..._buildExpenseGroup(group, expenses),
                ],
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
              _ExpenseRow(expense: grouped[index], currency: 'RM'),
              if (index != grouped.length - 1)
                const Divider(height: 1, indent: 68, color: AppColors.paleBlue),
            ],
          ],
        ),
      ),
    ];
  }
}

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
              const _PageHeader(
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
              const _EmptyPanel(
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

class ProfilePage extends StatefulWidget {
  const ProfilePage({required this.onSignOut, super.key});

  final Future<void> Function() onSignOut;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _notifications = true;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      key: const PageStorageKey('profile-page'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          sliver: SliverList.list(
            children: [
              const _PageHeader(
                title: 'Profile',
                subtitle: 'Your account and preferences.',
              ),
              const SizedBox(height: 20),
              SurfaceCard(
                child: Row(
                  children: [
                    const MemberAvatar(
                      name: 'Eric Wong',
                      size: 60,
                      color: Color(0xFFD9E8FF),
                      border: false,
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Eric Wong',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'eric.wong@email.com',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _message(
                        context,
                        'Profile editing is available in this preview.',
                      ),
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit profile',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const SectionHeading('Preferences'),
              const SizedBox(height: 8),
              SurfaceCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      value: _notifications,
                      onChanged: (value) =>
                          setState(() => _notifications = value),
                      title: const Text(
                        'Notifications',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: const Text(
                        'Room updates and settlement reminders',
                        style: TextStyle(fontSize: 11),
                      ),
                      activeThumbColor: AppColors.primary,
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _SettingsRow(
                      icon: Icons.currency_exchange_rounded,
                      title: 'Default currency',
                      value: 'MYR',
                      onTap: () => _chooseCurrency(context),
                    ),
                    const Divider(height: 1, indent: 58, endIndent: 16),
                    _SettingsRow(
                      icon: Icons.palette_outlined,
                      title: 'Theme',
                      value: 'System',
                      onTap: () => _chooseTheme(context),
                    ),
                    const Divider(height: 1, indent: 58, endIndent: 16),
                    _SettingsRow(
                      icon: Icons.lock_outline_rounded,
                      title: 'Account settings',
                      onTap: () => _message(
                        context,
                        'Your account settings are up to date.',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const SectionHeading('Help & account'),
              const SizedBox(height: 8),
              SurfaceCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _SettingsRow(
                      icon: Icons.help_outline_rounded,
                      title: 'Help center',
                      onTap: () => _message(context, 'Help center opened.'),
                    ),
                    const Divider(height: 1, indent: 58, endIndent: 16),
                    _SettingsRow(
                      icon: Icons.logout_rounded,
                      title: 'Sign out',
                      destructive: true,
                      onTap: () async {
                        try {
                          await widget.onSignOut();
                        } catch (_) {
                          if (context.mounted) {
                            _message(context, 'Unable to sign out. Try again.');
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _chooseCurrency(BuildContext context) {
    _showChoices(context, 'Default currency', [
      'MYR · Malaysian Ringgit',
      'JPY · Japanese Yen',
      'THB · Thai Baht',
    ]);
  }

  void _chooseTheme(BuildContext context) {
    _showChoices(context, 'Appearance', ['System', 'Light']);
  }

  void _showChoices(BuildContext context, String title, List<String> choices) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              for (final choice in choices)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(choice),
                  trailing: choice.startsWith('MYR') || choice == 'System'
                      ? const Icon(
                          Icons.check_rounded,
                          color: AppColors.primary,
                        )
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    _message(
                      this.context,
                      '$choice selected for this preview.',
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({required this.expense, required this.currency});

  final ExpenseMock expense;
  final String currency;

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
                formatMoney(expense.amount, currency: currency),
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

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    this.value,
    this.destructive = false,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? value;
  final bool destructive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.danger : AppColors.ink;
    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color: destructive ? AppColors.danger : AppColors.primary,
        size: 21,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: value == null
          ? Icon(
              Icons.chevron_right_rounded,
              color: AppColors.muted.withValues(alpha: 0.7),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value!,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(width: 3),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.muted,
                  size: 18,
                ),
              ],
            ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
      ],
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    required this.icon,
    required this.title,
    required this.message,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: EdgeInsets.all(compact ? 15 : 24),
      child: Row(
        children: [
          Icon(icon, size: 25, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void _message(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
