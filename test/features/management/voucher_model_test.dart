import 'package:flutter_test/flutter_test.dart';
import 'package:cinema_booking_v1/features/management/data/models/voucher_model.dart';

void main() {
  group('VoucherModel Unit Tests', () {
    test('calculateDiscount for percent voucher without maxDiscount', () {
      final voucher = VoucherModel(
        code: 'SALE20',
        type: 'percent',
        value: 20,
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        expiresAt: DateTime.now().add(const Duration(days: 10)),
        maxUses: 100,
        createdAt: DateTime.now(),
      );

      expect(voucher.isUsable, isTrue);
      expect(voucher.calculateDiscount(200000), 40000);
    });

    test('calculateDiscount for percent voucher with maxDiscount cap', () {
      final voucher = VoucherModel(
        code: 'SALE50CAP',
        type: 'percent',
        value: 50,
        maxDiscount: 30000,
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        expiresAt: DateTime.now().add(const Duration(days: 10)),
        maxUses: 100,
        createdAt: DateTime.now(),
      );

      // 50% of 200k = 100k, capped at 30k
      expect(voucher.calculateDiscount(200000), 30000);
    });

    test('calculateDiscount for amount voucher', () {
      final voucher = VoucherModel(
        code: 'FLAT50K',
        type: 'amount',
        value: 50000,
        minBookingAmount: 100000,
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        expiresAt: DateTime.now().add(const Duration(days: 10)),
        maxUses: 100,
        createdAt: DateTime.now(),
      );

      // Less than min booking amount
      expect(voucher.calculateDiscount(80000), 0);
      // Equal or greater than min booking amount
      expect(voucher.calculateDiscount(150000), 50000);
    });

    test('statusBadgeText reflects lifecycle states accurately', () {
      final activeVoucher = VoucherModel(
        code: 'ACTIVE1',
        type: 'amount',
        value: 10000,
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        expiresAt: DateTime.now().add(const Duration(days: 10)),
        maxUses: 10,
        usedCount: 2,
        isActive: true,
        createdAt: DateTime.now(),
      );
      expect(activeVoucher.statusBadgeText, 'CÒN HẠN');

      final lockedVoucher = activeVoucher.copyWith(isActive: false);
      expect(lockedVoucher.statusBadgeText, 'TẠM KHÓA');

      final expiredVoucher = activeVoucher.copyWith(
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(expiredVoucher.statusBadgeText, 'HẾT HẠN');

      final exhaustedVoucher = activeVoucher.copyWith(usedCount: 10);
      expect(exhaustedVoucher.statusBadgeText, 'HẾT LƯỢT');
    });

    test('toMap and fromMap serialize and deserialize properly', () {
      final voucher = VoucherModel(
        code: 'PROMO10',
        type: 'percent',
        value: 10,
        minBookingAmount: 50000,
        maxDiscount: 20000,
        startDate: DateTime.parse('2026-10-01T00:00:00Z'),
        expiresAt: DateTime.parse('2026-12-31T23:59:59Z'),
        maxUses: 50,
        usedCount: 5,
        isActive: true,
        createdAt: DateTime.parse('2026-10-01T00:00:00Z'),
      );

      final map = voucher.toMap();
      expect(map['code'], 'PROMO10');
      expect(map['value'], 10);

      final restored = VoucherModel.fromMap(map);
      expect(restored.code, 'PROMO10');
      expect(restored.value, 10);
      expect(restored.minBookingAmount, 50000);
      expect(restored.maxDiscount, 20000);
      expect(restored.maxUses, 50);
      expect(restored.usedCount, 5);
      expect(restored.isActive, isTrue);
    });
  });
}
