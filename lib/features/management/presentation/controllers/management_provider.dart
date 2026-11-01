import 'package:flutter/material.dart';
import '../../../../shared/models/app_user.dart';
import '../../../booking/data/models/booking_model.dart';
import '../../../booking/data/models/food_model.dart';
import '../../../booking/data/models/room_model.dart';
import '../../../booking/data/models/showtime_model.dart';
import '../../../cinemas/data/cinema_model.dart';
import '../../../movies/data/movie_model.dart';
import '../../data/models/audit_log_model.dart';
import '../../data/models/dashboard_metrics_model.dart';
import '../../data/models/pricing_settings_model.dart';
import '../../data/models/voucher_model.dart';
import '../../data/repositories/management_repository.dart';

/// Provider điều phối quản trị toàn diện hệ thống (Milestone 5).
class ManagementProvider extends ChangeNotifier {
  final ManagementRepository _repo;

  ManagementProvider([ManagementRepository? repo])
      : _repo = repo ?? ManagementRepository();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  DashboardMetricsModel? _metrics;
  List<MovieModel> _movies = [];
  List<ShowtimeModel> _showtimes = [];
  List<BookingModel> _bookings = [];
  List<FoodModel> _foods = [];
  List<CinemaModel> _cinemas = [];
  List<RoomModel> _rooms = [];
  PricingSettingsModel? _pricingSettings;
  List<VoucherModel> _vouchers = [];
  List<AppUser> _managers = [];
  List<AppUser> _employees = [];
  List<AuditLogModel> _auditLogs = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  DashboardMetricsModel? get metrics => _metrics;
  List<MovieModel> get movies => List.unmodifiable(_movies);
  List<ShowtimeModel> get showtimes => List.unmodifiable(_showtimes);
  List<BookingModel> get bookings => List.unmodifiable(_bookings);
  List<FoodModel> get foods => List.unmodifiable(_foods);
  List<CinemaModel> get cinemas => List.unmodifiable(_cinemas);
  List<RoomModel> get rooms => List.unmodifiable(_rooms);
  PricingSettingsModel? get pricingSettings => _pricingSettings;
  List<VoucherModel> get vouchers => List.unmodifiable(_vouchers);
  List<AppUser> get managers => List.unmodifiable(_managers);
  List<AppUser> get employees => List.unmodifiable(_employees);
  List<AuditLogModel> get auditLogs => List.unmodifiable(_auditLogs);

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  // ===========================================================================
  // S22: Dashboard Metrics
  // ===========================================================================
  Future<void> loadDashboardMetrics(String cinemaId, {String period = 'today'}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _metrics = await _repo.getDashboardMetrics(cinemaId, period: period);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Không thể tải số liệu Dashboard: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // ===========================================================================
  // S13: Movies Management
  // ===========================================================================
  Future<void> loadMovies() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _movies = await _repo.getAllMovies();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách phim: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveMovie(MovieModel movie, {bool isEditing = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (isEditing) {
        await _repo.updateMovie(movie);
      } else {
        await _repo.createMovie(movie);
      }
      _successMessage = isEditing ? 'Cập nhật phim thành công' : 'Thêm phim mới thành công';
      await loadMovies();
      return true;
    } catch (e) {
      _errorMessage = 'Lưu phim thất bại: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteMovie(String movieId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repo.deleteMovie(movieId);
      _successMessage = 'Xóa phim thành công';
      await loadMovies();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleMovieActive(MovieModel movie) async {
    try {
      final updated = movie.copyWith(isActive: !movie.isActive);
      await _repo.updateMovie(updated);
      final index = _movies.indexWhere((m) => m.id == movie.id);
      if (index != -1) {
        _movies[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Không thể đổi trạng thái phim: ${e.toString()}';
      notifyListeners();
    }
  }

  // ===========================================================================
  // S14: Showtimes Management
  // ===========================================================================
  Future<void> loadShowtimes(
    String cinemaId, {
    required DateTime date,
    String? roomId,
    String? format,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _showtimes = await _repo.getShowtimes(
        cinemaId: cinemaId,
        date: date,
        roomId: roomId,
        format: format,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách suất chiếu: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createShowtime({
    required String movieId,
    required String cinemaId,
    required String roomId,
    required String format,
    required DateTime startTime,
    required DateTime endTime,
    required int totalSeats,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repo.createShowtime(
        movieId: movieId,
        cinemaId: cinemaId,
        roomId: roomId,
        format: format,
        startTime: startTime,
        endTime: endTime,
        totalSeats: totalSeats,
      );
      _successMessage = 'Tạo suất chiếu thành công';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().contains('SHOWTIME_CONFLICT')
          ? e.toString()
          : 'Lỗi tạo suất chiếu: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelShowtime(String showtimeId, String reason, {String? cinemaId, DateTime? date}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repo.cancelShowtime(showtimeId, reason);
      _successMessage = 'Hủy suất chiếu thành công';
      if (cinemaId != null && date != null) {
        await loadShowtimes(cinemaId, date: date);
      } else {
        _isLoading = false;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = 'Hủy suất chiếu thất bại: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ===========================================================================
  // S15: Bookings Inspection
  // ===========================================================================
  Future<void> loadBookings(
    String cinemaId, {
    String? status,
    String? channel,
    String? search,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      var list = await _repo.getBookings(
        cinemaId,
        status: status,
        channel: channel,
      );
      if (search != null && search.trim().isNotEmpty) {
        final s = search.trim().toLowerCase();
        list = list.where((b) =>
          b.code.toLowerCase().contains(s) ||
          b.movieTitle.toLowerCase().contains(s) ||
          (b.userId != null && b.userId!.toLowerCase().contains(s))
        ).toList();
      }
      _bookings = list;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách đơn vé: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // ===========================================================================
  // S16: Food & Concessions Catalog
  // ===========================================================================
  Future<void> loadFoods(String cinemaId, {String? category}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _foods = await _repo.getFoods(cinemaId, category: category);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Không thể tải thực đơn: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveFood(FoodModel food, {bool isEditing = false, required String cinemaId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (isEditing) {
        await _repo.updateFood(food);
      } else {
        await _repo.createFood(food);
      }
      _successMessage = isEditing ? 'Cập nhật món ăn thành công' : 'Thêm món ăn thành công';
      await loadFoods(cinemaId);
      return true;
    } catch (e) {
      _errorMessage = 'Lưu món ăn thất bại: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteFood(String foodId, String cinemaId) async {
    try {
      await _repo.deleteFood(foodId);
      _foods.removeWhere((f) => f.id == foodId);
      _successMessage = 'Xóa món ăn thành công';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Xóa món ăn thất bại: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleFood(String foodId, bool isAvailable) async {
    try {
      await _repo.toggleFoodAvailability(foodId, isAvailable);
      final idx = _foods.indexWhere((f) => f.id == foodId);
      if (idx != -1) {
        _foods[idx] = _foods[idx].copyWith(isAvailable: isAvailable);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Không thể cập nhật trạng thái đồ ăn: ${e.toString()}';
      notifyListeners();
    }
  }

  // ===========================================================================
  // S24 & S25: Cinemas & Rooms Management & Seat Map
  // ===========================================================================
  Future<void> loadCinemas() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _cinemas = await _repo.getAllCinemas();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách cụm rạp: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveCinema(CinemaModel cinema, {bool isEditing = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (isEditing) {
        await _repo.updateCinema(cinema);
      } else {
        await _repo.createCinema(cinema);
      }
      _successMessage = isEditing ? 'Cập nhật rạp thành công' : 'Tạo rạp mới thành công';
      await loadCinemas();
      return true;
    } catch (e) {
      _errorMessage = 'Lưu rạp thất bại: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadRooms(String cinemaId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _rooms = await _repo.getRoomsByCinema(cinemaId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách phòng chiếu: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveRoom(RoomModel room, {bool isEditing = false, required String cinemaId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (isEditing) {
        await _repo.updateRoom(room);
      } else {
        await _repo.createRoom(room);
      }
      _successMessage = isEditing ? 'Cập nhật phòng thành công' : 'Thêm phòng mới thành công';
      await loadRooms(cinemaId);
      return true;
    } catch (e) {
      _errorMessage = 'Lưu phòng thất bại: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> checkRoomHasFutureSoldShowtimes(String roomId) async {
    try {
      return await _repo.hasFutureSoldShowtimes(roomId);
    } catch (_) {
      return false;
    }
  }

  Future<bool> saveRoomSeatLayout({
    required String roomId,
    required String cinemaId,
    required int rows,
    required int cols,
    required List<String> seatLayout,
    required int seatCount,
    Map<String, dynamic>? oldSnapshot,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repo.updateRoomLayout(
        roomId: roomId,
        rows: rows,
        cols: cols,
        seatLayout: seatLayout,
        seatCount: seatCount,
        oldSnapshot: oldSnapshot,
      );
      _successMessage = 'Lưu sơ đồ ghế thành công';
      await loadRooms(cinemaId);
      return true;
    } catch (e) {
      _errorMessage = 'Lưu sơ đồ ghế thất bại: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ===========================================================================
  // S26: Dynamic Pricing Settings
  // ===========================================================================
  Future<void> loadPricingSettings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _pricingSettings = await _repo.getPricingSettings();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Không thể tải bảng giá: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> savePricingSettings(PricingSettingsModel settings) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repo.updatePricingSettings(settings, oldSettings: _pricingSettings);
      _pricingSettings = settings;
      _successMessage = 'Cập nhật bảng giá thành công';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Lưu bảng giá thất bại: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ===========================================================================
  // S27: Voucher & Promotion Management
  // ===========================================================================
  Future<void> loadVouchers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _vouchers = await _repo.getVouchers();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách voucher: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveVoucher(VoucherModel voucher, {bool isEditing = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (isEditing) {
        await _repo.updateVoucher(voucher);
      } else {
        await _repo.createVoucher(voucher);
      }
      _successMessage = isEditing ? 'Cập nhật voucher thành công' : 'Tạo voucher thành công';
      await loadVouchers();
      return true;
    } catch (e) {
      _errorMessage = 'Lưu voucher thất bại: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleVoucher(String code, bool isActive) async {
    try {
      await _repo.toggleVoucherStatus(code, isActive);
      final idx = _vouchers.indexWhere((v) => v.code == code);
      if (idx != -1) {
        _vouchers[idx] = _vouchers[idx].copyWith(isActive: isActive);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Không thể đổi trạng thái voucher: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<bool> deleteVoucher(String code) async {
    try {
      await _repo.deleteVoucher(code);
      _vouchers.removeWhere((v) => v.code == code);
      _successMessage = 'Xóa voucher thành công';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Xóa voucher thất bại: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // ===========================================================================
  // S28: Manager Accounts Management
  // ===========================================================================
  Future<void> loadManagers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _managers = await _repo.getManagers();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách quản lý: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createManagerAccount({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String cinemaId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repo.createStaff(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        role: 'manager',
        cinemaId: cinemaId,
      );
      _successMessage = 'Tạo tài khoản quản lý thành công';
      await loadManagers();
      return true;
    } catch (e) {
      _errorMessage = 'Tạo quản lý thất bại: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> reassignManagerCinema(String managerId, String cinemaId) async {
    try {
      await _repo.reassignManagerCinema(managerId, cinemaId);
      await loadManagers();
    } catch (e) {
      _errorMessage = 'Không thể chuyển rạp cho quản lý: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> toggleManagerLock(String managerId, bool isLocked) async {
    try {
      await _repo.toggleUserLock(managerId, isLocked);
      await loadManagers();
    } catch (e) {
      _errorMessage = 'Không thể đổi trạng thái khóa: ${e.toString()}';
      notifyListeners();
    }
  }

  // ===========================================================================
  // S23: Staff Management
  // ===========================================================================
  // S23: Staff & Manager Accounts
  // ===========================================================================
  Future<void> loadEmployees(String cinemaId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _employees = await _repo.getEmployees(cinemaId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách nhân viên: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createStaffAccount({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
    required String cinemaId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repo.createStaff(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        role: role,
        cinemaId: cinemaId,
      );
      _successMessage = 'Tạo nhân viên thành công';
      await loadEmployees(cinemaId);
      return true;
    } catch (e) {
      _errorMessage = 'Tạo nhân viên thất bại: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleUserLock(String userId, bool isLocked, String cinemaId) async {
    try {
      await _repo.toggleUserLock(userId, isLocked);
      final idx = _employees.indexWhere((e) => e.id == userId);
      if (idx != -1) {
        _employees[idx] = _employees[idx].copyWith(isLocked: isLocked);
        notifyListeners();
      }
      await loadEmployees(cinemaId);
      return true;
    } catch (e) {
      _errorMessage = 'Không thể đổi trạng thái khóa tài khoản: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // ===========================================================================
  // S29: System Audit Logs
  // ===========================================================================
  Future<void> loadAuditLogs({
    String? action,
    String? cinemaId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _auditLogs = await _repo.getAuditLogs(
        action: action,
        cinemaId: cinemaId,
        startDate: startDate,
        endDate: endDate,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Không thể tải nhật ký hệ thống: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
}
