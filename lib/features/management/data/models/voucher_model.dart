/// Voucher model mapping from PostgreSQL `public.vouchers` table.
/// References: BUSINESS_RULES.md Section 8 & ROLE_FLOWS.md Section 5.6
class VoucherModel {
  final String code;
  final String type; // 'percent' or 'amount'
  final int value;
  final int minBookingAmount;
  final int? maxDiscount;
  final DateTime startDate;
  final DateTime expiresAt;
  final int maxUses;
  final int usedCount;
  final bool isActive;
  final DateTime createdAt;

  const VoucherModel({
    required this.code,
    required this.type,
    required this.value,
    this.minBookingAmount = 0,
    this.maxDiscount,
    required this.startDate,
    required this.expiresAt,
    required this.maxUses,
    this.usedCount = 0,
    this.isActive = true,
    required this.createdAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isExhausted => usedCount >= maxUses;
  bool get isUsable => isActive && !isExpired && !isExhausted;

  String get statusBadgeText {
    if (!isActive) return 'TẠM KHÓA';
    if (isExpired) return 'HẾT HẠN';
    if (isExhausted) return 'HẾT LƯỢT';
    return 'CÒN HẠN';
  }

  /// Calculates discount for a given booking ticket amount in integer VND.
  int calculateDiscount(int bookingAmount) {
    if (bookingAmount < minBookingAmount) return 0;
    if (!isUsable) return 0;

    int discount = 0;
    if (type == 'percent') {
      discount = ((bookingAmount * value) / 100).round();
      if (maxDiscount != null && discount > maxDiscount!) {
        discount = maxDiscount!;
      }
    } else {
      discount = value;
    }

    if (discount > bookingAmount) {
      discount = bookingAmount;
    }
    return discount;
  }

  factory VoucherModel.fromMap(Map<String, dynamic> map) {
    return VoucherModel(
      code: (map['code'] as String).toUpperCase(),
      type: (map['type'] as String?) ?? 'amount',
      value: (map['value'] as num).toInt(),
      minBookingAmount: (map['min_booking_amount'] as num?)?.toInt() ?? 0,
      maxDiscount: (map['max_discount'] as num?)?.toInt(),
      startDate: map['start_date'] != null
          ? DateTime.parse(map['start_date'] as String).toLocal()
          : (map['created_at'] != null ? DateTime.parse(map['created_at'] as String).toLocal() : DateTime.now()),
      expiresAt: DateTime.parse(map['expires_at'] as String).toLocal(),
      maxUses: (map['max_uses'] as num?)?.toInt() ?? 1,
      usedCount: (map['used_count'] as num?)?.toInt() ?? 0,
      isActive: (map['is_active'] as bool?) ?? true,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String).toLocal()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code.toUpperCase(),
      'type': type,
      'value': value,
      'min_booking_amount': minBookingAmount,
      'max_discount': maxDiscount,
      'start_date': startDate.toUtc().toIso8601String(),
      'expires_at': expiresAt.toUtc().toIso8601String(),
      'max_uses': maxUses,
      'used_count': usedCount,
      'is_active': isActive,
    };
  }

  VoucherModel copyWith({
    String? code,
    String? type,
    int? value,
    int? minBookingAmount,
    int? maxDiscount,
    DateTime? startDate,
    DateTime? expiresAt,
    int? maxUses,
    int? usedCount,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return VoucherModel(
      code: code ?? this.code,
      type: type ?? this.type,
      value: value ?? this.value,
      minBookingAmount: minBookingAmount ?? this.minBookingAmount,
      maxDiscount: maxDiscount ?? this.maxDiscount,
      startDate: startDate ?? this.startDate,
      expiresAt: expiresAt ?? this.expiresAt,
      maxUses: maxUses ?? this.maxUses,
      usedCount: usedCount ?? this.usedCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
