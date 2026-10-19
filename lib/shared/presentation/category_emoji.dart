import 'package:flutter/material.dart';

class ExpenseCategory {
  const ExpenseCategory(this.name, this.icon, this.group);

  final String name;
  final IconData icon;
  final String group;
}

const expenseCategories = [
  ExpenseCategory('Food', Icons.restaurant_outlined, 'Food & drinks'),
  ExpenseCategory('Coffee', Icons.local_cafe_outlined, 'Food & drinks'),
  ExpenseCategory('Drinks', Icons.local_bar_outlined, 'Food & drinks'),
  ExpenseCategory('Fast food', Icons.fastfood_outlined, 'Food & drinks'),
  ExpenseCategory('Fuel', Icons.local_gas_station_outlined, 'Transport'),
  ExpenseCategory('Taxi', Icons.local_taxi_outlined, 'Transport'),
  ExpenseCategory(
    'Public transport',
    Icons.directions_bus_outlined,
    'Transport',
  ),
  ExpenseCategory('Parking', Icons.local_parking_outlined, 'Transport'),
  ExpenseCategory('Train / flight', Icons.train_outlined, 'Transport'),
  ExpenseCategory('Rent', Icons.home_outlined, 'Living'),
  ExpenseCategory('Utilities', Icons.lightbulb_outline, 'Living'),
  ExpenseCategory('Groceries', Icons.shopping_cart_outlined, 'Living'),
  ExpenseCategory('Household', Icons.cleaning_services_outlined, 'Living'),
  ExpenseCategory('Clothing', Icons.checkroom_outlined, 'Shopping'),
  ExpenseCategory('Electronics', Icons.headphones_outlined, 'Shopping'),
  ExpenseCategory('Gifts', Icons.card_giftcard_outlined, 'Shopping'),
  ExpenseCategory('Shopping', Icons.shopping_bag_outlined, 'Shopping'),
  ExpenseCategory('Movies', Icons.movie_outlined, 'Entertainment'),
  ExpenseCategory('Games', Icons.sports_esports_outlined, 'Entertainment'),
  ExpenseCategory('Music', Icons.music_note_outlined, 'Entertainment'),
  ExpenseCategory('Events', Icons.confirmation_num_outlined, 'Entertainment'),
  ExpenseCategory('Medicine', Icons.medication_outlined, 'Health'),
  ExpenseCategory('Medical', Icons.medical_services_outlined, 'Health'),
  ExpenseCategory('Fitness', Icons.fitness_center_outlined, 'Health'),
  ExpenseCategory('Hotel', Icons.hotel_outlined, 'Travel'),
  ExpenseCategory('Flights', Icons.flight_outlined, 'Travel'),
  ExpenseCategory('Activities', Icons.hiking, 'Travel'),
  ExpenseCategory('Tickets', Icons.confirmation_num_outlined, 'Travel'),
  ExpenseCategory('Education', Icons.school_outlined, 'Others'),
  ExpenseCategory('Work', Icons.work_outline, 'Others'),
  ExpenseCategory('Bills', Icons.receipt_long_outlined, 'Others'),
  ExpenseCategory('Transfer', Icons.swap_horiz_rounded, 'Others'),
  ExpenseCategory('Other', Icons.inventory_2_outlined, 'Others'),
];

IconData categoryIcon(String category) {
  for (final expenseCategory in expenseCategories) {
    if (expenseCategory.name == category) return expenseCategory.icon;
  }
  return Icons.inventory_2_outlined;
}
