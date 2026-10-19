import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../shared/presentation/category_emoji.dart';
import '../../../../shared/presentation/money_format.dart';
import '../../../../shared/presentation/short_date.dart';
import '../../../../shared/presentation/widgets/empty_panel.dart';
import '../../../../shared/presentation/widgets/flow_widgets.dart';
import '../../../../shared/presentation/widgets/page_header.dart';
import '../../../rooms/models/room_ledger.dart';
import '../../../rooms/presentation/cubit/room_ledger_cubit.dart';
import '../../data/expense_repository.dart';
import '../../models/expense.dart';
import '../cubit/expense_cubit.dart';
import 'expense_detail_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({
    required this.currentUserId,
    required this.currentUserDisplayName,
    required this.expenseRepository,
    super.key,
  });

  final String currentUserId;
  final String currentUserDisplayName;
  final ExpenseRepository expenseRepository;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final _searchController = TextEditingController();
  String _category = 'All';
  String _memberId = '';
  String _date = 'All time';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ledgerState = context.watch<RoomLedgerCubit>().state;
    final entries = _entriesFrom(ledgerState.ledgers);
    final filtered = _filter(entries);
    final members = <String, String>{};
    for (final entry in entries) {
      for (final member in entry.ledger.members) {
        members.putIfAbsent(member.userId, () => member.displayName);
      }
    }
    final categories = <String>{
      'All',
      ...entries.map((entry) => entry.expense.category),
    }.toList();
    final totals = <String, int>{};
    for (final entry in filtered) {
      totals.update(
        entry.ledger.currency,
        (value) => value + entry.expense.amountInCents,
        ifAbsent: () => entry.expense.amountInCents,
      );
    }

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
                      child: Text(
                        'Total spending',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (final total in totals.entries)
                          Text(
                            formatCurrency(total.value, currency: total.key),
                          ),
                        if (totals.isEmpty) const Text('No expenses'),
                      ],
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
                    for (final category in categories)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category),
                          selected: _category == category,
                          onSelected: (_) =>
                              setState(() => _category = category),
                          showCheckmark: false,
                        ),
                      ),
                    PopupMenuButton<String>(
                      tooltip: 'Filter by member',
                      initialValue: _memberId,
                      onSelected: (value) => setState(() => _memberId = value),
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: '', child: Text('Everyone')),
                        for (final member in members.entries)
                          PopupMenuItem(
                            value: member.key,
                            child: Text(member.value),
                          ),
                      ],
                      child: Chip(
                        avatar: const Icon(
                          Icons.person_outline_rounded,
                          size: 16,
                        ),
                        label: Text(
                          _memberId.isEmpty
                              ? 'Everyone'
                              : members[_memberId] ?? 'Member',
                        ),
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
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'All time', child: Text('All time')),
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
                    '${filtered.length} expenses',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (ledgerState.isLoading && entries.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (filtered.isEmpty)
                const EmptyPanel(
                  icon: Icons.search_off_rounded,
                  title: 'No matching expenses',
                  message: 'Try another search or clear your filters.',
                )
              else
                for (final group in const ['Today', 'Yesterday', 'Earlier'])
                  ..._buildGroup(group, filtered),
            ],
          ),
        ),
      ],
    );
  }

  List<_HistoryEntry> _entriesFrom(List<RoomLedger> ledgers) => [
    for (final ledger in ledgers)
      for (final expense in ledger.expenses)
        if (expense.category != 'Transfer') _HistoryEntry(ledger, expense),
  ];

  List<_HistoryEntry> _filter(List<_HistoryEntry> entries) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final query = _searchController.text.trim().toLowerCase();
    return entries.where((entry) {
      final expense = entry.expense;
      final text =
          '${expense.note ?? ''} ${expense.category} ${_memberName(entry.ledger, expense.paidByUserId)}'
              .toLowerCase();
      final date = DateTime(
        expense.expenseDate.year,
        expense.expenseDate.month,
        expense.expenseDate.day,
      );
      final dateMatches = switch (_date) {
        'Today' => date == today,
        'This week' => !date.isBefore(
          today.subtract(Duration(days: now.weekday - 1)),
        ),
        _ => true,
      };
      return (query.isEmpty || text.contains(query)) &&
          (_category == 'All' || expense.category == _category) &&
          (_memberId.isEmpty || expense.paidByUserId == _memberId) &&
          dateMatches;
    }).toList()..sort(
      (a, b) => b.expense.expenseDate.compareTo(a.expense.expenseDate),
    );
  }

  List<Widget> _buildGroup(String group, List<_HistoryEntry> entries) {
    final grouped = entries
        .where((entry) => _dateGroup(entry.expense.expenseDate) == group)
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
              _ExpenseRow(
                entry: grouped[index],
                currentUserId: widget.currentUserId,
                currentUserDisplayName: widget.currentUserDisplayName,
                onTap: () => _openExpense(grouped[index]),
              ),
              if (index != grouped.length - 1)
                const Divider(height: 1, indent: 68, color: AppColors.paleBlue),
            ],
          ],
        ),
      ),
    ];
  }

  String _dateGroup(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final value = DateTime(date.year, date.month, date.day);
    if (value == today) return 'Today';
    if (value == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return 'Earlier';
  }

  Future<void> _openExpense(_HistoryEntry entry) async {
    final cubit = ExpenseCubit(widget.expenseRepository)
      ..loadExpenses(entry.ledger.room.id);
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: ExpenseDetailPage(
            room: entry.ledger.room,
            expense: entry.expense,
            members: entry.ledger.members,
            currentUserId: widget.currentUserId,
            currentUserDisplayName: widget.currentUserDisplayName,
          ),
        ),
      ),
    );
    await cubit.close();
    if (mounted) context.read<RoomLedgerCubit>().refresh();
  }

  String _memberName(RoomLedger ledger, String userId) {
    final name = ledger.memberName(userId);
    return name == 'Unknown member' && userId == widget.currentUserId
        ? widget.currentUserDisplayName
        : name;
  }
}

class _HistoryEntry {
  const _HistoryEntry(this.ledger, this.expense);
  final RoomLedger ledger;
  final Expense expense;
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({
    required this.entry,
    required this.currentUserId,
    required this.currentUserDisplayName,
    required this.onTap,
  });

  final _HistoryEntry entry;
  final String currentUserId;
  final String currentUserDisplayName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final expense = entry.expense;
    final memberName = entry.ledger.memberName(expense.paidByUserId);
    final paidByName =
        memberName == 'Unknown member' && expense.paidByUserId == currentUserId
        ? currentUserDisplayName
        : memberName;
    return InkWell(
      onTap: onTap,
      child: Padding(
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
              child: Icon(
                categoryIcon(expense.category),
                size: 20,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.note?.isNotEmpty == true
                        ? expense.note!
                        : expense.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Paid by $paidByName · ${formatShortDate(expense.expenseDate)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              formatCurrency(
                expense.amountInCents,
                currency: entry.ledger.currency,
              ),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
