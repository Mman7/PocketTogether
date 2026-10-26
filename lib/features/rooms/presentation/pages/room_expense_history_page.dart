import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../shared/presentation/category_emoji.dart';
import '../../../../shared/presentation/money_format.dart';
import '../../../../shared/presentation/short_date.dart';
import '../../../../shared/presentation/widgets/flow_widgets.dart';
import '../../../expenses/models/expense.dart';
import '../../../expenses/presentation/cubit/expense_cubit.dart';
import '../../../expenses/presentation/cubit/expense_state.dart';
import '../../../expenses/presentation/pages/expense_detail_page.dart';
import '../../models/room.dart';
import '../../models/room_member.dart';

class RoomExpenseHistoryPage extends StatefulWidget {
  const RoomExpenseHistoryPage({
    required this.room,
    required this.members,
    required this.currentUserId,
    required this.currentUserDisplayName,
    super.key,
  });

  final Room room;
  final List<RoomMember> members;
  final String currentUserId;
  final String currentUserDisplayName;

  @override
  State<RoomExpenseHistoryPage> createState() => _RoomExpenseHistoryPageState();
}

class _RoomExpenseHistoryPageState extends State<RoomExpenseHistoryPage> {
  int? _selectedMonthKey;
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: AppColors.white,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    '${widget.room.name} expenses',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(width: 8, height: 8),
                ),
              ],
            ),
            Text(
              '${widget.members.length} active members · Shared room',
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: BlocBuilder<ExpenseCubit, ExpenseState>(
        builder: (context, state) {
          if (state.isLoading && state.expenses.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.errorMessage != null && state.expenses.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.errorMessage!),
                  TextButton(
                    onPressed: () => context.read<ExpenseCubit>().loadExpenses(
                      widget.room.id,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state.expenses.isEmpty) {
            return const Center(child: Text('No expenses yet.'));
          }

          final monthKeys =
              state.expenses
                  .map((expense) => _monthKey(expense.expenseDate))
                  .toSet()
                  .toList()
                ..sort((first, second) => second.compareTo(first));
          final selectedMonthKey = _selectedMonthKey ?? monthKeys.first;
          final categories = <String>{
            'All',
            ...state.expenses
                .where((expense) => expense.category != 'Transfer')
                .map((expense) => expense.category),
          }.toList();
          final selectedExpenses = state.expenses
              .where(
                (expense) => _monthKey(expense.expenseDate) == selectedMonthKey,
              )
              .where((expense) => expense.category != 'Transfer')
              .toList();
          final filteredExpenses = selectedExpenses
              .where(
                (expense) =>
                    _selectedCategory == 'All' ||
                    expense.category == _selectedCategory,
              )
              .toList();
          final groupedExpenses = <String, List<Expense>>{};
          final today = DateTime.now();
          for (final expense in state.expenses) {
            if (!filteredExpenses.contains(expense)) continue;
            final date = expense.expenseDate;
            final day = DateTime(date.year, date.month, date.day);
            final currentDay = DateTime(today.year, today.month, today.day);
            final label = day == currentDay
                ? 'Today'
                : day == currentDay.subtract(const Duration(days: 1))
                ? 'Yesterday'
                : _formatDate(date);
            groupedExpenses.putIfAbsent(label, () => []).add(expense);
          }
          for (final expenses in groupedExpenses.values) {
            expenses.sort(
              (first, second) =>
                  second.expenseDate.compareTo(first.expenseDate),
            );
          }
          final nameById = {
            for (final member in widget.members)
              member.userId: member.displayName,
          };
          final groupTotal = filteredExpenses.fold<int>(
            0,
            (sum, expense) => sum + expense.amountInCents,
          );
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              _RoomLedgerSummary(
                totalInCents: groupTotal,
                currency: widget.room.currency,
                monthLabel: _formatMonth(selectedMonthKey),
                transactionCount: filteredExpenses.length,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Categories',
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _selectedCategory = 'All';
                    }),
                    child: const Text('Clear filters'),
                  ),
                ],
              ),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, index) {
                    final category = categories[index];
                    return ChoiceChip(
                      label: Text(category),
                      selected: _selectedCategory == category,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = category),
                      showCheckmark: false,
                      avatar: Icon(
                        categoryIcon(category),
                        size: 16,
                        color: _selectedCategory == category
                            ? AppColors.primary
                            : Colors.black.withAlpha(255),
                      ),
                    );
                  },
                ),
              ),
              if (filteredExpenses.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 36),
                  child: Center(
                    child: Text(
                      'No expenses for this month',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ),
                )
              else
                for (final entry in groupedExpenses.entries) ...[
                  _RoomExpenseDateHeading(
                    label: entry.key,
                    monthLabel: _formatMonth(selectedMonthKey),
                    total: entry.value.fold<int>(
                      0,
                      (sum, expense) => sum + expense.amountInCents,
                    ),
                    currency: widget.room.currency,
                    onMonthSelected: entry.key == groupedExpenses.keys.first
                        ? () => _selectMonth(monthKeys)
                        : null,
                  ),
                  for (final expense in entry.value) ...[
                    RoomExpenseTile(
                      expense: expense,
                      amount: formatCurrency(
                        expense.amountInCents,
                        currency: widget.room.currency,
                      ),
                      paidByName:
                          nameById[expense.paidByUserId] ?? 'Unknown member',
                      createdByCurrentUser:
                          expense.createdByUserId == widget.currentUserId,
                      onTap: () => Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => BlocProvider.value(
                            value: context.read<ExpenseCubit>(),
                            child: ExpenseDetailPage(
                              room: widget.room,
                              expense: expense,
                              members: widget.members,
                              currentUserId: widget.currentUserId,
                              currentUserDisplayName:
                                  widget.currentUserDisplayName,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'All transactions settled and synced',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  int _monthKey(DateTime date) => date.year * 100 + date.month;

  Future<void> _selectMonth(List<int> availableMonthKeys) async {
    final selectedMonthKey = await showDialog<int>(
      context: context,
      builder: (_) => _MonthPickerDialog(monthKeys: availableMonthKeys),
    );
    if (!mounted || selectedMonthKey == null) return;
    setState(() => _selectedMonthKey = selectedMonthKey);
  }

  String _formatMonth(int monthKey) {
    const monthNames = [
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
    final year = monthKey ~/ 100;
    final month = monthKey % 100;
    return '${monthNames[month - 1]} $year';
  }

  String _formatDate(DateTime date) =>
      '${date.day} ${_formatMonth(_monthKey(date)).split(' ').first}';
}

class _RoomLedgerSummary extends StatelessWidget {
  const _RoomLedgerSummary({
    required this.totalInCents,
    required this.currency,
    required this.monthLabel,
    required this.transactionCount,
  });

  final int totalInCents;
  final String? currency;
  final String monthLabel;
  final int transactionCount;

  @override
  Widget build(BuildContext context) {
    final averageInCents = transactionCount == 0
        ? null
        : (totalInCents / transactionCount).round();
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF172238), Color(0xFF0D172B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x220B1425),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TOTAL GROUP SPENDING',
                        style: TextStyle(
                          color: Color(0xFF9AA8BC),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.7,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        _formatCurrencyWithDecimals(
                          totalInCents,
                          currency: currency,
                        ),
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        monthLabel,
                        style: const TextStyle(
                          color: Color(0xFF9AA8BC),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_downward_rounded,
                  color: Color(0xFF50D6B0),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Divider(color: Color(0x334A5A73), height: 1),
            ),
            Row(
              children: [
                Expanded(
                  child: _RoomSummaryMetric(
                    label: 'TRANSACTIONS',
                    value: '$transactionCount',
                  ),
                ),
                Expanded(
                  child: _RoomSummaryMetric(
                    label: 'AVG. EXPENSE',
                    value: averageInCents == null
                        ? '—'
                        : _formatCurrencyWithDecimals(
                            averageInCents,
                            currency: currency,
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomSummaryMetric extends StatelessWidget {
  const _RoomSummaryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF9AA8BC),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: 5),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

String _formatCurrencyWithDecimals(int amountInCents, {String? currency}) {
  final formatted = formatCurrency(amountInCents, currency: currency);
  return amountInCents.abs() % 100 == 0 ? '$formatted.00' : formatted;
}

class _RoomExpenseDateHeading extends StatelessWidget {
  const _RoomExpenseDateHeading({
    required this.label,
    required this.monthLabel,
    required this.total,
    required this.currency,
    this.onMonthSelected,
  });

  final String label;
  final String monthLabel;
  final int total;
  final String? currency;
  final VoidCallback? onMonthSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
          if (onMonthSelected != null)
            Row(
              children: [
                StatusPill(label: monthLabel),
                IconButton(
                  icon: const Icon(Icons.calendar_month_rounded, size: 16),
                  tooltip: 'Choose month',
                  onPressed: onMonthSelected,
                ),
              ],
            ),
          const Spacer(),
          StatusPill(label: formatCurrency(total, currency: currency)),
        ],
      ),
    );
  }
}

class _MonthPickerDialog extends StatelessWidget {
  const _MonthPickerDialog({required this.monthKeys});

  final List<int> monthKeys;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choose month'),
      content: SizedBox(
        width: 320,
        child: GridView.builder(
          shrinkWrap: true,
          itemCount: monthKeys.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.8,
          ),
          itemBuilder: (context, index) {
            final monthKey = monthKeys[index];
            return OutlinedButton(
              onPressed: () => Navigator.of(context).pop(monthKey),
              child: Text(_formatMonth(monthKey), textAlign: TextAlign.center),
            );
          },
        ),
      ),
    );
  }

  String _formatMonth(int monthKey) {
    const monthNames = [
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
    final month = monthKey % 100;
    return '${monthNames[month - 1].substring(0, 3)} ${monthKey ~/ 100}';
  }
}

class RoomExpenseTile extends StatelessWidget {
  const RoomExpenseTile({
    required this.expense,
    required this.amount,
    required this.paidByName,
    required this.createdByCurrentUser,
    required this.onTap,
    super.key,
  });

  final Expense expense;
  final String amount;
  final String paidByName;
  final bool createdByCurrentUser;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final description = expense.note?.trim();
    final createdTime = formatShortTime(expense.createdAt);
    return SurfaceCard(
      onTap: onTap,
      color: createdByCurrentUser ? AppColors.expenseMine : AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(
              categoryIcon(expense.category),
              size: 20,
              color: createdByCurrentUser
                  ? Colors.deepPurpleAccent
                  : AppColors.primary,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        description == null || description.isEmpty
                            ? expense.category
                            : description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (createdByCurrentUser)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.expenseMineBadge,
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            child: Text(
                              'You',
                              style: TextStyle(
                                color: Colors.deepPurpleAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  'Paid by $paidByName· ${formatShortDate(expense.expenseDate)}'
                  '${createdTime == null ? '' : ' · $createdTime'}',
                  style: const TextStyle(fontSize: 10, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amount,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
