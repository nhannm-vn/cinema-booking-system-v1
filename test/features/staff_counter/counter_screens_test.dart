import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cinema_booking_v1/core/routes/app_router.dart';
import 'package:cinema_booking_v1/core/theme/app_theme.dart';
import 'package:cinema_booking_v1/features/auth/presentation/controllers/auth_provider.dart';
import 'package:cinema_booking_v1/features/booking/data/models/showtime_model.dart';
import 'package:cinema_booking_v1/features/staff_counter/data/repositories/staff_counter_repository.dart';
import 'package:cinema_booking_v1/features/staff_counter/presentation/controllers/staff_counter_provider.dart';
import 'package:cinema_booking_v1/features/staff_counter/presentation/screens/counter_payment_screen.dart';
import 'package:cinema_booking_v1/features/staff_counter/presentation/screens/counter_showtimes_screen.dart';
import 'package:cinema_booking_v1/shared/models/app_user.dart';
import 'package:cinema_booking_v1/core/utils/currency_formatter.dart';

class MockStaffCounterRepository implements StaffCounterRepository {
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
}

class FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  final AppUser _user = const AppUser(
    id: 'staff_counter',
    fullName: 'Nhân viên Quầy',
    role: UserRole.staff,
    cinemaId: 'cn_q1',
  );

  @override
  AppUser? get currentUser => _user;

  @override
  bool get isAuthenticated => true;

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
  Future<void> signOut() async {}

  @override
  Future<bool> signUp({required String email, required String password, required String fullName, String? phone}) async => true;

  @override
  Future<bool> updateProfile({required String fullName, String? phone}) async => true;
}

ShowtimeModel createTestShowtime({
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

Widget createCounterTestHarness({
  required StaffCounterProvider counterProvider,
  Widget? home,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: FakeAuthProvider()),
      ChangeNotifierProvider<StaffCounterProvider>.value(value: counterProvider),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.staffCounterPayment) {
          return MaterialPageRoute(builder: (_) => const CounterPaymentScreen());
        }
        if (settings.name == AppRoutes.staffCounterShowtimes || settings.name == '/') {
          return MaterialPageRoute(builder: (_) => const CounterShowtimesScreen());
        }
        return MaterialPageRoute(
          builder: (_) => Scaffold(body: Text('ROUTE: ${settings.name}')),
        );
      },
      home: home ?? const CounterShowtimesScreen(),
    ),
  );
}

void main() {
  group('S20 Counter Showtimes Screen Widget Tests', () {
    late MockStaffCounterRepository mockRepo;
    late StaffCounterProvider counterProvider;

    setUp(() {
      mockRepo = MockStaffCounterRepository();
      counterProvider = StaffCounterProvider(mockRepo);
    });

    testWidgets('renders screen header, date, room chips and staff bottom nav', (tester) async {
      mockRepo.mockShowtimes = [
        createTestShowtime(
          id: 'st_1',
          movieTitle: 'Godzilla x Kong',
          roomName: 'Phòng 1',
          startTime: DateTime(2026, 10, 28, 14, 0),
          endTime: DateTime(2026, 10, 28, 16, 0),
        ),
        createTestShowtime(
          id: 'st_2',
          movieTitle: 'Kung Fu Panda 4',
          roomName: 'Phòng 2',
          startTime: DateTime(2026, 10, 28, 16, 30),
          endTime: DateTime(2026, 10, 28, 18, 15),
        ),
      ];

      await tester.pumpWidget(createCounterTestHarness(counterProvider: counterProvider));
      await tester.pumpAndSettle();

      expect(find.text('BÁN VÉ TẠI QUẦY'), findsOneWidget);
      expect(find.text('TẤT CẢ'), findsOneWidget);
      expect(find.text('PHÒNG 1'), findsOneWidget);
      expect(find.text('PHÒNG 2'), findsOneWidget);

      // Verify Showtimes
      expect(find.text('Godzilla x Kong'), findsOneWidget);
      expect(find.text('Kung Fu Panda 4'), findsOneWidget);

      // Verify StaffBottomNav
      expect(find.text('SOÁT VÉ'), findsOneWidget);
      expect(find.text('ĐỒ ĂN'), findsOneWidget);
      expect(find.text('BÁN VÉ'), findsOneWidget);
      expect(find.text('TÀI KHOẢN'), findsOneWidget);
    });

    testWidgets('filters showtimes when room chip tapped', (tester) async {
      mockRepo.mockShowtimes = [
        createTestShowtime(
          id: 'st_1',
          movieTitle: 'Phim Phòng 1',
          roomName: 'Phòng 1',
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(hours: 2)),
        ),
        createTestShowtime(
          id: 'st_2',
          movieTitle: 'Phim Phòng 2',
          roomName: 'Phòng 2',
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(hours: 2)),
        ),
      ];

      await tester.pumpWidget(createCounterTestHarness(counterProvider: counterProvider));
      await tester.pumpAndSettle();

      expect(find.text('Phim Phòng 1'), findsOneWidget);
      expect(find.text('Phim Phòng 2'), findsOneWidget);

      // Tap Phòng 1 chip
      await tester.tap(find.text('PHÒNG 1'));
      await tester.pumpAndSettle();

      expect(find.text('Phim Phòng 1'), findsOneWidget);
      expect(find.text('Phim Phòng 2'), findsNothing);
    });

    testWidgets('opens seat & concession sheet, selects seats, and proceeds to payment', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      mockRepo.mockShowtimes = [
        createTestShowtime(
          id: 'st_sel',
          movieTitle: 'Dune: Part Two',
          roomName: 'Phòng 1',
          startTime: DateTime(2026, 10, 28, 19, 0),
          endTime: DateTime(2026, 10, 28, 21, 30),
          minPrice: 90000,
        ),
      ];

      await tester.pumpWidget(createCounterTestHarness(counterProvider: counterProvider));
      await tester.pumpAndSettle();

      // Tap showtime card
      await tester.tap(find.byKey(const Key('counter_showtime_st_sel')));
      await tester.pumpAndSettle();

      // Modal sheet opens
      expect(find.text('CHỌN GHẾ TẠI QUẦY'), findsOneWidget);
      expect(find.text('0/8 GHẾ'), findsOneWidget);

      // Select seat A1
      await tester.tap(find.byKey(const Key('counter_seat_A1')));
      await tester.pumpAndSettle();

      expect(find.text('1/8 GHẾ'), findsOneWidget);
      expect(find.text(CurrencyFormatter.format(90000)), findsOneWidget);

      // Continue button is enabled
      expect(find.byKey(const Key('counter_continue_booking_btn')), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('counter_continue_booking_btn')));
      await tester.tap(find.byKey(const Key('counter_continue_booking_btn')));
      await tester.pumpAndSettle();

      // Transitions to S21 Payment Screen
      expect(find.text('THANH TOÁN TẠI QUẦY'), findsOneWidget);
      expect(find.text('GHẾ (1)'), findsOneWidget);
      expect(find.text('A1'), findsOneWidget);
    });
  });

  group('S21 Counter Payment Screen Widget Tests', () {
    late MockStaffCounterRepository mockRepo;
    late StaffCounterProvider counterProvider;

    setUp(() {
      mockRepo = MockStaffCounterRepository();
      counterProvider = StaffCounterProvider(mockRepo);

      // Pre-select showtime & seats
      final showtime = createTestShowtime(
        id: 'st_pay',
        movieTitle: 'Avengers: Secret Wars',
        roomName: 'Phòng IMAX',
        startTime: DateTime(2026, 10, 28, 20, 0),
        endTime: DateTime(2026, 10, 28, 23, 0),
        format: 'IMAX',
        minPrice: 120000,
      );
      counterProvider.selectShowtime(showtime);
      counterProvider.toggleSeat('A1');
      counterProvider.toggleSeat('A2'); // Total 240.000 đ
    });

    testWidgets('renders order summary breakdown and payment method tabs', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createCounterTestHarness(
        counterProvider: counterProvider,
        home: const CounterPaymentScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('THANH TOÁN TẠI QUẦY'), findsOneWidget);
      expect(find.text('Avengers: Secret Wars'), findsOneWidget);
      expect(find.text('Phòng IMAX · IMAX'), findsOneWidget);
      expect(find.text('GHẾ (2)'), findsOneWidget);
      expect(find.text('A1, A2'), findsOneWidget);
      expect(find.text(CurrencyFormatter.format(240000)), findsOneWidget);
      expect(find.textContaining('KHÁCH ĐƯA THIẾU: 240.000'), findsOneWidget);
      expect(find.text('TIỀN MẶT'), findsOneWidget);
      expect(find.text('THẺ / POS / QR'), findsOneWidget);
    });

    testWidgets('cash mode calculates exact change and completes sale with receipt dialog', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createCounterTestHarness(
        counterProvider: counterProvider,
        home: const CounterPaymentScreen(),
      ));
      await tester.pumpAndSettle();

      // Initially 0 VND received -> warning shown, button disabled
      expect(find.text(CurrencyFormatter.format(240000)), findsOneWidget);
      final confirmBtn = tester.widget<ElevatedButton>(
        find.ancestor(of: find.text('XÁC NHẬN BÁN VÉ'), matching: find.byType(ElevatedButton)),
      );
      expect(confirmBtn.onPressed, isNull);

      // Tap +500K quick cash button
      await tester.ensureVisible(find.byKey(const Key('cash_plus_500k_btn')));
      await tester.tap(find.byKey(const Key('cash_plus_500k_btn')));
      await tester.pumpAndSettle();

      // 500.000 - 240.000 = 260.000 change
      expect(find.text('TIỀN THỪA TRẢ KHÁCH'), findsOneWidget);
      expect(find.textContaining('260.000'), findsOneWidget);

      // Confirm sale
      await tester.ensureVisible(find.byKey(const Key('counter_confirm_sale_btn')));
      await tester.tap(find.byKey(const Key('counter_confirm_sale_btn')));
      await tester.pumpAndSettle();

      // Success receipt dialog
      expect(find.text('XUẤT VÉ THÀNH CÔNG'), findsOneWidget);
      expect(find.text('IN VÉ NHIỆT / HÓA ĐƠN'), findsOneWidget);
      expect(find.byKey(const Key('counter_new_sale_btn')), findsOneWidget);

      // Tap Bán đơn mới closes receipt and resets provider
      await tester.ensureVisible(find.byKey(const Key('counter_new_sale_btn')));
      await tester.tap(find.byKey(const Key('counter_new_sale_btn')));
      await tester.pumpAndSettle();

      expect(counterProvider.selectedSeatIds, isEmpty);
      expect(counterProvider.selectedShowtime, isNull);
    });

    testWidgets('card/pos mode requires confirmation checkbox before enabling sale', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createCounterTestHarness(
        counterProvider: counterProvider,
        home: const CounterPaymentScreen(),
      ));
      await tester.pumpAndSettle();

      // Switch to Card/POS mode
      await tester.ensureVisible(find.byKey(const Key('payment_method_card_tab')));
      await tester.tap(find.byKey(const Key('payment_method_card_tab')));
      await tester.pumpAndSettle();

      expect(find.text('Quẹt thẻ ngân hàng hoặc quét mã QR thanh toán trên máy POS tại quầy'), findsOneWidget);
      expect(find.byKey(const Key('pos_confirmed_checkbox')), findsOneWidget);

      // Confirm button disabled before checkbox
      final btnBefore = tester.widget<ElevatedButton>(
        find.ancestor(of: find.text('XÁC NHẬN BÁN VÉ'), matching: find.byType(ElevatedButton)),
      );
      expect(btnBefore.onPressed, isNull);

      // Check POS checkbox
      await tester.ensureVisible(find.byKey(const Key('pos_confirmed_checkbox')));
      await tester.tap(find.byKey(const Key('pos_confirmed_checkbox')));
      await tester.pumpAndSettle();

      // Button now enabled
      final btnAfter = tester.widget<ElevatedButton>(
        find.ancestor(of: find.text('XÁC NHẬN BÁN VÉ'), matching: find.byType(ElevatedButton)),
      );
      expect(btnAfter.onPressed, isNotNull);

      await tester.ensureVisible(find.byKey(const Key('counter_confirm_sale_btn')));
      await tester.tap(find.byKey(const Key('counter_confirm_sale_btn')));
      await tester.pumpAndSettle();

      expect(mockRepo.lastPaymentMethod, 'card');
      expect(find.text('XUẤT VÉ THÀNH CÔNG'), findsOneWidget);
    });
  });
}
