import 'package:flutter_test/flutter_test.dart';
import 'package:cinema_booking_v1/features/booking/data/models/showtime_model.dart';
import 'package:cinema_booking_v1/features/staff_counter/presentation/controllers/staff_counter_provider.dart';

void main() {
  group('StaffCounterProvider Tests', () {
    late StaffCounterProvider provider;

    setUp(() {
      provider = StaffCounterProvider();
    });

    test('toggleSeat enforces maximum 8 seats limit', () {
      final seats = ['A1', 'A2', 'A3', 'A4', 'A5', 'A6', 'A7', 'A8'];
      for (final s in seats) {
        expect(provider.toggleSeat(s), isTrue);
      }
      expect(provider.selectedSeatIds.length, 8);

      // Attempting 9th seat should return false and set error message
      expect(provider.toggleSeat('A9'), isFalse);
      expect(provider.selectedSeatIds.length, 8);
      expect(provider.errorMessage, contains('tối đa 8 ghế'));

      // Toggling an already selected seat removes it
      expect(provider.toggleSeat('A1'), isTrue);
      expect(provider.selectedSeatIds.length, 7);
      expect(provider.selectedSeatIds.contains('A1'), isFalse);
    });

    test('calculateTotal and calculateChange compute VND amounts accurately', () {
      final showtime = ShowtimeModel(
        id: 'st-01',
        movieId: 'm-01',
        cinemaId: 'cn_q1',
        roomId: 'r-01',
        format: 'IMAX',
        startTime: DateTime.now().add(const Duration(hours: 2)),
        endTime: DateTime.now().add(const Duration(hours: 4)),
        totalSeats: 75,
        minPrice: 120000,
      );

      provider.selectShowtime(showtime);
      provider.toggleSeat('B1');
      provider.toggleSeat('B2');

      provider.setFoodQuantity('f-01', 'Combo Solo', 85000, 2); // 170,000

      // Total = 2 * 120,000 + 170,000 = 410,000 VND
      final total = provider.calculateTotal();
      expect(total, 410000);

      // Change calculation when receiving 500,000 VND -> change 90,000 VND
      final change = provider.calculateChange(500000);
      expect(change, 90000);
      expect(provider.receivedCash, 500000);

      // When receiving exact or less than total -> change 0
      expect(provider.calculateChange(410000), 0);
      expect(provider.calculateChange(300000), 0);
    });

    test('reset clears all selections and state', () {
      final showtime = ShowtimeModel(
        id: 'st-01',
        movieId: 'm-01',
        cinemaId: 'cn_q1',
        roomId: 'r-01',
        format: '2D',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(hours: 2)),
        totalSeats: 50,
      );

      provider.selectShowtime(showtime);
      provider.toggleSeat('C1');
      provider.setFoodQuantity('f-01', 'Popcorn', 60000, 1);
      provider.calculateChange(200000);

      expect(provider.selectedShowtime, isNotNull);
      expect(provider.selectedSeatIds, isNotEmpty);
      expect(provider.selectedFoods, isNotEmpty);

      provider.reset();

      expect(provider.selectedShowtime, isNull);
      expect(provider.selectedSeatIds, isEmpty);
      expect(provider.selectedFoods, isEmpty);
      expect(provider.receivedCash, 0);
      expect(provider.errorMessage, isNull);
    });
  });
}
