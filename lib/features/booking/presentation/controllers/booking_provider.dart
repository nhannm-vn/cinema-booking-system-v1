import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/app_constants.dart';
import '../../../../shared/models/api_response.dart';
import '../../../../shared/widgets/seat_widget.dart';
import '../../../auth/presentation/controllers/auth_provider.dart';
import '../../data/models/food_model.dart';
import '../../data/models/showtime_model.dart';
import '../../data/repositories/seat_repository.dart';
import '../../../management/data/models/pricing_settings_model.dart';

/// Provider managing active booking flow (S05, S06, S07, S08).
class BookingProvider extends ChangeNotifier {
  final SeatRepository _seatRepo;
  final SupabaseClient? _supabase;
  AuthProvider? _authProvider;

  ShowtimeModel? _selectedShowtime;
  final List<String> _selectedSeatIds = [];
  final Map<String, SeatType> _selectedSeatTypes = {};
  final List<FoodModel> _selectedFoods = [];
  DateTime? _holdUntil;
  String? _currentBookingCode;
  bool _isLoading = false;
  String? _errorMessage;

  String? _appliedVoucherCode;
  int _discount = 0;
  String? _voucherError;

  PricingSettingsModel _pricing = PricingSettingsModel.defaultSettings();
  PricingSettingsModel get pricing => _pricing;

  BookingProvider([SeatRepository? seatRepo, SupabaseClient? supabase])
      : _seatRepo = seatRepo ?? SeatRepository(),
        _supabase = supabase;

  void attach(AuthProvider auth) {
    _authProvider = auth;
  }

  AuthProvider? get auth => _authProvider;

  ShowtimeModel? get selectedShowtime => _selectedShowtime;
  List<String> get selectedSeatIds => List.unmodifiable(_selectedSeatIds);
  List<FoodModel> get selectedFoods => List.unmodifiable(_selectedFoods);
  DateTime? get holdUntil => _holdUntil;
  String? get currentBookingCode => _currentBookingCode;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String? get appliedVoucherCode => _appliedVoucherCode;
  int get discount => _discount;
  String? get voucherError => _voucherError;

  void setShowtime(ShowtimeModel showtime) {
    _selectedShowtime = showtime;
    _selectedSeatIds.clear();
    _selectedSeatTypes.clear();
    _selectedFoods.clear();
    _holdUntil = null;
    _currentBookingCode = null;
    _errorMessage = null;
    notifyListeners();
    loadPricingSettings();
  }

  /// Tải bảng giá hiện hành từ `pricing_settings` (Admin cập nhật) - BUSINESS_RULES mục 4.
  Future<void> loadPricingSettings() async {
    try {
      final client = _supabase ?? Supabase.instance.client;
      final response = await client
          .from('pricing_settings')
          .select()
          .eq('id', 1)
          .maybeSingle();
      if (response != null) {
        _pricing = PricingSettingsModel.fromMap(response);
        notifyListeners();
      }
    } catch (_) {
      // Giữ bảng giá mặc định khi không tải được
    }
  }

  /// Toggle seat selection (up to 8 seats).
  void toggleSeat(String seatId, SeatType type) {
    if (_selectedSeatIds.contains(seatId)) {
      _selectedSeatIds.remove(seatId);
      _selectedSeatTypes.remove(seatId);
      notifyListeners();
    } else {
      if (_selectedSeatIds.length >= AppConstants.maxSeatsPerBooking) {
        _errorMessage = 'Bạn chỉ được chọn tối đa ${AppConstants.maxSeatsPerBooking} ghế mỗi lần.';
        notifyListeners();
        return;
      }
      _errorMessage = null;
      _selectedSeatIds.add(seatId);
      _selectedSeatTypes[seatId] = type;
      notifyListeners();
    }
  }

  /// Update food quantity
  void updateFoodQuantity(FoodModel food, int quantity) {
    final index = _selectedFoods.indexWhere((f) => f.id == food.id);
    if (quantity <= 0) {
      if (index >= 0) _selectedFoods.removeAt(index);
    } else {
      final updated = food.copyWith(quantity: quantity);
      if (index >= 0) {
        _selectedFoods[index] = updated;
      } else {
        _selectedFoods.add(updated);
      }
    }
    notifyListeners();
  }

  /// Calculate ticket total based on BUSINESS_RULES.md Section 4
  int calculateTicketTotal() {
    if (_selectedShowtime == null) return 0;
    int total = 0;
    final format = _selectedShowtime!.format;
    final start = _selectedShowtime!.startTime;

    final bool isWeekend = start.weekday == DateTime.friday ||
        start.weekday == DateTime.saturday ||
        start.weekday == DateTime.sunday;
    final bool isPrime =
        start.hour >= _pricing.primeStartHour && start.hour < _pricing.primeEndHour;

    for (final seatId in _selectedSeatIds) {
      final type = _selectedSeatTypes[seatId] ?? SeatType.standard;
      total += _pricing.calculateSeatPrice(
        format: format,
        seatType: type.name,
        isWeekend: isWeekend,
        isPrimeTime: isPrime,
      );
    }
    return total;
  }

  int calculateFoodTotal() {
    int total = 0;
    for (final food in _selectedFoods) {
      total += food.price * food.quantity;
    }
    return total;
  }

  int calculateGrandTotal() {
    return max(0, calculateTicketTotal() + calculateFoodTotal() - _discount);
  }

  Map<String, dynamic> generatePriceSnapshot() {
    final ticket = calculateTicketTotal();
    final food = calculateFoodTotal();
    return {
      'ticket_total': ticket,
      'food_total': food,
      'discount': _discount,
      'total': calculateGrandTotal(),
    };
  }

  /// Apply voucher code to discount ticket total (BUSINESS_RULES.md Section 11)
  Future<bool> applyVoucher(String code) async {
    final trimmed = code.trim().toUpperCase();
    if (trimmed.isEmpty) {
      _voucherError = 'Vui lòng nhập mã giảm giá.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _voucherError = null;
    notifyListeners();

    try {
      final client = _supabase ?? Supabase.instance.client;
      final data = await client
          .from('vouchers')
          .select()
          .eq('code', trimmed)
          .maybeSingle();

      if (data == null) {
        _voucherError = 'Mã giảm giá không tồn tại.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final isActive = (data['is_active'] as bool?) ?? false;
      if (!isActive) {
        _voucherError = 'Mã giảm giá không còn hoạt động.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (data['expires_at'] != null) {
        final expiresAt = DateTime.parse(data['expires_at'] as String);
        if (expiresAt.isBefore(DateTime.now())) {
          _voucherError = 'Mã giảm giá đã hết hạn.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      final maxUses = data['max_uses'] as int?;
      final usedCount = (data['used_count'] as int?) ?? 0;
      if (maxUses != null && usedCount >= maxUses) {
        _voucherError = 'Mã giảm giá đã hết lượt sử dụng.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final type = (data['type'] as String?) ?? 'amount';
      final value = (data['value'] as num?)?.toInt() ?? 0;
      final ticketTotal = calculateTicketTotal();

      if (type == 'percent') {
        _discount = (ticketTotal * value / 100).round();
      } else {
        _discount = min(ticketTotal, value);
      }

      _appliedVoucherCode = trimmed;
      _voucherError = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _voucherError = 'Lỗi kiểm tra voucher: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void removeVoucher() {
    _appliedVoucherCode = null;
    _discount = 0;
    _voucherError = null;
    notifyListeners();
  }

  /// Generate 8-character uppercase booking code (e.g. K7M2QX9P)
  static String generateBookingCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// Hold selected seats via RPC `hold_seats`
  Future<bool> holdSelectedSeats() async {
    if (_selectedShowtime == null || _selectedSeatIds.isEmpty) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _currentBookingCode = generateBookingCode();

    final start = _selectedShowtime!.startTime;
    final bool isWeekend = start.weekday == DateTime.friday ||
        start.weekday == DateTime.saturday ||
        start.weekday == DateTime.sunday;
    final bool isPrime =
        start.hour >= _pricing.primeStartHour && start.hour < _pricing.primeEndHour;

    final bookingJson = {
      'showtime_id': _selectedShowtime!.id,
      'cinema_id': _selectedShowtime!.cinemaId,
      'movie_title': _selectedShowtime!.movieTitle ?? '',
      'cinema_name': _selectedShowtime!.cinemaName ?? '',
      'room_name': _selectedShowtime!.roomName ?? '',
      'format': _selectedShowtime!.format,
      'showtime_start': _selectedShowtime!.startTime.toUtc().toIso8601String(),
      'price_snapshot': generatePriceSnapshot(),
      'seats': _selectedSeatIds.map((id) {
        final type = _selectedSeatTypes[id] ?? SeatType.standard;
        final seatPrice = _pricing.calculateSeatPrice(
          format: _selectedShowtime!.format,
          seatType: type.name,
          isWeekend: isWeekend,
          isPrimeTime: isPrime,
        );
        return {
          'id': id,
          'type': type.name,
          'price': seatPrice,
        };
      }).toList(),
      'foods': _selectedFoods.map((f) => f.toBookingJson()).toList(),
    };

    try {
      _holdUntil = await _seatRepo.holdSeats(
        showtimeId: _selectedShowtime!.id,
        bookingCode: _currentBookingCode!,
        seatIds: _selectedSeatIds,
        booking: bookingJson,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on SeatTakenException catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Lỗi giữ ghế: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Re-invoke RPC `hold_seats` with current booking code to safely update foods and price_snapshot in PostgreSQL
  Future<bool> syncBookingDetails() async {
    if (_selectedShowtime == null || _currentBookingCode == null || _selectedSeatIds.isEmpty) {
      return false;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final start = _selectedShowtime!.startTime;
    final bool isWeekend = start.weekday == DateTime.friday ||
        start.weekday == DateTime.saturday ||
        start.weekday == DateTime.sunday;
    final bool isPrime =
        start.hour >= _pricing.primeStartHour && start.hour < _pricing.primeEndHour;

    final bookingJson = {
      'showtime_id': _selectedShowtime!.id,
      'cinema_id': _selectedShowtime!.cinemaId,
      'movie_title': _selectedShowtime!.movieTitle ?? '',
      'cinema_name': _selectedShowtime!.cinemaName ?? '',
      'room_name': _selectedShowtime!.roomName ?? '',
      'format': _selectedShowtime!.format,
      'showtime_start': _selectedShowtime!.startTime.toUtc().toIso8601String(),
      'price_snapshot': generatePriceSnapshot(),
      'seats': _selectedSeatIds.map((id) {
        final type = _selectedSeatTypes[id] ?? SeatType.standard;
        final seatPrice = _pricing.calculateSeatPrice(
          format: _selectedShowtime!.format,
          seatType: type.name,
          isWeekend: isWeekend,
          isPrimeTime: isPrime,
        );
        return {
          'id': id,
          'type': type.name,
          'price': seatPrice,
        };
      }).toList(),
      'foods': _selectedFoods.map((f) => f.toBookingJson()).toList(),
    };

    try {
      _holdUntil = await _seatRepo.holdSeats(
        showtimeId: _selectedShowtime!.id,
        bookingCode: _currentBookingCode!,
        seatIds: _selectedSeatIds,
        booking: bookingJson,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Lỗi đồng bộ thông tin: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Release held seats
  Future<void> releaseCurrentHold() async {
    if (_currentBookingCode != null) {
      await _seatRepo.releaseHold(_currentBookingCode!);
      _holdUntil = null;
      _currentBookingCode = null;
      notifyListeners();
    }
  }

  void reset() {
    _selectedShowtime = null;
    _selectedSeatIds.clear();
    _selectedSeatTypes.clear();
    _selectedFoods.clear();
    _holdUntil = null;
    _currentBookingCode = null;
    _errorMessage = null;
    _appliedVoucherCode = null;
    _discount = 0;
    _voucherError = null;
    notifyListeners();
  }
}
