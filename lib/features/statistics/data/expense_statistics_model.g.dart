// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_statistics_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExpenseStatistics _$ExpenseStatisticsFromJson(Map<String, dynamic> json) =>
    ExpenseStatistics(
      personalAllTimeInCents: (json['personalAllTimeInCents'] as num).toInt(),
      personalMonthlyInCents: (json['personalMonthlyInCents'] as num).toInt(),
      roomAllTimeInCents: (json['roomAllTimeInCents'] as num).toInt(),
      roomMonthlyInCents: (json['roomMonthlyInCents'] as num).toInt(),
      month: json['month'] as String,
    );

Map<String, dynamic> _$ExpenseStatisticsToJson(ExpenseStatistics instance) =>
    <String, dynamic>{
      'personalAllTimeInCents': instance.personalAllTimeInCents,
      'personalMonthlyInCents': instance.personalMonthlyInCents,
      'roomAllTimeInCents': instance.roomAllTimeInCents,
      'roomMonthlyInCents': instance.roomMonthlyInCents,
      'month': instance.month,
    };
