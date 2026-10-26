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

  /// Personal total paid amount across all loaded rooms, keyed by currency.
  Map<String, int> totalSpendByCurrency() {
    final totals = <String, int>{};
    for (final ledger in ledgers) {
      final total =
          ledger.personalAllTimeInCents ??
          ledger.expenses.fold<int>(
            0,
            (sum, expense) => sum + expense.amountInCents,
          );
      totals.update(
        ledger.currency,
        (value) => value + total,
        ifAbsent: () => total,
      );
    }
    return totals;
  }
}
