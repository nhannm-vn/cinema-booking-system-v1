/// Audit log model from PostgreSQL `public.audit_logs` table.
/// References: ROLE_FLOWS.md Section 5.8 & TECH_STACK.md Section 4
class AuditLogModel {
  final String id;
  final String? actorId;
  final String actorRole;
  final String? actorName;
  final String? cinemaId;
  final String? cinemaName;
  final String action;
  final String targetType;
  final String targetId;
  final String? reason;
  final Map<String, dynamic>? oldData;
  final Map<String, dynamic>? newData;
  final DateTime createdAt;

  const AuditLogModel({
    required this.id,
    this.actorId,
    required this.actorRole,
    this.actorName,
    this.cinemaId,
    this.cinemaName,
    required this.action,
    required this.targetType,
    required this.targetId,
    this.reason,
    this.oldData,
    this.newData,
    required this.createdAt,
  });

  String get actionLabel {
    switch (action) {
      case 'checkIn':
        return 'SOÁT VÉ';
      case 'cancelShowtime':
        return 'HỦY SUẤT';
      case 'refund':
      case 'cancelBooking':
        return 'HOÀN TIỀN';
      case 'changePrice':
        return 'ĐỔI GIÁ';
      case 'lockUser':
        return 'KHÓA USER';
      case 'unlockUser':
        return 'MỞ KHÓA USER';
      case 'createStaff':
        return 'TẠO NHÂN VIÊN';
      case 'createManager':
        return 'TẠO QUẢN LÝ';
      case 'updateRoomLayout':
        return 'SỬA SƠ ĐỒ GHẾ';
      case 'createVoucher':
        return 'TẠO VOUCHER';
      case 'updateVoucher':
        return 'SỬA VOUCHER';
      default:
        return action.toUpperCase();
    }
  }

  factory AuditLogModel.fromMap(Map<String, dynamic> map) {
    return AuditLogModel(
      id: map['id'] as String,
      actorId: map['actor_id'] as String?,
      actorRole: (map['actor_role'] as String?) ?? 'staff',
      actorName: (map['profiles'] as Map?)?['full_name'] as String?,
      cinemaId: map['cinema_id'] as String?,
      cinemaName: (map['cinemas'] as Map?)?['name'] as String?,
      action: (map['action'] as String?) ?? 'general',
      targetType: (map['target_type'] as String?) ?? '',
      targetId: (map['target_id'] as String?) ?? '',
      reason: map['reason'] as String?,
      oldData: map['old_data'] != null ? Map<String, dynamic>.from(map['old_data'] as Map) : null,
      newData: map['new_data'] != null ? Map<String, dynamic>.from(map['new_data'] as Map) : null,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String).toLocal()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'actor_id': actorId,
      'actor_role': actorRole,
      'cinema_id': cinemaId,
      'action': action,
      'target_type': targetType,
      'target_id': targetId,
      'reason': reason,
      'old_data': oldData,
      'new_data': newData,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
