import 'expense_statistics_model.dart';

abstract interface class ExpenseStatisticsRepository {
  Future<ExpenseStatistics> getStatistics({
    required String roomId,
    required String userId,
    DateTime? month,
  });
}
