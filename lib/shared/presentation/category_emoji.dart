class ExpenseCategory {
  const ExpenseCategory(this.name, this.emoji, this.group);

  final String name;
  final String emoji;
  final String group;
}

const expenseCategories = [
  ExpenseCategory('Food', '🍜', 'Food & drinks'),
  ExpenseCategory('Coffee', '☕', 'Food & drinks'),
  ExpenseCategory('Drinks', '🥤', 'Food & drinks'),
  ExpenseCategory('Fast food', '🍔', 'Food & drinks'),
  ExpenseCategory('Fuel', '⛽', 'Transport'),
  ExpenseCategory('Taxi', '🚕', 'Transport'),
  ExpenseCategory('Public transport', '🚌', 'Transport'),
  ExpenseCategory('Parking', '🅿️', 'Transport'),
  ExpenseCategory('Train / flight', '🚆', 'Transport'),
  ExpenseCategory('Rent', '🏠', 'Living'),
  ExpenseCategory('Utilities', '💡', 'Living'),
  ExpenseCategory('Groceries', '🛒', 'Living'),
  ExpenseCategory('Household', '🧹', 'Living'),
  ExpenseCategory('Clothing', '👕', 'Shopping'),
  ExpenseCategory('Electronics', '🎧', 'Shopping'),
  ExpenseCategory('Gifts', '🎁', 'Shopping'),
  ExpenseCategory('Shopping', '🛍️', 'Shopping'),
  ExpenseCategory('Movies', '🎬', 'Entertainment'),
  ExpenseCategory('Games', '🎮', 'Entertainment'),
  ExpenseCategory('Music', '🎵', 'Entertainment'),
  ExpenseCategory('Events', '🎟️', 'Entertainment'),
  ExpenseCategory('Medicine', '💊', 'Health'),
  ExpenseCategory('Medical', '🩺', 'Health'),
  ExpenseCategory('Fitness', '🏃', 'Health'),
  ExpenseCategory('Hotel', '🏨', 'Travel'),
  ExpenseCategory('Flights', '✈️', 'Travel'),
  ExpenseCategory('Activities', '🧗', 'Travel'),
  ExpenseCategory('Tickets', '🎫', 'Travel'),
  ExpenseCategory('Education', '📚', 'Others'),
  ExpenseCategory('Work', '💼', 'Others'),
  ExpenseCategory('Bills', '🧾', 'Others'),
  ExpenseCategory('Transfer', '↔️', 'Others'),
  ExpenseCategory('Other', '📦', 'Others'),
];

String categoryEmoji(String category) {
  for (final expenseCategory in expenseCategories) {
    if (expenseCategory.name == category) return expenseCategory.emoji;
  }
  return '📦';
}
