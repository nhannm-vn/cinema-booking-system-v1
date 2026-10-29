import 'package:flutter_test/flutter_test.dart';
import 'package:cinema_booking_v1/features/management/data/models/pricing_settings_model.dart';

void main() {
  group('PricingSettingsModel Unit Tests', () {
    test('defaultSettings has expected base prices and surcharges', () {
      final settings = PricingSettingsModel.defaultSettings();
      expect(settings.base2d, 80000);
      expect(settings.base3d, 100000);
      expect(settings.baseImax, 120000);
      expect(settings.surchargeVip, 20000);
      expect(settings.surchargeCouple, 20000);
      expect(settings.surchargeWeekend, 10000);
      expect(settings.surchargePrime, 10000);
      expect(settings.primeStartHour, 18);
      expect(settings.primeEndHour, 22);
    });

    test('calculateSeatPrice 2D standard weekday non-prime returns base2d', () {
      final settings = PricingSettingsModel.defaultSettings();
      final price = settings.calculateSeatPrice(
        format: '2D',
        seatType: 'standard',
        isWeekend: false,
        isPrimeTime: false,
      );
      expect(price, 80000);
    });

    test('calculateSeatPrice 2D VIP weekday non-prime adds VIP surcharge', () {
      final settings = PricingSettingsModel.defaultSettings();
      final price = settings.calculateSeatPrice(
        format: '2D',
        seatType: 'vip',
        isWeekend: false,
        isPrimeTime: false,
      );
      expect(price, 100000);
    });

    test('calculateSeatPrice 3D couple weekend prime adds all surcharges with 2x base', () {
      final settings = PricingSettingsModel.defaultSettings();
      final price = settings.calculateSeatPrice(
        format: '3D',
        seatType: 'couple',
        isWeekend: true,
        isPrimeTime: true,
      );
      // (2 * base3d (100k)) + couple (20k) + weekend (10k) + prime (10k) = 240k
      expect(price, 240000);
    });

    test('calculateSeatPrice 2D couple weekday non-prime returns 2 * base2d + couple', () {
      final settings = PricingSettingsModel.defaultSettings();
      final price = settings.calculateSeatPrice(
        format: '2D',
        seatType: 'couple',
        isWeekend: false,
        isPrimeTime: false,
      );
      // (2 * base2d (80k)) + couple (20k) = 180k
      expect(price, 180000);
    });

    test('calculateSeatPrice IMAX VIP weekend prime adds IMAX base and surcharges', () {
      final settings = PricingSettingsModel.defaultSettings();
      final price = settings.calculateSeatPrice(
        format: 'IMAX',
        seatType: 'vip',
        isWeekend: true,
        isPrimeTime: true,
      );
      // baseImax (120k) + vip (20k) + weekend (10k) + prime (10k) = 160k
      expect(price, 160000);
    });

    test('toMap and fromMap serialize and deserialize accurately', () {
      final settings = PricingSettingsModel.defaultSettings();
      final map = settings.toMap();
      expect(map['base_2d'], 80000);
      expect(map['base_3d'], 100000);
      expect(map['base_imax'], 120000);

      final restored = PricingSettingsModel.fromMap(map);
      expect(restored.base2d, settings.base2d);
      expect(restored.base3d, settings.base3d);
      expect(restored.baseImax, settings.baseImax);
      expect(restored.surchargeVip, settings.surchargeVip);
      expect(restored.surchargeCouple, settings.surchargeCouple);
      expect(restored.surchargeWeekend, settings.surchargeWeekend);
      expect(restored.surchargePrime, settings.surchargePrime);
    });
  });
}
