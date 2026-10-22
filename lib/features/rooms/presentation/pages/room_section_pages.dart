import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../shared/presentation/money_format.dart';
import '../../../../shared/presentation/widgets/flow_widgets.dart';
import '../../../expenses/domain/balance_calculator.dart';
import '../../../expenses/models/expense.dart';
import '../../../expenses/presentation/cubit/expense_cubit.dart';
import '../../../expenses/presentation/cubit/expense_state.dart';
import '../../../statistics/presentation/widgets/spending_statistics.dart';
import '../../models/room.dart';
import '../../models/room_member.dart';

class RoomMembersPage extends StatelessWidget {
  const RoomMembersPage({
    required this.roomName,
    required this.members,
    super.key,
  });

  final String roomName;
  final List<RoomMember> members;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$roomName members')),
      body: members.isEmpty
          ? const Center(child: Text('No members found in this room.'))
          : ListView(
              padding: const EdgeInsets.all(18),
              children: [
                for (final member in members) ...[
                  SurfaceCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        MemberAvatar(
                          name: member.displayName,
                          size: 42,
                          color: member.isOwner
                              ? AppColors.paleBlue
                              : AppColors.paleCyan,
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member.displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (member.email != null)
                                Text(
                                  member.email!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.muted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        StatusPill(label: member.isOwner ? 'Owner' : 'Member'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 9),
                ],
              ],
            ),
    );
  }
}

class RoomStatisticsPage extends StatelessWidget {
  const RoomStatisticsPage({
    required this.room,
    required this.members,
    super.key,
  });

  final Room room;
  final List<RoomMember> members;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${room.name} stats')),
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
                    onPressed: () =>
                        context.read<ExpenseCubit>().loadExpenses(room.id),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            children: [
              SpendingStatistics(
                currency: room.currency,
                members: members,
                expenses: state.expenses,
              ),
            ],
          );
        },
      ),
    );
  }
}

class RoomSettlePage extends StatelessWidget {
  const RoomSettlePage({
    required this.room,
    required this.members,
    required this.currentUserId,
    super.key,
  });

  final Room room;
  final List<RoomMember> members;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settle up · ${room.name}')),
      body: BlocBuilder<ExpenseCubit, ExpenseState>(
        builder: (context, state) {
          if (state.isLoading && state.expenses.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final namesById = {
            for (final member in members) member.userId: member.displayName,
          };
          String nameOf(String userId) => namesById[userId] ?? 'Unknown member';

          final balances = calculateNetBalances(
            memberIds: members.map((member) => member.userId),
            expenses: state.expenses,
          );
          final settlements = suggestSettlements(balances);
          final currency = room.currency ?? 'MYR';

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            children: [
              if (state.errorMessage != null) ...[
                SurfaceCard(
                  child: Text(
                    state.errorMessage!,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SurfaceCard(
                color: AppColors.paleBlue,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      settlements.isEmpty
                          ? 'Everyone is settled up'
                          : 'Suggested transfers',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Suggested transfers keep the number of payments low.',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 17),
              SectionHeading(
                'Suggested settlements',
                icon: Icons.swap_horiz_rounded,
                trailing: StatusPill(
                  label: '${settlements.length} pending',
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 10),
              if (settlements.isEmpty)
                const SurfaceCard(child: Text('No payments needed right now.'))
              else
                for (final settlement in settlements) ...[
                  _SettlementCard(
                    from: nameOf(settlement.fromUserId),
                    to: nameOf(settlement.toUserId),
                    amount: formatCurrency(
                      settlement.amountInCents,
                      currency: currency,
                    ),
                    enabled: !state.isMutating,
                    onMarkPaid: () => _markPaid(context, settlement),
                  ),
                  const SizedBox(height: 9),
                ],
              const SizedBox(height: 16),
              const SectionHeading(
                'Net balances',
                icon: Icons.account_balance_wallet_rounded,
              ),
              const SizedBox(height: 10),
              SurfaceCard(
                child: Column(
                  children: [
                    for (final member in members) ...[
                      _NetBalanceRow(
                        name: member.displayName,
                        netInCents: balances[member.userId] ?? 0,
                        currency: currency,
                      ),
                      if (member != members.last) const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _markPaid(BuildContext context, Settlement settlement) async {
    final now = DateTime.now();
    await context.read<ExpenseCubit>().createExpense(
      room.id,
      Expense(
        id: '',
        amountInCents: settlement.amountInCents,
        category: 'Transfer',
        paidByUserId: settlement.fromUserId,
        createdByUserId: currentUserId,
        transferMethod: 'Bank transfer',
        transferToUserId: settlement.toUserId,
        splitAmountsInCents: {settlement.toUserId: settlement.amountInCents},
        expenseDate: DateTime(now.year, now.month, now.day),
      ),
    );
  }
}

class _SettlementCard extends StatelessWidget {
  const _SettlementCard({
    required this.from,
    required this.to,
    required this.amount,
    required this.enabled,
    required this.onMarkPaid,
  });

  final String from;
  final String to;
  final String amount;
  final bool enabled;
  final VoidCallback onMarkPaid;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          _SettlementAvatars(from: from, to: to),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$from → $to',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const Text(
                  'Pending',
                  style: TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextButton(
                onPressed: enabled ? onMarkPaid : null,
                child: const Text('Mark paid'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NetBalanceRow extends StatelessWidget {
  const _NetBalanceRow({
    required this.name,
    required this.netInCents,
    required this.currency,
  });

  final String name;
  final int netInCents;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final String status;
    final Color color;
    if (netInCents == 0) {
      status = 'Settled';
      color = AppColors.muted;
    } else if (netInCents > 0) {
      status = 'Is owed ${formatCurrency(netInCents, currency: currency)}';
      color = AppColors.success;
    } else {
      status = 'Owes ${formatCurrency(-netInCents, currency: currency)}';
      color = AppColors.danger;
    }

    return Row(
      children: [
        MemberAvatar(
          name: name,
          size: 30,
          color: AppColors.paleBlue,
          border: false,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        Text(
          status,
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _SettlementAvatars extends StatelessWidget {
  const _SettlementAvatars({required this.from, required this.to});

  final String from;
  final String to;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 36,
      child: Stack(
        children: [
          MemberAvatar(name: from, size: 34, color: AppColors.paleBlue),
          Positioned(
            left: 25,
            child: MemberAvatar(name: to, size: 34, color: AppColors.paleCyan),
          ),
        ],
      ),
    );
  }
}
