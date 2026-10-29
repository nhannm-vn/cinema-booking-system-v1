import 'package:flutter_test/flutter_test.dart';
import 'package:cinema_booking_v1/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter Tests', () {
    test('formats VND currency properly with symbol', () {
      final formatted = CurrencyFormatter.format(80000);
      expect(formatted.contains('80.000'), isTrue);
      expect(formatted.contains('đ'), isTrue);
    });

    test('formats large currency amounts', () {
      final formatted = CurrencyFormatter.format(1250000);
      expect(formatted.contains('1.250.000'), isTrue);
    });

    test('formats zero VND', () {
      final formatted = CurrencyFormatter.format(0);
      expect(formatted.contains('0'), isTrue);
    });

    test('formatNumber outputs plain thousands separation', () {
      expect(CurrencyFormatter.formatNumber(150000), '150.000');
    });
  });
}
