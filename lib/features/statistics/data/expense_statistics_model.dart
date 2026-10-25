import 'package:json_annotation/json_annotation.dart';

part 'expense_statistics_model.g.dart';

@JsonSerializable()
class ExpenseStatistics {
  const ExpenseStatistics({
    required this.personalAllTimeInCents,
    required this.personalMonthlyInCents,
    required this.roomAllTimeInCents,
    required this.roomMonthlyInCents,
    required this.month,
  });

  final int personalAllTimeInCents;
  final int personalMonthlyInCents;
  final int roomAllTimeInCents;
  final int roomMonthlyInCents;
  final String month;

  factory ExpenseStatistics.fromJson(Map<String, dynamic> json) =>
      _$ExpenseStatisticsFromJson(json);

  Map<String, dynamic> toJson() => _$ExpenseStatisticsToJson(this);
}
