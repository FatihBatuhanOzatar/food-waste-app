import 'package:intl/intl.dart';

/// Utility for formatting prices consistently throughout the app.
///
/// Always use this formatter instead of raw string interpolation for
/// monetary values to ensure consistent locale and symbol placement.
///
/// **Example:**
/// ```dart
/// PriceFormatter.format(12.5);  // → '₺12,50'
/// ```
class PriceFormatter {
  PriceFormatter._();

  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 2,
  );

  /// Formats [amount] as a Turkish lira price string.
  ///
  /// Example: `format(12.5)` → `'₺12,50'`
  static String format(double amount) => _formatter.format(amount);

  /// Formats [amount] with a discount applied.
  ///
  /// [discountFraction] is a value between 0.0 and 1.0.
  /// Example: `formatDiscounted(20.0, 0.30)` → `'₺14,00'`
  static String formatDiscounted(double amount, double discountFraction) {
    final discounted = amount * (1 - discountFraction);
    return format(discounted);
  }
}
