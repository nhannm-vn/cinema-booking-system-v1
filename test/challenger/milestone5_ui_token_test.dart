import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:cinema_booking_v1/core/routes/app_router.dart';
import 'package:cinema_booking_v1/core/theme/app_theme.dart';
import 'package:cinema_booking_v1/features/auth/presentation/controllers/auth_provider.dart';
import 'package:cinema_booking_v1/features/booking/data/models/booking_model.dart';
import 'package:cinema_booking_v1/features/booking/data/models/food_model.dart';
import 'package:cinema_booking_v1/features/booking/data/models/room_model.dart';
import 'package:cinema_booking_v1/features/booking/data/models/showtime_model.dart';
import 'package:cinema_booking_v1/features/chat/data/models/chat_message_model.dart';
import 'package:cinema_booking_v1/features/chat/presentation/controllers/support_chat_provider.dart';
import 'package:cinema_booking_v1/features/chat/presentation/screens/support_chat_screen.dart';
import 'package:cinema_booking_v1/features/cinemas/data/cinema_model.dart';
import 'package:cinema_booking_v1/features/management/data/models/audit_log_model.dart';
import 'package:cinema_booking_v1/features/management/data/models/dashboard_metrics_model.dart';
import 'package:cinema_booking_v1/features/management/data/models/pricing_settings_model.dart';
import 'package:cinema_booking_v1/features/management/data/models/voucher_model.dart';
import 'package:cinema_booking_v1/features/management/data/repositories/management_repository.dart';
import 'package:cinema_booking_v1/features/management/presentation/controllers/management_provider.dart';
import 'package:cinema_booking_v1/features/management/presentation/screens/audit_logs_screen.dart';
import 'package:cinema_booking_v1/features/management/presentation/screens/bookings_management_screen.dart';
import 'package:cinema_booking_v1/features/management/presentation/screens/cinemas_rooms_screen.dart';
import 'package:cinema_booking_v1/features/management/presentation/screens/food_catalog_screen.dart';
import 'package:cinema_booking_v1/features/management/presentation/screens/management_menu_screen.dart';
import 'package:cinema_booking_v1/features/management/presentation/screens/managers_management_screen.dart';
import 'package:cinema_booking_v1/features/management/presentation/screens/movies_management_screen.dart';
import 'package:cinema_booking_v1/features/management/presentation/screens/operational_dashboard_screen.dart';
import 'package:cinema_booking_v1/features/management/presentation/screens/pricing_settings_screen.dart';
import 'package:cinema_booking_v1/features/management/presentation/screens/seat_map_designer_screen.dart';
import 'package:cinema_booking_v1/features/management/presentation/screens/showtimes_management_screen.dart';
import 'package:cinema_booking_v1/features/management/presentation/screens/vouchers_management_screen.dart';
import 'package:cinema_booking_v1/features/movies/data/movie_model.dart';
import 'package:cinema_booking_v1/features/tickets/presentation/controllers/ticket_provider.dart';
import 'package:cinema_booking_v1/features/tickets/presentation/screens/my_tickets_screen.dart';
import 'package:cinema_booking_v1/features/tickets/presentation/screens/ticket_detail_screen.dart';
import 'package:cinema_booking_v1/shared/models/app_user.dart';
import 'package:cinema_booking_v1/shared/widgets/app_button.dart';
import 'package:cinema_booking_v1/shared/widgets/manager_bottom_nav.dart';

// =============================================================================
// TEST OBSERVER & DOUBLES FOR CHALLENGER M5.2
// =============================================================================

class MockChallengerNavigatorObserver extends NavigatorObserver {
  final List<String> pushedRoutes = [];
  final List<String> replacedRoutes = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route.settings.name != null) {
      pushedRoutes.add(route.settings.name!);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute?.settings.name != null) {
      replacedRoutes.add(newRoute!.settings.name!);
    }
  }
}

class MockChallengerAuthProvider extends ChangeNotifier implements AuthProvider {
  AppUser? _user;

  MockChallengerAuthProvider({
    String id = 'usr_admin_m5_challenger',
    String fullName = 'Challenger Admin',
    UserRole role = UserRole.admin,
    String cinemaId = 'cn_q1',
    bool isLocked = false,
  }) : _user = AppUser(
          id: id,
          fullName: fullName,
          role: role,
          cinemaId: cinemaId,
          isLocked: isLocked,
        );

  @override
  AppUser? get currentUser => _user;

  @override
  bool get isAuthenticated => _user != null;

  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => null;

  void setUser(AppUser? user) {
    _user = user;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeChallengerManagementRepository implements ManagementRepository {
  List<MovieModel> movies = [
    MovieModel(
      id: 'mov_mai',
      title: 'Mai',
      durationMin: 120,
      releaseDate: DateTime.now().subtract(const Duration(days: 10)),
      genres: ['Tâm lý', 'Hài'],
      ageRating: 'T18',
      isActive: true,
      description: 'Phim điện ảnh tâm lý xã hội',
      director: 'Trấn Thành',
    ),
  ];

  List<RoomModel> rooms = [
    const RoomModel(
      id: 'room_1',
      cinemaId: 'cn_q1',
      name: 'Phòng 1 (IMAX)',
      rows: 8,
      cols: 10,
      seatLayout: ['S,S,S,S,S,S,S,S,S,S', 'S,S,S,S,S,S,S,S,S,S'],
      seatCount: 80,
      formats: ['2D', '3D', 'IMAX'],
    ),
  ];

  List<ShowtimeModel> showtimes = [
    ShowtimeModel(
      id: 'st_1',
      movieId: 'mov_mai',
      cinemaId: 'cn_q1',
      roomId: 'room_1',
      startTime: DateTime.now().add(const Duration(hours: 3)),
      endTime: DateTime.now().add(const Duration(hours: 5)),
      format: '2D',
      movieTitle: 'Mai',
      roomName: 'Phòng 1 (IMAX)',
      totalSeats: 80,
      soldSeats: 15,
      status: 'active',
    ),
  ];

  List<BookingModel> bookings = [
    BookingModel(
      code: 'BK8888',
      userId: 'usr_cust',
      showtimeId: 'st_1',
      cinemaId: 'cn_q1',
      cinemaName: 'CGV Vincom Đồng Khởi',
      roomName: 'Phòng 1 (IMAX)',
      format: '2D',
      movieTitle: 'Mai',
      showtimeStart: DateTime.now().add(const Duration(hours: 4)),
      status: 'paid',
      channel: 'online',
      priceSnapshot: const {
        'total': 150000,
        'ticket_total': 150000,
        'food_total': 0,
        'discount': 0,
      },
      seats: const [
        {
          'id': 'D5',
          'type': 'standard',
          'price': 75000,
        },
      ],
      createdAt: DateTime.now(),
    ),
  ];

  List<FoodModel> foods = [
    const FoodModel(
      id: 'f1',
      cinemaId: 'cn_q1',
      name: 'Combo Bắp Nước 1',
      category: 'combo',
      price: 85000,
      isAvailable: true,
      description: '1 Bắp lớn + 2 Nước ngọt',
    ),
  ];

  List<VoucherModel> vouchers = [
    VoucherModel(
      code: 'VIP50',
      type: 'percent',
      value: 50,
      maxDiscount: 50000,
      startDate: DateTime.now().subtract(const Duration(days: 1)),
      expiresAt: DateTime.now().add(const Duration(days: 30)),
      maxUses: 100,
      usedCount: 5,
      isActive: true,
      createdAt: DateTime.now(),
    ),
  ];

  List<AppUser> managers = [
    const AppUser(
      id: 'mgr_1',
      fullName: 'Quản Lý Quận 1',
      role: UserRole.manager,
      cinemaId: 'cn_q1',
      email: 'manager1@cinema.vn',
      phone: '0901234567',
      isLocked: false,
    ),
  ];

  List<AuditLogModel> auditLogs = [
    AuditLogModel(
      id: 'log_1',
      actorRole: 'manager',
      actorName: 'Quản Lý Quận 1',
      action: 'cancelShowtime',
      targetType: 'showtime',
      targetId: 'st_1',
      reason: 'Hỏng máy chiếu',
      createdAt: DateTime.now(),
    ),
  ];

  PricingSettingsModel pricingSettings = PricingSettingsModel.defaultSettings();

  @override
  Future<DashboardMetricsModel> getDashboardMetrics(String cinemaId, {String period = 'today'}) async {
    return DashboardMetricsModel(
      cinemaId: cinemaId,
      period: period,
      todayRevenue: 25000000,
      todayTickets: 250,
      occupancyRate: 72.0,
      totalCapacity: 350,
      soldCapacity: 250,
      upcomingShowtimes: [
        UpcomingShowtimeItem(
          id: 'st_1',
          movieTitle: 'Mai',
          roomName: 'Phòng 1 (IMAX)',
          format: '2D',
          startTime: DateTime.now().add(const Duration(hours: 3)),
          totalSeats: 80,
          soldSeats: 15,
        ),
      ],
    );
  }

  @override
  Future<List<MovieModel>> getAllMovies() async => movies;

  @override
  Future<MovieModel> createMovie(MovieModel movie) async {
    movies.add(movie);
    return movie;
  }

  @override
  Future<void> updateMovie(MovieModel movie) async {
    final idx = movies.indexWhere((m) => m.id == movie.id);
    if (idx != -1) movies[idx] = movie;
  }

  @override
  Future<bool> hasActiveFutureShowtimes(String movieId) async => false;

  @override
  Future<void> deleteMovie(String movieId) async {
    movies.removeWhere((m) => m.id == movieId);
  }

  @override
  Future<List<ShowtimeModel>> getShowtimes({
    required String cinemaId,
    required DateTime date,
    String? roomId,
    String? format,
  }) async => showtimes;

  @override
  Future<void> createShowtime({
    required String movieId,
    required String cinemaId,
    required String roomId,
    required String format,
    required DateTime startTime,
    required DateTime endTime,
    required int totalSeats,
  }) async {
    showtimes.add(
      ShowtimeModel(
        id: 'st_${showtimes.length + 1}',
        movieId: movieId,
        cinemaId: cinemaId,
        roomId: roomId,
        startTime: startTime,
        endTime: endTime,
        format: format,
        movieTitle: 'Phim Mới',
        roomName: 'Phòng 1 (IMAX)',
        totalSeats: totalSeats,
        soldSeats: 0,
        status: 'active',
      ),
    );
  }

  @override
  Future<Map<String, dynamic>> cancelShowtime(String showtimeId, String reason) async {
    final idx = showtimes.indexWhere((s) => s.id == showtimeId);
    if (idx != -1) {
      showtimes[idx] = showtimes[idx].copyWith(status: 'cancelled', cancelReason: reason);
    }
    return {'success': true, 'refunded_bookings_count': 1};
  }

  @override
  Future<List<BookingModel>> getBookings(String cinemaId, {String? status, String? channel}) async => bookings;

  @override
  Future<List<FoodModel>> getFoods(String cinemaId, {String? category}) async {
    if (category != null && category.isNotEmpty && category != 'ALL') {
      return foods.where((f) => f.category == category.toLowerCase()).toList();
    }
    return foods;
  }

  @override
  Future<void> createFood(FoodModel food) async {
    foods.add(food);
  }

  @override
  Future<void> updateFood(FoodModel food) async {
    final idx = foods.indexWhere((f) => f.id == food.id);
    if (idx != -1) foods[idx] = food;
  }

  @override
  Future<void> toggleFoodAvailability(String foodId, bool isAvailable) async {
    final idx = foods.indexWhere((f) => f.id == foodId);
    if (idx != -1) {
      foods[idx] = foods[idx].copyWith(isAvailable: isAvailable);
    }
  }

  @override
  Future<void> deleteFood(String foodId) async {
    foods.removeWhere((f) => f.id == foodId);
  }

  @override
  Future<List<CinemaModel>> getAllCinemas() async => [
        const CinemaModel(
          id: 'cn_q1',
          name: 'CGV Vincom Đồng Khởi',
          address: '72 Lê Thánh Tôn, Q.1, TP. Hồ Chí Minh',
          lat: 10.778,
          lng: 106.702,
        ),
      ];

  @override
  Future<void> createCinema(CinemaModel cinema) async {}

  @override
  Future<void> updateCinema(CinemaModel cinema) async {}

  @override
  Future<List<RoomModel>> getRoomsByCinema(String cinemaId) async => rooms;

  @override
  Future<void> createRoom(RoomModel room) async {
    rooms.add(room);
  }

  @override
  Future<void> updateRoom(RoomModel room) async {
    final idx = rooms.indexWhere((r) => r.id == room.id);
    if (idx != -1) rooms[idx] = room;
  }

  @override
  Future<bool> hasFutureSoldShowtimes(String roomId) async => false;

  @override
  Future<void> updateRoomLayout({
    required String roomId,
    required int rows,
    required int cols,
    required List<String> seatLayout,
    required int seatCount,
    Map<String, dynamic>? oldSnapshot,
  }) async {}

  @override
  Future<PricingSettingsModel> getPricingSettings() async => pricingSettings;

  @override
  Future<void> updatePricingSettings(
    PricingSettingsModel settings, {
    PricingSettingsModel? oldSettings,
  }) async {
    pricingSettings = settings;
  }

  @override
  Future<List<VoucherModel>> getVouchers() async => vouchers;

  @override
  Future<void> createVoucher(VoucherModel voucher) async {
    vouchers.add(voucher);
  }

  @override
  Future<void> updateVoucher(VoucherModel voucher) async {
    final idx = vouchers.indexWhere((v) => v.code == voucher.code);
    if (idx != -1) vouchers[idx] = voucher;
  }

  @override
  Future<void> toggleVoucherStatus(String code, bool isActive) async {
    final idx = vouchers.indexWhere((v) => v.code == code);
    if (idx != -1) {
      vouchers[idx] = vouchers[idx].copyWith(isActive: isActive);
    }
  }

  @override
  Future<void> deleteVoucher(String code) async {
    vouchers.removeWhere((v) => v.code == code);
  }

  @override
  Future<List<AppUser>> getManagers() async => managers;

  @override
  Future<void> toggleUserLock(String userId, bool isLocked) async {
    final idx = managers.indexWhere((m) => m.id == userId);
    if (idx != -1) {
      managers[idx] = managers[idx].copyWith(isLocked: isLocked);
    }
  }

  @override
  Future<void> reassignManagerCinema(String managerId, String cinemaId) async {
    final idx = managers.indexWhere((m) => m.id == managerId);
    if (idx != -1) {
      managers[idx] = managers[idx].copyWith(cinemaId: cinemaId);
    }
  }

  @override
  Future<Map<String, dynamic>> createStaff({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
    required String cinemaId,
  }) async {
    managers.add(
      AppUser(
        id: 'mgr_${managers.length + 1}',
        fullName: fullName,
        role: UserRole.manager,
        cinemaId: cinemaId,
        email: email,
        phone: phone,
        isLocked: false,
      ),
    );
    return {'id': 'mgr_${managers.length}'};
  }

  @override
  Future<List<AuditLogModel>> getAuditLogs({
    String? action,
    String? cinemaId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async => auditLogs;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeChallengerTicketProvider extends ChangeNotifier implements TicketProvider {
  final List<BookingModel> _bookings = [
    BookingModel(
      code: 'VND1234',
      userId: 'usr_cust',
      showtimeId: 'st_1',
      cinemaId: 'cn_q1',
      cinemaName: 'CGV Vincom Đồng Khởi',
      roomName: 'Phòng 1 (IMAX)',
      format: '2D',
      movieTitle: 'Mai',
      showtimeStart: DateTime.now().add(const Duration(hours: 4)),
      status: 'paid',
      channel: 'online',
      priceSnapshot: const {
        'total': 150000,
        'ticket_total': 150000,
        'food_total': 0,
        'discount': 0,
      },
      seats: const [
        {
          'id': 'D5',
          'type': 'standard',
          'price': 75000,
        },
      ],
      createdAt: DateTime.now(),
    ),
  ];

  @override
  List<BookingModel> get upcomingTickets => _bookings
      .where((b) => b.status == 'paid' && DateTime.now().isBefore(b.showtimeStart))
      .toList();

  @override
  List<BookingModel> get historyTickets => _bookings
      .where((b) => b.status == 'used' || (b.status == 'paid' && DateTime.now().isAfter(b.showtimeStart)))
      .toList();

  @override
  List<BookingModel> get cancelledTickets => _bookings
      .where((b) => b.status == 'cancelled')
      .toList();

  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => null;

  @override
  Future<void> loadMyTickets() async {}

  @override
  Future<bool> cancelBooking(String code, {String reason = 'Khách hủy vé trực tuyến'}) async {
    final idx = _bookings.indexWhere((b) => b.code == code);
    if (idx != -1) {
      _bookings[idx] = _bookings[idx].copyWith(status: 'cancelled');
      notifyListeners();
      return true;
    }
    return false;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeChallengerSupportChatProvider extends ChangeNotifier implements SupportChatProvider {
  final List<ChatMessageModel> _messages = [
    ChatMessageModel(
      id: 'msg_1',
      conversationId: 'conv_1',
      senderId: 'usr_cust',
      text: 'Xin chào rạp, tôi cần hỗ trợ về đơn vé',
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    ChatMessageModel(
      id: 'msg_2',
      conversationId: 'conv_1',
      senderId: 'staff_1',
      text: 'Dạ rạp nghe ạ, anh/chị cung cấp mã đơn nhé',
      createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
  ];

  @override
  List<ChatMessageModel> get messages => _messages;

  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => null;

  @override
  String? get conversationId => 'conv_1';

  @override
  Future<void> initConversation(String userId, String cinemaId) async {}

  @override
  Future<bool> sendMessage(String text, {String? bookingCode}) async {
    _messages.add(
      ChatMessageModel(
        id: 'msg_${_messages.length + 1}',
        conversationId: 'conv_1',
        senderId: 'usr_cust',
        text: text,
        bookingCode: bookingCode,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// =============================================================================
// STRICT TOKEN ASSERTION HELPERS
// =============================================================================

void setTestScreenSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

/// Asserts all button and tab labels are strictly UPPERCASE (.toUpperCase()).
void verifyAllButtonAndTabLabelsUppercase(WidgetTester tester) {
  // 1. AppButton labels
  final appButtons = tester.widgetList<AppButton>(find.byType(AppButton));
  for (final btn in appButtons) {
    expect(
      btn.label,
      equals(btn.label.toUpperCase()),
      reason: 'AppButton label "${btn.label}" must be strictly UPPERCASE',
    );
  }

  // 2. ElevatedButton text
  final elevatedButtons = find.byType(ElevatedButton);
  for (final eb in tester.widgetList<ElevatedButton>(elevatedButtons)) {
    final textWidgets = tester.widgetList<Text>(
      find.descendant(of: find.byWidget(eb), matching: find.byType(Text)),
    );
    for (final tw in textWidgets) {
      if (tw.data != null && tw.data!.trim().isNotEmpty) {
        expect(
          tw.data!.trim(),
          equals(tw.data!.trim().toUpperCase()),
          reason: 'ElevatedButton child text "${tw.data}" must be strictly UPPERCASE',
        );
      }
    }
  }

  // 3. OutlinedButton text
  final outlinedButtons = find.byType(OutlinedButton);
  for (final ob in tester.widgetList<OutlinedButton>(outlinedButtons)) {
    final textWidgets = tester.widgetList<Text>(
      find.descendant(of: find.byWidget(ob), matching: find.byType(Text)),
    );
    for (final tw in textWidgets) {
      if (tw.data != null && tw.data!.trim().isNotEmpty) {
        expect(
          tw.data!.trim(),
          equals(tw.data!.trim().toUpperCase()),
          reason: 'OutlinedButton child text "${tw.data}" must be strictly UPPERCASE',
        );
      }
    }
  }

  // 4. TextButton text
  final textButtons = find.byType(TextButton);
  for (final tb in tester.widgetList<TextButton>(textButtons)) {
    final textWidgets = tester.widgetList<Text>(
      find.descendant(of: find.byWidget(tb), matching: find.byType(Text)),
    );
    for (final tw in textWidgets) {
      if (tw.data != null && tw.data!.trim().isNotEmpty) {
        expect(
          tw.data!.trim(),
          equals(tw.data!.trim().toUpperCase()),
          reason: 'TextButton child text "${tw.data}" must be strictly UPPERCASE',
        );
      }
    }
  }

  // 5. TabBar Tab widgets
  final tabs = tester.widgetList<Tab>(find.byType(Tab));
  for (final tab in tabs) {
    if (tab.text != null && tab.text!.trim().isNotEmpty) {
      expect(
        tab.text!.trim(),
        equals(tab.text!.trim().toUpperCase()),
        reason: 'Tab text "${tab.text}" must be strictly UPPERCASE',
      );
    }
  }
}

/// Asserts that at most 1 primary button exists on a screen or modal.
void verifyMaxOnePrimaryButton(WidgetTester tester, {Finder? scope}) {
  final Finder finder = scope != null
      ? find.descendant(of: scope, matching: find.byType(ElevatedButton))
      : find.byType(ElevatedButton);
  final count = tester.widgetList(finder).length;
  expect(
    count,
    lessThanOrEqualTo(1),
    reason: 'DESIGN_TOKENS.md rule violation: At most 1 primary button on a screen or modal. Found $count',
  );
}

/// Asserts zero elevation (0) and zero BoxShadow across all rendered widgets.
void verifyZeroElevationAndZeroBoxShadow(WidgetTester tester) {
  // 1. AppBars have 0 elevation
  final appBars = tester.widgetList<AppBar>(find.byType(AppBar));
  for (final ab in appBars) {
    expect(ab.elevation ?? 0, equals(0), reason: 'AppBar elevation must be 0');
    expect(ab.scrolledUnderElevation ?? 0, equals(0), reason: 'AppBar scrolledUnderElevation must be 0');
  }

  // 2. ElevatedButtons have 0 elevation
  final elevatedButtons = tester.widgetList<ElevatedButton>(find.byType(ElevatedButton));
  for (final eb in elevatedButtons) {
    final elev = eb.style?.elevation?.resolve({});
    expect(elev ?? 0, equals(0), reason: 'ElevatedButton elevation must be 0');
  }

  // 3. OutlinedButtons have 0 elevation
  final outlinedButtons = tester.widgetList<OutlinedButton>(find.byType(OutlinedButton));
  for (final ob in outlinedButtons) {
    final elev = ob.style?.elevation?.resolve({});
    expect(elev ?? 0, equals(0), reason: 'OutlinedButton elevation must be 0');
  }

  // 4. TextButtons have 0 elevation
  final textButtons = tester.widgetList<TextButton>(find.byType(TextButton));
  for (final tb in textButtons) {
    final elev = tb.style?.elevation?.resolve({});
    expect(elev ?? 0, equals(0), reason: 'TextButton elevation must be 0');
  }

  // 5. FloatingActionButtons have 0 elevation
  final fabs = tester.widgetList<FloatingActionButton>(find.byType(FloatingActionButton));
  for (final fab in fabs) {
    expect(fab.elevation ?? 0, equals(0), reason: 'FloatingActionButton elevation must be 0');
  }

  // 6. ChoiceChips have 0 elevation
  final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
  for (final chip in chips) {
    expect(chip.elevation ?? 0, equals(0), reason: 'ChoiceChip elevation must be 0');
    expect(chip.pressElevation ?? 0, equals(0), reason: 'ChoiceChip pressElevation must be 0');
  }

  // 7. Cards have 0 elevation
  final cards = tester.widgetList<Card>(find.byType(Card));
  for (final card in cards) {
    expect(card.elevation ?? 0, equals(0), reason: 'Card elevation must be 0');
  }

  // 8. DecoratedBox widgets have zero BoxShadow
  final decoratedBoxes = tester.widgetList<DecoratedBox>(find.byType(DecoratedBox));
  for (final db in decoratedBoxes) {
    if (db.decoration is BoxDecoration) {
      final boxDec = db.decoration as BoxDecoration;
      expect(
        boxDec.boxShadow == null || boxDec.boxShadow!.isEmpty,
        isTrue,
        reason: 'DecoratedBox BoxDecoration must have zero BoxShadow',
      );
    }
  }

  // 9. Containers have zero BoxShadow
  final containers = tester.widgetList<Container>(find.byType(Container));
  for (final c in containers) {
    if (c.decoration is BoxDecoration) {
      final boxDec = c.decoration as BoxDecoration;
      expect(
        boxDec.boxShadow == null || boxDec.boxShadow!.isEmpty,
        isTrue,
        reason: 'Container BoxDecoration must have zero BoxShadow',
      );
    }
  }
}

/// Combined validation helper for all strict tokens.
void verifyAllStrictTokens(WidgetTester tester, {Finder? primaryScope}) {
  verifyAllButtonAndTabLabelsUppercase(tester);
  verifyMaxOnePrimaryButton(tester, scope: primaryScope);
  verifyZeroElevationAndZeroBoxShadow(tester);
}

// =============================================================================
// MAIN TEST SUITE: EMPIRICAL UI TOKEN & ROUTING STRESS TEST
// =============================================================================

void main() {
  late MockChallengerAuthProvider authProvider;
  late FakeChallengerManagementRepository repository;
  late ManagementProvider managementProvider;
  late FakeChallengerTicketProvider ticketProvider;
  late FakeChallengerSupportChatProvider chatProvider;
  late MockChallengerNavigatorObserver navigatorObserver;

  setUp(() {
    authProvider = MockChallengerAuthProvider();
    repository = FakeChallengerManagementRepository();
    managementProvider = ManagementProvider(repository);
    ticketProvider = FakeChallengerTicketProvider();
    chatProvider = FakeChallengerSupportChatProvider();
    navigatorObserver = MockChallengerNavigatorObserver();
  });

  Widget buildTestApp(
    Widget child, {
    ManagementProvider? customManagementProvider,
    NavigatorObserver? customObserver,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<ManagementProvider>.value(
          value: customManagementProvider ?? managementProvider,
        ),
        ChangeNotifierProvider<TicketProvider>.value(value: ticketProvider),
        ChangeNotifierProvider<SupportChatProvider>.value(value: chatProvider),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        navigatorObservers: [
          if (customObserver != null) customObserver else navigatorObserver,
        ],
        routes: {
          AppRoutes.home: (_) => const Scaffold(body: Text('HOME_ROUTE')),
          AppRoutes.myTickets: (_) => const MyTicketsScreen(),
          AppRoutes.ticketDetail: (_) => const TicketDetailScreen(),
          AppRoutes.managementHome: (_) => const ManagementMenuScreen(),
          AppRoutes.manageMovies: (_) => const MoviesManagementScreen(),
          AppRoutes.manageShowtimes: (_) => const ShowtimesManagementScreen(),
          AppRoutes.manageBookings: (_) => const BookingsManagementScreen(),
          AppRoutes.manageFoods: (_) => const FoodCatalogScreen(),
          AppRoutes.dashboard: (_) => const OperationalDashboardScreen(),
          AppRoutes.configSeatMap: (_) => const SeatMapDesignerScreen(),
          AppRoutes.manageRooms: (_) => const CinemasRoomsScreen(),
          AppRoutes.configPricing: (_) => const PricingSettingsScreen(),
          AppRoutes.manageVouchers: (_) => const VouchersManagementScreen(),
          AppRoutes.manageManagers: (_) => const ManagersManagementScreen(),
          AppRoutes.auditLogs: (_) => const AuditLogsScreen(),
          AppRoutes.supportChat: (_) => const SupportChatScreen(),
          AppRoutes.profile: (_) => const Scaffold(body: Text('PROFILE_ROUTE')),
        },
        home: child,
      ),
    );
  }

  group('Milestone 5 Empirical UI Token & Routing Stress Suite', () {
    // -------------------------------------------------------------------------
    // S10: My Tickets Screen
    // -------------------------------------------------------------------------
    testWidgets('1. S10 MyTicketsScreen: strict tokens, uppercase tabs, zero shadow', (tester) async {
      setTestScreenSize(tester);
      await tester.pumpWidget(buildTestApp(const MyTicketsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('VÉ CỦA TÔI'), findsAtLeastNWidgets(1));
      expect(find.text('SẮP TỚI'), findsOneWidget);
      expect(find.text('ĐÃ XEM'), findsOneWidget);
      expect(find.text('ĐÃ HỦY'), findsOneWidget);

      verifyAllStrictTokens(tester);
    });

    // -------------------------------------------------------------------------
    // S10B: Ticket Detail Screen & Cancellation Dialog
    // -------------------------------------------------------------------------
    testWidgets('2. S10B TicketDetailScreen & Cancel Modal: uppercase actions, zero elevation', (tester) async {
      setTestScreenSize(tester);
      final ticket = ticketProvider.upcomingTickets.first;
      await tester.pumpWidget(buildTestApp(TicketDetailScreen(initialTicket: ticket)));
      await tester.pumpAndSettle();

      expect(find.text('CHI TIẾT VÉ'), findsOneWidget);
      expect(find.text('HỦY VÉ VÀ HOÀN TIỀN'), findsOneWidget);

      verifyAllStrictTokens(tester);

      // Open cancel dialog
      await tester.scrollUntilVisible(find.text('HỦY VÉ VÀ HOÀN TIỀN'), 300);
      await tester.tap(find.text('HỦY VÉ VÀ HOÀN TIỀN'));
      await tester.pumpAndSettle();

      expect(find.text('XÁC NHẬN HỦY VÉ'), findsOneWidget);
      expect(find.text('QUAY LẠI'), findsOneWidget);
      expect(find.text('XÁC NHẬN HỦY'), findsOneWidget);

      verifyAllStrictTokens(tester, primaryScope: find.byType(AlertDialog));
    });

    // -------------------------------------------------------------------------
    // S12: Management Menu Screen
    // -------------------------------------------------------------------------
    testWidgets('3. S12 ManagementMenuScreen: strict tokens, zero elevation, uppercase title', (tester) async {
      setTestScreenSize(tester);
      await tester.pumpWidget(buildTestApp(const ManagementMenuScreen()));
      await tester.pumpAndSettle();

      expect(find.text('QUẢN LÝ HỆ THỐNG'), findsOneWidget);
      verifyAllStrictTokens(tester);
    });

    // -------------------------------------------------------------------------
    // S13: Movies Management Screen, Delete Dialog & Add Sheet
    // -------------------------------------------------------------------------
    testWidgets('4. S13 MoviesManagementScreen & Modals: uppercase chips, <=1 primary button', (tester) async {
      setTestScreenSize(tester);
      await tester.pumpWidget(buildTestApp(const MoviesManagementScreen()));
      await tester.pumpAndSettle();

      expect(find.text('QUẢN LÝ DANH MỤC PHIM'), findsOneWidget);
      expect(find.text('THÊM PHIM'), findsOneWidget);
      verifyAllStrictTokens(tester);

      // Open delete dialog
      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();

      expect(find.text('XÁC NHẬN XÓA PHIM'), findsOneWidget);
      expect(find.text('HỦY'), findsOneWidget);
      expect(find.text('XÁC NHẬN XÓA'), findsOneWidget);
      verifyAllStrictTokens(tester, primaryScope: find.byType(AlertDialog));
    });

    // -------------------------------------------------------------------------
    // S14: Showtimes Management Screen, Cancel Dialog & Add Sheet
    // -------------------------------------------------------------------------
    testWidgets('5. S14 ShowtimesManagementScreen & Modals: strict tokens, uppercase buttons', (tester) async {
      setTestScreenSize(tester);
      await tester.pumpWidget(buildTestApp(const ShowtimesManagementScreen()));
      await tester.pumpAndSettle();

      expect(find.text('LỊCH SUẤT CHIẾU'), findsOneWidget);
      expect(find.text('THÊM SUẤT'), findsOneWidget);
      expect(find.text('HỦY SUẤT'), findsOneWidget);
      verifyAllStrictTokens(tester);

      // Open cancel showtime dialog
      await tester.tap(find.text('HỦY SUẤT').first);
      await tester.pumpAndSettle();

      expect(find.text('XÁC NHẬN HỦY SUẤT CHIẾU'), findsOneWidget);
      expect(find.text('QUAY LẠI'), findsOneWidget);
      expect(find.text('XÁC NHẬN HỦY'), findsOneWidget);
      verifyAllStrictTokens(tester, primaryScope: find.byType(AlertDialog));
    });

    // -------------------------------------------------------------------------
    // S15: Bookings Management Screen & Detail Modal Sheet
    // -------------------------------------------------------------------------
    testWidgets('6. S15 BookingsManagementScreen & Detail: uppercase filter chips, zero shadow', (tester) async {
      setTestScreenSize(tester);
      await tester.pumpWidget(buildTestApp(const BookingsManagementScreen()));
      await tester.pumpAndSettle();

      expect(find.text('KIỂM TRA ĐƠN VÉ & ĐẶT CHỖ'), findsOneWidget);
      expect(find.text('TẤT CẢ'), findsAtLeastNWidgets(1));
      expect(find.text('ONLINE'), findsAtLeastNWidgets(1));
      verifyAllStrictTokens(tester);

      // Open booking detail bottom sheet
      await tester.tap(find.text('#BK8888').first);
      await tester.pumpAndSettle();

      expect(find.text('ĐƠN VÉ #BK8888'), findsOneWidget);
      verifyAllStrictTokens(tester, primaryScope: find.byType(BottomSheet));
    });

    // -------------------------------------------------------------------------
    // S16: Food Catalog Screen, Delete Dialog & Add Sheet
    // -------------------------------------------------------------------------
    testWidgets('7. S16 FoodCatalogScreen & Modals: uppercase categories, <=1 primary button', (tester) async {
      setTestScreenSize(tester);
      await tester.pumpWidget(buildTestApp(const FoodCatalogScreen()));
      await tester.pumpAndSettle();

      expect(find.text('MENU BẮP NƯỚC & ĐỒ ĂN'), findsOneWidget);
      expect(find.text('THÊM MÓN'), findsOneWidget);
      verifyAllStrictTokens(tester);

      // Open delete dialog
      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();

      expect(find.text('XÁC NHẬN XÓA MÓN ĂN'), findsOneWidget);
      expect(find.text('HỦY'), findsOneWidget);
      expect(find.text('XÁC NHẬN XÓA'), findsOneWidget);
      verifyAllStrictTokens(tester, primaryScope: find.byType(AlertDialog));
    });

    // -------------------------------------------------------------------------
    // S22: Operational Dashboard Screen
    // -------------------------------------------------------------------------
    testWidgets('8. S22 OperationalDashboardScreen: uppercase period tabs, zero shadow', (tester) async {
      setTestScreenSize(tester);
      await tester.pumpWidget(buildTestApp(const OperationalDashboardScreen()));
      await tester.pumpAndSettle();

      expect(find.text('BÀN LÀM VIỆC VẬN HÀNH'), findsOneWidget);
      expect(find.text('HÔM NAY'), findsOneWidget);
      expect(find.text('7 NGÀY'), findsOneWidget);
      expect(find.text('THÁNG NÀY'), findsOneWidget);
      expect(find.text('LẬP SUẤT'), findsOneWidget);
      expect(find.text('BÁN QUẦY'), findsOneWidget);
      expect(find.text('SOÁT VÉ'), findsOneWidget);
      expect(find.text('ĐƠN VÉ'), findsOneWidget);

      verifyAllStrictTokens(tester);
    });

    // -------------------------------------------------------------------------
    // S24: Seat Map Designer Screen
    // -------------------------------------------------------------------------
    testWidgets('9. S24 SeatMapDesignerScreen: uppercase brush chips, exactly 1 primary button', (tester) async {
      setTestScreenSize(tester);
      final room = repository.rooms.first;
      await tester.pumpWidget(buildTestApp(SeatMapDesignerScreen(room: room)));
      await tester.pumpAndSettle();

      expect(find.text('THIẾT KẾ SƠ ĐỒ GHẾ'), findsOneWidget);
      expect(find.text('XOAY VÒNG'), findsOneWidget);
      expect(find.text('THƯỜNG (S)'), findsOneWidget);
      expect(find.text('VIP (V)'), findsOneWidget);
      expect(find.text('ĐÔI (C)'), findsOneWidget);
      expect(find.text('LỐI ĐI (_)'), findsOneWidget);
      expect(find.text('LƯU SƠ ĐỒ PHÒNG CHIẾU'), findsOneWidget);

      verifyAllStrictTokens(tester);
    });

    // -------------------------------------------------------------------------
    // S25: Cinemas & Rooms Screen
    // -------------------------------------------------------------------------
    testWidgets('10. S25 CinemasRoomsScreen: uppercase chips, <=1 primary button', (tester) async {
      setTestScreenSize(tester);
      await tester.pumpWidget(buildTestApp(const CinemasRoomsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('RẠP VÀ PHÒNG CHIẾU'), findsOneWidget);
      expect(find.text('THÊM PHÒNG'), findsOneWidget);
      expect(find.text('THIẾT KẾ SƠ ĐỒ GHẾ'), findsOneWidget);
      verifyAllStrictTokens(tester);
    });

    // -------------------------------------------------------------------------
    // S26: Pricing Settings Screen & Confirm Dialog
    // -------------------------------------------------------------------------
    testWidgets('11. S26 PricingSettingsScreen: uppercase actions, 0 elevation, <=1 primary button', (tester) async {
      setTestScreenSize(tester);
      await tester.pumpWidget(buildTestApp(const PricingSettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('BẢNG GIÁ VÀ PHỤ THU ĐỘNG'), findsOneWidget);
      expect(find.text('LƯU BẢNG GIÁ'), findsOneWidget);
      expect(find.text('GIÁ VÉ MÔ PHỎNG:'), findsOneWidget);
      verifyAllStrictTokens(tester);

      // Open confirmation dialog
      await tester.tap(find.text('LƯU BẢNG GIÁ'));
      await tester.pumpAndSettle();

      expect(find.text('XÁC NHẬN CẬP NHẬT BẢNG GIÁ'), findsOneWidget);
      expect(find.text('HỦY'), findsOneWidget);
      expect(find.text('XÁC NHẬN LƯU'), findsOneWidget);
      verifyAllStrictTokens(tester, primaryScope: find.byType(AlertDialog));
    });

    // -------------------------------------------------------------------------
    // S27: Vouchers Management Screen & Delete Dialog
    // -------------------------------------------------------------------------
    testWidgets('12. S27 VouchersManagementScreen & Modals: uppercase chips, zero elevation', (tester) async {
      setTestScreenSize(tester);
      await tester.pumpWidget(buildTestApp(const VouchersManagementScreen()));
      await tester.pumpAndSettle();

      expect(find.text('QUẢN LÝ VOUCHER & KHUYẾN MÃI'), findsOneWidget);
      expect(find.text('THÊM VOUCHER'), findsOneWidget);
      verifyAllStrictTokens(tester);

      // Open delete dialog
      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();

      expect(find.text('XÁC NHẬN XÓA VOUCHER'), findsOneWidget);
      expect(find.text('HỦY'), findsOneWidget);
      expect(find.text('XÁC NHẬN XÓA'), findsOneWidget);
      verifyAllStrictTokens(tester, primaryScope: find.byType(AlertDialog));
    });

    // -------------------------------------------------------------------------
    // S28: Managers Management Screen, Lock Dialog & Reassign Modal
    // -------------------------------------------------------------------------
    testWidgets('13. S28 ManagersManagementScreen & Modals: strict tokens, uppercase actions', (tester) async {
      setTestScreenSize(tester);
      await tester.pumpWidget(buildTestApp(const ManagersManagementScreen()));
      await tester.pumpAndSettle();

      expect(find.text('QUẢN LÝ QUẢN LÝ RẠP'), findsOneWidget);
      expect(find.text('THÊM MANAGER'), findsOneWidget);
      expect(find.text('CHUYỂN RẠP'), findsOneWidget);
      expect(find.text('KHÓA'), findsOneWidget);
      verifyAllStrictTokens(tester);

      // Open lock dialog
      await tester.tap(find.text('KHÓA').first);
      await tester.pumpAndSettle();

      expect(find.text('XÁC NHẬN KHÓA TÀI KHOẢN'), findsOneWidget);
      expect(find.text('HỦY'), findsOneWidget);
      expect(find.text('KHÓA TÀI KHOẢN'), findsOneWidget);
      verifyAllStrictTokens(tester, primaryScope: find.byType(AlertDialog));

      // Close dialog and open reassign dialog
      await tester.tap(find.text('HỦY'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('CHUYỂN RẠP').first);
      await tester.pumpAndSettle();

      expect(find.text('CHUYỂN CÔNG TÁC QUẢN LÝ'), findsOneWidget);
      expect(find.text('HỦY'), findsOneWidget);
      expect(find.text('XÁC NHẬN'), findsOneWidget);
      verifyAllStrictTokens(tester, primaryScope: find.byType(AlertDialog));
    });

    // -------------------------------------------------------------------------
    // S29: Audit Logs Screen & Detail Modal
    // -------------------------------------------------------------------------
    testWidgets('14. S29 AuditLogsScreen & Modal: uppercase action chips, zero shadow', (tester) async {
      setTestScreenSize(tester);
      await tester.pumpWidget(buildTestApp(const AuditLogsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('NHẬT KÝ THAO TÁC HỆ THỐNG'), findsOneWidget);
      expect(find.text('TẤT CẢ'), findsOneWidget);
      expect(find.text('HỦY SUẤT'), findsAtLeastNWidgets(1));
      verifyAllStrictTokens(tester);

      // Open audit log detail sheet by tapping the log item
      await tester.tap(find.text('Thực hiện: Quản Lý Quận 1'));
      await tester.pumpAndSettle();

      expect(find.text('CHI TIẾT NHẬT KÝ'), findsOneWidget);
      expect(find.text('ĐÓNG'), findsOneWidget);
      verifyAllStrictTokens(tester, primaryScope: find.byType(BottomSheet));
    });

    // -------------------------------------------------------------------------
    // S31: Support Chat Screen
    // -------------------------------------------------------------------------
    testWidgets('15. S31 SupportChatScreen: strict tokens, uppercase title, zero shadow', (tester) async {
      setTestScreenSize(tester);
      await tester.pumpWidget(buildTestApp(const SupportChatScreen()));
      await tester.pumpAndSettle();

      expect(find.text('HỖ TRỢ TRỰC TUYẾN'), findsOneWidget);
      expect(find.text('Xin chào rạp, tôi cần hỗ trợ về đơn vé'), findsOneWidget);
      expect(find.text('Dạ rạp nghe ạ, anh/chị cung cấp mã đơn nhé'), findsOneWidget);

      verifyAllStrictTokens(tester);
    });

    // -------------------------------------------------------------------------
    // ManagerBottomNav Rendering & Strict Tokens
    // -------------------------------------------------------------------------
    testWidgets('16. ManagerBottomNav: renders 3 tabs, all uppercase, zero shadow, zero elevation', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const Scaffold(
            bottomNavigationBar: ManagerBottomNav(currentIndex: 0),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TỔNG QUAN'), findsOneWidget);
      expect(find.text('QUẢN LÝ'), findsOneWidget);
      expect(find.text('TÀI KHOẢN'), findsOneWidget);

      verifyAllStrictTokens(tester);
    });

    // -------------------------------------------------------------------------
    // ManagerBottomNav 3-Tab Navigation Routing Stress Test
    // -------------------------------------------------------------------------
    testWidgets('17. ManagerBottomNav Routing: tapping each tab triggers pushReplacementNamed to target route', (tester) async {
      final navObserver = MockChallengerNavigatorObserver();

      // Mount with currentIndex: 0 (TỔNG QUAN)
      await tester.pumpWidget(
        buildTestApp(
          const Scaffold(
            bottomNavigationBar: ManagerBottomNav(currentIndex: 0),
          ),
          customObserver: navObserver,
        ),
      );
      await tester.pumpAndSettle();

      // Tapping current tab (TỔNG QUAN, index 0) must be a no-op
      await tester.tap(find.text('TỔNG QUAN'));
      await tester.pumpAndSettle();
      expect(navObserver.replacedRoutes, isEmpty,
          reason: 'Tapping active tab 0 must not trigger navigation');

      // Tapping QUẢN LÝ (index 1) must navigate to AppRoutes.managementHome
      await tester.tap(find.text('QUẢN LÝ'));
      await tester.pumpAndSettle();
      expect(navObserver.replacedRoutes, contains(AppRoutes.managementHome));

      // Now mount with currentIndex: 1 (QUẢN LÝ)
      navObserver.replacedRoutes.clear();
      await tester.pumpWidget(
        buildTestApp(
          const Scaffold(
            bottomNavigationBar: ManagerBottomNav(currentIndex: 1),
          ),
          customObserver: navObserver,
        ),
      );
      await tester.pumpAndSettle();

      // Tapping TỔNG QUAN (index 0) must navigate to AppRoutes.dashboard
      await tester.tap(find.text('TỔNG QUAN'));
      await tester.pumpAndSettle();
      expect(navObserver.replacedRoutes, contains(AppRoutes.dashboard));

      // Tapping TÀI KHOẢN (index 2) must navigate to AppRoutes.profile
      navObserver.replacedRoutes.clear();
      await tester.pumpWidget(
        buildTestApp(
          const Scaffold(
            bottomNavigationBar: ManagerBottomNav(currentIndex: 1),
          ),
          customObserver: navObserver,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('TÀI KHOẢN'));
      await tester.pumpAndSettle();
      expect(navObserver.replacedRoutes, contains(AppRoutes.profile));
    });

    // -------------------------------------------------------------------------
    // Adversarial Stress Test: Multi-room scenario on S25
    // -------------------------------------------------------------------------
    testWidgets('18. Multi-room on S25 uses outline buttons per room card (max 1 primary invariant satisfied)', (tester) async {
      setTestScreenSize(tester);
      final multiRoomRepo = FakeChallengerManagementRepository();
      multiRoomRepo.rooms = [
        const RoomModel(
          id: 'room_1',
          cinemaId: 'cn_q1',
          name: 'Phòng 1 (IMAX)',
          rows: 8,
          cols: 10,
          seatLayout: ['S,S'],
          seatCount: 80,
          formats: ['2D', 'IMAX'],
        ),
        const RoomModel(
          id: 'room_2',
          cinemaId: 'cn_q1',
          name: 'Phòng 2 (Gold Class)',
          rows: 6,
          cols: 8,
          seatLayout: ['S,S'],
          seatCount: 48,
          formats: ['2D', '3D'],
        ),
      ];
      final multiRoomProvider = ManagementProvider(multiRoomRepo);

      await tester.pumpWidget(
        buildTestApp(
          const CinemasRoomsScreen(),
          customManagementProvider: multiRoomProvider,
        ),
      );
      await tester.pumpAndSettle();

      // In multi-room scenario, room cards render AppButton.outline so <= 1 primary button exists
      final primaryButtons = tester.widgetList<ElevatedButton>(find.byType(ElevatedButton)).toList();
      expect(primaryButtons.length, lessThanOrEqualTo(1),
          reason: 'At most 1 primary button exists per screen view');
      final outlineButtons = tester.widgetList<OutlinedButton>(find.byType(OutlinedButton)).toList();
      expect(outlineButtons.length, equals(2),
          reason: 'Each room card renders an outline button for THIẾT KẾ SƠ ĐỒ GHẾ');
    });

    // -------------------------------------------------------------------------
    // Adversarial Stress Test: Constrained Width & Modal Responsive Wrap on S27
    // -------------------------------------------------------------------------
    testWidgets('19. S27 constrained width stress: filter chips and modal voucher type wrap without overflow', (tester) async {
      // Constrained mobile viewport (320px width)
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final emptyRepo = FakeChallengerManagementRepository();
      emptyRepo.vouchers = [];
      final emptyProvider = ManagementProvider(emptyRepo);

      await tester.pumpWidget(
        buildTestApp(
          const VouchersManagementScreen(),
          customManagementProvider: emptyProvider,
        ),
      );
      await tester.pumpAndSettle();

      // Verify filter chips wrap properly without any RenderFlex overflow
      expect(tester.takeException(), isNull);
      expect(find.text('TẤT CẢ'), findsOneWidget);
      expect(find.text('CÒN HẠN'), findsOneWidget);
      expect(find.text('HẾT LƯỢT'), findsOneWidget);
      expect(find.text('HẾT HẠN'), findsOneWidget);
      expect(find.text('TẠM KHÓA'), findsOneWidget);

      // Open Voucher Form Sheet modal
      await tester.tap(find.text('THÊM VOUCHER'));
      await tester.pumpAndSettle();

      // Verify modal sheet rendered and type selector chips wrapped without overflow
      expect(find.text('TẠO VOUCHER MỚI'), findsOneWidget);
      expect(find.text('Phần trăm (%)'), findsOneWidget);
      expect(find.text('Số tiền cố định (VND)'), findsOneWidget);
      expect(find.text('LƯU VOUCHER'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Verify strict tokens in bottom sheet
      verifyAllStrictTokens(tester, primaryScope: find.byType(BottomSheet));
    });

    // -------------------------------------------------------------------------
    // Adversarial Stress Test: Voucher Card Action Row Overflow on 360px Screen
    // -------------------------------------------------------------------------
    testWidgets('20. S27 voucher card layout on standard 360px mobile screen (finding: action row overflow)', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp(const VouchersManagementScreen()));
      await tester.pumpAndSettle();

      // Catch the RenderFlex overflow exception
      final exception = tester.takeException();
      expect(exception, isNotNull,
          reason: 'Voucher card action row currently overflows by 45px at 360px width');
      expect(exception.toString(), contains('RenderFlex overflowed'));
    });
  });
}


