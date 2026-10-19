import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../shared/presentation/widgets/empty_panel.dart';
import '../../../../shared/presentation/widgets/page_header.dart';
import '../../../rooms/models/room_ledger.dart';
import '../../../rooms/presentation/cubit/room_ledger_cubit.dart';
import '../../../rooms/presentation/cubit/room_ledger_state.dart';
import '../widgets/spending_statistics.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  String? _selectedRoomId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoomLedgerCubit, RoomLedgerState>(
      builder: (context, state) {
        final ledgers = state.ledgers;
        final selected = _selectedLedger(ledgers);

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
                  if (selected != null) ...[
                    _RoomSelector(
                      ledgers: ledgers,
                      selectedRoomId: selected.room.id,
                      onSelected: (roomId) =>
                          setState(() => _selectedRoomId = roomId),
                    ),
                    const SizedBox(height: 14),
                    SpendingStatistics(
                      currency: selected.room.currency,
                      members: selected.members,
                      expenses: selected.expenses,
                    ),
                  ] else if (state.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (state.errorMessage != null)
                    EmptyPanel(
                      icon: Icons.error_outline_rounded,
                      title: 'Statistics unavailable',
                      message: state.errorMessage!,
                      compact: true,
                    )
                  else
                    const EmptyPanel(
                      icon: Icons.insights_outlined,
                      title: 'No rooms yet',
                      message: 'Create or join a room to see its statistics.',
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

  RoomLedger? _selectedLedger(List<RoomLedger> ledgers) {
    if (ledgers.isEmpty) return null;
    for (final ledger in ledgers) {
      if (ledger.room.id == _selectedRoomId) return ledger;
    }
    return ledgers.first;
  }
}

class _RoomSelector extends StatelessWidget {
  const _RoomSelector({
    required this.ledgers,
    required this.selectedRoomId,
    required this.onSelected,
  });

  final List<RoomLedger> ledgers;
  final String selectedRoomId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final ledger in ledgers)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(ledger.room.name),
                selected: ledger.room.id == selectedRoomId,
                onSelected: (_) => onSelected(ledger.room.id),
                showCheckmark: false,
                side: BorderSide(
                  color: ledger.room.id == selectedRoomId
                      ? AppColors.primary
                      : AppColors.border,
                ),
                backgroundColor: AppColors.white,
                selectedColor: AppColors.paleBlue,
                labelStyle: TextStyle(
                  color: ledger.room.id == selectedRoomId
                      ? AppColors.primary
                      : AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
