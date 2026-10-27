import 'package:supabase_flutter/supabase_flutter.dart';
import '../../booking/data/models/booking_model.dart';

/// Repository for Customer tickets and cancellation.
/// References: BUSINESS_RULES.md Section 7 & 10.1
class TicketRepository {
  final SupabaseClient _supabase;

  TicketRepository([SupabaseClient? supabase])
      : _supabase = supabase ?? Supabase.instance.client;

  /// Fetch all bookings belonging to the current logged-in customer.
  Future<List<BookingModel>> getMyTickets() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final response = await _supabase
        .from('bookings')
        .select()
        .eq('user_id', user.id)
        .order('showtime_start', ascending: false);

    return (response as List).map((b) => BookingModel.fromMap(b)).toList();
  }

  /// Get ticket detail by 8-char booking code.
  Future<BookingModel?> getTicketByCode(String code) async {
    final response = await _supabase
        .from('bookings')
        .select()
        .eq('code', code)
        .maybeSingle();

    if (response == null) return null;
    return BookingModel.fromMap(response);
  }

  /// Cancel booking (customer ≥ 2 hours before showtime).
  Future<void> cancelBooking(String code, {String reason = 'Khách hủy vé trực tuyến'}) async {
    await _supabase.rpc('cancel_booking', params: {
      'p_booking_code': code,
      'p_reason': reason,
    });
  }
}
