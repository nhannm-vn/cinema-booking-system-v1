import 'package:flutter_test/flutter_test.dart';
import 'package:cinema_booking_v1/features/booking/data/models/showtime_model.dart';
import 'package:cinema_booking_v1/features/management/data/models/pricing_settings_model.dart';

void main() {
  group('Showtime format & pricing tests', () {
    test('computeDefaultMinPrice computes correct base price for 2D, 3D, and IMAX on weekday', () {
      // Wednesday at 10:00 (Weekday, non-prime)
      final wedMorning = DateTime(2026, 11, 4, 10, 0);

      final price2d = ShowtimeModel.computeDefaultMinPrice(
        format: '2D',
        startTime: wedMorning,
      );
      final price3d = ShowtimeModel.computeDefaultMinPrice(
        format: '3D',
        startTime: wedMorning,
      );
      final priceImax = ShowtimeModel.computeDefaultMinPrice(
        format: 'IMAX',
        startTime: wedMorning,
      );

      expect(price2d, equals(80000));
      expect(price3d, equals(100000));
      expect(priceImax, equals(120000));
    });

    test('computeDefaultMinPrice applies weekend and prime time surcharges correctly', () {
      // Saturday at 19:00 (Weekend + Prime)
      final satPrime = DateTime(2026, 11, 7, 19, 0);

      final price2d = ShowtimeModel.computeDefaultMinPrice(
        format: '2D',
        startTime: satPrime,
      );
      final price3d = ShowtimeModel.computeDefaultMinPrice(
        format: '3D',
        startTime: satPrime,
      );
      final priceImax = ShowtimeModel.computeDefaultMinPrice(
        format: 'IMAX',
        startTime: satPrime,
      );

      // Base + 10k weekend + 10k prime = Base + 20k
      expect(price2d, equals(100000));
      expect(price3d, equals(120000));
      expect(priceImax, equals(140000));
    });

    test('ShowtimeModel.fromMap computes format-specific minPrice when min_price is missing or 0', () {
      final wedMorning = DateTime(2026, 11, 4, 14, 0).toUtc().toIso8601String();

      final model2d = ShowtimeModel.fromMap({
        'id': 'st_2d',
        'movie_id': 'm1',
        'cinema_id': 'c1',
        'room_id': 'r1',
        'format': '2D',
        'start_time': wedMorning,
        'end_time': wedMorning,
      });

      final model3d = ShowtimeModel.fromMap({
        'id': 'st_3d',
        'movie_id': 'm1',
        'cinema_id': 'c1',
        'room_id': 'r2',
        'format': '3D',
        'start_time': wedMorning,
        'end_time': wedMorning,
      });

      final modelImax = ShowtimeModel.fromMap({
        'id': 'st_imax',
        'movie_id': 'm1',
        'cinema_id': 'c1',
        'room_id': 'r3',
        'format': 'IMAX',
        'start_time': wedMorning,
        'end_time': wedMorning,
      });

      expect(model2d.minPrice, equals(80000));
      expect(model3d.minPrice, equals(100000));
      expect(modelImax.minPrice, equals(120000));
    });

    test('ShowtimeModel respects custom pricing settings when provided', () {
      final wedMorning = DateTime(2026, 11, 4, 10, 0);
      final customPricing = PricingSettingsModel(
        base2d: 90000,
        base3d: 110000,
        baseImax: 150000,
        surchargeVip: 25000,
        surchargeCouple: 30000,
        surchargeWeekend: 15000,
        surchargePrime: 15000,
        updatedAt: DateTime.now(),
      );

      final price2d = ShowtimeModel.computeDefaultMinPrice(
        format: '2D',
        startTime: wedMorning,
        pricing: customPricing,
      );
      final price3d = ShowtimeModel.computeDefaultMinPrice(
        format: '3D',
        startTime: wedMorning,
        pricing: customPricing,
      );
      final priceImax = ShowtimeModel.computeDefaultMinPrice(
        format: 'IMAX',
        startTime: wedMorning,
        pricing: customPricing,
      );

      expect(price2d, equals(90000));
      expect(price3d, equals(110000));
      expect(priceImax, equals(150000));
    });
  });
}
