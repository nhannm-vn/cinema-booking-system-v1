import 'package:flutter/material.dart';
import '../../../booking/data/models/booking_model.dart';
import '../../data/ticket_repository.dart';

/// Provider managing customer tickets list and status categorization.
class TicketProvider extends ChangeNotifier {
  final TicketRepository _repo;

  bool _isLoading = false;
  String? _errorMessage;
  List<BookingModel> _tickets = [];

  TicketProvider([TicketRepository? repo]) : _repo = repo ?? TicketRepository();

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Sắp tới: status == 'paid' và chưa qua giờ
  List<BookingModel> get upcomingTickets => _tickets
      .where((t) => t.status == 'paid' && !t.isNoShow && DateTime.now().isBefore(t.showtimeStart))
      .toList();

  /// Đã xem: status == 'used' hoặc noShow hoặc suất chiếu đã bắt đầu
  List<BookingModel> get historyTickets => _tickets
      .where((t) => t.status == 'used' || t.isNoShow || (t.status == 'paid' && DateTime.now().isAfter(t.showtimeStart)))
      .toList();

  /// Đã hủy: status == 'cancelled'
  List<BookingModel> get cancelledTickets => _tickets
      .where((t) => t.status == 'cancelled')
      .toList();

  Future<void> loadMyTickets() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _tickets = await _repo.getMyTickets();
      _isLoading = false;
      notifyListeners();
    } catch (_) {
      _errorMessage = 'Không thể tải danh sách vé.';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cancelBooking(String code, {String reason = 'Khách hủy vé trực tuyến'}) async {
    try {
      await _repo.cancelBooking(code, reason: reason);
      await loadMyTickets();
      return true;
    } catch (e) {
      _errorMessage = 'Không thể hủy vé: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
}
