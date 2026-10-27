import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/presentation/widgets/empty_panel.dart';
import '../../../../shared/presentation/widgets/page_header.dart';
import '../../../expenses/models/expense.dart';
import '../../../rooms/models/room_member.dart';
import '../../../rooms/presentation/cubit/room_ledger_cubit.dart';
import '../../../rooms/presentation/cubit/room_ledger_state.dart';
import '../widgets/spending_statistics.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({required this.currentUserId, super.key});

  final String currentUserId;

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoomLedgerCubit, RoomLedgerState>(
      builder: (context, state) {
        final expensesByCurrency = <String, List<Expense>>{};
        final membersByCurrency = <String, List<RoomMember>>{};
        for (final ledger in state.ledgers) {
          final personalExpenses = ledger.expenses
              .where((expense) => expense.paidByUserId == widget.currentUserId)
              .toList();
          if (personalExpenses.isEmpty) continue;
          expensesByCurrency
              .putIfAbsent(ledger.currency, () => [])
              .addAll(personalExpenses);
          final member = ledger.members.where(
            (candidate) => candidate.userId == widget.currentUserId,
          );
          membersByCurrency
              .putIfAbsent(ledger.currency, () => [])
              .addAll(member);
        }

        return CustomScrollView(
          key: const PageStorageKey('statistics-page'),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              sliver: SliverList.list(
                children: [
                  const PageHeader(
                    title: 'My statistics',
                    subtitle: 'A clearer picture of your spending.',
                  ),
                  const SizedBox(height: 17),
                  if (state.isLoading && state.ledgers.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (state.errorMessage != null)
                    EmptyPanel(
                      icon: Icons.error_outline_rounded,
                      title: 'Your statistics are unavailable',
                      message: state.errorMessage!,
                      compact: true,
                    )
                  else if (expensesByCurrency.isNotEmpty)
                    for (final entry in expensesByCurrency.entries) ...[
                      if (expensesByCurrency.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      SpendingStatistics(
                        currency: entry.key,
                        members: membersByCurrency[entry.key] ?? const [],
                        expenses: entry.value,
                      ),
                      const SizedBox(height: 18),
                    ]
                  else
                    const EmptyPanel(
                      icon: Icons.insights_outlined,
                      title: 'No personal spending yet',
                      message: 'Expenses you pay will appear here.',
                      compact: true,
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
