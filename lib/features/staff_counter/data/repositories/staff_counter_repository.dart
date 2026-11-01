import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../booking/data/models/showtime_model.dart';

/// Repository xử lý nghiệp vụ bán vé tại quầy (S20 & S21).
/// Tham chiếu: BUSINESS_RULES.md Section 10 & TECH_STACK.md RPC sell_counter
class StaffCounterRepository {
  final SupabaseClient? _client;

  StaffCounterRepository([SupabaseClient? supabase]) : _client = supabase;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  /// Lấy danh sách suất chiếu của rạp hôm nay phục vụ bán vé tại quầy.
  Future<List<ShowtimeModel>> getCounterShowtimes(String cinemaId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final response = await _supabase
        .from('showtimes')
        .select('*, rooms(name), cinemas(name), movies(title)')
        .eq('cinema_id', cinemaId)
        .eq('status', 'active')
        .gte('start_time', startOfDay.toUtc().toIso8601String())
        .lte('start_time', endOfDay.toUtc().toIso8601String())
        .order('start_time', ascending: true);

    return (response as List).map((row) {
      final room = row['rooms'] as Map<String, dynamic>?;
      final cinema = row['cinemas'] as Map<String, dynamic>?;
      final movie = row['movies'] as Map<String, dynamic>?;

      final enriched = Map<String, dynamic>.from(row);
      enriched['room_name'] = room?['name'];
      enriched['cinema_name'] = cinema?['name'];
      enriched['movie_title'] = movie?['title'];

      return ShowtimeModel.fromMap(enriched);
    }).toList();
  }

  /// Giữ ghế 3 phút tại quầy qua RPC hold_seats.
  Future<DateTime> holdCounterSeats({
    required String showtimeId,
    required String bookingCode,
    required List<String> seatIds,
    required Map<String, dynamic> booking,
  }) async {
    final response = await _supabase.rpc('hold_seats', params: {
      'p_showtime_id': showtimeId,
      'p_booking_code': bookingCode,
      'p_seat_ids': seatIds,
      'p_hold_minutes': 3, // Giữ 3 phút theo BUSINESS_RULES.md Section 3.2
      'p_booking': booking,
    });

    return DateTime.parse(response as String).toLocal();
  }

  /// Bán vé trực tiếp và xuất hóa đơn tại quầy qua RPC sell_counter.
  Future<void> sellCounter({
    required String showtimeId,
    required String bookingCode,
    required List<String> seatIds,
    required String paymentMethod, // 'cash' hoặc 'card'
    required Map<String, dynamic> booking,
  }) async {
    await _supabase.rpc('sell_counter', params: {
      'p_showtime_id': showtimeId,
      'p_booking_code': bookingCode,
      'p_seat_ids': seatIds,
      'p_payment_method': paymentMethod,
      'p_booking': booking,
    });
  }

  /// Lấy danh sách trạng thái ghế (sold, holding) trực tiếp từ bảng seats trong DB.
  Future<List<Map<String, dynamic>>> getShowtimeSeats(String showtimeId) async {
    try {
      final response = await _supabase
          .from('seats')
          .select('seat_id, status, hold_until')
          .eq('showtime_id', showtimeId);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (_) {
      return [];
    }
  }

  /// Lấy danh sách món ăn / bắp nước đang có sẵn từ bảng foods trong DB.
  Future<List<Map<String, dynamic>>> getAvailableFoods(String cinemaId) async {
    try {
      final response = await _supabase
          .from('foods')
          .select()
          .eq('cinema_id', cinemaId)
          .eq('is_available', true)
          .order('price', ascending: true);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (_) {
      return [];
    }
  }

  /// Lấy sơ đồ phòng chiếu (seat_layout) từ bảng rooms trong DB.
  Future<List<String>> getRoomLayout(String roomId) async {
    try {
      final response = await _supabase
          .from('rooms')
          .select('seat_layout')
          .eq('id', roomId)
          .maybeSingle();
      final layout = response?['seat_layout'];
      if (layout is List) {
        return layout.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return [];
  }
}
