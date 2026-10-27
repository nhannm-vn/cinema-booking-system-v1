import 'package:flutter_test/flutter_test.dart';
import 'package:cinema_booking_v1/features/booking/data/models/booking_model.dart';

void main() {
  group('BookingModel Serialization', () {
    test('toMap() and fromMap() round-trip preserves all fields including created_at', () {
      final now = DateTime.now();
      final original = BookingModel(
        code: 'K7M2QX9P',
        userId: 'usr_123',
        channel: 'online',
        soldBy: null,
        status: 'holding',
        holdUntil: now.add(const Duration(minutes: 5)),
        showtimeId: 'st_01',
        cinemaId: 'cn_q1',
        movieTitle: 'Mai',
        posterUrl: 'https://example.com/poster.jpg',
        ageRating: 'T18',
        cinemaName: 'Cinema Quận 1',
        roomName: 'Phòng 1',
        format: '2D',
        showtimeStart: now.add(const Duration(hours: 2)),
        seats: [
          {'id': 'A1', 'type': 'standard', 'price': 80000},
          {'id': 'A2', 'type': 'standard', 'price': 80000},
        ],
        foods: [
          {'id': 'f_01', 'name': 'Combo Solo', 'quantity': 1, 'price': 75000},
        ],
        foodStatus: 'none',
        priceSnapshot: {
          'ticket_total': 160000,
          'food_total': 75000,
          'discount': 0,
          'total': 235000,
        },
        paymentMethod: 'vnpay',
        vnpTransactionNo: null,
        paidAt: null,
        checkedInBy: null,
        checkedInAt: null,
        cancelReason: null,
        createdAt: now,
      );

      final map = original.toMap();
      expect(map.containsKey('created_at'), isTrue);
      expect(map['created_at'], isNotNull);

      final deserialized = BookingModel.fromMap(map);
      expect(deserialized.code, equals(original.code));
      expect(deserialized.userId, equals(original.userId));
      expect(deserialized.movieTitle, equals(original.movieTitle));
      expect(deserialized.createdAt.toIso8601String(), equals(original.createdAt.toIso8601String()));
      expect(deserialized.seats.length, equals(2));
      expect(deserialized.foods.length, equals(1));
    });
  });
}
