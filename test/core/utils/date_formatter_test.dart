import 'package:flutter_test/flutter_test.dart';
import 'package:cinema_booking_v1/core/utils/date_formatter.dart';

void main() {
  group('DateFormatter Tests', () {
    test('formatTime formats HH:mm', () {
      final date = DateTime(2026, 10, 27, 19, 30);
      expect(DateFormatter.formatTime(date), '19:30');
    });

    test('formatDate formats dd/MM/yyyy', () {
      final date = DateTime(2026, 10, 27);
      expect(DateFormatter.formatDate(date), '27/10/2026');
    });

    test('formatWeekdayAbbr returns correct Vietnamese abbreviation', () {
      final monday = DateTime(2026, 10, 26); // Monday
      expect(DateFormatter.formatWeekdayAbbr(monday), 'T2');

      final sunday = DateTime(2026, 11, 1); // Sunday
      expect(DateFormatter.formatWeekdayAbbr(sunday), 'CN');
    });

    test('formatTimer formats mm:ss', () {
      expect(DateFormatter.formatTimer(const Duration(minutes: 4, seconds: 32)), '04:32');
      expect(DateFormatter.formatTimer(const Duration(seconds: 45)), '00:45');
      expect(DateFormatter.formatTimer(const Duration(seconds: -10)), '00:00');
    });
  });
}
