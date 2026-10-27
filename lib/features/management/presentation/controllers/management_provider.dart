import 'package:flutter/material.dart';
import '../../../../shared/models/app_user.dart';
import '../../../booking/data/models/booking_model.dart';
import '../../../booking/data/models/food_model.dart';
import '../../data/models/dashboard_metrics_model.dart';
import '../../data/repositories/management_repository.dart';

/// Provider điều phối màn hình quản trị và báo cáo vận hành.
class ManagementProvider extends ChangeNotifier {
  final ManagementRepository _repo;

  ManagementProvider([ManagementRepository? repo])
      : _repo = repo ?? ManagementRepository();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  DashboardMetricsModel? _metrics;
  List<AppUser> _employees = [];
  List<BookingModel> _bookings = [];
  final List<FoodModel> _foods = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  DashboardMetricsModel? get metrics => _metrics;
  List<AppUser> get employees => List.unmodifiable(_employees);
  List<BookingModel> get bookings => List.unmodifiable(_bookings);
  List<FoodModel> get foods => List.unmodifiable(_foods);

  /// Tải số liệu Dashboard theo rạp và chu kỳ.
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

  /// Lập lịch suất chiếu mới (Bắt lỗi xung đột 15 phút nếu có).
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

  /// Hủy suất chiếu.
  Future<bool> cancelShowtime(String showtimeId, String reason) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repo.cancelShowtime(showtimeId, reason);
      _successMessage = 'Hủy suất chiếu thành công';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Hủy suất chiếu thất bại: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Bật / tắt đồ ăn.
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

  /// Tạo tài khoản nhân viên mới.
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
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Tạo nhân viên thất bại: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Khóa / Mở khóa nhân viên.
  Future<void> toggleUserLock(String userId, bool isLocked, String cinemaId) async {
    try {
      await _repo.toggleUserLock(userId, isLocked);
      await loadEmployees(cinemaId);
    } catch (e) {
      _errorMessage = 'Không thể đổi trạng thái khóa tài khoản: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Nạp danh sách nhân sự của rạp.
  Future<void> loadEmployees(String cinemaId) async {
    try {
      _employees = await _repo.getEmployees(cinemaId);
      notifyListeners();
    } catch (_) {}
  }

  /// Nạp danh sách đơn vé kiểm tra (S15).
  Future<void> loadBookings(String cinemaId, {String? status, String? channel}) async {
    _isLoading = true;
    notifyListeners();
    try {
      _bookings = await _repo.getBookings(cinemaId, status: status, channel: channel);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách đơn vé: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
}
