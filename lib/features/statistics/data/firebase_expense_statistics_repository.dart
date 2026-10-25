import 'package:cloud_firestore/cloud_firestore.dart';

import 'expense_statistics_model.dart';
import 'expense_statistics_repository.dart';

class FirebaseExpenseStatisticsRepository
    implements ExpenseStatisticsRepository {
  FirebaseExpenseStatisticsRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<ExpenseStatistics> getStatistics({
    required String roomId,
    required String userId,
    DateTime? month,
  }) async {
    final selectedMonth = month?.toUtc() ?? DateTime.now().toUtc();
    final monthId = _monthId(selectedMonth);
    final room = _firestore.collection('rooms').doc(roomId);
    final snapshots = await Future.wait([
      room.collection('stats').doc('summary').get(),
      room.collection('monthlyStats').doc(monthId).get(),
      room
          .collection('members')
          .doc(userId)
          .collection('stats')
          .doc('summary')
          .get(),
      room
          .collection('members')
          .doc(userId)
          .collection('monthlyStats')
          .doc(monthId)
          .get(),
    ]);
    return ExpenseStatistics(
      roomAllTimeInCents: _int(snapshots[0].data()?['totalExpenseInCents']),
      roomMonthlyInCents: _int(snapshots[1].data()?['totalExpenseInCents']),
      personalAllTimeInCents: _int(snapshots[2].data()?['totalPaidInCents']),
      personalMonthlyInCents: _int(snapshots[3].data()?['totalPaidInCents']),
      month: monthId,
    );
  }

  String _monthId(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}';

  int _int(Object? value) => value is num ? value.toInt() : 0;
}
