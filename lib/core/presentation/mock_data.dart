import 'package:flutter/material.dart';

class RoomMock {
  const RoomMock({
    required this.name,
    required this.subtitle,
    required this.emoji,
    required this.currency,
    required this.total,
    required this.members,
    required this.activity,
    this.live = false,
  });

  final String name;
  final String subtitle;
  final String emoji;
  final String currency;
  final String total;
  final List<String> members;
  final String activity;
  final bool live;
}

class ExpenseMock {
  const ExpenseMock({
    required this.title,
    required this.category,
    required this.emoji,
    required this.amount,
    required this.paidBy,
    required this.time,
    required this.dateGroup,
    this.splitCount,
    this.note = '',
    this.addedBy = 'Eric',
    this.transferMethod,
    this.transferTo,
    this.date,
  });

  final String title;
  final String category;
  final String emoji;
  final double amount;
  final String paidBy;
  final String time;
  final String dateGroup;
  final int? splitCount;
  final String note;
  final String addedBy;
  final String? transferMethod;
  final String? transferTo;
  final DateTime? date;
}

class MemberMock {
  const MemberMock({
    required this.name,
    required this.role,
    required this.spending,
    required this.balance,
    required this.color,
  });

  final String name;
  final String role;
  final double spending;
  final double balance;
  final Color color;

  String get initials => name.split(' ').map((part) => part[0]).take(2).join();
}

const japanExpenses = [
  ExpenseMock(
    title: 'Ramen dinner at Ichiran',
    category: 'Food',
    emoji: '🍜',
    amount: 1200,
    paidBy: 'Eric',
    time: '8:32 PM',
    dateGroup: 'Today',
  ),
  ExpenseMock(
    title: 'Subway to Shibuya',
    category: 'Transport',
    emoji: '🚆',
    amount: 800,
    paidBy: 'John',
    time: '7:45 PM',
    dateGroup: 'Today',
  ),
  ExpenseMock(
    title: 'Hotel in Kyoto',
    category: 'Travel',
    emoji: '🏨',
    amount: 18000,
    paidBy: 'Amy',
    time: 'Yesterday',
    dateGroup: 'Yesterday',
  ),
  ExpenseMock(
    title: 'Matcha latte',
    category: 'Coffee',
    emoji: '☕',
    amount: 650,
    paidBy: 'Eric',
    time: 'Yesterday',
    dateGroup: 'Yesterday',
  ),
  ExpenseMock(
    title: 'Shinkansen tickets',
    category: 'Transport',
    emoji: '🚄',
    amount: 3200,
    paidBy: 'John',
    time: 'Oct 3',
    dateGroup: 'Earlier',
  ),
];

const householdExpenses = [
  ExpenseMock(
    title: 'Lunch at the market',
    category: 'Food',
    emoji: '🍜',
    amount: 25,
    paidBy: 'Eric',
    time: '1:20 PM',
    dateGroup: 'Today',
  ),
  ExpenseMock(
    title: 'Train to the office',
    category: 'Transport',
    emoji: '🚆',
    amount: 18,
    paidBy: 'John',
    time: '9:10 AM',
    dateGroup: 'Today',
  ),
  ExpenseMock(
    title: 'Weekend hotel',
    category: 'Travel',
    emoji: '🏨',
    amount: 180,
    paidBy: 'Amy',
    time: 'Yesterday',
    dateGroup: 'Yesterday',
  ),
  ExpenseMock(
    title: 'Coffee run',
    category: 'Coffee',
    emoji: '☕',
    amount: 12.5,
    paidBy: 'Eric',
    time: 'Yesterday',
    dateGroup: 'Yesterday',
  ),
];

const roomMembers = [
  MemberMock(
    name: 'Eric Wong',
    role: 'Owner',
    spending: 423,
    balance: 30,
    color: Color(0xFFD9E8FF),
  ),
  MemberMock(
    name: 'John Tan',
    role: 'Member',
    spending: 512,
    balance: 80,
    color: Color(0xFFE2F6FC),
  ),
  MemberMock(
    name: 'Amy Lim',
    role: 'Member',
    spending: 349,
    balance: -50,
    color: Color(0xFFFFEAD8),
  ),
  MemberMock(
    name: 'David Lee',
    role: 'Member',
    spending: 286,
    balance: -30,
    color: Color(0xFFE9E4FF),
  ),
];

String formatMoney(double amount, {String currency = 'RM'}) {
  final digits = amount == amount.roundToDouble() ? 0 : 2;
  final value = amount.toStringAsFixed(digits);
  final parts = value.split('.');
  final whole = parts.first.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  final formatted = parts.length == 1 ? whole : '$whole.${parts.last}';
  return currency == 'RM' ? 'RM $formatted' : '$currency $formatted';
}
