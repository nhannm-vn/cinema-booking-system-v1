/// Booking model mapping from PostgreSQL `bookings` table.
/// References: TECH_STACK.md Section 4 & BUSINESS_RULES.md Section 6 & 7
class BookingModel {
  final String code;
  final String? userId;
  final String channel; // 'online', 'counter'
  final String? soldBy;
  final String status; // 'holding', 'paid', 'used', 'cancelled', 'expired'
  final DateTime? holdUntil;
  final String showtimeId;
  final String cinemaId;
  final String movieTitle;
  final String? posterUrl;
  final String? ageRating;
  final String cinemaName;
  final String roomName;
  final String format;
  final DateTime showtimeStart;
  final List<Map<String, dynamic>> seats;
  final List<Map<String, dynamic>> foods;
  final String foodStatus; // 'none', 'pending', 'delivered', 'cancelled'
  final Map<String, dynamic> priceSnapshot; // {ticket_total, food_total, discount, total}
  final String? paymentMethod;
  final String? vnpTransactionNo;
  final DateTime? paidAt;
  final String? checkedInBy;
  final DateTime? checkedInAt;
  final String? cancelReason;
  final DateTime createdAt;

  const BookingModel({
    required this.code,
    this.userId,
    this.channel = 'online',
    this.soldBy,
    required this.status,
    this.holdUntil,
    required this.showtimeId,
    required this.cinemaId,
    required this.movieTitle,
    this.posterUrl,
    this.ageRating,
    required this.cinemaName,
    required this.roomName,
    required this.format,
    required this.showtimeStart,
    this.seats = const [],
    this.foods = const [],
    this.foodStatus = 'none',
    required this.priceSnapshot,
    this.paymentMethod,
    this.vnpTransactionNo,
    this.paidAt,
    this.checkedInBy,
    this.checkedInAt,
    this.cancelReason,
    required this.createdAt,
  });

  /// No-show: paid quá 15 phút sau giờ chiếu mà chưa soát vé (BUSINESS_RULES.md mục 6.1)
  bool get isNoShow =>
      status == 'paid' &&
      checkedInAt == null &&
      DateTime.now().isAfter(showtimeStart.add(const Duration(minutes: 15)));

  /// Display status for ticket views
  String get displayStatus {
    if (isNoShow) return 'noShow';
    if (status == 'holding' && holdUntil != null && holdUntil!.isBefore(DateTime.now())) {
      return 'expired';
    }
    return status;
  }

  /// Khách có thể hủy nếu còn >= 2 giờ trước giờ chiếu (BUSINESS_RULES.md mục 10.1)
  bool get canCancel =>
      status == 'paid' &&
      DateTime.now().isBefore(showtimeStart.subtract(const Duration(hours: 2)));

  int get totalAmount => (priceSnapshot['total'] as int?) ?? 0;
  int get ticketTotal => (priceSnapshot['ticket_total'] as int?) ?? 0;
  int get foodTotal => (priceSnapshot['food_total'] as int?) ?? 0;
  int get discount => (priceSnapshot['discount'] as int?) ?? 0;

  String get seatNamesSummary =>
      seats.map((s) => s['id']?.toString() ?? '').where((id) => id.isNotEmpty).join(', ');

  String get foodSummary =>
      foods.map((f) => '${f['qty']}x ${f['name']}').join(', ');

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      code: map['code'] as String,
      userId: map['user_id'] as String?,
      channel: (map['channel'] as String?) ?? 'online',
      soldBy: map['sold_by'] as String?,
      status: map['status'] as String,
      holdUntil: map['hold_until'] != null ? DateTime.parse(map['hold_until'] as String).toLocal() : null,
      showtimeId: map['showtime_id'] as String,
      cinemaId: map['cinema_id'] as String,
      movieTitle: map['movie_title'] as String,
      posterUrl: map['poster_url'] as String?,
      ageRating: map['age_rating'] as String?,
      cinemaName: map['cinema_name'] as String,
      roomName: map['room_name'] as String,
      format: (map['format'] as String?) ?? '2D',
      showtimeStart: DateTime.parse(map['showtime_start'] as String).toLocal(),
      seats: List<Map<String, dynamic>>.from(map['seats'] ?? []),
      foods: List<Map<String, dynamic>>.from(map['foods'] ?? []),
      foodStatus: (map['food_status'] as String?) ?? 'none',
      priceSnapshot: Map<String, dynamic>.from(map['price_snapshot'] ?? {}),
      paymentMethod: map['payment_method'] as String?,
      vnpTransactionNo: map['vnp_transaction_no'] as String?,
      paidAt: map['paid_at'] != null ? DateTime.parse(map['paid_at'] as String).toLocal() : null,
      checkedInBy: map['checked_in_by'] as String?,
      checkedInAt: map['checked_in_at'] != null ? DateTime.parse(map['checked_in_at'] as String).toLocal() : null,
      cancelReason: map['cancel_reason'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'user_id': userId,
      'channel': channel,
      'sold_by': soldBy,
      'status': status,
      'hold_until': holdUntil?.toIso8601String(),
      'showtime_id': showtimeId,
      'cinema_id': cinemaId,
      'movie_title': movieTitle,
      'poster_url': posterUrl,
      'age_rating': ageRating,
      'cinema_name': cinemaName,
      'room_name': roomName,
      'format': format,
      'showtime_start': showtimeStart.toIso8601String(),
      'seats': seats,
      'foods': foods,
      'food_status': foodStatus,
      'price_snapshot': priceSnapshot,
      'payment_method': paymentMethod,
      'vnp_transaction_no': vnpTransactionNo,
      'paid_at': paidAt?.toIso8601String(),
      'checked_in_by': checkedInBy,
      'checked_in_at': checkedInAt?.toIso8601String(),
      'cancel_reason': cancelReason,
    };
  }
}
