import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../shared/presentation/category_emoji.dart';
import '../../../../shared/presentation/money_format.dart';
import '../../../../shared/presentation/short_date.dart';
import '../../../../shared/presentation/widgets/flow_widgets.dart';
import '../../../expenses/models/expense.dart';
import '../../../expenses/presentation/cubit/expense_cubit.dart';
import '../../../expenses/presentation/cubit/expense_state.dart';
import '../../models/room_member.dart';

class RoomExpensesSection extends StatelessWidget {
  const RoomExpensesSection({
    required this.roomCurrency,
    required this.members,
    required this.currentUserId,
    required this.onViewAll,
    required this.onExpenseTap,
    super.key,
  });

  final String? roomCurrency;
  final List<RoomMember> members;
  final String currentUserId;
  final VoidCallback onViewAll;
  final ValueChanged<Expense> onExpenseTap;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpenseCubit, ExpenseState>(
      builder: (context, state) {
        final today = state.expenses.where((expense) {
          final date = expense.expenseDate;
          final now = DateTime.now();
          return date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;
        }).toList();
        final nameById = {
          for (final member in members) member.userId: member.displayName,
        };

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeading(
              "Today's expenses",
              icon: Icons.wallet,
              trailing: TextButton(
                onPressed: onViewAll,
                child: const Text('View all'),
              ),
            ),
            const SizedBox(height: 5),
            if (state.isLoading && state.expenses.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.expenses.isEmpty && state.errorMessage == null)
              const _RoomEmptyState()
            else
              for (final expense in today.take(5)) ...[
                RoomExpenseTile(
                  expense: expense,
                  amount: formatCurrency(
                    expense.amountInCents,
                    currency: roomCurrency,
                  ),
                  paidByName:
                      nameById[expense.paidByUserId] ?? 'Unknown member',
                  createdByCurrentUser:
                      expense.createdByUserId == currentUserId,
                  onTap: () => onExpenseTap(expense),
                ),
                const SizedBox(height: 8),
              ],
            if (!state.isLoading && state.expenses.isNotEmpty && today.isEmpty)
              const Text(
                'No expenses today',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted),
              ),
          ],
        );
      },
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                MemberAvatar(name: paidByName, size: 55),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: createdByCurrentUser
                          ? Colors.deepPurpleAccent
                          : AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.white, width: 3),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      categoryIcon(expense.category),
                      size: 13,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  description == null || description.isEmpty
                      ? expense.category
                      : description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  paidByName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                if (createdByCurrentUser) ...[
                  const Text(
                    'You',
                    style: TextStyle(
                      color: Colors.deepPurpleAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                createdTime ?? formatShortDate(expense.expenseDate),
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoomEmptyState extends StatelessWidget {
  const _RoomEmptyState();

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        children: [
          Lottie.asset(
            'assets/lottie/no_result.lottie',
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          ),
          const SizedBox(height: 3),
          const Text(
            'Add the first shared expense to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
