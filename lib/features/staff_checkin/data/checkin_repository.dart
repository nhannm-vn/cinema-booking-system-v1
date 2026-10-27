import 'package:supabase_flutter/supabase_flutter.dart';

/// Check-in verification result.
class CheckinResult {
  final bool isSuccess;
  final String? errorCode;
  final String message;
  final String? code;
  final String? movieTitle;
  final String? roomName;
  final String? showtimeStart;
  final String? seatsSummary;
  final String? foodsSummary;
  final String? ageRating;

  const CheckinResult({
    required this.isSuccess,
    this.errorCode,
    required this.message,
    this.code,
    this.movieTitle,
    this.roomName,
    this.showtimeStart,
    this.seatsSummary,
    this.foodsSummary,
    this.ageRating,
  });

  factory CheckinResult.fromRpc(Map<String, dynamic> map) {
    final bool success = (map['success'] as bool?) ?? false;
    final seatsList = map['seats'] as List<dynamic>? ?? [];
    final foodsList = map['foods'] as List<dynamic>? ?? [];

    final seatsStr = seatsList.map((s) => s['id']?.toString() ?? '').join(', ');
    final foodsStr = foodsList.map((f) => '${f['qty']}x ${f['name']}').join(', ');

    return CheckinResult(
      isSuccess: success,
      errorCode: map['error_code'] as String?,
      message: (map['message'] as String?) ?? (success ? 'Soát vé thành công' : 'Vé không hợp lệ'),
      code: map['code'] as String?,
      movieTitle: map['movie_title'] as String?,
      roomName: map['room_name'] as String?,
      showtimeStart: map['showtime_start'] as String?,
      seatsSummary: seatsStr,
      foodsSummary: foodsStr,
      ageRating: map['age_rating'] as String?,
    );
  }
}

/// Repository for Staff Checkin operations.
/// References: BUSINESS_RULES.md Section 8 & ROLE_FLOWS.md Section 3.1
class CheckinRepository {
  final SupabaseClient _supabase;

  CheckinRepository([SupabaseClient? supabase])
      : _supabase = supabase ?? Supabase.instance.client;

  /// Check-in ticket by 8-char booking code.
  Future<CheckinResult> checkIn(String bookingCode) async {
    final response = await _supabase.rpc('check_in', params: {
      'p_booking_code': bookingCode.trim().toUpperCase(),
    });

    return CheckinResult.fromRpc(Map<String, dynamic>.from(response as Map));
  }
}
