import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pocket_together/shared/presentation/widgets/ambient_background.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../shared/presentation/category_emoji.dart';
import '../../../../shared/presentation/money_format.dart';
import '../../../../shared/presentation/widgets/flow_widgets.dart';
import '../../../rooms/models/room.dart';
import '../../../rooms/models/room_member.dart';
import '../../models/expense.dart';
import '../cubit/expense_cubit.dart';
import 'add_expense_page.dart';

class ExpenseDetailPage extends StatelessWidget {
  const ExpenseDetailPage({
    required this.room,
    required this.expense,
    required this.members,
    required this.currentUserId,
    required this.currentUserDisplayName,
    super.key,
  });

  final Room room;
  final Expense expense;
  final List<RoomMember> members;
  final String currentUserId;
  final String currentUserDisplayName;

  @override
  Widget build(BuildContext context) {
    final expenseState = context.watch<ExpenseCubit>().state;
    var currentExpense = expense;
    final isUserCreated = currentExpense.createdByUserId == currentUserId;
    for (final savedExpense in expenseState.expenses) {
      if (savedExpense.id == expense.id) {
        currentExpense = savedExpense;
        break;
      }
    }

    return AmbientBackground(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Expense details',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          children: [
            SurfaceCard(
              padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
              child: Column(
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: AppColors.paleBlue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      categoryIcon(currentExpense.category),
                      size: 31,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  StatusPill(label: currentExpense.category),
                  const SizedBox(height: 6),
                  Text(
                    formatCurrency(
                      currentExpense.amountInCents,
                      currency: room.currency,
                    ),
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    currentExpense.note?.trim().isNotEmpty == true
                        ? currentExpense.note!.trim()
                        : currentExpense.category,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _DetailRow(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Paid by',
                    value: _memberName(currentExpense.paidByUserId),
                  ),
                  const Divider(
                    height: 1,
                    indent: 58,
                    endIndent: 16,
                    color: AppColors.paleBlue,
                  ),
                  if (currentExpense.category == 'Transfer') ...[
                    _DetailRow(
                      icon: Icons.swap_horiz_rounded,
                      label: 'Transfer method',
                      value: currentExpense.transferMethod ?? 'Bank transfer',
                    ),
                    const Divider(
                      height: 1,
                      indent: 58,
                      endIndent: 16,
                      color: AppColors.paleBlue,
                    ),
                    _DetailRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Transfer to',
                      value: currentExpense.transferToUserId == null
                          ? 'Unknown'
                          : _memberName(currentExpense.transferToUserId!),
                    ),
                    const Divider(
                      height: 1,
                      indent: 58,
                      endIndent: 16,
                      color: AppColors.paleBlue,
                    ),
                  ],
                  _DetailRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Added by',
                    value: _memberName(currentExpense.createdByUserId),
                  ),
                  const Divider(
                    height: 1,
                    indent: 58,
                    endIndent: 16,
                    color: AppColors.paleBlue,
                  ),
                  _DetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Date',
                    value:
                        '${currentExpense.expenseDate.day} ${_month(currentExpense.expenseDate.month)} ${currentExpense.expenseDate.year}',
                  ),
                  const Divider(
                    height: 1,
                    indent: 58,
                    endIndent: 16,
                    color: AppColors.paleBlue,
                  ),
                  _DetailRow(
                    icon: Icons.schedule_rounded,
                    label: 'Time',
                    value: currentExpense.createdAt == null
                        ? 'Recently'
                        : '${currentExpense.createdAt!.hour.toString().padLeft(2, '0')}:${currentExpense.createdAt!.minute.toString().padLeft(2, '0')}',
                  ),
                  const Divider(
                    height: 1,
                    indent: 58,
                    endIndent: 16,
                    color: AppColors.paleBlue,
                  ),
                  if (currentExpense.category != 'Transfer')
                    _DetailRow(
                      icon: Icons.groups_outlined,
                      label: 'Split',
                      value: currentExpense.splitAmountsInCents.length == 1
                          ? 'Just me'
                          : 'Equally · ${currentExpense.splitAmountsInCents.length} people',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            if (expenseState.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  expenseState.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
            if (isUserCreated)
              PrimaryButton(
                label: 'Edit expense',
                icon: Icons.edit_outlined,
                onPressed: () => _edit(context, currentExpense),
              ),
            const SizedBox(height: 10),
            if (isUserCreated)
              OutlinedButton.icon(
                onPressed: () => _confirmDelete(context, currentExpense),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Delete expense'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 50),
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: Color(0xFFE8BFC0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.control),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _month(int month) => const [
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
  ][month - 1];

  String _memberName(String userId) {
    for (final member in members) {
      if (member.userId == userId) return member.displayName;
    }
    if (userId == currentUserId) return currentUserDisplayName;
    return 'Unknown member';
  }

  Future<void> _edit(BuildContext context, Expense currentExpense) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: context.read<ExpenseCubit>(),
          child: AddExpensePage(
            room: room,
            members: members,
            currentUserId: currentUserId,
            currentUserDisplayName: currentUserDisplayName,
            expense: currentExpense,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    Expense currentExpense,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
        title: const Text('Delete this expense?'),
        content: Text(
          '“${currentExpense.note?.trim().isNotEmpty == true ? currentExpense.note : currentExpense.category}” will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep expense'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final deleted = await context.read<ExpenseCubit>().deleteExpense(
        room.id,
        currentExpense.id,
      );
      if (deleted && context.mounted) Navigator.pop(context);
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 19, color: AppColors.primary),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
