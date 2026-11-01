import 'dart:math';
import 'package:flutter/material.dart';
import '../../../booking/data/models/showtime_model.dart';
import '../../data/repositories/staff_counter_repository.dart';

/// Provider quản lý luồng bán vé tại quầy (S20, S21).
/// Tham chiếu: ROLE_FLOWS.md Section 3.3 & BUSINESS_RULES.md Section 10
class StaffCounterProvider extends ChangeNotifier {
  final StaffCounterRepository _repo;

  StaffCounterProvider([StaffCounterRepository? repo])
      : _repo = repo ?? StaffCounterRepository();

  bool _isLoading = false;
  String? _errorMessage;
  List<ShowtimeModel> _showtimes = [];
  ShowtimeModel? _selectedShowtime;
  final List<String> _selectedSeatIds = [];
  final List<Map<String, dynamic>> _selectedFoods = [];
  String? _bookingCode;
  DateTime? _holdUntil;
  int _receivedCash = 0;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<ShowtimeModel> get showtimes => _showtimes;
  ShowtimeModel? get selectedShowtime => _selectedShowtime;
  List<String> get selectedSeatIds => List.unmodifiable(_selectedSeatIds);
  List<Map<String, dynamic>> get selectedFoods => List.unmodifiable(_selectedFoods);
  String? get bookingCode => _bookingCode;
  DateTime? get holdUntil => _holdUntil;
  int get receivedCash => _receivedCash;
  StaffCounterRepository get repo => _repo;

  /// Tạo mã booking ngẫu nhiên 8 ký tự viết hoa.
  String _generateBookingCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(8, (i) => chars[random.nextInt(chars.length)]).join();
  }

  /// Nạp danh sách suất chiếu của rạp.
  Future<void> loadShowtimes(String cinemaId, DateTime date) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _showtimes = await _repo.getCounterShowtimes(cinemaId, date);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách suất chiếu: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectShowtime(ShowtimeModel showtime) {
    _selectedShowtime = showtime;
    _selectedSeatIds.clear();
    _selectedFoods.clear();
    _bookingCode = null;
    _holdUntil = null;
    notifyListeners();
  }

  /// Chọn / bỏ chọn ghế (tối đa 8 ghế).
  bool toggleSeat(String seatId) {
    if (_selectedSeatIds.contains(seatId)) {
      _selectedSeatIds.remove(seatId);
      notifyListeners();
      return true;
    }

    if (_selectedSeatIds.length >= 8) {
      _errorMessage = 'Chỉ được chọn tối đa 8 ghế mỗi lần bán';
      notifyListeners();
      return false;
    }

    _selectedSeatIds.add(seatId);
    notifyListeners();
    return true;
  }

  /// Thêm hoặc giảm món ăn.
  void setFoodQuantity(String foodId, String name, int price, int qty) {
    _selectedFoods.removeWhere((item) => item['food_id'] == foodId);
    if (qty > 0) {
      _selectedFoods.add({
        'food_id': foodId,
        'name': name,
        'unit_price': price,
        'qty': qty,
        'total': price * qty,
      });
    }
    notifyListeners();
  }

  /// Tính tổng tiền đơn quầy (VND).
  int calculateTotal() {
    final seatTotal = _selectedSeatIds.length * (_selectedShowtime?.minPrice ?? 80000);
    final foodTotal = _selectedFoods.fold<int>(0, (sum, item) => sum + ((item['total'] as int?) ?? 0));
    return seatTotal + foodTotal;
  }

  /// Tính tiền thối lại cho khách: receivedCash - total.
  int calculateChange(int received) {
    _receivedCash = received;
    final total = calculateTotal();
    return received > total ? received - total : 0;
  }

  /// Giữ ghế 3 phút tại quầy.
  Future<bool> holdSeatsForCounter() async {
    if (_selectedShowtime == null || _selectedSeatIds.isEmpty) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _bookingCode = _generateBookingCode();
      final total = calculateTotal();
      final bookingPayload = {
        'showtime_id': _selectedShowtime!.id,
        'channel': 'counter',
        'cinema_id': _selectedShowtime!.cinemaId,
        'movie_title': _selectedShowtime!.movieTitle ?? '',
        'cinema_name': _selectedShowtime!.cinemaName ?? '',
        'room_name': _selectedShowtime!.roomName ?? '',
        'format': _selectedShowtime!.format,
        'showtime_start': _selectedShowtime!.startTime.toUtc().toIso8601String(),
        'seats': _selectedSeatIds.map((id) => {'id': id, 'type': 'standard', 'price': _selectedShowtime!.minPrice}).toList(),
        'foods': _selectedFoods,
        'price_snapshot': {'total': total},
      };

      _holdUntil = await _repo.holdCounterSeats(
        showtimeId: _selectedShowtime!.id,
        bookingCode: _bookingCode!,
        seatIds: _selectedSeatIds,
        booking: bookingPayload,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Giữ ghế không thành công: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Hoàn tất xuất vé tại quầy (tiền mặt / quẹt thẻ).
  Future<bool> completeSale(String paymentMethod) async {
    if (_selectedShowtime == null) return false;
    _bookingCode ??= _generateBookingCode();

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final total = calculateTotal();
      final bookingPayload = {
        'showtime_id': _selectedShowtime!.id,
        'channel': 'counter',
        'cinema_id': _selectedShowtime!.cinemaId,
        'movie_title': _selectedShowtime!.movieTitle ?? '',
        'cinema_name': _selectedShowtime!.cinemaName ?? '',
        'room_name': _selectedShowtime!.roomName ?? '',
        'format': _selectedShowtime!.format,
        'showtime_start': _selectedShowtime!.startTime.toUtc().toIso8601String(),
        'seats': _selectedSeatIds.map((id) => {'id': id, 'type': 'standard', 'price': _selectedShowtime!.minPrice}).toList(),
        'foods': _selectedFoods,
        'price_snapshot': {'total': total},
      };

      await _repo.sellCounter(
        showtimeId: _selectedShowtime!.id,
        bookingCode: _bookingCode!,
        seatIds: _selectedSeatIds,
        paymentMethod: paymentMethod,
        booking: bookingPayload,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Xuất vé tại quầy thất bại: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _selectedShowtime = null;
    _selectedSeatIds.clear();
    _selectedFoods.clear();
    _bookingCode = null;
    _holdUntil = null;
    _receivedCash = 0;
    _errorMessage = null;
    notifyListeners();
  }
}
