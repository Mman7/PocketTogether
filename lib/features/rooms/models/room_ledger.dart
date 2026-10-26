import '../../expenses/models/expense.dart';
import 'room.dart';
import 'room_member.dart';

/// A room together with its members and expenses.
class RoomLedger {
  const RoomLedger({
    required this.room,
    required this.members,
    required this.expenses,
    this.personalAllTimeInCents,
  });

  final Room room;
  final List<RoomMember> members;
  final List<Expense> expenses;
  final int? personalAllTimeInCents;

  String get currency => room.currency ?? 'MYR';

  String memberName(String userId) {
    for (final member in members) {
      if (member.userId == userId) return member.displayName;
    }
    return 'Unknown member';
  }
}
