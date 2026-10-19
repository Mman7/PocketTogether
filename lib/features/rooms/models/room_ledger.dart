import '../../expenses/domain/balance_calculator.dart';
import '../../expenses/models/expense.dart';
import 'room.dart';
import 'room_member.dart';

/// A room together with its members and expenses.
class RoomLedger {
  const RoomLedger({
    required this.room,
    required this.members,
    required this.expenses,
  });

  final Room room;
  final List<RoomMember> members;
  final List<Expense> expenses;

  String get currency => room.currency ?? 'MYR';

  String memberName(String userId) {
    for (final member in members) {
      if (member.userId == userId) return member.displayName;
    }
    return 'Unknown member';
  }

  /// Net position per member in cents. Positive means owed money.
  Map<String, int> get netBalances => calculateNetBalances(
    memberIds: members.map((member) => member.userId),
    expenses: expenses,
  );
}
