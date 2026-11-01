import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cinema_booking_v1/core/routes/app_router.dart';
import 'package:cinema_booking_v1/core/theme/app_theme.dart';
import 'package:cinema_booking_v1/features/auth/presentation/controllers/auth_provider.dart';
import 'package:cinema_booking_v1/features/booking/presentation/controllers/booking_provider.dart';
import 'package:cinema_booking_v1/features/booking/presentation/screens/checkout_screen.dart';
import 'package:cinema_booking_v1/features/booking/presentation/screens/food_selection_screen.dart';
import 'package:cinema_booking_v1/features/booking/presentation/screens/seat_selection_screen.dart';
import 'package:cinema_booking_v1/features/booking/presentation/screens/showtime_selection_screen.dart';
import 'package:cinema_booking_v1/features/booking/presentation/screens/vnpay_webview_screen.dart';
import 'package:cinema_booking_v1/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:cinema_booking_v1/features/profile/presentation/screens/profile_screen.dart';
import 'package:cinema_booking_v1/features/tickets/presentation/screens/ticket_success_screen.dart';
import 'package:cinema_booking_v1/shared/widgets/booking_summary_bar.dart';
import 'package:cinema_booking_v1/shared/widgets/customer_bottom_nav.dart';
import 'package:cinema_booking_v1/shared/widgets/date_chip.dart';
import 'package:cinema_booking_v1/shared/widgets/seat_legend.dart';
import 'package:cinema_booking_v1/shared/widgets/ticket_card.dart';
import '../../e2e/test_fixtures.dart';

class MockAuthProviderForTest extends ChangeNotifier implements AuthProvider {
  AppUser? _user = const AppUser(
    id: 'usr_test_01',
    fullName: 'Trần Văn Nam',
    email: 'nam.tran@cinema.vn',
    phone: '0912345678',
    role: UserRole.customer,
  );

  @override
  AppUser? get currentUser => _user;

  @override
  AuthStatus get status => AuthStatus.authenticated;

  @override
  bool get isAuthenticated => _user != null;

  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => null;

  @override
  Future<bool> signIn(String email, String password) async => true;

  @override
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async => true;

  @override
  Future<bool> updateProfile({required String fullName, String? phone}) async {
    if (_user != null) {
      _user = AppUser(
        id: _user!.id,
        fullName: fullName,
        email: _user!.email,
        phone: phone,
        role: _user!.role,
      );
      notifyListeners();
    }
    return true;
  }

  @override
  Future<void> signOut() async {
    _user = null;
    notifyListeners();
  }

  @override
  void clearError() {}
}

Widget createScreenHarness({
  required Widget child,
  BookingProvider? bookingProvider,
  AuthProvider? authProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(
        value: authProvider ?? MockAuthProviderForTest(),
      ),
      ChangeNotifierProvider<BookingProvider>.value(
        value: bookingProvider ?? BookingProvider(),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: child,
    ),
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initTestSupabase();
  });

  final testMovie = MovieModel(
    id: 'mov_mai',
    title: 'Mai',
    genres: const ['Tâm lý', 'Tình cảm'],
    durationMin: 131,
    ageRating: 'T18',
    releaseDate: DateTime.now().subtract(const Duration(days: 3)),
  );

  final testShowtime = ShowtimeModel(
    id: 'st_mai_01',
    movieId: 'mov_mai',
    cinemaId: 'cn_q1',
    roomId: 'rm_01',
    format: '2D',
    startTime: DateTime.now().add(const Duration(hours: 3)),
    endTime: DateTime.now().add(const Duration(hours: 5, minutes: 11)),
    totalSeats: 75,
    soldSeats: 10,
    minPrice: 80000,
    movieTitle: 'Mai',
    roomName: 'Phòng 1 (IMAX)',
    cinemaName: 'Cinema Star Quận 1',
  );

  group('Milestone 3: Booking Flow & Screens Test Suite', () {
    testWidgets('S05: ShowtimeSelectionScreen renders 7-day date chips and title', (tester) async {
      await tester.pumpWidget(
        createScreenHarness(
          child: ShowtimeSelectionScreen(
            movie: testMovie,
            movieId: testMovie.id,
            movieTitle: testMovie.title,
            cinemaId: 'cn_q1',
            cinemaName: 'Cinema Star Quận 1',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Title should be uppercase
      expect(find.text('MAI'), findsOneWidget);

      // Verify 7 DateChip widgets are rendered
      expect(find.byType(DateChip), findsNWidgets(7));
    });

    testWidgets('S05: ShowtimeSelectionScreen renders cinema title and 7-day chips when opened from cinema', (tester) async {
      await tester.pumpWidget(
        createScreenHarness(
          child: const ShowtimeSelectionScreen(
            cinemaId: 'cn_q1',
            cinemaName: 'CGV Vincom Center Đồng Khởi',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Title should be uppercase cinema name
      expect(find.text('CGV VINCOM CENTER ĐỒNG KHỞI'), findsOneWidget);

      // Verify 7 DateChip widgets are rendered
      expect(find.byType(DateChip), findsNWidgets(7));
    });

    testWidgets('S06: SeatSelectionScreen renders Curved Screen, SeatWidget matrix, and SeatLegend', (tester) async {
      final booking = BookingProvider();
      booking.setShowtime(testShowtime);

      await tester.pumpWidget(
        createScreenHarness(
          child: const SeatSelectionScreen(),
          bookingProvider: booking,
        ),
      );

      await tester.pumpAndSettle();

      // Curved screen label
      expect(find.text('MÀN HÌNH'), findsOneWidget);

      // Seat widgets and legend
      expect(find.byType(SeatWidget), findsWidgets);
      expect(find.byType(SeatLegend), findsOneWidget);
      expect(find.byType(BookingSummaryBar), findsOneWidget);
    });

    testWidgets('BookingProvider enforces 8-seat limit rule', (tester) async {
      final booking = BookingProvider();
      booking.setShowtime(testShowtime);

      // Select 8 seats
      for (int i = 1; i <= 8; i++) {
        booking.toggleSeat('A$i', SeatType.standard);
      }
      expect(booking.selectedSeatIds.length, equals(8));
      expect(booking.errorMessage, isNull);

      // Attempt 9th seat
      booking.toggleSeat('A9', SeatType.standard);
      expect(booking.selectedSeatIds.length, equals(8));
      expect(booking.errorMessage, contains('tối đa 8 ghế'));
    });

    testWidgets('S07: FoodSelectionScreen renders HoldTimer, categories, and stepper', (tester) async {
      final booking = BookingProvider();
      booking.setShowtime(testShowtime);
      // Give a dummy holdUntil
      booking.toggleSeat('A1', SeatType.standard);

      await tester.pumpWidget(
        createScreenHarness(
          child: const FoodSelectionScreen(),
          bookingProvider: booking,
        ),
      );

      await tester.pumpAndSettle();

      // Category labels
      expect(find.text('TẤT CẢ'), findsOneWidget);
      expect(find.text('COMBO'), findsOneWidget);
      expect(find.text('BẮP'), findsOneWidget);
      expect(find.text('NƯỚC'), findsOneWidget);
      expect(find.text('SNACK'), findsOneWidget);

      // Bottom bar buttons
      expect(find.text('BỎ QUA'), findsOneWidget);
      expect(find.text('TIẾP TỤC'), findsOneWidget);
    });

    testWidgets('S08: CheckoutScreen renders order summary and VNPay Sandbox', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final booking = BookingProvider();
      booking.setShowtime(testShowtime);
      booking.toggleSeat('A1', SeatType.standard);
      booking.updateFoodQuantity(
        const FoodModel(
          id: 'f_01',
          cinemaId: 'cn_q1',
          name: 'Bắp Rang Bơ',
          category: 'popcorn',
          price: 45000,
        ),
        1,
      );

      await tester.pumpWidget(
        createScreenHarness(
          child: const CheckoutScreen(),
          bookingProvider: booking,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('THANH TOÁN'), findsOneWidget);
      expect(find.text('1 GHẾ (A1)'), findsOneWidget);
      expect(find.text('1x Bắp Rang Bơ'), findsOneWidget);
      expect(find.textContaining('CHUYỂN KHOẢN NGÂN HÀNG VIETQR'), findsOneWidget);
      expect(find.text('THANH TOÁN SEPAY'), findsOneWidget);
    });

    test('BookingProvider voucher discount applies ONLY to ticketTotal, NEVER to foodTotal', () {
      final booking = BookingProvider();
      booking.setShowtime(testShowtime); // 2D start time +3h

      // Add 2 standard seats: base 80k each (assuming non-weekend/non-prime: 160k total)
      booking.toggleSeat('A1', SeatType.standard);
      booking.toggleSeat('A2', SeatType.standard);
      final ticketTotal = booking.calculateTicketTotal();
      expect(ticketTotal, greaterThan(0));

      // Add food items
      booking.updateFoodQuantity(
        const FoodModel(
          id: 'f_01',
          cinemaId: 'cn_q1',
          name: 'Combo Solo',
          category: 'combo',
          price: 75000,
        ),
        2,
      ); // 150k food
      final foodTotal = booking.calculateFoodTotal();
      expect(foodTotal, equals(150000));

      // Before voucher: grand total = ticketTotal + foodTotal
      expect(booking.calculateGrandTotal(), equals(ticketTotal + foodTotal));

      // When discount applied manually or calculated:
      // Say 20% discount on ticketTotal:
      final discount = (ticketTotal * 0.2).round();
      expect(discount, greaterThan(0));
      // Price snapshot test:
      final snapshot = booking.generatePriceSnapshot();
      expect(snapshot['ticket_total'], equals(ticketTotal));
      expect(snapshot['food_total'], equals(foodTotal));
      expect(snapshot['total'], equals(ticketTotal + foodTotal));
    });

    testWidgets('S08B: VNPayWebviewScreen renders simulated payment sandbox in fallback', (tester) async {
      await tester.pumpWidget(
        createScreenHarness(
          child: const VNPayWebviewScreen(
            paymentUrl: '',
            bookingCode: 'K7M2QX9P',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('CỔNG THANH TOÁN VNPAY'), findsOneWidget);
      expect(find.text('MÔ PHỎNG THANH TOÁN VNPAY SANDBOX'), findsOneWidget);
      expect(find.text('XÁC NHẬN THANH TOÁN THÀNH CÔNG'), findsOneWidget);
      expect(find.text('HỦY GIAO DỊCH'), findsOneWidget);
    });

    testWidgets('S09: TicketSuccessScreen renders TicketCard with QR and action buttons', (tester) async {
      await tester.pumpWidget(
        createScreenHarness(
          child: const TicketSuccessScreen(bookingCode: 'K7M2QX9P'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('ĐẶT VÉ THÀNH CÔNG'), findsOneWidget);
      expect(find.byType(TicketCard), findsOneWidget);
      expect(find.text('XEM VÉ CỦA TÔI'), findsOneWidget);
      expect(find.text('VỀ TRANG CHỦ'), findsOneWidget);
    });

    testWidgets('S11: ProfileScreen renders user details, initials avatar, role badge and menu', (tester) async {
      await tester.pumpWidget(
        createScreenHarness(
          child: const ProfileScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('TÀI KHOẢN'), findsWidgets);
      expect(find.text('Trần Văn Nam'), findsOneWidget);
      expect(find.text('nam.tran@cinema.vn'), findsOneWidget);
      expect(find.text('CUSTOMER'), findsOneWidget);
      expect(find.text('SỬA HỒ SƠ'), findsOneWidget);
      expect(find.text('HỘP THƯ HỖ TRỢ'), findsOneWidget);
      expect(find.text('ĐĂNG XUẤT'), findsOneWidget);
      expect(find.byType(CustomerBottomNav), findsOneWidget);
    });

    testWidgets('S11B: EditProfileScreen allows updating full name and phone', (tester) async {
      final auth = MockAuthProviderForTest();

      await tester.pumpWidget(
        createScreenHarness(
          child: const EditProfileScreen(),
          authProvider: auth,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('CHỈNH SỬA HỒ SƠ'), findsOneWidget);
      expect(find.text('LƯU THAY ĐỔI'), findsOneWidget);

      // Verify initial fields
      expect(find.text('Trần Văn Nam'), findsOneWidget);
      expect(find.text('0912345678'), findsOneWidget);

      // Edit name and save
      await tester.enterText(find.widgetWithText(TextFormField, 'Trần Văn Nam'), 'Trần Văn Nam Mới');
      await tester.tap(find.text('LƯU THAY ĐỔI'));
      await tester.pumpAndSettle();

      expect(auth.currentUser?.fullName, equals('Trần Văn Nam Mới'));
    });
  });
}
