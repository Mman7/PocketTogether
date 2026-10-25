// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Expense _$ExpenseFromJson(Map<String, dynamic> json) => Expense(
  id: json['id'] as String,
  amountInCents: (json['amountInCents'] as num).toInt(),
  category: json['category'] as String,
  note: json['note'] as String?,
  paidByUserId: json['paidByUserId'] as String,
  createdByUserId: json['createdByUserId'] as String,
  transferMethod: json['transferMethod'] as String?,
  transferToUserId: json['transferToUserId'] as String?,
  splitAmountsInCents: Map<String, int>.from(
    json['splitAmountsInCents'] as Map,
  ),
  expenseDate: DateTime.parse(json['expenseDate'] as String),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$ExpenseToJson(Expense instance) => <String, dynamic>{
  'id': instance.id,
  'amountInCents': instance.amountInCents,
  'category': instance.category,
  'note': instance.note,
  'paidByUserId': instance.paidByUserId,
  'createdByUserId': instance.createdByUserId,
  'transferMethod': instance.transferMethod,
  'transferToUserId': instance.transferToUserId,
  'splitAmountsInCents': instance.splitAmountsInCents,
  'expenseDate': instance.expenseDate.toIso8601String(),
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};
