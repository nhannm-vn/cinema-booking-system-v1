import 'package:flutter_test/flutter_test.dart';
import 'package:cinema_booking_v1/features/management/data/models/audit_log_model.dart';

void main() {
  group('AuditLogModel Unit Tests', () {
    test('actionLabel translates business action codes accurately', () {
      final logCheckin = AuditLogModel(
        id: '1',
        actorRole: 'staff',
        action: 'checkIn',
        targetType: 'ticket',
        targetId: 't1',
        createdAt: DateTime.now(),
      );
      expect(logCheckin.actionLabel, 'SOÁT VÉ');

      final logShowtime = AuditLogModel(
        id: '2',
        actorRole: 'manager',
        action: 'cancelShowtime',
        targetType: 'showtime',
        targetId: 's1',
        createdAt: DateTime.now(),
      );
      expect(logShowtime.actionLabel, 'HỦY SUẤT');

      final logPrice = AuditLogModel(
        id: '3',
        actorRole: 'admin',
        action: 'changePrice',
        targetType: 'pricing',
        targetId: 'p1',
        createdAt: DateTime.now(),
      );
      expect(logPrice.actionLabel, 'ĐỔI GIÁ');

      final logVoucher = AuditLogModel(
        id: '4',
        actorRole: 'admin',
        action: 'createVoucher',
        targetType: 'voucher',
        targetId: 'v1',
        createdAt: DateTime.now(),
      );
      expect(logVoucher.actionLabel, 'TẠO VOUCHER');
    });

    test('toMap and fromMap retain oldData and newData JSON diffs', () {
      final log = AuditLogModel(
        id: 'log_999',
        actorId: 'usr_admin',
        actorRole: 'admin',
        actorName: 'Nguyen Admin',
        cinemaId: 'cn_q1',
        cinemaName: 'CGV Vincom',
        action: 'changePrice',
        targetType: 'pricing_settings',
        targetId: '1',
        reason: 'Tăng giá giờ cao điểm theo mùa lễ',
        oldData: {'base_2d': 80000, 'surcharge_prime': 10000},
        newData: {'base_2d': 85000, 'surcharge_prime': 15000},
        createdAt: DateTime.parse('2026-10-28T03:00:00Z'),
      );

      final map = log.toMap();
      expect(map['action'], 'changePrice');
      expect(map['old_data']['base_2d'], 80000);
      expect(map['new_data']['base_2d'], 85000);

      final restored = AuditLogModel.fromMap(map);
      expect(restored.id, 'log_999');
      expect(restored.actorRole, 'admin');
      expect(restored.reason, 'Tăng giá giờ cao điểm theo mùa lễ');
      expect(restored.oldData?['base_2d'], 80000);
      expect(restored.newData?['base_2d'], 85000);
    });
  });
}
