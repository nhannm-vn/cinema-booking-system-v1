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
  });

  bool get isSoldOut => soldSeats >= totalSeats;
  bool get isCancelled => status == 'cancelled';
  bool get isPast => startTime.isBefore(DateTime.now());

  factory ShowtimeModel.fromMap(Map<String, dynamic> map) {
    return ShowtimeModel(
      id: map['id'] as String,
      movieId: map['movie_id'] as String,
      cinemaId: map['cinema_id'] as String,
      roomId: map['room_id'] as String,
      format: (map['format'] as String?) ?? '2D',
      startTime: DateTime.parse(map['start_time'] as String).toLocal(),
      endTime: DateTime.parse(map['end_time'] as String).toLocal(),
      status: (map['status'] as String?) ?? 'active',
      cancelReason: map['cancel_reason'] as String?,
      totalSeats: (map['total_seats'] as int?) ?? 0,
      soldSeats: (map['sold_seats'] as int?) ?? 0,
      minPrice: (map['min_price'] as int?) ?? 80000,
      movieTitle: map['movie_title'] as String?,
      roomName: map['room_name'] as String?,
      cinemaName: map['cinema_name'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'movie_id': movieId,
      'cinema_id': cinemaId,
      'room_id': roomId,
      'format': format,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'status': status,
      'cancel_reason': cancelReason,
      'total_seats': totalSeats,
      'sold_seats': soldSeats,
    };
  }
}
