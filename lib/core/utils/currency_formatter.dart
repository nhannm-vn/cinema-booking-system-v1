import 'package:intl/intl.dart';

/// Formatter for Vietnamese currency (VND).
/// Money is always integer according to TECH_STACK.md and BUSINESS_RULES.md.
abstract final class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  /// Format an integer VND amount: e.g. 80000 -> "80.000 đ"
  static String format(int amount) {
    return _formatter.format(amount).trim();
  }

  /// Compact representation without currency symbol: e.g. 80000 -> "80.000"
  static String formatNumber(int amount) {
    final format = NumberFormat('#,###', 'vi_VN');
    return format.format(amount);
  }
}
