import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/models/app_user.dart';
import '../../../booking/data/models/booking_model.dart';
import '../../../booking/data/models/food_model.dart';
import '../../../booking/data/models/room_model.dart';
import '../../../booking/data/models/showtime_model.dart';
import '../../../cinemas/data/cinema_model.dart';
import '../../../movies/data/movie_model.dart';
import '../models/audit_log_model.dart';
import '../models/dashboard_metrics_model.dart';
import '../models/pricing_settings_model.dart';
import '../models/voucher_model.dart';

/// Repository quản lý vận hành và cấu hình hệ thống (S12–S16, S22–S29).
class ManagementRepository {
  final SupabaseClient? _client;

  ManagementRepository([SupabaseClient? supabase]) : _client = supabase;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  // ===========================================================================
  // S22: Dashboard Metrics
  // ===========================================================================

  /// Lấy số liệu vận hành Dashboard (RPC get_dashboard_metrics).
  Future<DashboardMetricsModel> getDashboardMetrics(String cinemaId, {String period = 'today'}) async {
    final response = await _supabase.rpc('get_dashboard_metrics', params: {
      'p_cinema_id': cinemaId,
      'p_period': period,
    });

    return DashboardMetricsModel.fromMap(Map<String, dynamic>.from(response as Map));
  }

  // ===========================================================================
  // S13: Movies Management (CRUD & Protection)
  // ===========================================================================

  /// Lấy danh sách toàn bộ phim (quản trị viên xem cả phim ngừng chiếu).
  Future<List<MovieModel>> getAllMovies() async {
    final response = await _supabase
        .from('movies')
        .select()
        .order('release_date', ascending: false);

    return (response as List).map((m) => MovieModel.fromMap(m)).toList();
  }

  /// Tạo phim mới.
  Future<MovieModel> createMovie(MovieModel movie) async {
    final data = movie.toMap()..remove('id');
    final response = await _supabase.from('movies').insert(data).select().single();
    return MovieModel.fromMap(response);
  }

  /// Cập nhật thông tin phim.
  Future<void> updateMovie(MovieModel movie) async {
    final data = movie.toMap()..remove('id');
    await _supabase.from('movies').update(data).eq('id', movie.id);
  }

  /// Kiểm tra xem phim có suất chiếu tương lai đang hoạt động không.
  Future<bool> hasActiveFutureShowtimes(String movieId) async {
    final response = await _supabase
        .from('showtimes')
        .select('id')
        .eq('movie_id', movieId)
        .eq('status', 'active')
        .gte('start_time', DateTime.now().toUtc().toIso8601String())
        .limit(1);

    return (response as List).isNotEmpty;
  }

  /// Xóa phim (chặn nếu còn suất chiếu tương lai).
  Future<void> deleteMovie(String movieId) async {
    final hasShowtimes = await hasActiveFutureShowtimes(movieId);
    if (hasShowtimes) {
      throw Exception('Không thể xóa phim vì đang có suất chiếu trong tương lai.');
    }
    await _supabase.from('movies').delete().eq('id', movieId);
  }

  // ===========================================================================
  // S14: Showtime Management
  // ===========================================================================

  /// Lấy danh sách suất chiếu của rạp theo ngày, kèm phòng và tên phim.
  Future<List<ShowtimeModel>> getShowtimes({
    required String cinemaId,
    required DateTime date,
    String? roomId,
    String? format,
  }) async {
    final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    var query = _supabase
        .from('showtimes')
        .select('*, rooms(name), cinemas(name), movies(title, duration_min, poster_url, age_rating)')
        .eq('cinema_id', cinemaId)
        .gte('start_time', startOfDay.toUtc().toIso8601String())
        .lte('start_time', endOfDay.toUtc().toIso8601String());

    if (roomId != null && roomId.isNotEmpty && roomId != 'ALL') {
      query = query.eq('room_id', roomId);
    }
    if (format != null && format.isNotEmpty && format != 'ALL') {
      query = query.eq('format', format);
    }

    final response = await query.order('start_time', ascending: true);
    return (response as List).map((row) {
      final enriched = Map<String, dynamic>.from(row);
      enriched['room_name'] = (row['rooms'] as Map?)?['name'];
      enriched['cinema_name'] = (row['cinemas'] as Map?)?['name'];
      enriched['movie_title'] = (row['movies'] as Map?)?['title'];
      return ShowtimeModel.fromMap(enriched);
    }).toList();
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

  // ===========================================================================
  // S15: Bookings Inspection
  // ===========================================================================

  /// Lấy danh sách các đơn đặt vé (S15).
  Future<List<BookingModel>> getBookings(
    String cinemaId, {
    String? status,
    String? channel,
  }) async {
    var query = _supabase.from('bookings').select();

    if (cinemaId.isNotEmpty && cinemaId != 'ALL') {
      query = query.eq('cinema_id', cinemaId);
    }
    if (status != null && status.isNotEmpty && status != 'ALL') {
      query = query.eq('status', status.toLowerCase());
    }
    if (channel != null && channel.isNotEmpty && channel != 'ALL') {
      query = query.eq('channel', channel.toLowerCase());
    }

    final response = await query.order('created_at', ascending: false).limit(100);
    return (response as List).map((b) => BookingModel.fromMap(b)).toList();
  }

  // ===========================================================================
  // S16: Food & Concessions Catalog
  // ===========================================================================

  /// Lấy danh sách thực đơn của rạp.
  Future<List<FoodModel>> getFoods(String cinemaId, {String? category}) async {
    var query = _supabase.from('foods').select();
    if (cinemaId.isNotEmpty && cinemaId != 'ALL') {
      query = query.eq('cinema_id', cinemaId);
    }
    if (category != null && category.isNotEmpty && category != 'ALL') {
      query = query.eq('category', category.toLowerCase());
    }

    final response = await query.order('category').order('name');
    return (response as List).map((f) => FoodModel.fromMap(f)).toList();
  }

  /// Tạo món ăn mới.
  Future<void> createFood(FoodModel food) async {
    await _supabase.from('foods').insert({
      'cinema_id': food.cinemaId,
      'name': food.name,
      'category': food.category,
      'price': food.price,
      'is_available': food.isAvailable,
      'image_url': food.imageUrl,
      'description': food.description,
    });
  }

  /// Cập nhật món ăn.
  Future<void> updateFood(FoodModel food) async {
    await _supabase.from('foods').update({
      'name': food.name,
      'category': food.category,
      'price': food.price,
      'is_available': food.isAvailable,
      'image_url': food.imageUrl,
      'description': food.description,
    }).eq('id', food.id);
  }

  /// Xóa món ăn.
  Future<void> deleteFood(String foodId) async {
    await _supabase.from('foods').delete().eq('id', foodId);
  }

  /// Bật / tắt khả dụng của món ăn trong thực đơn.
  Future<void> toggleFoodAvailability(String foodId, bool isAvailable) async {
    await _supabase.from('foods').update({
      'is_available': isAvailable,
    }).eq('id', foodId);
  }

  // ===========================================================================
  // S24 & S25: Cinemas & Rooms Management & Seat Map Designer
  // ===========================================================================

  /// Lấy danh sách toàn bộ cụm rạp.
  Future<List<CinemaModel>> getAllCinemas() async {
    final response = await _supabase.from('cinemas').select().order('name');
    return (response as List).map((c) => CinemaModel.fromMap(c)).toList();
  }

  /// Tạo rạp mới.
  Future<void> createCinema(CinemaModel cinema) async {
    await _supabase.from('cinemas').insert(cinema.toMap());
  }

  /// Cập nhật thông tin rạp.
  Future<void> updateCinema(CinemaModel cinema) async {
    await _supabase.from('cinemas').update(cinema.toMap()).eq('id', cinema.id);
  }

  /// Lấy danh sách phòng của rạp.
  Future<List<RoomModel>> getRoomsByCinema(String cinemaId) async {
    final response = await _supabase
        .from('rooms')
        .select()
        .eq('cinema_id', cinemaId)
        .order('name');
    return (response as List).map((r) => RoomModel.fromMap(r)).toList();
  }

  /// Tạo phòng mới.
  Future<void> createRoom(RoomModel room) async {
    await _supabase.from('rooms').insert(room.toMap());
  }

  /// Cập nhật thông tin phòng.
  Future<void> updateRoom(RoomModel room) async {
    await _supabase.from('rooms').update(room.toMap()).eq('id', room.id);
  }

  /// Kiểm tra phòng có suất chiếu tương lai đã bán vé hay không (S24 Lock Check).
  Future<bool> hasFutureSoldShowtimes(String roomId) async {
    final response = await _supabase
        .from('showtimes')
        .select('id, sold_seats')
        .eq('room_id', roomId)
        .eq('status', 'active')
        .gt('sold_seats', 0)
        .gte('start_time', DateTime.now().toUtc().toIso8601String())
        .limit(1);

    return (response as List).isNotEmpty;
  }

  /// Cập nhật ma trận sơ đồ ghế phòng chiếu (S24).
  Future<void> updateRoomLayout({
    required String roomId,
    required int rows,
    required int cols,
    required List<String> seatLayout,
    required int seatCount,
    Map<String, dynamic>? oldSnapshot,
  }) async {
    await _supabase.from('rooms').update({
      'rows': rows,
      'cols': cols,
      'seat_layout': seatLayout,
      'seat_count': seatCount,
    }).eq('id', roomId);

    await logAudit(
      action: 'updateRoomLayout',
      targetType: 'room',
      targetId: roomId,
      reason: 'Cập nhật cấu hình sơ đồ ghế phòng chiếu',
      oldData: oldSnapshot,
      newData: {
        'rows': rows,
        'cols': cols,
        'seat_layout': seatLayout,
        'seat_count': seatCount,
      },
    );
  }

  // ===========================================================================
  // S26: Dynamic Pricing Settings
  // ===========================================================================

  /// Lấy bảng giá động hiện hành.
  Future<PricingSettingsModel> getPricingSettings() async {
    final response = await _supabase
        .from('pricing_settings')
        .select()
        .eq('id', 1)
        .maybeSingle();

    if (response == null) {
      return PricingSettingsModel.defaultSettings();
    }
    return PricingSettingsModel.fromMap(response);
  }

  /// Cập nhật bảng giá động (Admin).
  Future<void> updatePricingSettings(
    PricingSettingsModel settings, {
    PricingSettingsModel? oldSettings,
  }) async {
    await _supabase
        .from('pricing_settings')
        .upsert(settings.toMap());

    await logAudit(
      action: 'changePrice',
      targetType: 'pricing_settings',
      targetId: '1',
      reason: 'Cập nhật bảng giá vé và phụ thu hệ thống',
      oldData: oldSettings?.toMap(),
      newData: settings.toMap(),
    );
  }

  // ===========================================================================
  // S27: Voucher & Promotion Management
  // ===========================================================================

  /// Lấy danh sách voucher.
  Future<List<VoucherModel>> getVouchers() async {
    final response = await _supabase
        .from('vouchers')
        .select()
        .order('created_at', ascending: false);

    return (response as List).map((v) => VoucherModel.fromMap(v)).toList();
  }

  /// Tạo voucher mới.
  Future<void> createVoucher(VoucherModel voucher) async {
    await _supabase.from('vouchers').insert(voucher.toMap());
    await logAudit(
      action: 'createVoucher',
      targetType: 'voucher',
      targetId: voucher.code,
      reason: 'Tạo mã khuyến mãi mới ${voucher.code}',
      newData: voucher.toMap(),
    );
  }

  /// Cập nhật voucher.
  Future<void> updateVoucher(VoucherModel voucher) async {
    await _supabase.from('vouchers').update(voucher.toMap()).eq('code', voucher.code);
    await logAudit(
      action: 'updateVoucher',
      targetType: 'voucher',
      targetId: voucher.code,
      reason: 'Cập nhật mã khuyến mãi ${voucher.code}',
      newData: voucher.toMap(),
    );
  }

  /// Bật / tắt trạng thái kích hoạt của voucher.
  Future<void> toggleVoucherStatus(String code, bool isActive) async {
    await _supabase.from('vouchers').update({'is_active': isActive}).eq('code', code);
  }

  /// Xóa voucher.
  Future<void> deleteVoucher(String code) async {
    await _supabase.from('vouchers').delete().eq('code', code);
  }

  // ===========================================================================
  // S28: Manager & Staff Management
  // ===========================================================================

  /// Lấy danh sách các quản lý rạp (Manager accounts).
  Future<List<AppUser>> getManagers() async {
    final response = await _supabase
        .from('profiles')
        .select('*, cinemas(name)')
        .eq('role', 'manager')
        .order('created_at', ascending: false);

    return (response as List).map((p) {
      final map = Map<String, dynamic>.from(p);
      map['cinema_name'] = (p['cinemas'] as Map?)?['name'];
      return AppUser.fromMap(map);
    }).toList();
  }

  /// Chuyển công tác quản lý sang rạp khác.
  Future<void> reassignManagerCinema(String managerId, String cinemaId) async {
    await _supabase.from('profiles').update({'cinema_id': cinemaId}).eq('id', managerId);
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

    await logAudit(
      action: isLocked ? 'lockUser' : 'unlockUser',
      targetType: 'profile',
      targetId: userId,
      reason: isLocked ? 'Khóa tài khoản người dùng' : 'Mở khóa tài khoản người dùng',
    );
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

  // ===========================================================================
  // S29: System Audit Logs
  // ===========================================================================

  /// Lấy nhật ký kiểm toán hệ thống kèm thông tin người thực hiện và rạp.
  Future<List<AuditLogModel>> getAuditLogs({
    String? action,
    String? cinemaId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    var query = _supabase
        .from('audit_logs')
        .select('*, profiles:actor_id(full_name), cinemas(name)');

    if (action != null && action.isNotEmpty && action != 'ALL') {
      query = query.eq('action', action);
    }
    if (cinemaId != null && cinemaId.isNotEmpty && cinemaId != 'ALL') {
      query = query.eq('cinema_id', cinemaId);
    }
    if (startDate != null) {
      query = query.gte('created_at', startDate.toUtc().toIso8601String());
    }
    if (endDate != null) {
      query = query.lte('created_at', endDate.toUtc().toIso8601String());
    }

    final response = await query.order('created_at', ascending: false).limit(limit);
    return (response as List).map((row) => AuditLogModel.fromMap(row)).toList();
  }

  /// Ghi nhật ký thao tác kiểm toán.
  Future<void> logAudit({
    required String action,
    required String targetType,
    required String targetId,
    String? cinemaId,
    String? reason,
    Map<String, dynamic>? oldData,
    Map<String, dynamic>? newData,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      await _supabase.from('audit_logs').insert({
        'actor_id': user?.id,
        'actor_role': 'admin',
        'cinema_id': cinemaId,
        'action': action,
        'target_type': targetType,
        'target_id': targetId,
        'reason': reason,
        'old_data': oldData,
        'new_data': newData,
      });
    } catch (_) {
      // Non-blocking for UI if audit insert encounters missing columns
    }
  }
}
