import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/models/app_user.dart';
import '../../../booking/data/models/booking_model.dart';
import '../models/dashboard_metrics_model.dart';

/// Repository quản lý vận hành và cấu hình hệ thống (S12–S16, S22–S29).
class ManagementRepository {
  final SupabaseClient? _client;

  ManagementRepository([SupabaseClient? supabase]) : _client = supabase;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  /// Lấy số liệu vận hành Dashboard (RPC get_dashboard_metrics).
  Future<DashboardMetricsModel> getDashboardMetrics(String cinemaId, {String period = 'today'}) async {
    final response = await _supabase.rpc('get_dashboard_metrics', params: {
      'p_cinema_id': cinemaId,
      'p_period': period,
    });

    return DashboardMetricsModel.fromMap(Map<String, dynamic>.from(response as Map));
  }

  /// Tạo suất chiếu mới (DB trigger trg_showtime_conflict tự động kiểm tra 15 phút).
  Future<void> createShowtime({
    required String movieId,
    required String cinemaId,
    required String roomId,
    required String format,
    required DateTime startTime,
    required DateTime endTime,
    required int totalSeats,
  }) async {
    await _supabase.from('showtimes').insert({
      'movie_id': movieId,
      'cinema_id': cinemaId,
      'room_id': roomId,
      'format': format,
      'start_time': startTime.toUtc().toIso8601String(),
      'end_time': endTime.toUtc().toIso8601String(),
      'status': 'active',
      'total_seats': totalSeats,
      'sold_seats': 0,
    });
  }

  /// Hủy suất chiếu qua RPC cancel_showtime.
  Future<Map<String, dynamic>> cancelShowtime(String showtimeId, String reason) async {
    final response = await _supabase.rpc('cancel_showtime', params: {
      'p_showtime_id': showtimeId,
      'p_reason': reason,
    });

    return Map<String, dynamic>.from(response as Map);
  }

  /// Bật / tắt khả dụng của món ăn trong thực đơn.
  Future<void> toggleFoodAvailability(String foodId, bool isAvailable) async {
    await _supabase.from('foods').update({
      'is_available': isAvailable,
    }).eq('id', foodId);
  }

  /// Tạo tài khoản nhân viên / quản lý mới qua Edge Function create-staff.
  Future<Map<String, dynamic>> createStaff({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
    required String cinemaId,
  }) async {
    final response = await _supabase.functions.invoke('create-staff', body: {
      'email': email,
      'password': password,
      'full_name': fullName,
      'phone': phone,
      'role': role,
      'cinema_id': cinemaId,
    });

    if (response.status != 200) {
      final error = response.data?['error'] ?? 'Lỗi tạo tài khoản nhân viên';
      throw Exception(error);
    }

    return Map<String, dynamic>.from(response.data as Map);
  }

  /// Khóa / mở khóa tài khoản người dùng.
  Future<void> toggleUserLock(String userId, bool isLocked) async {
    await _supabase.from('profiles').update({
      'is_locked': isLocked,
    }).eq('id', userId);
  }

  /// Danh sách nhân sự của rạp.
  Future<List<AppUser>> getEmployees(String cinemaId) async {
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('cinema_id', cinemaId)
        .inFilter('role', ['staff', 'manager'])
        .order('created_at', ascending: false);

    return (response as List).map((p) => AppUser.fromMap(p)).toList();
  }

  /// Lấy danh sách các đơn đặt vé (S15).
  Future<List<BookingModel>> getBookings(String cinemaId, {String? status, String? channel}) async {
    var query = _supabase.from('bookings').select().eq('cinema_id', cinemaId);

    if (status != null && status.isNotEmpty) {
      query = query.eq('status', status);
    }
    if (channel != null && channel.isNotEmpty) {
      query = query.eq('channel', channel);
    }

    final response = await query.order('created_at', ascending: false).limit(100);
    return (response as List).map((b) => BookingModel.fromMap(b)).toList();
  }
}
