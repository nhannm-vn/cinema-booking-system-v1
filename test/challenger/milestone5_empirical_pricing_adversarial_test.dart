import 'package:flutter_test/flutter_test.dart';
import 'package:cinema_booking_v1/features/booking/data/models/booking_model.dart';
import 'package:cinema_booking_v1/features/management/data/models/pricing_settings_model.dart';

void main() {
  group('Empirical Challenger: 36-Combination Exact Pricing Oracle Matrix', () {
    final settings = PricingSettingsModel.defaultSettings();

    // Mapping: { 'format|seatType|isWeekend|isPrimeTime': expectedVndPrice }
    final Map<String, int> exactExpectedPrices = {
      // 2D Standard
      '2D|standard|false|false': 80000,
      '2D|standard|false|true': 90000,
      '2D|standard|true|false': 90000,
      '2D|standard|true|true': 100000,

      // 2D VIP (+20k)
      '2D|vip|false|false': 100000,
      '2D|vip|false|true': 110000,
      '2D|vip|true|false': 110000,
      '2D|vip|true|true': 120000,

      // 2D Couple (2 * 80k + 20k = 180k base + extras)
      '2D|couple|false|false': 180000,
      '2D|couple|false|true': 190000,
      '2D|couple|true|false': 190000,
      '2D|couple|true|true': 200000,

      // 3D Standard
      '3D|standard|false|false': 100000,
      '3D|standard|false|true': 110000,
      '3D|standard|true|false': 110000,
      '3D|standard|true|true': 120000,

      // 3D VIP (+20k)
      '3D|vip|false|false': 120000,
      '3D|vip|false|true': 130000,
      '3D|vip|true|false': 130000,
      '3D|vip|true|true': 140000,

      // 3D Couple (2 * 100k + 20k = 220k base + extras)
      '3D|couple|false|false': 220000,
      '3D|couple|false|true': 230000,
      '3D|couple|true|false': 230000,
      '3D|couple|true|true': 240000,

      // IMAX Standard
      'IMAX|standard|false|false': 120000,
      'IMAX|standard|false|true': 130000,
      'IMAX|standard|true|false': 130000,
      'IMAX|standard|true|true': 140000,

      // IMAX VIP (+20k)
      'IMAX|vip|false|false': 140000,
      'IMAX|vip|false|true': 150000,
      'IMAX|vip|true|false': 150000,
      'IMAX|vip|true|true': 160000,

      // IMAX Couple (2 * 120k + 20k = 260k base + extras)
      'IMAX|couple|false|false': 260000,
      'IMAX|couple|false|true': 270000,
      'IMAX|couple|true|false': 270000,
      'IMAX|couple|true|true': 280000,
    };

    test('Strict verification of all 36 pricing combinations against exact oracle', () {
      expect(exactExpectedPrices.length, 36, reason: 'Oracle table must contain exactly 36 distinct permutations');

      exactExpectedPrices.forEach((key, expectedVnd) {
        final parts = key.split('|');
        final format = parts[0];
        final seatType = parts[1];
        final isWeekend = parts[2] == 'true';
        final isPrime = parts[3] == 'true';

        final computed = settings.calculateSeatPrice(
          format: format,
          seatType: seatType,
          isWeekend: isWeekend,
          isPrimeTime: isPrime,
        );

        expect(
          computed,
          expectedVnd,
          reason: 'Failed exact match for $key: expected $expectedVnd VND but got $computed VND',
        );
      });
    });

    test('Couple seat pricing strictly doubles base format price', () {
      for (final format in ['2D', '3D', 'IMAX']) {
        final base = format == '2D' ? 80000 : (format == '3D' ? 100000 : 120000);

        for (final isWeekend in [false, true]) {
          for (final isPrime in [false, true]) {
            final couplePrice = settings.calculateSeatPrice(
              format: format,
              seatType: 'couple',
              isWeekend: isWeekend,
              isPrimeTime: isPrime,
            );

            final standardPrice = settings.calculateSeatPrice(
              format: format,
              seatType: 'standard',
              isWeekend: isWeekend,
              isPrimeTime: isPrime,
            );

            // Notice: Couple price = (2 * base) + couple + weekend + prime
            // Standard price = base + weekend + prime
            // Therefore: couplePrice - standardPrice MUST equal base + coupleSurcharge!
            final diff = couplePrice - standardPrice;
            expect(
              diff,
              base + settings.surchargeCouple,
              reason: 'Couple price difference from standard must be exactly (base + coupleSurcharge) '
                  'for format=$format, weekend=$isWeekend, prime=$isPrime',
            );
          }
        }
      }
    });

    test('Case-insensitivity stress test on format and seat type variations', () {
      final formatVariations = {
        '2d': 180000,
        '2D': 180000,
        '3d': 220000,
        '3D': 220000,
        'imax': 260000,
        'IMAX': 260000,
        'Imax': 260000,
        'iMaX': 260000,
      };

      final seatCasingVariations = ['couple', 'COUPLE', 'Couple', 'CoUpLe', 'cOuPlE'];

      formatVariations.forEach((fmt, expectedPrice) {
        for (final seatCasing in seatCasingVariations) {
          final price = settings.calculateSeatPrice(
            format: fmt,
            seatType: seatCasing,
            isWeekend: false,
            isPrimeTime: false,
          );
          expect(
            price,
            expectedPrice,
            reason: 'Case sensitivity mismatch for format=$fmt, seatType=$seatCasing',
          );
        }
      });
    });

    test('Zero values and promotional pricing resilience', () {
      final zeroSettings = PricingSettingsModel(
        id: 1,
        base2d: 0,
        base3d: 0,
        baseImax: 0,
        surchargeVip: 0,
        surchargeCouple: 0,
        surchargeWeekend: 0,
        surchargePrime: 0,
        updatedAt: DateTime.now(),
      );

      // All zero inputs produce exactly 0 VND for standard, vip, and couple
      expect(zeroSettings.calculateSeatPrice(format: '2D', seatType: 'standard', isWeekend: false, isPrimeTime: false), 0);
      expect(zeroSettings.calculateSeatPrice(format: '3D', seatType: 'vip', isWeekend: true, isPrimeTime: true), 0);
      expect(zeroSettings.calculateSeatPrice(format: 'IMAX', seatType: 'couple', isWeekend: true, isPrimeTime: true), 0);
    });

    test('Large VND integer calculations (no overflow, integer precision)', () {
      final largeSettings = PricingSettingsModel(
        id: 1,
        base2d: 1000000000, // 1 billion VND
        base3d: 2000000000, // 2 billion VND
        baseImax: 3000000000, // 3 billion VND
        surchargeVip: 500000000,
        surchargeCouple: 500000000,
        surchargeWeekend: 100000000,
        surchargePrime: 100000000,
        updatedAt: DateTime.now(),
      );

      // IMAX Couple Weekend Prime: (2 * 3B) + 500M + 100M + 100M = 6,700,000,000 VND
      final price = largeSettings.calculateSeatPrice(
        format: 'IMAX',
        seatType: 'couple',
        isWeekend: true,
        isPrimeTime: true,
      );
      expect(price, 6700000000);
    });

    test('Cancellation 2-hour threshold boundary stress test at precision levels', () {
      final now = DateTime.now();

      // Case 1: 2 hours and 1 second in future -> CAN cancel
      final bookingCanCancel = BookingModel(
        code: 'CANCEL01',
        status: 'paid',
        showtimeStart: now.add(const Duration(hours: 2, seconds: 1)),
        showtimeId: 'st_1',
        cinemaId: 'cn_q1',
        cinemaName: 'Cinema Q1',
        roomName: 'Phòng 1',
        format: '2D',
        movieTitle: 'Test Movie',
        priceSnapshot: const {'total': 100000},
        seats: const [],
        foods: const [],
        createdAt: now,
      );
      expect(bookingCanCancel.canCancel, isTrue);

      // Case 2: 1 hour 59 minutes 59 seconds in future -> CANNOT cancel
      final bookingCannotCancel = BookingModel(
        code: 'CANCEL02',
        status: 'paid',
        showtimeStart: now.add(const Duration(hours: 1, minutes: 59, seconds: 59)),
        showtimeId: 'st_1',
        cinemaId: 'cn_q1',
        cinemaName: 'Cinema Q1',
        roomName: 'Phòng 1',
        format: '2D',
        movieTitle: 'Test Movie',
        priceSnapshot: const {'total': 100000},
        seats: const [],
        foods: const [],
        createdAt: now,
      );
      expect(bookingCannotCancel.canCancel, isFalse);

      // Case 3: Other statuses (holding, used, cancelled, expired, noShow) even with 10h remaining -> CANNOT cancel
      for (final nonPaidStatus in ['holding', 'used', 'cancelled', 'expired', 'noShow']) {
        final b = BookingModel(
          code: 'STATUS_${nonPaidStatus.toUpperCase()}',
          status: nonPaidStatus,
          showtimeStart: now.add(const Duration(hours: 10)),
          showtimeId: 'st_1',
          cinemaId: 'cn_q1',
          cinemaName: 'Cinema Q1',
          roomName: 'Phòng 1',
          format: '2D',
          movieTitle: 'Test Movie',
          priceSnapshot: const {'total': 100000},
          seats: const [],
          foods: const [],
          createdAt: now,
        );
        expect(b.canCancel, isFalse, reason: 'Status $nonPaidStatus must never be eligible for cancellation');
      }
    });
  });
}
