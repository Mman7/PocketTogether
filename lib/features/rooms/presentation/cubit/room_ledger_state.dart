import '../../models/room_ledger.dart';

class RoomLedgerState {
  const RoomLedgerState({
    this.ledgers = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<RoomLedger> ledgers;
  final bool isLoading;
  final String? errorMessage;

  /// Net balance of [userId] across all rooms, keyed by currency.
  ///
  /// Each currency is kept separate because rooms do not share one.
  Map<String, int> netBalanceByCurrency(String userId) {
    final totals = <String, int>{};
    for (final ledger in ledgers) {
      final net = ledger.netBalances[userId];
      if (net == null) continue;
      totals.update(
        ledger.currency,
        (value) => value + net,
        ifAbsent: () => net,
      );
    }
    return totals;
  }
}
