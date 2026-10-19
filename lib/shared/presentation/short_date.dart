String formatShortDate(DateTime date) =>
    '${date.day} ${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][date.month - 1]}';

String? formatShortTime(DateTime? date) {
  if (date == null) return null;
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final period = date.hour >= 12 ? 'pm' : 'am';
  final minutes = date.minute == 0
      ? ''
      : ':${date.minute.toString().padLeft(2, '0')}';
  return '$hour$minutes$period';
}
