import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/showtime_model.dart';

/// Repository for Showtimes queries.
/// References: TECH_STACK.md Section 4 & BUSINESS_RULES.md Section 3.3
class ShowtimeRepository {
  final SupabaseClient _supabase;

  ShowtimeRepository([SupabaseClient? supabase])
      : _supabase = supabase ?? Supabase.instance.client;

  /// Fetch showtimes for a specific movie on a specific date.
  Future<List<ShowtimeModel>> getShowtimes({
    required String movieId,
    required DateTime date,
    String? cinemaId,
  }) async {
    final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    var query = _supabase
        .from('showtimes')
        .select('*, rooms(name), cinemas(name), movies(title)')
        .eq('movie_id', movieId)
        .eq('status', 'active')
        .gte('start_time', startOfDay.toUtc().toIso8601String())
        .lte('start_time', endOfDay.toUtc().toIso8601String());

    if (cinemaId != null && cinemaId.isNotEmpty) {
      query = query.eq('cinema_id', cinemaId);
    }

    final response = await query.order('start_time', ascending: true);

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

  /// Get showtime details with room information.
  Future<Map<String, dynamic>?> getShowtimeWithRoom(String showtimeId) async {
    final response = await _supabase
        .from('showtimes')
        .select('*, rooms(*), cinemas(*), movies(*)')
        .eq('id', showtimeId)
        .maybeSingle();

    return response;
  }
}
