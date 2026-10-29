import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/models/api_response.dart';
import '../models/seat_model.dart';

/// Repository for Seat status, Realtime stream and RPC hold_seats.
/// References: TECH_STACK.md Section 9, 12 & BUSINESS_RULES.md Section 5
class SeatRepository {
  final SupabaseClient _supabase;

  SeatRepository([SupabaseClient? supabase])
      : _supabase = supabase ?? Supabase.instance.client;

  /// Realtime stream for seats of a given showtime.
  Stream<List<SeatModel>> streamSeats(String showtimeId) {
    return _supabase
        .from('seats')
        .stream(primaryKey: ['showtime_id', 'seat_id'])
        .eq('showtime_id', showtimeId)
        .map((rows) => rows.map((r) => SeatModel.fromMap(r)).toList());
  }

  /// Call Postgres RPC `hold_seats` with row lock `for update`.
  /// Throws [SeatTakenException] if a seat was already taken by someone else.
  Future<DateTime> holdSeats({
    required String showtimeId,
    required String bookingCode,
    required List<String> seatIds,
    required Map<String, dynamic> booking,
    int holdMinutes = 5,
  }) async {
    try {
      final res = await _supabase.rpc('hold_seats', params: {
        'p_showtime_id': showtimeId,
        'p_booking_code': bookingCode,
        'p_seat_ids': seatIds,
        'p_hold_minutes': holdMinutes,
        'p_booking': booking,
      });

      return DateTime.parse(res as String).toLocal();
    } on PostgrestException catch (e) {
      if (e.message.startsWith('SEAT_TAKEN:')) {
        final takenSeat = e.message.replaceFirst('SEAT_TAKEN:', '');
        throw SeatTakenException(takenSeat);
      }
      rethrow;
    }
  }

  /// Release held seats when user leaves or timer expires.
  Future<void> releaseHold(String bookingCode) async {
    try {
      await _supabase.rpc('release_hold', params: {
        'p_booking_code': bookingCode,
      });
    } catch (_) {
      // Ignore network errors on teardown
    }
  }
}
