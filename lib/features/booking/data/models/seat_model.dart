import '../../../../shared/widgets/seat_widget.dart';

/// Seat model representing row in `seats` table or layout seat definition.
/// References: TECH_STACK.md Section 4 & BUSINESS_RULES.md Section 5
class SeatModel {
  final String showtimeId;
  final String seatId; // 'A5', 'H3'
  final SeatType type;
  final String status; // 'available', 'holding', 'sold'
  final String? bookingCode;
  final String? holdHolder;
  final DateTime? holdUntil;
  final int price;

  const SeatModel({
    required this.showtimeId,
    required this.seatId,
    this.type = SeatType.standard,
    this.status = 'available',
    this.bookingCode,
    this.holdHolder,
    this.holdUntil,
    this.price = 0,
  });

  bool get isSold => status == 'sold';
  bool get isHolding {
    if (status != 'holding') return false;
    if (holdUntil == null) return false;
    // Lazy expiration check: holding past holdUntil is considered available
    return holdUntil!.isAfter(DateTime.now());
  }

  bool isHeldBy(String? userId) => isHolding && holdHolder == userId;

  factory SeatModel.fromMap(Map<String, dynamic> map, {SeatType type = SeatType.standard, int price = 0}) {
    return SeatModel(
      showtimeId: (map['showtime_id'] as String?) ?? '',
      seatId: map['seat_id'] as String,
      type: type,
      status: (map['status'] as String?) ?? 'available',
      bookingCode: map['booking_code'] as String?,
      holdHolder: map['hold_holder'] as String?,
      holdUntil: map['hold_until'] != null ? DateTime.parse(map['hold_until'] as String).toLocal() : null,
      price: price,
    );
  }

  Map<String, dynamic> toBookingJson() {
    return {
      'id': seatId,
      'type': type.name,
      'price': price,
    };
  }
}
