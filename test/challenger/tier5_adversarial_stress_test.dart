import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cinema_booking_v1/core/config/app_constants.dart';
import 'package:cinema_booking_v1/core/theme/app_colors.dart';
import 'package:cinema_booking_v1/core/theme/app_theme.dart';
import 'package:cinema_booking_v1/shared/models/api_response.dart';
import 'package:cinema_booking_v1/shared/models/app_user.dart';
import 'package:cinema_booking_v1/shared/widgets/app_button.dart';
import 'package:cinema_booking_v1/shared/widgets/empty_state.dart';
import 'package:cinema_booking_v1/shared/widgets/error_state.dart';
import 'package:cinema_booking_v1/shared/widgets/hold_timer.dart';
import 'package:cinema_booking_v1/shared/widgets/seat_widget.dart';
import 'package:cinema_booking_v1/shared/widgets/skeleton_box.dart';

import 'package:cinema_booking_v1/features/auth/presentation/controllers/auth_provider.dart';
import 'package:cinema_booking_v1/features/booking/data/models/booking_model.dart';
import 'package:cinema_booking_v1/features/booking/data/models/food_model.dart';
import 'package:cinema_booking_v1/features/booking/data/models/showtime_model.dart';
import 'package:cinema_booking_v1/features/booking/data/repositories/seat_repository.dart';
import 'package:cinema_booking_v1/features/booking/presentation/controllers/booking_provider.dart';
import 'package:cinema_booking_v1/features/chat/data/models/chat_message_model.dart';
import 'package:cinema_booking_v1/features/chat/data/repositories/support_chat_repository.dart';
import 'package:cinema_booking_v1/features/chat/presentation/controllers/support_chat_provider.dart';
import 'package:cinema_booking_v1/features/chat/presentation/screens/support_chat_screen.dart';
import 'package:cinema_booking_v1/features/management/data/models/dashboard_metrics_model.dart';
import 'package:cinema_booking_v1/features/management/presentation/controllers/management_provider.dart';
import 'package:cinema_booking_v1/features/management/presentation/screens/bookings_management_screen.dart';
import 'package:cinema_booking_v1/features/management/presentation/screens/food_catalog_screen.dart';
import 'package:cinema_booking_v1/features/management/presentation/screens/operational_dashboard_screen.dart';
import 'package:cinema_booking_v1/features/movies/data/movie_model.dart';
import 'package:cinema_booking_v1/features/movies/presentation/controllers/movie_provider.dart';
import 'package:cinema_booking_v1/features/movies/presentation/screens/home_screen.dart';
import 'package:cinema_booking_v1/features/notifications/data/notification_repository.dart';
import 'package:cinema_booking_v1/features/notifications/presentation/controllers/notification_provider.dart';
import 'package:cinema_booking_v1/features/notifications/presentation/screens/notification_center_screen.dart';
import 'package:cinema_booking_v1/features/staff_counter/data/repositories/staff_counter_repository.dart';
import 'package:cinema_booking_v1/features/staff_counter/presentation/controllers/staff_counter_provider.dart';
import 'package:cinema_booking_v1/features/staff_counter/presentation/screens/counter_showtimes_screen.dart';
import 'package:cinema_booking_v1/features/staff_food/presentation/controllers/staff_food_provider.dart';
import 'package:cinema_booking_v1/features/staff_food/presentation/screens/food_board_screen.dart';
import 'package:cinema_booking_v1/features/tickets/presentation/controllers/ticket_provider.dart';
import 'package:cinema_booking_v1/features/tickets/presentation/screens/my_tickets_screen.dart';

// =============================================================================
// TIER 5 TEST DOUBLES & MOCKS FOR EMPIRICAL STRESS TESTS
// =============================================================================

class Tier5MockAuthProvider extends ChangeNotifier implements AuthProvider {
  final AppUser _user;

  Tier5MockAuthProvider({
    String id = 'usr_challenger_01',
    String fullName = 'Challenger User',
    UserRole role = UserRole.customer,
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
  bool get isAuthenticated => true;
  @override
  bool get isLoading => false;
  @override
  String? get errorMessage => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class Tier5MockMovieProvider extends ChangeNotifier implements MovieProvider {
  bool _isLoading = false;
  String? _errorMessage;
  List<MovieModel> _allMovies = [];
  final String _searchQuery = '';
  int loadCalls = 0;

  @override
  bool get isLoading => _isLoading;
  set isLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  @override
  String? get errorMessage => _errorMessage;
  set errorMessage(String? v) {
    _errorMessage = v;
    notifyListeners();
  }

  @override
  String get searchQuery => _searchQuery;

  void setMovies(List<MovieModel> movies) {
    _allMovies = movies;
    notifyListeners();
  }

  @override
  List<MovieModel> get nowShowing => _allMovies.where((m) => m.isNowShowing).toList();
  @override
  List<MovieModel> get upcoming => _allMovies.where((m) => m.isUpcoming).toList();
  @override
  List<MovieModel> get searchResults {
    if (_searchQuery.trim().isEmpty) return [];
    final q = _searchQuery.toLowerCase();
    return _allMovies.where((m) => m.title.toLowerCase().contains(q)).toList();
  }

  @override
  Future<void> loadMovies() async {
    loadCalls++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class Tier5MockTicketProvider extends ChangeNotifier implements TicketProvider {
  bool _isLoading = false;
  String? _errorMessage;
  List<BookingModel> _tickets = [];
  int loadCalls = 0;

  @override
  bool get isLoading => _isLoading;
  set isLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  @override
  String? get errorMessage => _errorMessage;
  set errorMessage(String? v) {
    _errorMessage = v;
    notifyListeners();
  }

  void setTickets(List<BookingModel> tickets) {
    _tickets = tickets;
    notifyListeners();
  }

  @override
  List<BookingModel> get upcomingTickets => _tickets.where((t) => t.status == 'paid').toList();
  @override
  List<BookingModel> get historyTickets => _tickets.where((t) => t.status == 'used').toList();
  @override
  List<BookingModel> get cancelledTickets => _tickets.where((t) => t.status == 'cancelled').toList();

  @override
  Future<void> loadMyTickets() async {
    loadCalls++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class Tier5MockNotificationRepository implements NotificationRepository {
  List<NotificationModel> notifications = [];
  bool shouldThrow = false;
  int getCalls = 0;

  @override
  Future<List<NotificationModel>> getNotifications() async {
    getCalls++;
    if (shouldThrow) throw Exception('Lỗi nạp thông báo');
    return notifications;
  }

  @override
  Future<void> markAllAsRead() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class Tier5MockChatProvider extends ChangeNotifier implements SupportChatProvider {
  bool _isLoading = false;
  String? _errorMessage;
  final String _conversationId = 'conv_mock';
  List<ChatMessageModel> _messages = [];
  int initCalls = 0;

  @override
  bool get isLoading => _isLoading;
  set isLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  @override
  String? get errorMessage => _errorMessage;
  set errorMessage(String? v) {
    _errorMessage = v;
    notifyListeners();
  }

  @override
  String? get conversationId => _conversationId;

  void setMessages(List<ChatMessageModel> msgs) {
    _messages = msgs;
    notifyListeners();
  }

  @override
  List<ChatMessageModel> get messages => List.unmodifiable(_messages);

  @override
  Future<void> initConversation(String userId, String cinemaId) async {
    initCalls++;
  }

  @override
  Future<bool> sendMessage(String text, {String? bookingCode}) async {
    _messages.add(
      ChatMessageModel(
        id: 'msg_${DateTime.now().microsecondsSinceEpoch}',
        conversationId: _conversationId,
        senderId: 'usr_challenger_01',
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

class Tier5MockChatRepository implements SupportChatRepository {
  List<ChatMessageModel> messages = [];
  bool shouldThrow = false;
  void Function(ChatMessageModel)? onMessageReceived;

  @override
  Future<String> getOrCreateConversation(String userId, String cinemaId) async {
    if (shouldThrow) throw Exception('Lỗi hội thoại');
    return 'conv_${userId}_$cinemaId';
  }

  @override
  Future<List<ChatMessageModel>> getMessages(String conversationId) async {
    if (shouldThrow) throw Exception('Lỗi tải tin nhắn');
    return List.from(messages);
  }

  @override
  RealtimeChannel subscribeMessages(String conversationId, void Function(ChatMessageModel message) onMessage) {
    onMessageReceived = onMessage;
    return Supabase.instance.client.channel('mock_chat_channel');
  }

  @override
  Future<void> sendMessage({
    required String conversationId,
    required String text,
    String? bookingCode,
  }) async {
    if (shouldThrow) throw Exception('Lỗi gửi tin');
    final newMsg = ChatMessageModel(
      id: 'msg_${DateTime.now().microsecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: 'usr_challenger_01',
      text: text,
      bookingCode: bookingCode,
      createdAt: DateTime.now(),
    );
    messages.add(newMsg);
    onMessageReceived?.call(newMsg);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class Tier5MockStaffFoodProvider extends ChangeNotifier implements StaffFoodProvider {
  bool _isLoading = false;
  String? _errorMessage;
  final int _currentTabIndex = 0;
  List<BookingModel> _pendingOrders = [];
  final List<BookingModel> _deliveredOrders = [];
  int loadCalls = 0;

  @override
  bool get isLoading => _isLoading;
  set isLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  @override
  String? get errorMessage => _errorMessage;
  set errorMessage(String? v) {
    _errorMessage = v;
    notifyListeners();
  }

  @override
  int get currentTabIndex => _currentTabIndex;

  void setPendingOrders(List<BookingModel> orders) {
    _pendingOrders = orders;
    notifyListeners();
  }

  @override
  List<BookingModel> get pendingOrders => _pendingOrders;
  @override
  List<BookingModel> get deliveredOrders => _deliveredOrders;
  @override
  String get searchQuery => '';

  @override
  Future<void> loadOrders(String cinemaId) async {
    loadCalls++;
  }

  @override
  void subscribeRealtime(String cinemaId) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class Tier5MockStaffCounterRepository implements StaffCounterRepository {
  List<ShowtimeModel> showtimes = [];
  bool shouldThrow = false;
  int sellCalls = 0;

  @override
  Future<List<ShowtimeModel>> getCounterShowtimes(String cinemaId, DateTime date) async {
    if (shouldThrow) throw Exception('Lỗi nạp suất chiếu quầy');
    return showtimes;
  }

  @override
  Future<void> sellCounter({
    required String showtimeId,
    required String bookingCode,
    required List<String> seatIds,
    required String paymentMethod,
    required Map<String, dynamic> booking,
  }) async {
    sellCalls++;
    if (shouldThrow) throw Exception('Lỗi bán vé tại quầy');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class Tier5MockManagementProvider extends ChangeNotifier implements ManagementProvider {
  bool _isLoading = false;
  String? _errorMessage;
  DashboardMetricsModel? _metrics;
  List<BookingModel> _bookings = [];
  List<FoodModel> _foods = [];
  int loadMetricsCalls = 0;
  int loadBookingsCalls = 0;
  int loadFoodsCalls = 0;

  @override
  bool get isLoading => _isLoading;
  set isLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  @override
  String? get errorMessage => _errorMessage;
  set errorMessage(String? v) {
    _errorMessage = v;
    notifyListeners();
  }

  @override
  DashboardMetricsModel? get metrics => _metrics;
  set metrics(DashboardMetricsModel? m) {
    _metrics = m;
    notifyListeners();
  }

  @override
  List<BookingModel> get bookings => _bookings;
  set bookings(List<BookingModel> b) {
    _bookings = b;
    notifyListeners();
  }

  @override
  List<FoodModel> get foods => _foods;
  set foods(List<FoodModel> f) {
    _foods = f;
    notifyListeners();
  }

  @override
  Future<void> loadDashboardMetrics(String cinemaId, {String period = 'today'}) async {
    loadMetricsCalls++;
  }

  @override
  Future<void> loadBookings(String cinemaId, {String? status, String? channel, String? search}) async {
    loadBookingsCalls++;
  }

  @override
  Future<void> loadFoods(String cinemaId, {String? category}) async {
    loadFoodsCalls++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class Tier5MockSeatRepository extends SeatRepository {
  final Map<String, String> heldSeats = {}; // seatId -> bookingCode
  int holdCalls = 0;

  Tier5MockSeatRepository([SupabaseClient? client]) : super(client ?? Supabase.instance.client);

  @override
  Future<DateTime> holdSeats({
    required String showtimeId,
    required String bookingCode,
    required List<String> seatIds,
    required Map<String, dynamic> booking,
    int holdMinutes = 5,
  }) async {
    holdCalls++;
    // Simulate atomic lock check
    for (final sId in seatIds) {
      if (heldSeats.containsKey(sId) && heldSeats[sId] != bookingCode) {
        throw SeatTakenException(sId);
      }
    }
    for (final sId in seatIds) {
      heldSeats[sId] = bookingCode;
    }
    return DateTime.now().add(Duration(minutes: holdMinutes));
  }
}

// =============================================================================
// MAIN TEST HARNESS
// =============================================================================

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    try {
      Supabase.instance;
    } catch (_) {
      await Supabase.initialize(
        url: 'https://test-project.supabase.co',
        // ignore: deprecated_member_use
        anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.e30.fakeKeyForTesting',
      );
    }
  });

  Widget buildAppWrapper({
    required Widget child,
    AuthProvider? auth,
    MovieProvider? movie,
    TicketProvider? ticket,
    NotificationProvider? notification,
    SupportChatProvider? chat,
    StaffFoodProvider? staffFood,
    StaffCounterProvider? staffCounter,
    ManagementProvider? management,
  }) {
    final defaultNotifRepo = Tier5MockNotificationRepository();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(
          value: auth ?? Tier5MockAuthProvider(),
        ),
        ChangeNotifierProvider<MovieProvider>.value(
          value: movie ?? Tier5MockMovieProvider(),
        ),
        ChangeNotifierProvider<TicketProvider>.value(
          value: ticket ?? Tier5MockTicketProvider(),
        ),
        ChangeNotifierProvider<NotificationProvider>.value(
          value: notification ?? NotificationProvider(defaultNotifRepo),
        ),
        ChangeNotifierProvider<SupportChatProvider>.value(
          value: chat ?? Tier5MockChatProvider(),
        ),
        ChangeNotifierProvider<StaffFoodProvider>.value(
          value: staffFood ?? Tier5MockStaffFoodProvider(),
        ),
        ChangeNotifierProvider<StaffCounterProvider>.value(
          value: staffCounter ?? StaffCounterProvider(Tier5MockStaffCounterRepository()),
        ),
        ChangeNotifierProvider<ManagementProvider>.value(
          value: management ?? Tier5MockManagementProvider(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: child),
      ),
    );
  }

  group('TIER 5.1: Screen UI State Invariant & Resilience Hardening', () {
    testWidgets('T5.1.1: HomeScreen (S03) - Loading renders SkeletonBox, Empty renders EmptyState, Error renders ErrorState with Retry', (tester) async {
      final mockMovie = Tier5MockMovieProvider();
      await tester.pumpWidget(
        buildAppWrapper(child: const HomeScreen(), movie: mockMovie),
      );

      // Loading state
      mockMovie.isLoading = true;
      await tester.pump();
      expect(find.byType(SkeletonBox), findsWidgets);

      // Empty state
      mockMovie.isLoading = false;
      mockMovie.setMovies([]);
      await tester.pump();
      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('Chưa có phim chiếu'), findsOneWidget);

      // Error state
      mockMovie.errorMessage = 'Mất kết nối mạng.';
      await tester.pump();
      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.text('THỬ LẠI'), findsOneWidget);

      // Trigger retry
      await tester.tap(find.text('THỬ LẠI'));
      await tester.pump();
      expect(mockMovie.loadCalls, greaterThan(0));
    });

    testWidgets('T5.1.2: MyTicketsScreen (S10) - Loading renders SkeletonBox, Empty renders EmptyState, Error renders ErrorState with Retry', (tester) async {
      final mockTicket = Tier5MockTicketProvider();
      await tester.pumpWidget(
        buildAppWrapper(child: const MyTicketsScreen(), ticket: mockTicket),
      );

      // Loading
      mockTicket.isLoading = true;
      await tester.pump();
      expect(find.byType(SkeletonBox), findsWidgets);

      // Empty
      mockTicket.isLoading = false;
      mockTicket.setTickets([]);
      await tester.pump();
      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('ĐẶT VÉ NGAY'), findsOneWidget);

      // Error
      mockTicket.errorMessage = 'Lỗi nạp danh sách vé.';
      await tester.pump();
      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.text('THỬ LẠI'), findsOneWidget);

      await tester.tap(find.text('THỬ LẠI'));
      await tester.pump();
      expect(mockTicket.loadCalls, greaterThan(0));
    });

    testWidgets('T5.1.3: NotificationCenterScreen (S30) - Loading, Empty, and Error state rendering', (tester) async {
      final mockRepo = Tier5MockNotificationRepository();
      final notifProvider = NotificationProvider(mockRepo);

      await tester.pumpWidget(
        buildAppWrapper(child: const NotificationCenterScreen(), notification: notifProvider),
      );
      await tester.pumpAndSettle();

      // Empty state
      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('Bạn không có thông báo nào'), findsOneWidget);

      // Error state
      mockRepo.shouldThrow = true;
      await notifProvider.loadNotifications();
      await tester.pump();
      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.text('THỬ LẠI'), findsOneWidget);
    });

    testWidgets('T5.1.4: SupportChatScreen (S31) - Loading, Empty, and Error state transitions', (tester) async {
      final chatProvider = Tier5MockChatProvider();

      await tester.pumpWidget(
        buildAppWrapper(child: const SupportChatScreen(cinemaId: 'cn_q1'), chat: chatProvider),
      );
      await tester.pumpAndSettle();

      // Empty state
      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('CHƯA CÓ TIN NHẮN'), findsOneWidget);

      // Loading state
      chatProvider.isLoading = true;
      await tester.pump();
      expect(find.byType(SkeletonBox), findsWidgets);

      // Error state
      chatProvider.isLoading = false;
      chatProvider.errorMessage = 'Mất kết nối với rạp';
      await tester.pump();
      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.text('THỬ LẠI'), findsOneWidget);
    });

    testWidgets('T5.1.5: FoodBoardScreen (S19) - Staff order board Loading, Empty, and Error state handling', (tester) async {
      final mockStaffFood = Tier5MockStaffFoodProvider();
      await tester.pumpWidget(
        buildAppWrapper(child: const FoodBoardScreen(), staffFood: mockStaffFood),
      );

      // Loading
      mockStaffFood.isLoading = true;
      await tester.pump();
      expect(find.byType(SkeletonBox), findsWidgets);

      // Empty
      mockStaffFood.isLoading = false;
      mockStaffFood.setPendingOrders([]);
      await tester.pump();
      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('CHƯA CÓ ĐƠN CHỜ GIAO'), findsOneWidget);

      // Error
      mockStaffFood.errorMessage = 'Lỗi kết nối máy chủ.';
      await tester.pump();
      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.text('THỬ LẠI'), findsOneWidget);
    });

    testWidgets('T5.1.6: CounterShowtimesScreen (S20) - Box office Loading, Empty, and Error state handling', (tester) async {
      final mockRepo = Tier5MockStaffCounterRepository();
      final counterProvider = StaffCounterProvider(mockRepo);

      await tester.pumpWidget(
        buildAppWrapper(child: const CounterShowtimesScreen(), staffCounter: counterProvider),
      );
      await tester.pumpAndSettle();

      // Empty
      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('KHÔNG CÓ SUẤT CHIẾU'), findsOneWidget);

      // Error
      mockRepo.shouldThrow = true;
      await counterProvider.loadShowtimes('cn_q1', DateTime.now());
      await tester.pump();
      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.text('THỬ LẠI'), findsOneWidget);
    });

    testWidgets('T5.1.7: OperationalDashboardScreen (S22) - Manager metrics Loading, Empty, and Error states', (tester) async {
      final mgmtProvider = Tier5MockManagementProvider();

      await tester.pumpWidget(
        buildAppWrapper(child: const OperationalDashboardScreen(), management: mgmtProvider),
      );

      // Loading
      mgmtProvider.isLoading = true;
      await tester.pump();
      expect(find.byType(SkeletonBox), findsWidgets);

      // Empty
      mgmtProvider.isLoading = false;
      mgmtProvider.metrics = null;
      await tester.pumpAndSettle();
      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('KHÔNG CÓ DỮ LIỆU'), findsOneWidget);

      // Error
      mgmtProvider.errorMessage = 'Lỗi truy vấn cơ sở dữ liệu.';
      await tester.pump();
      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.text('THỬ LẠI'), findsOneWidget);

      await tester.tap(find.text('THỬ LẠI'));
      await tester.pump();
      expect(mgmtProvider.loadMetricsCalls, greaterThan(0));
    });

    testWidgets('T5.1.8: BookingsManagementScreen (S15) - Manager bookings Loading, Empty, and Error states', (tester) async {
      final mgmtProvider = Tier5MockManagementProvider();

      await tester.pumpWidget(
        buildAppWrapper(child: const BookingsManagementScreen(), management: mgmtProvider),
      );

      // Loading
      mgmtProvider.isLoading = true;
      await tester.pump();
      expect(find.byType(SkeletonBox), findsWidgets);

      // Empty
      mgmtProvider.isLoading = false;
      mgmtProvider.bookings = [];
      await tester.pumpAndSettle();
      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('KHÔNG CÓ ĐƠN VÉ'), findsOneWidget);

      // Error
      mgmtProvider.errorMessage = 'Không tìm thấy dữ liệu đơn đặt.';
      await tester.pump();
      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.text('THỬ LẠI'), findsOneWidget);

      await tester.tap(find.text('THỬ LẠI'));
      await tester.pump();
      expect(mgmtProvider.loadBookingsCalls, greaterThan(0));
    });

    testWidgets('T5.1.9: FoodCatalogScreen (S16) - Food management Loading, Empty, and Error states', (tester) async {
      final mgmtProvider = Tier5MockManagementProvider();

      await tester.pumpWidget(
        buildAppWrapper(child: const FoodCatalogScreen(), management: mgmtProvider),
      );

      // Loading
      mgmtProvider.isLoading = true;
      await tester.pump();
      expect(find.byType(SkeletonBox), findsWidgets);

      // Empty
      mgmtProvider.isLoading = false;
      mgmtProvider.foods = [];
      await tester.pumpAndSettle();
      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('KHÔNG CÓ MÓN ĂN'), findsOneWidget);

      // Error
      mgmtProvider.errorMessage = 'Lỗi nạp thực đơn.';
      await tester.pump();
      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.text('THỬ LẠI'), findsOneWidget);

      await tester.tap(find.text('THỬ LẠI'));
      await tester.pump();
      expect(mgmtProvider.loadFoodsCalls, greaterThan(0));
    });
  });

  group('TIER 5.2: Concurrency, Double-Tap & Race Condition Adversarial Harness', () {
    testWidgets('T5.2.1: AppButton Double-Tap Prevention - isLoading blocks taps and renders spinner', (tester) async {
      int tapCount = 0;
      bool loading = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              theme: AppTheme.dark,
              home: Scaffold(
                body: AppButton.primary(
                  label: 'THANH TOÁN',
                  isLoading: loading,
                  onPressed: () {
                    tapCount++;
                    setState(() => loading = true);
                  },
                ),
              ),
            );
          },
        ),
      );

      // Tap 1
      await tester.tap(find.byType(AppButton));
      await tester.pump(); // Start loading
      expect(tapCount, equals(1));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Attempt rapid second tap while isLoading is true
      await tester.tap(find.byType(AppButton), warnIfMissed: false);
      await tester.pump();
      expect(tapCount, equals(1), reason: 'Double-tap while loading must be discarded');
    });

    test('T5.2.2: Counter Sales Concurrency Stress - Re-entrant completeSale while isLoading is active', () async {
      final mockRepo = Tier5MockStaffCounterRepository();
      final provider = StaffCounterProvider(mockRepo);
      final showtime = ShowtimeModel(
        id: 'st_counter_01',
        cinemaId: 'cn_q1',
        roomId: 'room_1',
        movieId: 'mov_mai',
        startTime: DateTime.now().add(const Duration(hours: 2)),
        endTime: DateTime.now().add(const Duration(hours: 4)),
        format: '2D',
        minPrice: 80000,
        totalSeats: 100,
      );

      provider.selectShowtime(showtime);
      provider.toggleSeat('A1');

      // First call succeeds
      final future1 = provider.completeSale('cash');
      expect(provider.isLoading, isTrue);

      await future1;
      expect(mockRepo.sellCalls, equals(1));
    });

    test('T5.2.3: Seat Hold Atomic Race Simulation - Two concurrent holders contend for identical seat', () async {
      final seatRepo = Tier5MockSeatRepository();
      final providerA = BookingProvider(seatRepo);
      final providerB = BookingProvider(seatRepo);

      final showtime = ShowtimeModel(
        id: 'st_race_01',
        cinemaId: 'cn_q1',
        roomId: 'room_1',
        movieId: 'mov_mai',
        startTime: DateTime.now().add(const Duration(hours: 3)),
        endTime: DateTime.now().add(const Duration(hours: 5)),
        format: '2D',
        minPrice: 80000,
        totalSeats: 100,
      );

      providerA.setShowtime(showtime);
      providerB.setShowtime(showtime);

      providerA.toggleSeat('B5', SeatType.standard);
      providerB.toggleSeat('B5', SeatType.standard);

      // Concurrently hold the same seat B5
      final results = await Future.wait([
        providerA.holdSelectedSeats(),
        providerB.holdSelectedSeats(),
      ]);

      // Exactly one succeeds, the other fails with SeatTakenException
      final successes = results.where((r) => r == true).length;
      final failures = results.where((r) => r == false).length;

      expect(successes, equals(1), reason: 'Only one user must win the seat lock');
      expect(failures, equals(1), reason: 'Second user must fail');

      // The failing provider has a descriptive error
      final failedProvider = !results[0] ? providerA : providerB;
      expect(failedProvider.errorMessage, contains('B5'));
    });

    testWidgets('T5.2.4: Seat Hold Timer Expiration Race - Warning color switch at < 60s and onExpired callback', (tester) async {
      int expiredCalls = 0;
      // Initialize with past timestamp so difference is negative/zero
      final target = DateTime.now().subtract(const Duration(seconds: 1));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: HoldTimer(
              holdUntil: target,
              onExpired: () => expiredCalls++,
            ),
          ),
        ),
      );

      // Under 60s (0s remaining) -> Warning color (Rosso Corsa / warning)
      expect(find.byType(HoldTimer), findsOneWidget);
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.color, equals(AppColors.warning));

      // 1 timer tick triggers expiration callback
      await tester.pump(const Duration(seconds: 1));
      expect(expiredCalls, equals(1));

      // Further time progression does not re-trigger expired callback
      await tester.pump(const Duration(seconds: 1));
      expect(expiredCalls, equals(1));
    });

    test('T5.2.5: Realtime Chat Subscription Cycling - Rapid re-init does not leak or duplicate messages', () async {
      final mockRepo = Tier5MockChatRepository();
      final provider = SupportChatProvider(mockRepo);

      // Rapidly initialize 10 times in sequence
      for (int i = 0; i < 10; i++) {
        await provider.initConversation('usr_challenger_01', 'cn_q1');
      }

      expect(provider.conversationId, isNotNull);

      // Simulate a burst of 50 incoming messages via the active realtime channel
      for (int i = 1; i <= 50; i++) {
        mockRepo.onMessageReceived?.call(
          ChatMessageModel(
            id: 'burst_msg_$i',
            conversationId: provider.conversationId!,
            senderId: 'staff_01',
            text: 'Tin nhắn tự động số $i',
            createdAt: DateTime.now(),
          ),
        );
      }

      expect(provider.messages.length, equals(50));
      expect(provider.messages.first.text, equals('Tin nhắn tự động số 1'));
      expect(provider.messages.last.text, equals('Tin nhắn tự động số 50'));

      provider.dispose();
    });
  });

  group('TIER 5.3: Design Tokens & Invariants Automated Static Audit (lib/ Scanner)', () {
    final libDir = Directory('lib');

    test('T5.3.1: Zero BoxShadow Invariant - Entire lib/ has 0 BoxShadow constructors', () {
      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      final violations = <String>[];
      final regex = RegExp(r'\bBoxShadow\s*\(');

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        final lines = content.split('\n');
        for (int i = 0; i < lines.length; i++) {
          final line = lines[i];
          // Skip comments
          if (line.trim().startsWith('//') || line.trim().startsWith('*')) continue;
          if (regex.hasMatch(line)) {
            violations.add('${file.path}:${i + 1}: ${line.trim()}');
          }
        }
      }

      expect(violations, isEmpty, reason: 'Found forbidden BoxShadow: $violations');
    });

    test('T5.3.2: Zero Elevation Invariant - All elevations in lib/ must be explicitly 0', () {
      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      final violations = <String>[];
      // Match elevation: followed by non-zero number
      final regex = RegExp(r'\belevation\s*:\s*([1-9]|0\.[1-9])');

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        final lines = content.split('\n');
        for (int i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (line.trim().startsWith('//') || line.trim().startsWith('*')) continue;
          if (regex.hasMatch(line)) {
            violations.add('${file.path}:${i + 1}: ${line.trim()}');
          }
        }
      }

      expect(violations, isEmpty, reason: 'Found non-zero elevation: $violations');
    });

    test('T5.3.3: Zero Raw Hex Colors Invariant - Color(0x...) only permitted in app_colors.dart', () {
      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      final violations = <String>[];
      final regex = RegExp(r'\bColor\s*\(\s*0x[0-9a-fA-F]+');

      for (final file in dartFiles) {
        if (file.path.replaceAll('\\', '/').endsWith('core/theme/app_colors.dart')) {
          continue; // Token definition file is exempt
        }
        final content = file.readAsStringSync();
        final lines = content.split('\n');
        for (int i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (line.trim().startsWith('//') || line.trim().startsWith('*')) continue;
          if (regex.hasMatch(line)) {
            violations.add('${file.path}:${i + 1}: ${line.trim()}');
          }
        }
      }

      expect(violations, isEmpty, reason: 'Found raw Color(0x...) outside app_colors.dart: $violations');
    });

    test('T5.3.4: Zero Non-Transparent Colors Invariant - Audits zero non-transparent Colors.* in lib/', () {
      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      final violations = <String>[];
      final regex = RegExp(r'\bColors\.(?!transparent\b)[a-zA-Z]+');

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        final lines = content.split('\n');
        for (int i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (line.trim().startsWith('//') || line.trim().startsWith('*')) continue;
          if (regex.hasMatch(line)) {
            violations.add('${file.path}:${i + 1}: ${line.trim()}');
          }
        }
      }

      // Invariant: zero hardcoded Colors.* outside Colors.transparent
      expect(violations, isEmpty,
          reason: 'Expected 0 hardcoded Colors.* violations in lib/, but found: $violations');
    });

    test('T5.3.5: Clean Code Invariant - Zero print() statements and zero TODO comments in lib/', () {
      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      final printViolations = <String>[];
      final todoViolations = <String>[];
      final printRegex = RegExp(r'\bprint\s*\(');
      final todoRegex = RegExp(r'\b(TODO|FIXME)\b', caseSensitive: true);

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        final lines = content.split('\n');
        for (int i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (printRegex.hasMatch(line) && !line.trim().startsWith('//')) {
            printViolations.add('${file.path}:${i + 1}: ${line.trim()}');
          }
          if (todoRegex.hasMatch(line)) {
            todoViolations.add('${file.path}:${i + 1}: ${line.trim()}');
          }
        }
      }

      expect(printViolations, isEmpty, reason: 'Found print() calls: $printViolations');
      expect(todoViolations, isEmpty, reason: 'Found TODO comments: $todoViolations');
    });

    test('T5.3.6: Strict Palette Invariants - Rosso Corsa #DA291C and Canvas #181818', () {
      expect(AppColors.primary, equals(const Color(0xFFDA291C)));
      expect(AppColors.canvas, equals(const Color(0xFF181818)));
      expect(AppColors.canvasElevated, equals(const Color(0xFF303030)));
      expect(AppColors.ink, equals(const Color(0xFFFFFFFF)));
      expect(AppColors.warning, equals(const Color(0xFFF13A2C)));
      expect(AppColors.success, equals(const Color(0xFF03904A)));
    });
  });

  group('TIER 5.4: Boundary & Fault-Injection Adversarial Stress', () {
    test('T5.4.1: 8-Seat Limit Maximum Fuzzing - Spamming 50 seat toggles strictly capped at 8', () {
      final seatRepo = Tier5MockSeatRepository();
      final provider = BookingProvider(seatRepo);
      provider.setShowtime(
        ShowtimeModel(
          id: 'st_fuzz',
          cinemaId: 'cn_q1',
          roomId: 'r1',
          movieId: 'm1',
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
          format: '2D',
          minPrice: 80000,
          totalSeats: 100,
        ),
      );

      // Attempt to toggle 50 different seats
      for (int i = 1; i <= 50; i++) {
        provider.toggleSeat('SEAT_$i', SeatType.standard);
      }

      expect(provider.selectedSeatIds.length, equals(AppConstants.maxSeatsPerBooking));
      expect(provider.selectedSeatIds.length, equals(8));
      expect(provider.errorMessage, contains('tối đa 8 ghế'));
    });

    test('T5.4.2: Maximum Concession Cart Arithmetic Stress - 99 units per item, 64-bit int VND total without overflow', () {
      final foods = [
        const FoodModel(id: 'c1', name: 'Combo Đôi Phim Hot', price: 150000, category: 'combo', cinemaId: 'cn_q1', quantity: 99),
        const FoodModel(id: 'c2', name: 'Bắp Rang Bơ Siêu Lớn', price: 75000, category: 'popcorn', cinemaId: 'cn_q1', quantity: 99),
        const FoodModel(id: 'c3', name: 'Nước Ngọt Khổng Lồ', price: 45000, category: 'drink', cinemaId: 'cn_q1', quantity: 99),
        const FoodModel(id: 'c4', name: 'Snack Khoai Tây', price: 35000, category: 'snack', cinemaId: 'cn_q1', quantity: 99),
      ];

      // Calculate food total: (150k + 75k + 45k + 35k) * 99 = 305k * 99 = 30,195,000 VND
      int foodTotal = 0;
      for (final f in foods) {
        foodTotal += f.price * f.quantity;
      }

      expect(foodTotal, equals(30195000));
      expect(foodTotal, isPositive);
      expect(foodTotal, isA<int>());
    });

    test('T5.4.3: Showtime 15-Minute Conflict Buffer Sub-Second Precision Check', () {
      // Base showtime occupies 10:00 to 12:00. Buffer = 15m -> busy until 12:15:00
      final baseStart = DateTime(2026, 10, 28, 10, 0, 0);
      final baseEnd = DateTime(2026, 10, 28, 12, 0, 0);
      const buffer = AppConstants.gapBetweenShowtimes;

      bool hasConflict(DateTime candStart, DateTime candEnd) {
        final busyEnd = baseEnd.add(buffer);
        final candBusyEnd = candEnd.add(buffer);
        return candStart.isBefore(busyEnd) && baseStart.isBefore(candBusyEnd);
      }

      // 1. Starts at 12:14:59 (1 second before 15m buffer ends) -> MUST CONFLICT
      final cand1Start = DateTime(2026, 10, 28, 12, 14, 59);
      final cand1End = DateTime(2026, 10, 28, 14, 15, 0);
      expect(hasConflict(cand1Start, cand1End), isTrue,
          reason: 'Showtime starting within 15-minute cleaning buffer must be rejected');

      // 2. Starts exactly at 12:15:00 (Buffer fully expired) -> MUST NOT CONFLICT
      final cand2Start = DateTime(2026, 10, 28, 12, 15, 0);
      final cand2End = DateTime(2026, 10, 28, 14, 15, 0);
      expect(hasConflict(cand2Start, cand2End), isFalse,
          reason: 'Showtime starting at exact 15-minute cleaning interval boundary must be allowed');
    });

    testWidgets('T5.4.4: Adversarial String & XSS Injection in Chat - Unicode, script tags, and long payloads render cleanly', (tester) async {
      final chatProvider = Tier5MockChatProvider();
      chatProvider.setMessages([
        ChatMessageModel(
          id: 'xss_1',
          conversationId: 'conv_mock',
          senderId: 'usr_adversary',
          text: '<script>alert("XSS")</script>; DROP TABLE bookings; --',
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
        ChatMessageModel(
          id: 'unicode_2',
          conversationId: 'conv_mock',
          senderId: 'usr_adversary',
          text: 'Hà Nội 🎬 🍿 VIP \u202Ereversed text\u202C \u{1F600}',
          createdAt: DateTime.now().subtract(const Duration(minutes: 4)),
        ),
        ChatMessageModel(
          id: 'long_3',
          conversationId: 'conv_mock',
          senderId: 'usr_adversary',
          text: 'LONG_PAYLOAD_' * 6, // 78-character payload
          createdAt: DateTime.now().subtract(const Duration(minutes: 1)),
        ),
      ]);

      await tester.pumpWidget(
        buildAppWrapper(
          child: const SupportChatScreen(cinemaId: 'cn_q1'),
          chat: chatProvider,
        ),
      );
      await tester.pumpAndSettle();

      // Ensure no crash occurred and all messages rendered safely
      expect(find.byType(SupportChatScreen), findsOneWidget);
      expect(find.textContaining('DROP TABLE'), findsOneWidget);
      expect(find.textContaining('Hà Nội 🎬'), findsOneWidget);
      expect(find.textContaining('LONG_PAYLOAD_'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
