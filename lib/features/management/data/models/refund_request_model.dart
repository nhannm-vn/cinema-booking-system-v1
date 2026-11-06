/// Yêu cầu hoàn vé của khách (bảng `refund_requests`).
class RefundRequestModel {
  final String id;
  final String bookingCode;
  final String userId;
  final String cinemaId;
  final String cinemaName;
  final String movieTitle;
  final DateTime showtimeStart;
  final int amount;
  final String? reason;
  final String status; // pending | completed | rejected
  final String? sepayTransactionId;
  final DateTime? processedAt;
  final DateTime createdAt;

  const RefundRequestModel({
    required this.id,
    required this.bookingCode,
    required this.userId,
    required this.cinemaId,
    required this.cinemaName,
    required this.movieTitle,
    required this.showtimeStart,
    required this.amount,
    this.reason,
    required this.status,
    this.sepayTransactionId,
    this.processedAt,
    required this.createdAt,
  });

  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';

  factory RefundRequestModel.fromMap(Map<String, dynamic> map) {
    return RefundRequestModel(
      id: map['id'] as String,
      bookingCode: map['booking_code'] as String,
      userId: map['user_id'] as String,
      cinemaId: map['cinema_id'] as String,
      cinemaName: (map['cinema_name'] as String?) ?? '',
      movieTitle: (map['movie_title'] as String?) ?? '',
      showtimeStart: DateTime.parse(map['showtime_start'] as String).toLocal(),
      amount: (map['amount'] as num).toInt(),
      reason: map['reason'] as String?,
      status: (map['status'] as String?) ?? 'pending',
      sepayTransactionId: map['sepay_transaction_id'] as String?,
      processedAt: map['processed_at'] != null
          ? DateTime.parse(map['processed_at'] as String).toLocal()
          : null,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }
}
