import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cinema_booking_v1/core/routes/app_router.dart';
import 'package:cinema_booking_v1/core/theme/app_colors.dart';
import 'package:cinema_booking_v1/core/theme/app_theme.dart';
import 'package:cinema_booking_v1/core/utils/currency_formatter.dart';
import 'package:cinema_booking_v1/features/auth/presentation/controllers/auth_provider.dart';
import 'package:cinema_booking_v1/features/booking/data/models/booking_model.dart';
import 'package:cinema_booking_v1/features/booking/data/models/showtime_model.dart';
import 'package:cinema_booking_v1/features/management/data/repositories/management_repository.dart';
import 'package:cinema_booking_v1/features/management/presentation/controllers/management_provider.dart';
import 'package:cinema_booking_v1/features/management/presentation/screens/staff_accounts_screen.dart';
import 'package:cinema_booking_v1/features/staff_checkin/data/checkin_repository.dart';
import 'package:cinema_booking_v1/features/staff_checkin/presentation/controllers/checkin_provider.dart';
import 'package:cinema_booking_v1/features/staff_checkin/presentation/screens/ticket_checkin_screen.dart';
import 'package:cinema_booking_v1/features/staff_counter/data/repositories/staff_counter_repository.dart';
import 'package:cinema_booking_v1/features/staff_counter/presentation/controllers/staff_counter_provider.dart';
import 'package:cinema_booking_v1/features/staff_counter/presentation/screens/counter_payment_screen.dart';
import 'package:cinema_booking_v1/features/staff_counter/presentation/screens/counter_showtimes_screen.dart';
import 'package:cinema_booking_v1/features/staff_food/data/staff_food_repository.dart';
import 'package:cinema_booking_v1/features/staff_food/presentation/controllers/staff_food_provider.dart';
import 'package:cinema_booking_v1/features/staff_food/presentation/screens/food_board_screen.dart';
import 'package:cinema_booking_v1/shared/models/app_user.dart';
import 'package:cinema_booking_v1/shared/widgets/app_button.dart';
import 'package:cinema_booking_v1/shared/widgets/hold_timer.dart';
import 'package:cinema_booking_v1/shared/widgets/staff_bottom_nav.dart';
import 'package:cinema_booking_v1/shared/widgets/ticket_card.dart';

// =============================================================================
// TEST HARNESS & DOUBLES FOR EMPIRICAL CHALLENGER M4_2
// =============================================================================

class MockChallengerStaffAuthProvider extends ChangeNotifier implements AuthProvider {
  AppUser? _user = const AppUser(
    id: 'staff_challenger_01',
    fullName: 'Lê Văn Thử Nghiệm',
    email: 'staff.test@cinema.vn',
    phone: '0909888777',
    role: UserRole.staff,
    cinemaId: 'cn_q1',
    isLocked: false,
  );

  void setRole(UserRole role) {
    if (_user != null) {
      _user = AppUser(
        id: _user!.id,
        fullName: _user!.fullName,
        email: _user!.email,
        phone: _user!.phone,
        role: role,
        cinemaId: _user!.cinemaId,
        isLocked: _user!.isLocked,
      );
      notifyListeners();
    }
  }

  @override
  AppUser? get currentUser => _user;

  @override
  bool get isAuthenticated => _user != null;

  @override
  bool get isLoading => false;

  @override
  AuthStatus get status => AuthStatus.authenticated;

  @override
  String? get errorMessage => null;

  @override
  void clearError() {}

  @override
  Future<bool> signIn(String email, String password) async => true;

  @override
  Future<void> signOut() async {
    _user = null;
    notifyListeners();
  }

  @override
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async =>
      true;

  @override
  Future<bool> updateProfile({required String fullName, String? phone}) async => true;
}

class MockChallengerCheckinRepository implements CheckinRepository {
  CheckinResult? nextResult;

  @override
  Future<CheckinResult> checkIn(String bookingCode) async {
    if (nextResult != null) return nextResult!;

    if (bookingCode == 'VALID001') {
      return const CheckinResult(
        isSuccess: true,
        message: 'Soát vé thành công',
        code: 'VALID001',
        movieTitle: 'Dune: Hành Tinh Cát 2',
        roomName: 'Phòng 1',
        showtimeStart: '19:00',
        seatsSummary: 'A1, A2',
        foodsSummary: '1x Bắp Ngọt, 1x Coca-Cola',
        ageRating: 'P',
      );
    } else if (bookingCode == 'AGE18XYZ') {
      return const CheckinResult(
        isSuccess: true,
        message: 'Soát vé thành công',
        code: 'AGE18XYZ',
        movieTitle: 'Deadpool & Wolverine',
        roomName: 'Phòng IMAX',
        showtimeStart: '20:30',
        seatsSummary: 'C5, C6',
        foodsSummary: '',
        ageRating: 'T18',
      );
    } else {
      return const CheckinResult(
        isSuccess: false,
        errorCode: 'NOT_FOUND',
        message: 'Mã vé không tồn tại trong hệ thống',
      );
    }
  }
}

class MockChallengerStaffFoodRepository implements StaffFoodRepository {
  List<BookingModel> mockPending = [];
  List<BookingModel> mockDelivered = [];
  String? lastDeliveredCode;

  @override
  Future<List<BookingModel>> getPendingOrders(String cinemaId) async {
    return List.from(mockPending);
  }

  @override
  Future<List<BookingModel>> getDeliveredOrders(String cinemaId) async {
    return List.from(mockDelivered);
  }

  @override
  Future<void> deliverFood(String bookingCode) async {
    lastDeliveredCode = bookingCode;
    final idx = mockPending.indexWhere((b) => b.code == bookingCode);
    if (idx != -1) {
      final order = mockPending.removeAt(idx);
      mockDelivered.insert(0, order);
    }
  }
}

class MockChallengerStaffCounterRepository implements StaffCounterRepository {
  List<ShowtimeModel> mockShowtimes = [];
  bool holdSuccess = true;
  bool sellSuccess = true;
  String? lastPaymentMethod;

  @override
  Future<List<ShowtimeModel>> getCounterShowtimes(String cinemaId, DateTime date) async {
    return List.from(mockShowtimes);
  }

  @override
  Future<DateTime> holdCounterSeats({
    required String showtimeId,
    required String bookingCode,
    required List<String> seatIds,
    required Map<String, dynamic> booking,
  }) async {
    if (!holdSuccess) throw Exception('Ghế đang có người giữ');
    return DateTime.now().add(const Duration(minutes: 3));
  }

  @override
  Future<void> sellCounter({
    required String showtimeId,
    required String bookingCode,
    required List<String> seatIds,
    required String paymentMethod,
    required Map<String, dynamic> booking,
  }) async {
    if (!sellSuccess) throw Exception('Lỗi thanh toán');
    lastPaymentMethod = paymentMethod;
  }

  @override
  Future<List<Map<String, dynamic>>> getShowtimeSeats(String showtimeId) async => [];

  @override
  Future<List<Map<String, dynamic>>> getAvailableFoods(String cinemaId) async => [];

  @override
  Future<List<String>> getRoomLayout(String roomId) async => [];
}

class MockChallengerManagementRepository extends ManagementRepository {
  List<AppUser> mockEmployees = [];
  Map<String, dynamic>? lastCreatedStaff;
  Map<String, dynamic>? lastToggledUser;

  MockChallengerManagementRepository() : super(null);

  @override
  Future<List<AppUser>> getEmployees(String cinemaId) async {
    return List.from(mockEmployees);
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
    lastCreatedStaff = {
      'email': email,
      'password': password,
      'fullName': fullName,
      'phone': phone,
      'role': role,
      'cinemaId': cinemaId,
    };
    return {'success': true, 'email': email};
  }

  @override
  Future<void> toggleUserLock(String userId, bool isLocked) async {
    lastToggledUser = {'userId': userId, 'isLocked': isLocked};
    final index = mockEmployees.indexWhere((u) => u.id == userId);
    if (index != -1) {
      mockEmployees[index] = mockEmployees[index].copyWith(isLocked: isLocked);
    }
  }
}

class TestNavigatorObserver extends NavigatorObserver {
  final List<String> replacedRoutes = [];
  final List<String> pushedRoutes = [];

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute?.settings.name != null) {
      replacedRoutes.add(newRoute!.settings.name!);
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route.settings.name != null) {
      pushedRoutes.add(route.settings.name!);
    }
  }
}

void setTestScreenSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget createM4TestHarness({
  required Widget child,
  AuthProvider? authProvider,
  CheckinProvider? checkinProvider,
  StaffFoodProvider? foodProvider,
  StaffCounterProvider? counterProvider,
  ManagementProvider? managementProvider,
  NavigatorObserver? navigatorObserver,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(
        value: authProvider ?? MockChallengerStaffAuthProvider(),
      ),
      ChangeNotifierProvider<CheckinProvider>.value(
        value: checkinProvider ?? CheckinProvider(MockChallengerCheckinRepository()),
      ),
      ChangeNotifierProvider<StaffFoodProvider>.value(
        value: foodProvider ?? StaffFoodProvider(MockChallengerStaffFoodRepository()),
      ),
      ChangeNotifierProvider<StaffCounterProvider>.value(
        value: counterProvider ?? StaffCounterProvider(MockChallengerStaffCounterRepository()),
      ),
      ChangeNotifierProvider<ManagementProvider>.value(
        value: managementProvider ?? ManagementProvider(MockChallengerManagementRepository()),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      navigatorObservers: navigatorObserver != null ? [navigatorObserver] : const [],
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.staffCheckin) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const TicketCheckinScreen(forceDesktopFallback: true),
          );
        }
        if (settings.name == AppRoutes.staffFood) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const FoodBoardScreen(),
          );
        }
        if (settings.name == AppRoutes.staffCounterShowtimes) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const CounterShowtimesScreen(),
          );
        }
        if (settings.name == AppRoutes.staffCounterPayment) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const CounterPaymentScreen(),
          );
        }
        if (settings.name == AppRoutes.manageEmployees) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const StaffAccountsScreen(),
          );
        }
        if (settings.name == AppRoutes.profile) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const Scaffold(body: Text('PROFILE_SCREEN_MOCK')),
          );
        }
        if (settings.name == AppRoutes.notifications) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const Scaffold(body: Text('NOTIFICATIONS_SCREEN_MOCK')),
          );
        }
        return AppRouter.onGenerateRoute(settings);
      },
      home: child,
    ),
  );
}

// =============================================================================
// ASSERTION HELPERS FOR STRICT COMPLIANCE
// =============================================================================

void verifyAllButtonLabelsUppercase(WidgetTester tester) {
  // 1. Check AppButton labels
  final appButtons = tester.widgetList<AppButton>(find.byType(AppButton));
  for (final btn in appButtons) {
    expect(btn.label, equals(btn.label.toUpperCase()),
        reason: 'AppButton label "${btn.label}" must be strictly UPPERCASE');
  }

  // 2. Check ElevatedButton child Text widgets
  final elevatedButtons = find.byType(ElevatedButton);
  for (final eb in tester.widgetList<ElevatedButton>(elevatedButtons)) {
    final textWidgets = tester.widgetList<Text>(
      find.descendant(of: find.byWidget(eb), matching: find.byType(Text)),
    );
    for (final tw in textWidgets) {
      if (tw.data != null && tw.data!.isNotEmpty) {
        expect(tw.data, equals(tw.data!.toUpperCase()),
            reason: 'ElevatedButton child text "${tw.data}" must be strictly UPPERCASE');
      }
    }
  }

  // 3. Check OutlinedButton child Text widgets
  final outlinedButtons = find.byType(OutlinedButton);
  for (final ob in tester.widgetList<OutlinedButton>(outlinedButtons)) {
    final textWidgets = tester.widgetList<Text>(
      find.descendant(of: find.byWidget(ob), matching: find.byType(Text)),
    );
    for (final tw in textWidgets) {
      if (tw.data != null && tw.data!.isNotEmpty) {
        expect(tw.data, equals(tw.data!.toUpperCase()),
            reason: 'OutlinedButton child text "${tw.data}" must be strictly UPPERCASE');
      }
    }
  }

  // 4. Check TextButton child Text widgets
  final textButtons = find.byType(TextButton);
  for (final tb in tester.widgetList<TextButton>(textButtons)) {
    final textWidgets = tester.widgetList<Text>(
      find.descendant(of: find.byWidget(tb), matching: find.byType(Text)),
    );
    for (final tw in textWidgets) {
      if (tw.data != null && tw.data!.isNotEmpty) {
        expect(tw.data, equals(tw.data!.toUpperCase()),
            reason: 'TextButton child text "${tw.data}" must be strictly UPPERCASE');
      }
    }
  }
}

void verifyMaxOnePrimaryButton(WidgetTester tester, {Finder? scope}) {
  final Finder finder = scope != null
      ? find.descendant(of: scope, matching: find.byType(ElevatedButton))
      : find.byType(ElevatedButton);
  final count = tester.widgetList(finder).length;
  expect(count, lessThanOrEqualTo(1),
      reason: 'DESIGN_TOKENS.md rule violation: At most 1 primary button on a screen or modal. Found $count');
}

void verifyZeroElevationAndZeroBoxShadow(WidgetTester tester) {
  // 1. Verify AppBars have 0 elevation
  final appBars = tester.widgetList<AppBar>(find.byType(AppBar));
  for (final ab in appBars) {
    expect(ab.elevation ?? 0, equals(0),
        reason: 'AppBar elevation must be 0');
    expect(ab.scrolledUnderElevation ?? 0, equals(0),
        reason: 'AppBar scrolledUnderElevation must be 0');
  }

  // 2. Verify ElevatedButtons have 0 elevation
  final elevatedButtons = tester.widgetList<ElevatedButton>(find.byType(ElevatedButton));
  for (final eb in elevatedButtons) {
    final elev = eb.style?.elevation?.resolve({});
    expect(elev ?? 0, equals(0),
        reason: 'ElevatedButton elevation must be 0');
  }

  // 3. Verify OutlinedButtons have 0 elevation
  final outlinedButtons = tester.widgetList<OutlinedButton>(find.byType(OutlinedButton));
  for (final ob in outlinedButtons) {
    final elev = ob.style?.elevation?.resolve({});
    expect(elev ?? 0, equals(0),
        reason: 'OutlinedButton elevation must be 0');
  }

  // 4. Verify FloatingActionButtons have 0 elevation
  final fabs = tester.widgetList<FloatingActionButton>(find.byType(FloatingActionButton));
  for (final fab in fabs) {
    expect(fab.elevation ?? 0, equals(0),
        reason: 'FloatingActionButton elevation must be 0');
  }

  // 5. Verify all DecoratedBox widgets have zero BoxShadow
  final decoratedBoxes = tester.widgetList<DecoratedBox>(find.byType(DecoratedBox));
  for (final db in decoratedBoxes) {
    if (db.decoration is BoxDecoration) {
      final boxDec = db.decoration as BoxDecoration;
      expect(boxDec.boxShadow == null || boxDec.boxShadow!.isEmpty, isTrue,
          reason: 'DecoratedBox BoxDecoration must have zero BoxShadow');
    }
  }

  // 6. Verify all Container widgets with BoxDecoration have zero BoxShadow
  final containers = tester.widgetList<Container>(find.byType(Container));
  for (final c in containers) {
    if (c.decoration is BoxDecoration) {
      final boxDec = c.decoration as BoxDecoration;
      expect(boxDec.boxShadow == null || boxDec.boxShadow!.isEmpty, isTrue,
          reason: 'Container BoxDecoration must have zero BoxShadow');
    }
  }
}

BookingModel createChallengerBooking({
  required String code,
  required String movieTitle,
  required String roomName,
  required DateTime showtimeStart,
  required List<Map<String, dynamic>> foods,
  String foodStatus = 'pending',
}) {
  return BookingModel(
    code: code,
    cinemaId: 'cn_q1',
    cinemaName: 'Cinema Quận 1',
    movieTitle: movieTitle,
    roomName: roomName,
    format: '2D',
    showtimeId: 'st_1',
    showtimeStart: showtimeStart,
    status: 'paid',
    foodStatus: foodStatus,
    seats: const [
      {'id': 'A1', 'type': 'standard', 'price': 80000}
    ],
    foods: foods,
    priceSnapshot: const {'total': 150000},
    createdAt: DateTime.now(),
  );
}

ShowtimeModel createChallengerShowtime({
  required String id,
  required String movieTitle,
  required String roomName,
  required DateTime startTime,
  required DateTime endTime,
  String format = '2D',
  int totalSeats = 64,
  int soldSeats = 10,
  int minPrice = 80000,
}) {
  return ShowtimeModel(
    id: id,
    movieId: 'mov_1',
    cinemaId: 'cn_q1',
    roomId: 'room_1',
    format: format,
    startTime: startTime,
    endTime: endTime,
    status: 'active',
    totalSeats: totalSeats,
    soldSeats: soldSeats,
    minPrice: minPrice,
    movieTitle: movieTitle,
    roomName: roomName,
    cinemaName: 'Cinema Quận 1',
  );
}

// =============================================================================
// MAIN EMPIRICAL VERIFICATION TEST SUITE
// =============================================================================

void main() {
  // ===========================================================================
  // REQUIREMENT 1: WIDGET RENDERING (S18, S19, S20, S21, S23, StaffBottomNav)
  // ===========================================================================
  group('Requirement 1: Widget Rendering of Milestone 4 Screens', () {
    testWidgets('1.1 S18: TicketCheckinScreen renders title, cinema, desktop scanner fallback, and StaffBottomNav',
        (tester) async {
      setTestScreenSize(tester);

      await tester.pumpWidget(createM4TestHarness(
        child: const TicketCheckinScreen(forceDesktopFallback: true),
      ));
      await tester.pumpAndSettle();

      expect(find.text('SOÁT VÉ VÀO RẠP'), findsOneWidget);
      expect(find.text('CN_Q1'), findsOneWidget);
      expect(find.text('CAMERA KHÔNG KHẢ DỤNG TRÊN THIẾT BỊ NÀY'), findsOneWidget);
      expect(find.byKey(const Key('ticket_checkin_manual_input_btn')), findsOneWidget);
      expect(find.byType(StaffBottomNav), findsOneWidget);
    });

    testWidgets('1.2 S18: Manual input modal and ResultSheet render ticket details and age check',
        (tester) async {
      setTestScreenSize(tester);
      final checkinRepo = MockChallengerCheckinRepository();
      final checkinProvider = CheckinProvider(checkinRepo);

      await tester.pumpWidget(createM4TestHarness(
        checkinProvider: checkinProvider,
        child: const TicketCheckinScreen(forceDesktopFallback: true),
      ));
      await tester.pumpAndSettle();

      // Open manual input modal
      await tester.tap(find.byKey(const Key('ticket_checkin_manual_input_btn')));
      await tester.pumpAndSettle();

      expect(find.text('NHẬP MÃ VÉ THỦ CÔNG'), findsOneWidget);
      expect(find.byKey(const Key('manual_code_input')), findsOneWidget);
      expect(find.byKey(const Key('manual_code_submit')), findsOneWidget);

      // Submit T18 code
      await tester.enterText(find.byKey(const Key('manual_code_input')), 'AGE18XYZ');
      await tester.tap(find.byKey(const Key('manual_code_submit')));
      await tester.pumpAndSettle();

      // Result sheet renders
      expect(find.text('VÉ HỢP LỆ'), findsOneWidget);
      expect(find.text('Deadpool & Wolverine'), findsOneWidget);
      expect(find.text('Khán giả phim T18. Đã kiểm tra giấy tờ tùy thân hợp lệ.'), findsOneWidget);
      expect(find.text('XÁC NHẬN CHO VÀO'), findsOneWidget);
    });

    testWidgets('1.3 S19: FoodBoardScreen renders header, search field, tabs, empty state, and StaffBottomNav',
        (tester) async {
      setTestScreenSize(tester);
      final foodRepo = MockChallengerStaffFoodRepository();
      final foodProvider = StaffFoodProvider(foodRepo);

      await tester.pumpWidget(createM4TestHarness(
        foodProvider: foodProvider,
        child: const FoodBoardScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('QUẦY ĐỒ ĂN'), findsOneWidget);
      expect(find.text('CN_Q1'), findsOneWidget);
      expect(find.byKey(const Key('food_search_field')), findsOneWidget);
      expect(find.byKey(const Key('food_tab_pending')), findsOneWidget);
      expect(find.byKey(const Key('food_tab_delivered')), findsOneWidget);
      expect(find.text('CHƯA CÓ ĐƠN CHỜ GIAO'), findsOneWidget);
      expect(find.byType(StaffBottomNav), findsOneWidget);
    });

    testWidgets('1.4 S19: FoodBoardScreen renders order card and delivery confirmation dialog',
        (tester) async {
      setTestScreenSize(tester);
      final foodRepo = MockChallengerStaffFoodRepository();
      foodRepo.mockPending = [
        createChallengerBooking(
          code: 'FD112233',
          movieTitle: 'Spider-Man',
          roomName: 'Phòng 1',
          showtimeStart: DateTime.now().add(const Duration(minutes: 30)),
          foods: [
            {'name': 'Bắp Rang Bơ', 'qty': 2},
          ],
        ),
      ];
      final foodProvider = StaffFoodProvider(foodRepo);

      await tester.pumpWidget(createM4TestHarness(
        foodProvider: foodProvider,
        child: const FoodBoardScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('#FD112233'), findsOneWidget);
      expect(find.text('Spider-Man'), findsOneWidget);
      expect(find.byKey(const Key('deliver_btn_FD112233')), findsOneWidget);

      // Open confirm dialog
      await tester.tap(find.byKey(const Key('deliver_btn_FD112233')));
      await tester.pumpAndSettle();

      expect(find.text('XÁC NHẬN GIAO ĐỒ ĂN'), findsOneWidget);
      expect(find.text('Xác nhận đã giao đủ đồ ăn cho đơn vé #FD112233?'), findsOneWidget);
      expect(find.text('HỦY'), findsOneWidget);
      expect(find.text('XÁC NHẬN'), findsOneWidget);
    });

    testWidgets('1.5 S20: CounterShowtimesScreen renders header, room chips, showtime cards, and StaffBottomNav',
        (tester) async {
      setTestScreenSize(tester);
      final counterRepo = MockChallengerStaffCounterRepository();
      counterRepo.mockShowtimes = [
        createChallengerShowtime(
          id: 'st_01',
          movieTitle: 'Avengers: Endgame',
          roomName: 'Phòng IMAX',
          startTime: DateTime(2026, 10, 28, 19, 0),
          endTime: DateTime(2026, 10, 28, 22, 0),
          minPrice: 110000,
        ),
      ];
      final counterProvider = StaffCounterProvider(counterRepo);

      await tester.pumpWidget(createM4TestHarness(
        counterProvider: counterProvider,
        child: const CounterShowtimesScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('BÁN VÉ TẠI QUẦY'), findsOneWidget);
      expect(find.text('TẤT CẢ'), findsOneWidget);
      expect(find.text('PHÒNG IMAX'), findsOneWidget);
      expect(find.text('Avengers: Endgame'), findsOneWidget);
      expect(find.text('TỪ ${CurrencyFormatter.format(110000)}'), findsOneWidget);
      expect(find.byType(StaffBottomNav), findsOneWidget);
    });

    testWidgets('1.6 S20: CounterShowtimesScreen opens seat selection modal with 4x8 seat matrix and concession steppers',
        (tester) async {
      setTestScreenSize(tester);
      final counterRepo = MockChallengerStaffCounterRepository();
      counterRepo.mockShowtimes = [
        createChallengerShowtime(
          id: 'st_02',
          movieTitle: 'Avatar 2',
          roomName: 'Phòng 1',
          startTime: DateTime(2026, 10, 28, 20, 0),
          endTime: DateTime(2026, 10, 28, 23, 15),
          minPrice: 90000,
        ),
      ];
      final counterProvider = StaffCounterProvider(counterRepo);

      await tester.pumpWidget(createM4TestHarness(
        counterProvider: counterProvider,
        child: const CounterShowtimesScreen(),
      ));
      await tester.pumpAndSettle();

      // Tap showtime
      await tester.tap(find.byKey(const Key('counter_showtime_st_02')));
      await tester.pumpAndSettle();

      expect(find.text('CHỌN GHẾ TẠI QUẦY'), findsOneWidget);
      expect(find.text('0/8 GHẾ'), findsOneWidget);
      expect(find.text('MÀN HÌNH'), findsOneWidget);
      expect(find.byKey(const Key('counter_seat_A1')), findsOneWidget);
      expect(find.byKey(const Key('counter_seat_D8')), findsOneWidget);
      expect(find.text('BẮP NƯỚC KÈM THEO'), findsOneWidget);
      expect(find.byKey(const Key('counter_continue_booking_btn')), findsOneWidget);
    });

    testWidgets('1.7 S21: CounterPaymentScreen renders HoldTimer, breakdown, payment modes, change display, and receipt dialog',
        (tester) async {
      setTestScreenSize(tester);
      final counterRepo = MockChallengerStaffCounterRepository();
      final counterProvider = StaffCounterProvider(counterRepo);

      final showtime = createChallengerShowtime(
        id: 'st_pay_01',
        movieTitle: 'Interstellar',
        roomName: 'Phòng VIP',
        startTime: DateTime(2026, 10, 28, 20, 0),
        endTime: DateTime(2026, 10, 28, 23, 0),
        format: 'IMAX',
        minPrice: 120000,
      );
      counterProvider.selectShowtime(showtime);
      counterProvider.toggleSeat('B1');
      counterProvider.toggleSeat('B2'); // Total 240.000 đ

      await tester.pumpWidget(createM4TestHarness(
        counterProvider: counterProvider,
        child: const CounterPaymentScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('THANH TOÁN TẠI QUẦY'), findsOneWidget);
      expect(find.byType(HoldTimer), findsOneWidget);
      expect(find.text('Interstellar'), findsOneWidget);
      expect(find.text('Phòng VIP · IMAX'), findsOneWidget);
      expect(find.text('GHẾ (2)'), findsOneWidget);
      expect(find.text('B1, B2'), findsOneWidget);
      expect(find.text(CurrencyFormatter.format(240000)), findsOneWidget);
      expect(find.text('TIỀN MẶT'), findsOneWidget);
      expect(find.text('THẺ / POS / QR'), findsOneWidget);
      expect(find.byKey(const Key('cash_received_input')), findsOneWidget);
      expect(find.byKey(const Key('counter_confirm_sale_btn')), findsOneWidget);

      // Tap +500k chip
      await tester.ensureVisible(find.byKey(const Key('cash_plus_500k_btn')));
      await tester.tap(find.byKey(const Key('cash_plus_500k_btn')));
      await tester.pumpAndSettle();

      expect(find.text('TIỀN THỪA TRẢ KHÁCH'), findsOneWidget);
      expect(find.textContaining('260.000'), findsOneWidget);

      // Confirm sale
      await tester.ensureVisible(find.byKey(const Key('counter_confirm_sale_btn')));
      await tester.tap(find.byKey(const Key('counter_confirm_sale_btn')));
      await tester.pumpAndSettle();

      // Success receipt dialog
      expect(find.text('XUẤT VÉ THÀNH CÔNG'), findsOneWidget);
      expect(find.byType(TicketCard), findsOneWidget);
      expect(find.text('IN VÉ NHIỆT / HÓA ĐƠN'), findsOneWidget);
      expect(find.byKey(const Key('counter_new_sale_btn')), findsOneWidget);
    });

    testWidgets('1.8 S23: StaffAccountsScreen renders employee list, role badges, lock buttons, and FAB',
        (tester) async {
      setTestScreenSize(tester);
      final mgmtRepo = MockChallengerManagementRepository();
      mgmtRepo.mockEmployees = [
        const AppUser(
          id: 'emp_01',
          fullName: 'Trần Văn Nhân Viên',
          email: 'tvnv@cinema.vn',
          phone: '0912345678',
          role: UserRole.staff,
          cinemaId: 'cn_q1',
          isLocked: false,
        ),
      ];
      final mgmtProvider = ManagementProvider(mgmtRepo);
      final authProvider = MockChallengerStaffAuthProvider()..setRole(UserRole.manager);

      await tester.pumpWidget(createM4TestHarness(
        authProvider: authProvider,
        managementProvider: mgmtProvider,
        child: const StaffAccountsScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('QUẢN LÝ NHÂN VIÊN'), findsOneWidget);
      expect(find.text('CN_Q1'), findsOneWidget);
      expect(find.text('Trần Văn Nhân Viên'), findsOneWidget);
      expect(find.text('STAFF'), findsOneWidget);
      expect(find.text('KHÓA'), findsOneWidget);
      expect(find.byKey(const Key('add_staff_fab')), findsOneWidget);
    });

    testWidgets('1.9 S23: StaffAccountsScreen renders empty state when no employees and opens add staff modal',
        (tester) async {
      setTestScreenSize(tester);
      final mgmtRepo = MockChallengerManagementRepository();
      mgmtRepo.mockEmployees = [];
      final mgmtProvider = ManagementProvider(mgmtRepo);
      final authProvider = MockChallengerStaffAuthProvider()..setRole(UserRole.manager);

      await tester.pumpWidget(createM4TestHarness(
        authProvider: authProvider,
        managementProvider: mgmtProvider,
        child: const StaffAccountsScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('CHƯA CÓ NHÂN VIÊN'), findsOneWidget);
      expect(find.text('THÊM NHÂN VIÊN'), findsOneWidget);

      // Open Add Staff modal
      await tester.tap(find.byKey(const Key('add_staff_fab')));
      await tester.pumpAndSettle();

      expect(find.text('THÊM TÀI KHOẢN NHÂN SỰ'), findsOneWidget);
      expect(find.byKey(const Key('add_staff_name_field')), findsOneWidget);
      expect(find.byKey(const Key('add_staff_email_field')), findsOneWidget);
      expect(find.byKey(const Key('add_staff_phone_field')), findsOneWidget);
      expect(find.byKey(const Key('add_staff_password_field')), findsOneWidget);
      expect(find.byKey(const Key('add_staff_submit_btn')), findsOneWidget);
    });

    testWidgets('1.10 StaffBottomNav renders 4 tabs with icons and uppercase text',
        (tester) async {
      setTestScreenSize(tester);

      await tester.pumpWidget(createM4TestHarness(
        child: const Scaffold(
          bottomNavigationBar: StaffBottomNav(currentIndex: 0),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('SOÁT VÉ'), findsOneWidget);
      expect(find.text('ĐỒ ĂN'), findsOneWidget);
      expect(find.text('BÁN VÉ'), findsOneWidget);
      expect(find.text('TÀI KHOẢN'), findsOneWidget);

      expect(find.byIcon(Icons.qr_code_scanner), findsOneWidget);
      expect(find.byIcon(Icons.fastfood_outlined), findsOneWidget);
      expect(find.byIcon(Icons.point_of_sale_outlined), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });
  });

  // ===========================================================================
  // REQUIREMENT 2: BUTTON TEXT CASE VERIFICATION (ALL BUTTONS UPPERCASE)
  // ===========================================================================
  group('Requirement 2: Button Text Case Verification (All Buttons Uppercase)', () {
    testWidgets('2.1 S18: All buttons render uppercase labels (main screen, modal, result sheet)',
        (tester) async {
      setTestScreenSize(tester);
      final checkinRepo = MockChallengerCheckinRepository();
      final checkinProvider = CheckinProvider(checkinRepo);

      await tester.pumpWidget(createM4TestHarness(
        checkinProvider: checkinProvider,
        child: const TicketCheckinScreen(forceDesktopFallback: true),
      ));
      await tester.pumpAndSettle();

      // Main screen
      verifyAllButtonLabelsUppercase(tester);

      // Open manual input modal
      await tester.tap(find.byKey(const Key('ticket_checkin_manual_input_btn')));
      await tester.pumpAndSettle();
      verifyAllButtonLabelsUppercase(tester);

      // Enter valid code
      await tester.enterText(find.byKey(const Key('manual_code_input')), 'VALID001');
      await tester.tap(find.byKey(const Key('manual_code_submit')));
      await tester.pumpAndSettle();

      // Result sheet
      verifyAllButtonLabelsUppercase(tester);
    });

    testWidgets('2.2 S19: All buttons render uppercase labels (deliver button, deliver confirm dialog)',
        (tester) async {
      setTestScreenSize(tester);
      final foodRepo = MockChallengerStaffFoodRepository();
      foodRepo.mockPending = [
        createChallengerBooking(
          code: 'FD990011',
          movieTitle: 'Dune',
          roomName: 'Phòng 2',
          showtimeStart: DateTime.now(),
          foods: [{'name': 'Bắp Phô Mai', 'qty': 1}],
        ),
      ];
      final foodProvider = StaffFoodProvider(foodRepo);

      await tester.pumpWidget(createM4TestHarness(
        foodProvider: foodProvider,
        child: const FoodBoardScreen(),
      ));
      await tester.pumpAndSettle();

      verifyAllButtonLabelsUppercase(tester);

      // Open dialog
      await tester.tap(find.byKey(const Key('deliver_btn_FD990011')));
      await tester.pumpAndSettle();

      verifyAllButtonLabelsUppercase(tester);
    });

    testWidgets('2.3 S20: All buttons render uppercase labels (seat modal continue button)',
        (tester) async {
      setTestScreenSize(tester);
      final counterRepo = MockChallengerStaffCounterRepository();
      counterRepo.mockShowtimes = [
        createChallengerShowtime(
          id: 'st_btn_01',
          movieTitle: 'Godzilla',
          roomName: 'Phòng 1',
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(hours: 2)),
        ),
      ];
      final counterProvider = StaffCounterProvider(counterRepo);

      await tester.pumpWidget(createM4TestHarness(
        counterProvider: counterProvider,
        child: const CounterShowtimesScreen(),
      ));
      await tester.pumpAndSettle();

      verifyAllButtonLabelsUppercase(tester);

      // Open seat modal
      await tester.tap(find.byKey(const Key('counter_showtime_st_btn_01')));
      await tester.pumpAndSettle();

      verifyAllButtonLabelsUppercase(tester);
    });

    testWidgets('2.4 S21: All buttons render uppercase labels (confirm, quick cash, receipt dialog)',
        (tester) async {
      setTestScreenSize(tester);
      final counterRepo = MockChallengerStaffCounterRepository();
      final counterProvider = StaffCounterProvider(counterRepo);
      counterProvider.selectShowtime(createChallengerShowtime(
        id: 'st_pay_btn',
        movieTitle: 'Batman',
        roomName: 'Phòng VIP',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(hours: 2)),
      ));
      counterProvider.toggleSeat('A1');

      await tester.pumpWidget(createM4TestHarness(
        counterProvider: counterProvider,
        child: const CounterPaymentScreen(),
      ));
      await tester.pumpAndSettle();

      verifyAllButtonLabelsUppercase(tester);

      // Tap exact cash
      await tester.ensureVisible(find.byKey(const Key('cash_exact_btn')));
      await tester.tap(find.byKey(const Key('cash_exact_btn')));
      await tester.pumpAndSettle();

      // Open receipt dialog
      await tester.ensureVisible(find.byKey(const Key('counter_confirm_sale_btn')));
      await tester.tap(find.byKey(const Key('counter_confirm_sale_btn')));
      await tester.pumpAndSettle();

      verifyAllButtonLabelsUppercase(tester);
    });

    testWidgets('2.5 S23: All buttons render uppercase labels (lock toggle, add staff submit, empty action)',
        (tester) async {
      setTestScreenSize(tester);
      final mgmtRepo = MockChallengerManagementRepository();
      mgmtRepo.mockEmployees = [
        const AppUser(
          id: 'emp_btn',
          fullName: 'Trần Văn B',
          email: 'tvb@cinema.vn',
          role: UserRole.staff,
          cinemaId: 'cn_q1',
        ),
      ];
      final mgmtProvider = ManagementProvider(mgmtRepo);
      final authProvider = MockChallengerStaffAuthProvider()..setRole(UserRole.manager);

      await tester.pumpWidget(createM4TestHarness(
        authProvider: authProvider,
        managementProvider: mgmtProvider,
        child: const StaffAccountsScreen(),
      ));
      await tester.pumpAndSettle();

      verifyAllButtonLabelsUppercase(tester);

      // Open add staff modal
      await tester.tap(find.byKey(const Key('add_staff_fab')));
      await tester.pumpAndSettle();

      verifyAllButtonLabelsUppercase(tester);
    });
  });

  // ===========================================================================
  // REQUIREMENT 3: PRIMARY BUTTON RULE (MAX 1 PRIMARY BUTTON PER VIEW)
  // ===========================================================================
  group('Requirement 3: Primary Button Rule Verification (Max 1 Primary Button)', () {
    testWidgets('3.1 S18 has exactly 1 primary button on main screen', (tester) async {
      setTestScreenSize(tester);
      await tester.pumpWidget(createM4TestHarness(
        child: const TicketCheckinScreen(forceDesktopFallback: true),
      ));
      await tester.pumpAndSettle();

      verifyMaxOnePrimaryButton(tester);
      expect(find.widgetWithText(ElevatedButton, 'NHẬP MÃ TAY'), findsOneWidget);
    });

    testWidgets('3.2 S18 manual input modal has exactly 1 primary button', (tester) async {
      setTestScreenSize(tester);
      await tester.pumpWidget(createM4TestHarness(
        child: const TicketCheckinScreen(forceDesktopFallback: true),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('ticket_checkin_manual_input_btn')));
      await tester.pumpAndSettle();

      verifyMaxOnePrimaryButton(tester, scope: find.byType(BottomSheet));
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.widgetWithText(ElevatedButton, 'KIỂM TRA VÉ'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('3.3 S18 valid result sheet has exactly 1 primary button', (tester) async {
      setTestScreenSize(tester);
      final checkinRepo = MockChallengerCheckinRepository();
      final checkinProvider = CheckinProvider(checkinRepo);

      await tester.pumpWidget(createM4TestHarness(
        checkinProvider: checkinProvider,
        child: const TicketCheckinScreen(forceDesktopFallback: true),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('ticket_checkin_manual_input_btn')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('manual_code_input')), 'VALID001');
      await tester.tap(find.byKey(const Key('manual_code_submit')));
      await tester.pumpAndSettle();

      verifyMaxOnePrimaryButton(tester, scope: find.byType(BottomSheet));
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.widgetWithText(ElevatedButton, 'XÁC NHẬN CHO VÀO'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('3.4 S19 empty state has 0 primary buttons', (tester) async {
      setTestScreenSize(tester);
      final foodRepo = MockChallengerStaffFoodRepository();
      final foodProvider = StaffFoodProvider(foodRepo);

      await tester.pumpWidget(createM4TestHarness(
        foodProvider: foodProvider,
        child: const FoodBoardScreen(),
      ));
      await tester.pumpAndSettle();

      verifyMaxOnePrimaryButton(tester);
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('3.5 S19 single order card has at most 1 primary button', (tester) async {
      setTestScreenSize(tester);
      final foodRepo = MockChallengerStaffFoodRepository();
      foodRepo.mockPending = [
        createChallengerBooking(
          code: 'FD_SINGLE',
          movieTitle: 'Godzilla',
          roomName: 'Phòng 1',
          showtimeStart: DateTime.now(),
          foods: [],
        ),
      ];
      final foodProvider = StaffFoodProvider(foodRepo);

      await tester.pumpWidget(createM4TestHarness(
        foodProvider: foodProvider,
        child: const FoodBoardScreen(),
      ));
      await tester.pumpAndSettle();

      verifyMaxOnePrimaryButton(tester);
      expect(find.widgetWithText(ElevatedButton, 'ĐÃ GIAO'), findsOneWidget);
    });

    testWidgets('3.6 S19 delivery confirmation dialog has exactly 1 primary button', (tester) async {
      setTestScreenSize(tester);
      final foodRepo = MockChallengerStaffFoodRepository();
      foodRepo.mockPending = [
        createChallengerBooking(
          code: 'FD_SINGLE',
          movieTitle: 'Godzilla',
          roomName: 'Phòng 1',
          showtimeStart: DateTime.now(),
          foods: [],
        ),
      ];
      final foodProvider = StaffFoodProvider(foodRepo);

      await tester.pumpWidget(createM4TestHarness(
        foodProvider: foodProvider,
        child: const FoodBoardScreen(),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('deliver_btn_FD_SINGLE')));
      await tester.pumpAndSettle();

      verifyMaxOnePrimaryButton(tester, scope: find.byType(AlertDialog));
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(ElevatedButton, 'XÁC NHẬN'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('3.7 S20 main screen has 0 primary buttons', (tester) async {
      setTestScreenSize(tester);
      final counterRepo = MockChallengerStaffCounterRepository();
      counterRepo.mockShowtimes = [
        createChallengerShowtime(
          id: 'st_nobtn',
          movieTitle: 'Dune',
          roomName: 'Phòng 1',
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(hours: 2)),
        ),
      ];
      final counterProvider = StaffCounterProvider(counterRepo);

      await tester.pumpWidget(createM4TestHarness(
        counterProvider: counterProvider,
        child: const CounterShowtimesScreen(),
      ));
      await tester.pumpAndSettle();

      verifyMaxOnePrimaryButton(tester);
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('3.8 S20 seat selection modal has exactly 1 primary button', (tester) async {
      setTestScreenSize(tester);
      final counterRepo = MockChallengerStaffCounterRepository();
      counterRepo.mockShowtimes = [
        createChallengerShowtime(
          id: 'st_seat_modal',
          movieTitle: 'Dune',
          roomName: 'Phòng 1',
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(hours: 2)),
        ),
      ];
      final counterProvider = StaffCounterProvider(counterRepo);

      await tester.pumpWidget(createM4TestHarness(
        counterProvider: counterProvider,
        child: const CounterShowtimesScreen(),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('counter_showtime_st_seat_modal')));
      await tester.pumpAndSettle();

      verifyMaxOnePrimaryButton(tester, scope: find.byType(BottomSheet));
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.widgetWithText(ElevatedButton, 'TIẾP TỤC'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('3.9 S21 has exactly 1 primary button on main screen', (tester) async {
      setTestScreenSize(tester);
      final counterRepo = MockChallengerStaffCounterRepository();
      final counterProvider = StaffCounterProvider(counterRepo);
      counterProvider.selectShowtime(createChallengerShowtime(
        id: 'st_pay_btn2',
        movieTitle: 'Avengers',
        roomName: 'Phòng 1',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(hours: 2)),
      ));
      counterProvider.toggleSeat('A1');

      await tester.pumpWidget(createM4TestHarness(
        counterProvider: counterProvider,
        child: const CounterPaymentScreen(),
      ));
      await tester.pumpAndSettle();

      verifyMaxOnePrimaryButton(tester);
      expect(find.widgetWithText(ElevatedButton, 'XÁC NHẬN BÁN VÉ'), findsOneWidget);
    });

    testWidgets('3.10 S21 receipt dialog has exactly 1 primary button', (tester) async {
      setTestScreenSize(tester);
      final counterRepo = MockChallengerStaffCounterRepository();
      final counterProvider = StaffCounterProvider(counterRepo);
      counterProvider.selectShowtime(createChallengerShowtime(
        id: 'st_pay_btn3',
        movieTitle: 'Avengers',
        roomName: 'Phòng 1',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(hours: 2)),
      ));
      counterProvider.toggleSeat('A1');

      await tester.pumpWidget(createM4TestHarness(
        counterProvider: counterProvider,
        child: const CounterPaymentScreen(),
      ));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('cash_exact_btn')));
      await tester.tap(find.byKey(const Key('cash_exact_btn')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('counter_confirm_sale_btn')));
      await tester.tap(find.byKey(const Key('counter_confirm_sale_btn')));
      await tester.pumpAndSettle();

      verifyMaxOnePrimaryButton(tester, scope: find.byType(Dialog));
      expect(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.widgetWithText(ElevatedButton, 'BÁN ĐƠN MỚI'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('3.11 S23 staff list screen has 0 primary buttons', (tester) async {
      setTestScreenSize(tester);
      final mgmtRepo = MockChallengerManagementRepository();
      mgmtRepo.mockEmployees = [
        const AppUser(
          id: 'emp_01',
          fullName: 'Staff A',
          email: 'a@cinema.vn',
          role: UserRole.staff,
          cinemaId: 'cn_q1',
        ),
      ];
      final mgmtProvider = ManagementProvider(mgmtRepo);
      final authProvider = MockChallengerStaffAuthProvider()..setRole(UserRole.manager);

      await tester.pumpWidget(createM4TestHarness(
        authProvider: authProvider,
        managementProvider: mgmtProvider,
        child: const StaffAccountsScreen(),
      ));
      await tester.pumpAndSettle();

      verifyMaxOnePrimaryButton(tester);
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('3.12 S23 add staff modal has exactly 1 primary button', (tester) async {
      setTestScreenSize(tester);
      final mgmtRepo = MockChallengerManagementRepository();
      final mgmtProvider = ManagementProvider(mgmtRepo);
      final authProvider = MockChallengerStaffAuthProvider()..setRole(UserRole.manager);

      await tester.pumpWidget(createM4TestHarness(
        authProvider: authProvider,
        managementProvider: mgmtProvider,
        child: const StaffAccountsScreen(),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add_staff_fab')));
      await tester.pumpAndSettle();

      verifyMaxOnePrimaryButton(tester, scope: find.byType(BottomSheet));
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.widgetWithText(ElevatedButton, 'TẠO TÀI KHOẢN'),
        ),
        findsOneWidget,
      );
    });
  });

  // ===========================================================================
  // REQUIREMENT 4: ELEVATION AND ZERO BOXSHADOW VERIFICATION
  // ===========================================================================
  group('Requirement 4: Elevation Verification (0 Elevation & Zero BoxShadow)', () {
    testWidgets('4.1 S18 has 0 elevation and zero BoxShadow', (tester) async {
      setTestScreenSize(tester);
      await tester.pumpWidget(createM4TestHarness(
        child: const TicketCheckinScreen(forceDesktopFallback: true),
      ));
      await tester.pumpAndSettle();
      verifyZeroElevationAndZeroBoxShadow(tester);
    });

    testWidgets('4.2 S18 manual input modal and result sheet have 0 elevation and zero BoxShadow', (tester) async {
      setTestScreenSize(tester);
      final checkinRepo = MockChallengerCheckinRepository();
      final checkinProvider = CheckinProvider(checkinRepo);

      await tester.pumpWidget(createM4TestHarness(
        checkinProvider: checkinProvider,
        child: const TicketCheckinScreen(forceDesktopFallback: true),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('ticket_checkin_manual_input_btn')));
      await tester.pumpAndSettle();
      verifyZeroElevationAndZeroBoxShadow(tester);

      await tester.enterText(find.byKey(const Key('manual_code_input')), 'VALID001');
      await tester.tap(find.byKey(const Key('manual_code_submit')));
      await tester.pumpAndSettle();
      verifyZeroElevationAndZeroBoxShadow(tester);
    });

    testWidgets('4.3 S19 has 0 elevation and zero BoxShadow', (tester) async {
      setTestScreenSize(tester);
      final foodRepo = MockChallengerStaffFoodRepository();
      final foodProvider = StaffFoodProvider(foodRepo);

      await tester.pumpWidget(createM4TestHarness(
        foodProvider: foodProvider,
        child: const FoodBoardScreen(),
      ));
      await tester.pumpAndSettle();
      verifyZeroElevationAndZeroBoxShadow(tester);
    });

    testWidgets('4.4 S19 delivery confirmation dialog has 0 elevation and zero BoxShadow', (tester) async {
      setTestScreenSize(tester);
      final foodRepo = MockChallengerStaffFoodRepository();
      foodRepo.mockPending = [
        createChallengerBooking(
          code: 'FD_ELEV',
          movieTitle: 'Kung Fu Panda',
          roomName: 'Phòng 2',
          showtimeStart: DateTime.now(),
          foods: [],
        ),
      ];
      final foodProvider = StaffFoodProvider(foodRepo);

      await tester.pumpWidget(createM4TestHarness(
        foodProvider: foodProvider,
        child: const FoodBoardScreen(),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('deliver_btn_FD_ELEV')));
      await tester.pumpAndSettle();
      verifyZeroElevationAndZeroBoxShadow(tester);
    });

    testWidgets('4.5 S20 has 0 elevation and zero BoxShadow', (tester) async {
      setTestScreenSize(tester);
      final counterRepo = MockChallengerStaffCounterRepository();
      counterRepo.mockShowtimes = [
        createChallengerShowtime(
          id: 'st_elev',
          movieTitle: 'Movie A',
          roomName: 'Phòng 1',
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(hours: 2)),
        ),
      ];
      final counterProvider = StaffCounterProvider(counterRepo);

      await tester.pumpWidget(createM4TestHarness(
        counterProvider: counterProvider,
        child: const CounterShowtimesScreen(),
      ));
      await tester.pumpAndSettle();
      verifyZeroElevationAndZeroBoxShadow(tester);
    });

    testWidgets('4.6 S20 seat selection modal has 0 elevation and zero BoxShadow', (tester) async {
      setTestScreenSize(tester);
      final counterRepo = MockChallengerStaffCounterRepository();
      counterRepo.mockShowtimes = [
        createChallengerShowtime(
          id: 'st_elev_seat',
          movieTitle: 'Movie A',
          roomName: 'Phòng 1',
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(hours: 2)),
        ),
      ];
      final counterProvider = StaffCounterProvider(counterRepo);

      await tester.pumpWidget(createM4TestHarness(
        counterProvider: counterProvider,
        child: const CounterShowtimesScreen(),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('counter_showtime_st_elev_seat')));
      await tester.pumpAndSettle();
      verifyZeroElevationAndZeroBoxShadow(tester);
    });

    testWidgets('4.7 S21 has 0 elevation and zero BoxShadow', (tester) async {
      setTestScreenSize(tester);
      final counterRepo = MockChallengerStaffCounterRepository();
      final counterProvider = StaffCounterProvider(counterRepo);
      counterProvider.selectShowtime(createChallengerShowtime(
        id: 'st_pay_elev',
        movieTitle: 'Movie B',
        roomName: 'Phòng 2',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(hours: 2)),
      ));
      counterProvider.toggleSeat('A1');

      await tester.pumpWidget(createM4TestHarness(
        counterProvider: counterProvider,
        child: const CounterPaymentScreen(),
      ));
      await tester.pumpAndSettle();
      verifyZeroElevationAndZeroBoxShadow(tester);
    });

    testWidgets('4.8 S23 has 0 elevation and zero BoxShadow (including FAB and Add Staff modal)', (tester) async {
      setTestScreenSize(tester);
      final mgmtRepo = MockChallengerManagementRepository();
      mgmtRepo.mockEmployees = [
        const AppUser(
          id: 'emp_elev',
          fullName: 'Staff C',
          email: 'c@cinema.vn',
          role: UserRole.staff,
          cinemaId: 'cn_q1',
        ),
      ];
      final mgmtProvider = ManagementProvider(mgmtRepo);
      final authProvider = MockChallengerStaffAuthProvider()..setRole(UserRole.manager);

      await tester.pumpWidget(createM4TestHarness(
        authProvider: authProvider,
        managementProvider: mgmtProvider,
        child: const StaffAccountsScreen(),
      ));
      await tester.pumpAndSettle();
      verifyZeroElevationAndZeroBoxShadow(tester);

      // Open Add Staff modal
      await tester.tap(find.byKey(const Key('add_staff_fab')));
      await tester.pumpAndSettle();
      verifyZeroElevationAndZeroBoxShadow(tester);
    });

    testWidgets('4.9 StaffBottomNav has 0 elevation and zero BoxShadow', (tester) async {
      setTestScreenSize(tester);
      await tester.pumpWidget(createM4TestHarness(
        child: const Scaffold(
          bottomNavigationBar: StaffBottomNav(currentIndex: 0),
        ),
      ));
      await tester.pumpAndSettle();
      verifyZeroElevationAndZeroBoxShadow(tester);
    });
  });

  // ===========================================================================
  // REQUIREMENT 5: STAFF NAVIGATION ROUTING ACROSS ALL 4 TABS
  // ===========================================================================
  group('Requirement 5: Staff Navigation Routing Across All 4 Tabs in StaffBottomNav', () {
    testWidgets('5.1 StaffBottomNav active colors and icon styling', (tester) async {
      setTestScreenSize(tester);

      await tester.pumpWidget(createM4TestHarness(
        child: const Scaffold(
          bottomNavigationBar: StaffBottomNav(currentIndex: 0),
        ),
      ));
      await tester.pumpAndSettle();

      // Active tab (index 0) icon color is AppColors.primary
      final activeIcon = tester.widget<Icon>(find.byIcon(Icons.qr_code_scanner));
      expect(activeIcon.color, equals(AppColors.primary));

      // Inactive tab (index 1) icon color is AppColors.muted
      final inactiveIcon = tester.widget<Icon>(find.byIcon(Icons.fastfood_outlined));
      expect(inactiveIcon.color, equals(AppColors.muted));
    });

    testWidgets('5.2 Tapping active tab does NOT push/replace route', (tester) async {
      setTestScreenSize(tester);
      final navObserver = TestNavigatorObserver();

      await tester.pumpWidget(createM4TestHarness(
        navigatorObserver: navObserver,
        child: const Scaffold(
          body: Text('START_SCREEN'),
          bottomNavigationBar: StaffBottomNav(currentIndex: 0),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('SOÁT VÉ'));
      await tester.pumpAndSettle();
      expect(navObserver.replacedRoutes, isEmpty);
    });

    testWidgets('5.3 Tapping Tab 1 routes to AppRoutes.staffFood (S19)', (tester) async {
      setTestScreenSize(tester);
      final navObserver = TestNavigatorObserver();

      await tester.pumpWidget(createM4TestHarness(
        navigatorObserver: navObserver,
        child: const Scaffold(
          body: Text('START_SCREEN'),
          bottomNavigationBar: StaffBottomNav(currentIndex: 0),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ĐỒ ĂN'));
      await tester.pumpAndSettle();
      expect(navObserver.replacedRoutes.last, equals(AppRoutes.staffFood));
      expect(find.text('QUẦY ĐỒ ĂN'), findsOneWidget);
    });

    testWidgets('5.4 Tapping Tab 2 routes to AppRoutes.staffCounterShowtimes (S20)', (tester) async {
      setTestScreenSize(tester);
      final navObserver = TestNavigatorObserver();

      await tester.pumpWidget(createM4TestHarness(
        navigatorObserver: navObserver,
        child: const Scaffold(
          body: Text('START_SCREEN'),
          bottomNavigationBar: StaffBottomNav(currentIndex: 0),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('BÁN VÉ'));
      await tester.pumpAndSettle();
      expect(navObserver.replacedRoutes.last, equals(AppRoutes.staffCounterShowtimes));
      expect(find.text('BÁN VÉ TẠI QUẦY'), findsOneWidget);
    });

    testWidgets('5.5 Tapping Tab 3 routes to AppRoutes.profile (S11)', (tester) async {
      setTestScreenSize(tester);
      final navObserver = TestNavigatorObserver();

      await tester.pumpWidget(createM4TestHarness(
        navigatorObserver: navObserver,
        child: const Scaffold(
          body: Text('START_SCREEN'),
          bottomNavigationBar: StaffBottomNav(currentIndex: 0),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('TÀI KHOẢN'));
      await tester.pumpAndSettle();
      expect(navObserver.replacedRoutes.last, equals(AppRoutes.profile));
      expect(find.text('PROFILE_SCREEN_MOCK'), findsOneWidget);
    });

    testWidgets('5.6 Tapping Tab 0 from another tab routes back to AppRoutes.staffCheckin (S18)', (tester) async {
      setTestScreenSize(tester);
      final navObserver = TestNavigatorObserver();

      await tester.pumpWidget(createM4TestHarness(
        navigatorObserver: navObserver,
        child: const Scaffold(
          body: Text('TAB_FOOD_SCREEN'),
          bottomNavigationBar: StaffBottomNav(currentIndex: 1),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('SOÁT VÉ'));
      await tester.pumpAndSettle();
      expect(navObserver.replacedRoutes.last, equals(AppRoutes.staffCheckin));
      expect(find.text('SOÁT VÉ VÀO RẠP'), findsOneWidget);
    });
  });
}
