import 'package:supabase_flutter/supabase_flutter.dart';
import '../../booking/data/models/booking_model.dart';

/// Repository for Food counter queue.
/// References: BUSINESS_RULES.md Section 9 & ROLE_FLOWS.md Section 3.2
class StaffFoodRepository {
  final SupabaseClient _supabase;

  StaffFoodRepository([SupabaseClient? supabase])
      : _supabase = supabase ?? Supabase.instance.client;

  /// Fetch pending food orders for a cinema.
  Future<List<BookingModel>> getPendingOrders(String cinemaId) async {
    final response = await _supabase
        .from('bookings')
        .select()
        .eq('cinema_id', cinemaId)
        .eq('food_status', 'pending')
        .order('showtime_start', ascending: true);

    return (response as List).map((b) => BookingModel.fromMap(b)).toList();
  }

  /// Fetch delivered food orders for a cinema.
  Future<List<BookingModel>> getDeliveredOrders(String cinemaId) async {
    final response = await _supabase
        .from('bookings')
        .select()
        .eq('cinema_id', cinemaId)
        .eq('food_status', 'delivered')
        .order('showtime_start', ascending: false)
        .limit(50);

    return (response as List).map((b) => BookingModel.fromMap(b)).toList();
  }

  /// Mark food as delivered.
  Future<void> deliverFood(String bookingCode) async {
    await _supabase.rpc('deliver_food', params: {
      'p_booking_code': bookingCode,
    });
  }
}
