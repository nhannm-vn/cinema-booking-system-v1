import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/config/app_constants.dart';
import '../../../../shared/models/api_response.dart';
import '../../../../shared/widgets/seat_widget.dart';
import '../../../auth/presentation/controllers/auth_provider.dart';
import '../../data/models/food_model.dart';
import '../../data/models/showtime_model.dart';
import '../../data/repositories/seat_repository.dart';

/// Provider managing active booking flow (S05, S06, S07, S08).
class BookingProvider extends ChangeNotifier {
  final SeatRepository _seatRepo;
  AuthProvider? _authProvider;

  ShowtimeModel? _selectedShowtime;
  final List<String> _selectedSeatIds = [];
  final Map<String, SeatType> _selectedSeatTypes = {};
  final List<FoodModel> _selectedFoods = [];
  DateTime? _holdUntil;
  String? _currentBookingCode;
  bool _isLoading = false;
  String? _errorMessage;

  BookingProvider([SeatRepository? seatRepo])
      : _seatRepo = seatRepo ?? SeatRepository();

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

  void setShowtime(ShowtimeModel showtime) {
    _selectedShowtime = showtime;
    _selectedSeatIds.clear();
    _selectedSeatTypes.clear();
    _selectedFoods.clear();
    _holdUntil = null;
    _currentBookingCode = null;
    _errorMessage = null;
    notifyListeners();
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

    // Pricing rules
    int basePrice = 80000;
    if (format == '3D') basePrice = 100000;
    if (format == 'IMAX') basePrice = 120000;

    final bool isWeekend = start.weekday == DateTime.friday ||
        start.weekday == DateTime.saturday ||
        start.weekday == DateTime.sunday;
    final bool isPrime = start.hour >= 18 && start.hour < 22;

    final int timeSurcharge = (isWeekend ? 10000 : 0) + (isPrime ? 10000 : 0);

    for (final seatId in _selectedSeatIds) {
      final type = _selectedSeatTypes[seatId] ?? SeatType.standard;
      if (type == SeatType.vip) {
        total += basePrice + 20000 + timeSurcharge;
      } else if (type == SeatType.couple) {
        total += (2 * basePrice) + 20000 + timeSurcharge;
      } else {
        total += basePrice + timeSurcharge;
      }
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
    return calculateTicketTotal() + calculateFoodTotal();
  }

  Map<String, dynamic> generatePriceSnapshot() {
    final ticket = calculateTicketTotal();
    final food = calculateFoodTotal();
    return {
      'ticket_total': ticket,
      'food_total': food,
      'discount': 0,
      'total': ticket + food,
    };
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

    final bookingJson = {
      'showtime_id': _selectedShowtime!.id,
      'cinema_id': _selectedShowtime!.cinemaId,
      'movie_title': _selectedShowtime!.movieTitle ?? '',
      'cinema_name': _selectedShowtime!.cinemaName ?? '',
      'room_name': _selectedShowtime!.roomName ?? '',
      'format': _selectedShowtime!.format,
      'showtime_start': _selectedShowtime!.startTime.toIso8601String(),
      'price_snapshot': generatePriceSnapshot(),
      'seats': _selectedSeatIds.map((id) => {
        'id': id,
        'type': _selectedSeatTypes[id]?.name ?? 'standard',
        'price': calculateTicketTotal() ~/ _selectedSeatIds.length,
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
    notifyListeners();
  }
}
