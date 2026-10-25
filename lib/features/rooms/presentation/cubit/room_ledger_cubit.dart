import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../expenses/data/expense_repository.dart';
import '../../../expenses/models/expense.dart';
import '../../../statistics/data/expense_statistics_model.dart';
import '../../../statistics/data/expense_statistics_repository.dart';
import '../../data/room_repository.dart';
import '../../models/room.dart';
import '../../models/room_member.dart';
import '../../models/room_ledger.dart';
import 'room_ledger_state.dart';

/// Loads members and expenses for every room the user belongs to.
class RoomLedgerCubit extends Cubit<RoomLedgerState> {
  RoomLedgerCubit({
    required this.roomRepository,
    required this.expenseRepository,
    required this.statisticsRepository,
    required this.userId,
  }) : super(const RoomLedgerState());

  final RoomRepository roomRepository;
  final ExpenseRepository expenseRepository;
  final ExpenseStatisticsRepository statisticsRepository;
  final String userId;
  List<Room> _rooms = const [];
  int _latestRequest = 0;

  Future<void> loadRooms(List<Room> rooms) async {
    _rooms = rooms;
    final request = ++_latestRequest;
    if (rooms.isEmpty) {
      emit(const RoomLedgerState());
      return;
    }

    emit(RoomLedgerState(ledgers: state.ledgers, isLoading: true));
    try {
      final ledgers = await Future.wait([
        for (final room in rooms) _loadLedger(room),
      ]);
      if (isClosed || request != _latestRequest) return;
      emit(RoomLedgerState(ledgers: ledgers));
    } catch (_) {
      if (isClosed || request != _latestRequest) return;
      emit(
        RoomLedgerState(
          ledgers: state.ledgers,
          errorMessage: 'Unable to load room activity.',
        ),
      );
    }
  }

  Future<void> refresh() => loadRooms(_rooms);

  Future<RoomLedger> _loadLedger(Room room) async {
    final results = await Future.wait([
      roomRepository.getRoomMembers(room.id),
      expenseRepository.getExpenses(room.id),
      statisticsRepository.getStatistics(roomId: room.id, userId: userId),
    ]);
    return RoomLedger(
      room: room,
      members: results[0] as List<RoomMember>,
      expenses: results[1] as List<Expense>,
      personalAllTimeInCents:
          (results[2] as ExpenseStatistics).personalAllTimeInCents,
    );
  }
}
