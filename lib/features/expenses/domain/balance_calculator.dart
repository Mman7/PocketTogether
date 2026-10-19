import '../models/expense.dart';

/// A suggested payment that settles part of a room's balance.
class Settlement {
  const Settlement({
    required this.fromUserId,
    required this.toUserId,
    required this.amountInCents,
  });

  final String fromUserId;
  final String toUserId;
  final int amountInCents;
}

/// Net position per member in cents.
///
/// Positive means the member is owed money, negative means they owe money.
/// Transfers are included because they are recorded as expenses paid by the
/// sender and split to the recipient.
Map<String, int> calculateNetBalances({
  required Iterable<String> memberIds,
  required Iterable<Expense> expenses,
}) {
  final balances = <String, int>{for (final id in memberIds) id: 0};

  void adjust(String userId, int delta) {
    balances.update(userId, (value) => value + delta, ifAbsent: () => delta);
  }

  for (final expense in expenses) {
    adjust(expense.paidByUserId, expense.amountInCents);
    for (final split in expense.splitAmountsInCents.entries) {
      adjust(split.key, -split.value);
    }
  }
  return balances;
}

/// Greedy settlement plan: largest debtor pays largest creditor, repeatedly.
///
/// Produces at most `members - 1` payments and clears every balance.
List<Settlement> suggestSettlements(Map<String, int> balances) {
  final creditors = <_OpenBalance>[
    for (final entry in balances.entries)
      if (entry.value > 0) _OpenBalance(entry.key, entry.value),
  ]..sort((a, b) => b.amount.compareTo(a.amount));
  final debtors = <_OpenBalance>[
    for (final entry in balances.entries)
      if (entry.value < 0) _OpenBalance(entry.key, -entry.value),
  ]..sort((a, b) => b.amount.compareTo(a.amount));

  final settlements = <Settlement>[];
  var debtorIndex = 0;
  var creditorIndex = 0;
  while (debtorIndex < debtors.length && creditorIndex < creditors.length) {
    final debtor = debtors[debtorIndex];
    final creditor = creditors[creditorIndex];
    final amount = debtor.amount < creditor.amount
        ? debtor.amount
        : creditor.amount;
    settlements.add(
      Settlement(
        fromUserId: debtor.userId,
        toUserId: creditor.userId,
        amountInCents: amount,
      ),
    );
    debtor.amount -= amount;
    creditor.amount -= amount;
    if (debtor.amount == 0) debtorIndex++;
    if (creditor.amount == 0) creditorIndex++;
  }
  return settlements;
}

class _OpenBalance {
  _OpenBalance(this.userId, this.amount);

  final String userId;
  int amount;
}
