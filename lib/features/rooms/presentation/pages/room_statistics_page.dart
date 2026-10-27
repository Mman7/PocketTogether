import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pocket_together/shared/presentation/widgets/ambient_background.dart';

import '../../../expenses/presentation/cubit/expense_cubit.dart';
import '../../../expenses/presentation/cubit/expense_state.dart';
import '../../../statistics/presentation/widgets/spending_statistics.dart';
import '../../models/room.dart';
import '../../models/room_member.dart';

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
    return AmbientBackground(
      child: Scaffold(
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
      ),
    );
  }
}
