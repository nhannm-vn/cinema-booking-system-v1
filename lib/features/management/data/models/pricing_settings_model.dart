/// Pricing settings model from `public.pricing_settings` table.
/// References: BUSINESS_RULES.md Section 4 & ROLE_FLOWS.md Section 5.5
class PricingSettingsModel {
  final int id;
  final int base2d;
  final int base3d;
  final int baseImax;
  final int surchargeVip;
  final int surchargeCouple;
  final int surchargeWeekend;
  final int surchargePrime;
  final int primeStartHour;
  final int primeEndHour;
  final DateTime updatedAt;

  const PricingSettingsModel({
    this.id = 1,
    required this.base2d,
    required this.base3d,
    required this.baseImax,
    required this.surchargeVip,
    required this.surchargeCouple,
    required this.surchargeWeekend,
    required this.surchargePrime,
    this.primeStartHour = 18,
    this.primeEndHour = 22,
    required this.updatedAt,
  });

  /// Business formula calculation per BUSINESS_RULES.md Section 4:
  /// Standard: base[format] + weekendExtra + primeExtra
  /// VIP: base[format] + surchargeVip + weekendExtra + primeExtra
  /// Couple: 2 * base[format] + surchargeCouple + weekendExtra + primeExtra
  int calculateSeatPrice({
    required String format,
    required String seatType, // 'standard', 'vip', 'couple'
    required bool isWeekend,
    required bool isPrimeTime,
  }) {
    int base = base2d;
    final fmt = format.toUpperCase();
    if (fmt == '3D') {
      base = base3d;
    } else if (fmt == 'IMAX') {
      base = baseImax;
    }

    final weekendExtra = isWeekend ? surchargeWeekend : 0;
    final primeExtra = isPrimeTime ? surchargePrime : 0;

    final type = seatType.toLowerCase();
    switch (type) {
      case 'vip':
        return base + surchargeVip + weekendExtra + primeExtra;
      case 'couple':
        // Couple seat base price is doubled per BUSINESS_RULES.md Section 4:
        // Ghế đôi = 2 × base[format] + couple + (cuối tuần ? weekend : 0) + (giờ vàng ? prime : 0)
        return (2 * base) + surchargeCouple + weekendExtra + primeExtra;
      case 'standard':
      default:
        return base + weekendExtra + primeExtra;
    }
  }

  factory PricingSettingsModel.defaultSettings() {
    return PricingSettingsModel(
      id: 1,
      base2d: 80000,
      base3d: 100000,
      baseImax: 120000,
      surchargeVip: 20000,
      surchargeCouple: 20000,
      surchargeWeekend: 10000,
      surchargePrime: 10000,
      primeStartHour: 18,
      primeEndHour: 22,
      updatedAt: DateTime.now(),
    );
  }

  factory PricingSettingsModel.fromMap(Map<String, dynamic> map) {
    return PricingSettingsModel(
      id: (map['id'] as num?)?.toInt() ?? 1,
      base2d: (map['base_2d'] as num?)?.toInt() ?? 80000,
      base3d: (map['base_3d'] as num?)?.toInt() ?? 100000,
      baseImax: (map['base_imax'] as num?)?.toInt() ?? 120000,
      surchargeVip: (map['surcharge_vip'] as num?)?.toInt() ?? 20000,
      surchargeCouple: (map['surcharge_couple'] as num?)?.toInt() ?? 20000,
      surchargeWeekend: (map['surcharge_weekend'] as num?)?.toInt() ?? 10000,
      surchargePrime: (map['surcharge_prime'] as num?)?.toInt() ?? 10000,
      primeStartHour: (map['prime_start_hour'] as num?)?.toInt() ?? 18,
      primeEndHour: (map['prime_end_hour'] as num?)?.toInt() ?? 22,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String).toLocal()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'base_2d': base2d,
      'base_3d': base3d,
      'base_imax': baseImax,
      'surcharge_vip': surchargeVip,
      'surcharge_couple': surchargeCouple,
      'surcharge_weekend': surchargeWeekend,
      'surcharge_prime': surchargePrime,
      'prime_start_hour': primeStartHour,
      'prime_end_hour': primeEndHour,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  PricingSettingsModel copyWith({
    int? base2d,
    int? base3d,
    int? baseImax,
    int? surchargeVip,
    int? surchargeCouple,
    int? surchargeWeekend,
    int? surchargePrime,
    int? primeStartHour,
    int? primeEndHour,
    DateTime? updatedAt,
  }) {
    return PricingSettingsModel(
      id: id,
      base2d: base2d ?? this.base2d,
      base3d: base3d ?? this.base3d,
      baseImax: baseImax ?? this.baseImax,
      surchargeVip: surchargeVip ?? this.surchargeVip,
      surchargeCouple: surchargeCouple ?? this.surchargeCouple,
      surchargeWeekend: surchargeWeekend ?? this.surchargeWeekend,
      surchargePrime: surchargePrime ?? this.surchargePrime,
      primeStartHour: primeStartHour ?? this.primeStartHour,
      primeEndHour: primeEndHour ?? this.primeEndHour,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
