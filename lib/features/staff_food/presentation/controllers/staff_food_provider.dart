import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../booking/data/models/booking_model.dart';
import '../../data/staff_food_repository.dart';

/// Presentation Controller for S19 Food Delivery Board.
/// References: ROLE_FLOWS.md Section 3.2 & BUSINESS_RULES.md Section 9 & m4_plan.md Section 5.2
class StaffFoodProvider extends ChangeNotifier {
  final StaffFoodRepository _repo;
  final SupabaseClient? _supabaseClient;

  StaffFoodProvider([StaffFoodRepository? repo, SupabaseClient? supabaseClient])
      : _repo = repo ?? StaffFoodRepository(),
        _supabaseClient = supabaseClient;

  bool _isLoading = false;
  String? _errorMessage;
  int _currentTabIndex = 0; // 0 = CHỜ GIAO, 1 = ĐÃ GIAO
  String _searchQuery = '';
  List<BookingModel> _allPendingOrders = [];
  List<BookingModel> _allDeliveredOrders = [];
  RealtimeChannel? _realtimeChannel;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentTabIndex => _currentTabIndex;
  String get searchQuery => _searchQuery;

  /// Danh sách đơn chờ giao, hỗ trợ tìm kiếm theo mã vé hoặc tên phim.
  List<BookingModel> get pendingOrders {
    if (_searchQuery.isEmpty) return _allPendingOrders;
    return _allPendingOrders
        .where((b) =>
            b.code.toUpperCase().contains(_searchQuery) ||
            b.movieTitle.toUpperCase().contains(_searchQuery))
        .toList();
  }

  /// Danh sách đơn đã giao, hỗ trợ tìm kiếm theo mã vé hoặc tên phim.
  List<BookingModel> get deliveredOrders {
    if (_searchQuery.isEmpty) return _allDeliveredOrders;
    return _allDeliveredOrders
        .where((b) =>
            b.code.toUpperCase().contains(_searchQuery) ||
            b.movieTitle.toUpperCase().contains(_searchQuery))
        .toList();
  }

  /// Nạp danh sách đơn đồ ăn cho rạp.
  Future<void> loadOrders(String cinemaId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final pending = await _repo.getPendingOrders(cinemaId);
      final delivered = await _repo.getDeliveredOrders(cinemaId);

      // Sắp xếp đơn chờ giao theo showtime_start tăng dần (suất chiếu gần nhất lên đầu)
      pending.sort((a, b) => a.showtimeStart.compareTo(b.showtimeStart));

      _allPendingOrders = pending;
      _allDeliveredOrders = delivered;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách đơn đồ ăn: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Chuyển đổi tab hiển thị (0: CHỜ GIAO, 1: ĐÃ GIAO).
  void setTab(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  /// Cập nhật từ khóa tìm kiếm mã vé.
  void setSearchQuery(String query) {
    _searchQuery = query.trim().toUpperCase();
    notifyListeners();
  }

  /// Xác nhận đã giao đồ ăn cho khách qua RPC deliver_food.
  Future<bool> deliverFood(String bookingCode, String cinemaId) async {
    try {
      await _repo.deliverFood(bookingCode);
      await loadOrders(cinemaId);
      return true;
    } catch (e) {
      _errorMessage = 'Không thể cập nhật trạng thái đã giao: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Đăng ký realtime lắng nghe thay đổi đơn hàng từ Supabase.
  void subscribeRealtime(String cinemaId) {
    try {
      final client = _supabaseClient ?? Supabase.instance.client;
      _realtimeChannel?.unsubscribe();
      _realtimeChannel = client
          .channel('public:bookings:food:$cinemaId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'bookings',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'cinema_id',
              value: cinemaId,
            ),
            callback: (_) {
              loadOrders(cinemaId);
            },
          )
          .subscribe();
    } on Object catch (_) {
      // Ignored in offline/test environments
    }
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }
}
