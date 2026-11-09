import '../../../management/data/models/pricing_settings_model.dart';

/// Showtime model mapping from PostgreSQL `showtimes` table.
/// References: TECH_STACK.md Section 4 & BUSINESS_RULES.md Section 3.3
class ShowtimeModel {
  final String id;
  final String movieId;
  final String cinemaId;
  final String roomId;
  final String format; // '2D', '3D', 'IMAX'
  final DateTime startTime;
  final DateTime endTime;
  final String status; // 'active', 'cancelled'
  final String? cancelReason;
  final int totalSeats;
  final int soldSeats;
  final int minPrice;
  final String? movieTitle;
  final String? roomName;
  final String? cinemaName;
  final String? ageRating;
  final String? posterUrl;

  const ShowtimeModel({
    required this.id,
    required this.movieId,
    required this.cinemaId,
    required this.roomId,
    required this.format,
    required this.startTime,
    required this.endTime,
    this.status = 'active',
    this.cancelReason,
    required this.totalSeats,
    this.soldSeats = 0,
    this.minPrice = 80000,
    this.movieTitle,
    this.roomName,
    this.cinemaName,
    this.ageRating,
    this.posterUrl,
  });

  bool get isSoldOut => soldSeats >= totalSeats;
  bool get isCancelled => status == 'cancelled';
  bool get isPast => startTime.isBefore(DateTime.now());

  /// Computes default minimum ticket price according to format and time per BUSINESS_RULES.md Section 4:
  /// Standard 2D: 80.000 đ
  /// Standard 3D: 100.000 đ
  /// Standard IMAX: 120.000 đ
  /// Weekend (Fri, Sat, Sun): +10.000 đ
  /// Prime time (18:00 - 22:00): +10.000 đ
  static int computeDefaultMinPrice({
    required String format,
    required DateTime startTime,
    int? customMinPrice,
    PricingSettingsModel? pricing,
  }) {
    if (customMinPrice != null && customMinPrice > 0) return customMinPrice;

    final isWeekend = startTime.weekday == DateTime.friday ||
        startTime.weekday == DateTime.saturday ||
        startTime.weekday == DateTime.sunday;
    final primeStart = pricing?.primeStartHour ?? 18;
    final primeEnd = pricing?.primeEndHour ?? 22;
    final isPrime = startTime.hour >= primeStart && startTime.hour < primeEnd;

    if (pricing != null) {
      return pricing.calculateSeatPrice(
        format: format,
        seatType: 'standard',
        isWeekend: isWeekend,
        isPrimeTime: isPrime,
      );
    }

    int base = 80000;
    final fmt = format.toUpperCase().trim();
    if (fmt.contains('3D')) {
      base = 100000;
    } else if (fmt.contains('IMAX')) {
      base = 120000;
    }

    return base + (isWeekend ? 10000 : 0) + (isPrime ? 10000 : 0);
  }

  factory ShowtimeModel.fromMap(Map<String, dynamic> map, {PricingSettingsModel? pricing}) {
    final formatStr = (map['format'] as String?) ?? '2D';
    final startTime = DateTime.parse(map['start_time'] as String).toLocal();
    final endTime = DateTime.parse(map['end_time'] as String).toLocal();
    final rawMinPrice = (map['min_price'] as num?)?.toInt();

    return ShowtimeModel(
      id: map['id'] as String,
      movieId: map['movie_id'] as String,
      cinemaId: map['cinema_id'] as String,
      roomId: map['room_id'] as String,
      format: formatStr,
      startTime: startTime,
      endTime: endTime,
      status: (map['status'] as String?) ?? 'active',
      cancelReason: map['cancel_reason'] as String?,
      totalSeats: (map['total_seats'] as int?) ?? 0,
      soldSeats: (map['sold_seats'] as int?) ?? 0,
      minPrice: computeDefaultMinPrice(
        format: formatStr,
        startTime: startTime,
        customMinPrice: rawMinPrice,
        pricing: pricing,
      ),
      movieTitle: map['movie_title'] as String?,
      roomName: map['room_name'] as String?,
      cinemaName: map['cinema_name'] as String?,
      ageRating: map['age_rating'] as String?,
      posterUrl: map['poster_url'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'movie_id': movieId,
      'cinema_id': cinemaId,
      'room_id': roomId,
      'format': format,
      'start_time': startTime.toUtc().toIso8601String(),
      'end_time': endTime.toUtc().toIso8601String(),
      'status': status,
      'cancel_reason': cancelReason,
      'total_seats': totalSeats,
      'sold_seats': soldSeats,
    };
  }

  ShowtimeModel copyWith({
    String? id,
    String? movieId,
    String? cinemaId,
    String? roomId,
    String? format,
    DateTime? startTime,
    DateTime? endTime,
    String? status,
    String? cancelReason,
    int? totalSeats,
    int? soldSeats,
    int? minPrice,
    String? movieTitle,
    String? roomName,
    String? cinemaName,
    bool? isCancelled,
    String? ageRating,
    String? posterUrl,
  }) {
    return ShowtimeModel(
      id: id ?? this.id,
      movieId: movieId ?? this.movieId,
      cinemaId: cinemaId ?? this.cinemaId,
      roomId: roomId ?? this.roomId,
      format: format ?? this.format,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: (isCancelled ?? this.isCancelled) ? 'cancelled' : (status ?? this.status),
      cancelReason: cancelReason ?? this.cancelReason,
      totalSeats: totalSeats ?? this.totalSeats,
      soldSeats: soldSeats ?? this.soldSeats,
      minPrice: minPrice ?? this.minPrice,
      movieTitle: movieTitle ?? this.movieTitle,
      roomName: roomName ?? this.roomName,
      cinemaName: cinemaName ?? this.cinemaName,
      ageRating: ageRating ?? this.ageRating,
      posterUrl: posterUrl ?? this.posterUrl,
    );
  }
}
