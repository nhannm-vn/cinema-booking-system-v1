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
import 'package:cinema_booking_v1/features/cinemas/data/cinema_model.dart';
import 'package:cinema_booking_v1/features/chat/data/models/chat_message_model.dart';
import 'package:cinema_booking_v1/features/chat/presentation/controllers/support_chat_provider.dart';
import 'package:cinema_booking_v1/features/chat/presentation/screens/support_chat_screen.dart';
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
import 'package:cinema_booking_v1/shared/widgets/manager_bottom_nav.dart';

// =============================================================================
// CHALLENGER TEST DOUBLES FOR MILESTONE 5 EMPIRICAL VERIFICATION
// =============================================================================

class MockM5AuthProvider extends ChangeNotifier implements AuthProvider {
  AppUser? _user;

  MockM5AuthProvider({
    String id = 'usr_admin_m5',
    String fullName = 'Admin Tổng',
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

class FakeM5ManagementRepository implements ManagementRepository {
  List<MovieModel> movies = [
    MovieModel(
      id: 'mov_1',
      title: 'Mai',
      durationMin: 120,
      releaseDate: DateTime.now().subtract(const Duration(days: 10)),
      genres: ['Tâm lý', 'Hài'],
      ageRating: 'T18',
      isActive: true,
      description: 'Phim tâm lý tình cảm',
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
      movieId: 'mov_1',
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

class FakeM5TicketProvider extends ChangeNotifier implements TicketProvider {
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
      showtimeStart: DateTime.now().add(const Duration(hours: 4)), // > 2h cutoff
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

class FakeM5SupportChatProvider extends ChangeNotifier implements SupportChatProvider {
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
// MAIN TEST SUITE: ALL 14 SCREENS + NAVIGATION VERIFICATION
// =============================================================================

void main() {
  late MockM5AuthProvider authProvider;
  late FakeM5ManagementRepository repository;
  late ManagementProvider managementProvider;
  late FakeM5TicketProvider ticketProvider;
  late FakeM5SupportChatProvider chatProvider;

  setUp(() {
    authProvider = MockM5AuthProvider();
    repository = FakeM5ManagementRepository();
    managementProvider = ManagementProvider(repository);
    ticketProvider = FakeM5TicketProvider();
    chatProvider = FakeM5SupportChatProvider();
  });

  Widget buildTestApp(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<ManagementProvider>.value(value: managementProvider),
        ChangeNotifierProvider<TicketProvider>.value(value: ticketProvider),
        ChangeNotifierProvider<SupportChatProvider>.value(value: chatProvider),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: child,
        routes: {
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
        },
      ),
    );
  }

  group('Milestone 5 Empirical Verification Test Suite', () {
    testWidgets('1. S10 MyTicketsScreen renders tabs and upcoming ticket card', (tester) async {
      await tester.pumpWidget(buildTestApp(const MyTicketsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('VÉ CỦA TÔI'), findsAtLeastNWidgets(1));
      expect(find.text('SẮP TỚI'), findsOneWidget);
      expect(find.text('ĐÃ XEM'), findsOneWidget);
      expect(find.text('ĐÃ HỦY'), findsOneWidget);
      expect(find.text('Mai'), findsOneWidget);
      expect(find.text('#VND1234'), findsOneWidget);
    });

    testWidgets('2. S10B TicketDetailScreen renders cutoff rule and refund dialog', (tester) async {
      final ticket = ticketProvider.upcomingTickets.first;
      await tester.pumpWidget(buildTestApp(TicketDetailScreen(initialTicket: ticket)));
      await tester.pumpAndSettle();

      expect(find.text('CHI TIẾT VÉ'), findsOneWidget);
      expect(find.text('Mai'), findsOneWidget);
      expect(find.text('HỦY VÉ VÀ HOÀN TIỀN'), findsOneWidget);

      // Scroll to button before tapping to ensure it is in view
      await tester.scrollUntilVisible(find.text('HỦY VÉ VÀ HOÀN TIỀN'), 300);
      await tester.tap(find.text('HỦY VÉ VÀ HOÀN TIỀN'));
      await tester.pumpAndSettle();

      expect(find.text('XÁC NHẬN HỦY VÉ'), findsOneWidget);
      expect(find.text('XÁC NHẬN HỦY'), findsOneWidget);
    });

    testWidgets('3. S12 ManagementMenuScreen renders admin menu items and badges', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp(const ManagementMenuScreen()));
      await tester.pumpAndSettle();

      expect(find.text('QUẢN LÝ HỆ THỐNG'), findsOneWidget);
      expect(find.text('Bàn làm việc / Dashboard (S22)'), findsOneWidget);
      expect(find.text('Quản lý đơn vé & Bookings (S15)'), findsOneWidget);
      expect(find.text('Phim (S13)'), findsOneWidget);
      expect(find.text('Lịch suất chiếu (S14)'), findsOneWidget);
      expect(find.text('Menu bắp nước (S16)'), findsOneWidget);
      expect(find.text('Bảng giá vé (S26)'), findsOneWidget);
      expect(find.text('Rạp & Phòng chiếu (S25)'), findsOneWidget);
      expect(find.text('Mã giảm giá / Voucher (S27)'), findsOneWidget);
      expect(find.text('Quản lý Quản lý rạp (S28)'), findsOneWidget);
      expect(find.text('Nhật ký thao tác / Audit Logs (S29)'), findsOneWidget);
    });

    testWidgets('4. S13 MoviesManagementScreen renders search, tabs, and movie list', (tester) async {
      await tester.pumpWidget(buildTestApp(const MoviesManagementScreen()));
      await tester.pumpAndSettle();

      expect(find.text('QUẢN LÝ DANH MỤC PHIM'), findsOneWidget);
      expect(find.text('TẤT CẢ'), findsOneWidget);
      expect(find.text('ĐANG CHIẾU'), findsAtLeastNWidgets(1));
      expect(find.text('SẮP CHIẾU'), findsOneWidget);
      expect(find.text('Mai'), findsOneWidget);
    });

    testWidgets('5. S14 ShowtimesManagementScreen renders date chips and showtime card', (tester) async {
      await tester.pumpWidget(buildTestApp(const ShowtimesManagementScreen()));
      await tester.pumpAndSettle();

      expect(find.text('LỊCH SUẤT CHIẾU'), findsOneWidget);
      expect(find.text('Mai'), findsOneWidget);
      expect(find.text('HỦY SUẤT'), findsOneWidget);
    });

    testWidgets('6. S15 BookingsManagementScreen renders orders and channel badge', (tester) async {
      await tester.pumpWidget(buildTestApp(const BookingsManagementScreen()));
      await tester.pumpAndSettle();

      expect(find.text('KIỂM TRA ĐƠN VÉ & ĐẶT CHỖ'), findsOneWidget);
      expect(find.text('#BK8888'), findsOneWidget);
      expect(find.text('Mai'), findsOneWidget);
      expect(find.text('ONLINE'), findsAtLeastNWidgets(1));
    });

    testWidgets('7. S16 FoodCatalogScreen renders category filter and food cards', (tester) async {
      await tester.pumpWidget(buildTestApp(const FoodCatalogScreen()));
      await tester.pumpAndSettle();

      expect(find.text('MENU BẮP NƯỚC & ĐỒ ĂN'), findsOneWidget);
      expect(find.text('Combo Bắp Nước 1'), findsOneWidget);
      expect(find.text('CÒN HÀNG'), findsOneWidget);
    });

    testWidgets('8. S22 OperationalDashboardScreen renders 4 KPI metrics and quick shortcuts', (tester) async {
      await tester.pumpWidget(buildTestApp(const OperationalDashboardScreen()));
      await tester.pumpAndSettle();

      expect(find.text('BÀN LÀM VIỆC VẬN HÀNH'), findsOneWidget);
      expect(find.text('DOANH THU THỰC'), findsOneWidget);
      expect(find.text('SỐ VÉ ĐÃ BÁN'), findsOneWidget);
      expect(find.text('TỈ LỆ LẤP ĐẦY'), findsOneWidget);
      expect(find.text('CÔNG SUẤT PHÒNG'), findsOneWidget);
      expect(find.text('LỐI TẮT THAO TÁC NHANH'), findsOneWidget);
    });

    testWidgets('9. S24 SeatMapDesignerScreen renders room grid, tally and cycle brush', (tester) async {
      final room = repository.rooms.first;
      await tester.pumpWidget(buildTestApp(SeatMapDesignerScreen(room: room)));
      await tester.pumpAndSettle();

      expect(find.text('THIẾT KẾ SƠ ĐỒ GHẾ'), findsOneWidget);
      expect(find.text('CHẾ ĐỘ CỌ: '), findsOneWidget);
      expect(find.text('THƯỜNG'), findsOneWidget);
      expect(find.text('VIP'), findsOneWidget);
      expect(find.text('ĐÔI'), findsOneWidget);
      expect(find.text('TỔNG SỐ GHẾ'), findsOneWidget);
      expect(find.text('LƯU SƠ ĐỒ PHÒNG CHIẾU'), findsOneWidget);
    });

    testWidgets('10. S25 CinemasRoomsScreen renders rooms list and design button', (tester) async {
      await tester.pumpWidget(buildTestApp(const CinemasRoomsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('RẠP VÀ PHÒNG CHIẾU'), findsOneWidget);
      expect(find.text('Phòng 1 (IMAX)'), findsOneWidget);
      expect(find.text('THIẾT KẾ SƠ ĐỒ GHẾ'), findsOneWidget);
    });

    testWidgets('11. S26 PricingSettingsScreen renders pricing simulator', (tester) async {
      await tester.pumpWidget(buildTestApp(const PricingSettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('BẢNG GIÁ VÀ PHỤ THU ĐỘNG'), findsOneWidget);
      expect(find.text('MÔ PHỎNG TÍNH GIÁ TRỰC TIẾP (TEST FORMULA)'), findsOneWidget);
      expect(find.text('GIÁ VÉ MÔ PHỎNG:'), findsOneWidget);
    });

    testWidgets('12. S27 VouchersManagementScreen renders voucher cards and details', (tester) async {
      await tester.pumpWidget(buildTestApp(const VouchersManagementScreen()));
      await tester.pumpAndSettle();

      expect(find.text('QUẢN LÝ VOUCHER & KHUYẾN MÃI'), findsOneWidget);
      expect(find.text('VIP50'), findsOneWidget);
      expect(find.text('Giảm 50% cho tiền vé'), findsOneWidget);
    });

    testWidgets('13. S28 ManagersManagementScreen renders manager cards and actions', (tester) async {
      await tester.pumpWidget(buildTestApp(const ManagersManagementScreen()));
      await tester.pumpAndSettle();

      expect(find.text('QUẢN LÝ QUẢN LÝ RẠP'), findsOneWidget);
      expect(find.text('Quản Lý Quận 1'), findsOneWidget);
      expect(find.text('CHUYỂN RẠP'), findsOneWidget);
      expect(find.text('KHÓA'), findsOneWidget);
    });

    testWidgets('14. S29 AuditLogsScreen renders action labels and log items', (tester) async {
      await tester.pumpWidget(buildTestApp(const AuditLogsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('NHẬT KÝ THAO TÁC HỆ THỐNG'), findsOneWidget);
      expect(find.text('HỦY SUẤT'), findsAtLeastNWidgets(1));
      expect(find.text('Thực hiện: Quản Lý Quận 1'), findsOneWidget);
    });

    testWidgets('15. S31 SupportChatScreen renders messages and message input field', (tester) async {
      await tester.pumpWidget(buildTestApp(const SupportChatScreen()));
      await tester.pumpAndSettle();

      expect(find.text('HỖ TRỢ TRỰC TUYẾN'), findsOneWidget);
      expect(find.text('Xin chào rạp, tôi cần hỗ trợ về đơn vé'), findsOneWidget);
      expect(find.text('Dạ rạp nghe ạ, anh/chị cung cấp mã đơn nhé'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('16. ManagerBottomNav renders 3 tabs correctly', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const Scaffold(
            bottomNavigationBar: ManagerBottomNav(
              currentIndex: 0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TỔNG QUAN'), findsOneWidget);
      expect(find.text('QUẢN LÝ'), findsOneWidget);
      expect(find.text('TÀI KHOẢN'), findsOneWidget);
    });
  });
}
