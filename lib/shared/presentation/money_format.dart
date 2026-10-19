/// Formats an amount stored in cents (minor units) for display.
///
/// Whole amounts omit decimals, e.g. `RM 2,340`. Currencies without a known
/// symbol fall back to their ISO code, e.g. `USD 12.50`.
String formatCurrency(int amountInCents, {String? currency}) {
  final absolute = amountInCents.abs();
  final whole = (absolute ~/ 100).toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (match) => '${match[1]},',
  );
  final cents = absolute % 100;
  final digits = cents == 0
      ? whole
      : '$whole.${cents.toString().padLeft(2, '0')}';
  final sign = amountInCents < 0 ? '-' : '';
  return '$sign${_symbolFor(currency)}$digits';
}

String _symbolFor(String? currency) {
  return switch (currency) {
    'JPY' => '¥',
    'THB' => '฿',
    null || 'MYR' => 'RM ',
    _ => '$currency ',
  };
}
