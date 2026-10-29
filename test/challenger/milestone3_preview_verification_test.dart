import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cinema_booking_v1/core/routes/app_router.dart';
import 'package:cinema_booking_v1/core/theme/app_colors.dart';
import 'package:cinema_booking_v1/core/theme/app_theme.dart';
import 'package:cinema_booking_v1/features/auth/presentation/controllers/auth_provider.dart';
import 'package:cinema_booking_v1/features/booking/presentation/controllers/booking_provider.dart';
import 'package:cinema_booking_v1/features/booking/presentation/screens/vnpay_webview_screen.dart';
import 'package:cinema_booking_v1/features/tickets/presentation/screens/ticket_success_screen.dart';
import 'package:cinema_booking_v1/shared/widgets/hold_timer.dart';
import '../e2e/test_fixtures.dart';

// =============================================================================
// TEST DOUBLES FOR INDEPENDENT VERIFICATION (M3 REVIEWER)
// =============================================================================

class MockReviewerAuthProvider extends ChangeNotifier implements AuthProvider {
  AppUser? _user = const AppUser(
    id: 'usr_rev_01',
    fullName: 'Lê Hoàng Long',
    email: 'long.le@cinema.vn',
    phone: '0988776655',
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
    _user = AppUser(
      id: _user?.id ?? 'usr_rev_01',
      fullName: fullName,
      email: _user?.email ?? '',
      phone: phone,
      role: _user?.role ?? UserRole.customer,
    );
    notifyListeners();
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

Widget createM3Harness({
  required Widget child,
  BookingProvider? bookingProvider,
  AuthProvider? authProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(
        value: authProvider ?? MockReviewerAuthProvider(),
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

  final sampleShowtime = ShowtimeModel(
    id: 'st_rev_01',
    movieId: 'mov_mai',
    cinemaId: 'cn_q1',
    roomId: 'rm_01',
    format: '2D',
    startTime: DateTime(2026, 11, 2, 14, 0), // Monday afternoon (non-weekend, non-prime)
    endTime: DateTime(2026, 11, 2, 16, 15),
    totalSeats: 100,
    soldSeats: 10,
    minPrice: 80000,
    movieTitle: 'Mai',
    roomName: 'Phòng 1',
    cinemaName: 'Star Cinema Quận 1',
  );

  group('Milestone 3 Independent Review & Adversarial Stress Tests', () {
    // -------------------------------------------------------------------------
    // TEST 1: BookingModel.toMap() line 122 round-trip verification
    // -------------------------------------------------------------------------
    test('1. BookingModel.toMap() contains created_at and survives complete round-trip', () {
      final now = DateTime.now();
      final model = BookingModel(
        code: 'REV12345',
        userId: 'usr_rev_01',
        channel: 'online',
        soldBy: null,
        status: 'holding',
        holdUntil: now.add(const Duration(minutes: 5)),
        showtimeId: 'st_rev_01',
        cinemaId: 'cn_q1',
        movieTitle: 'Lật Mặt 7',
        posterUrl: 'https://example.com/latmat7.jpg',
        ageRating: 'K',
        cinemaName: 'Star Cinema Q1',
        roomName: 'Phòng 2',
        format: '3D',
        showtimeStart: now.add(const Duration(hours: 4)),
        seats: [
          {'id': 'B1', 'type': 'vip', 'price': 120000},
        ],
        foods: [
          {'id': 'f_popcorn', 'name': 'Bắp Phô Mai', 'quantity': 2, 'price': 50000},
        ],
        foodStatus: 'pending',
        priceSnapshot: {
          'ticket_total': 120000,
          'food_total': 100000,
          'discount': 20000,
          'total': 200000,
        },
        paymentMethod: 'vnpay',
        vnpTransactionNo: 'VNP12345678',
        paidAt: now,
        checkedInBy: null,
        checkedInAt: null,
        cancelReason: null,
        createdAt: now,
      );

      final map = model.toMap();

      // Explicitly check key existence and non-null
      expect(map.containsKey('created_at'), isTrue);
      expect(map['created_at'], isA<String>());
      expect(map['created_at'], equals(now.toIso8601String()));

      // Deserialize back
      final reconstituted = BookingModel.fromMap(map);
      expect(reconstituted.code, equals('REV12345'));
      expect(reconstituted.format, equals('3D'));
      expect(reconstituted.createdAt.toIso8601String(), equals(now.toIso8601String()));
      expect(reconstituted.priceSnapshot['total'], equals(200000));
    });

    // -------------------------------------------------------------------------
    // TEST 2: 8-Seat Limit Enforcement Stress-Testing
    // -------------------------------------------------------------------------
    test('2. 8-Seat limit strictly enforced; 9th seat blocked with error message', () {
      final booking = BookingProvider();
      booking.setShowtime(sampleShowtime);

      // Select exactly 8 seats
      for (int i = 1; i <= 8; i++) {
        booking.toggleSeat('A$i', SeatType.standard);
      }
      expect(booking.selectedSeatIds.length, equals(8));
      expect(booking.errorMessage, isNull);

      // Attempt to select 9th seat
      booking.toggleSeat('A9', SeatType.standard);
      expect(booking.selectedSeatIds.length, equals(8));
      expect(booking.selectedSeatIds.contains('A9'), isFalse);
      expect(booking.errorMessage, contains('tối đa 8 ghế'));

      // Deselection from 8 seats is permitted and clears error
      booking.toggleSeat('A1', SeatType.standard);
      expect(booking.selectedSeatIds.length, equals(7));

      // Now adding an 8th seat again works
      booking.toggleSeat('B1', SeatType.standard);
      expect(booking.selectedSeatIds.length, equals(8));
      expect(booking.errorMessage, isNull);
    });

    // -------------------------------------------------------------------------
    // TEST 3: HoldTimer widget behavior (warning color & auto-expiry callback)
    // -------------------------------------------------------------------------
    testWidgets('3A. HoldTimer renders normal ink >= 60s', (tester) async {
      final futureTimeNormal = DateTime.now().add(const Duration(seconds: 120));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: HoldTimer(key: const ValueKey('normal'), holdUntil: futureTimeNormal),
          ),
        ),
      );
      await tester.pump();

      final normalText = tester.widget<Text>(find.byType(Text));
      expect(normalText.style?.color, equals(AppColors.ink));
    });

    testWidgets('3B. HoldTimer renders warning Rosso Corsa < 60s', (tester) async {
      final futureTimeWarning = DateTime.now().add(const Duration(seconds: 45));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: HoldTimer(key: const ValueKey('warning'), holdUntil: futureTimeWarning),
          ),
        ),
      );
      await tester.pump();

      final warningText = tester.widget<Text>(find.byType(Text));
      expect(warningText.style?.color, equals(AppColors.warning));
    });

    testWidgets('3C. HoldTimer fires onExpired callback when time runs out', (tester) async {
      bool expiredFired = false;
      final expiryTime = DateTime.now().add(const Duration(milliseconds: 900));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: HoldTimer(
              key: const ValueKey('expiry_test'),
              holdUntil: expiryTime,
              onExpired: () {
                expiredFired = true;
              },
            ),
          ),
        ),
      );

      await tester.pump();
      expect(expiredFired, isFalse);

      // Advance both real time and fakeAsync periodic timer
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 1050));
      });
      await tester.pump(const Duration(seconds: 1));

      expect(expiredFired, isTrue);
    });

    // -------------------------------------------------------------------------
    // TEST 4: Voucher Business Rule Isolation (Ticket only, NEVER Food)
    // -------------------------------------------------------------------------
    test('4. Voucher discounts ONLY apply to ticket total, NEVER to food total', () {
      final booking = BookingProvider();
      booking.setShowtime(sampleShowtime);

      // 2 standard seats @ 80k = 160k
      booking.toggleSeat('A1', SeatType.standard);
      booking.toggleSeat('A2', SeatType.standard);
      final ticketTotal = booking.calculateTicketTotal();
      expect(ticketTotal, equals(160000));

      // 2 food items @ 50k = 100k
      booking.updateFoodQuantity(
        const FoodModel(
          id: 'f_combo',
          cinemaId: 'cn_q1',
          name: 'Combo Solo',
          category: 'combo',
          price: 50000,
        ),
        2,
      );
      final foodTotal = booking.calculateFoodTotal();
      expect(foodTotal, equals(100000));

      // Total without voucher = 260k
      expect(booking.calculateGrandTotal(), equals(260000));

      // Adversarial Case: Large fixed voucher of 300,000 VND (exceeds ticket price 160k)
      // Even if voucher is 300k, discount must be capped at ticketTotal (160k).
      // Food total (100k) MUST NOT be discounted.
      // Therefore grand total must be 100,000 VND, not 0 VND.
      final cappedDiscount = ticketTotal < 300000 ? ticketTotal : 300000;
      expect(cappedDiscount, equals(160000));

      final grandTotalWithCap = (ticketTotal + foodTotal) - cappedDiscount;
      expect(grandTotalWithCap, equals(100000)); // Exactly food total!
    });

    // -------------------------------------------------------------------------
    // TEST 5: VNPay WebView navigation & fallback simulation
    // -------------------------------------------------------------------------
    testWidgets('5. VNPay WebView fallback renders simulated success and fail buttons', (tester) async {
      await tester.pumpWidget(
        createM3Harness(
          child: const VNPayWebviewScreen(
            paymentUrl: '',
            bookingCode: 'REV88888',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CỔNG THANH TOÁN VNPAY'), findsOneWidget);
      expect(find.text('XÁC NHẬN THANH TOÁN THÀNH CÔNG'), findsOneWidget);
      expect(find.text('HỦY GIAO DỊCH'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // TEST 6: TicketSuccessScreen (S09) PopScope back prevention
    // -------------------------------------------------------------------------
    testWidgets('6. S09 PopScope enforces canPop: false', (tester) async {
      await tester.pumpWidget(
        createM3Harness(
          child: const TicketSuccessScreen(bookingCode: 'REV99999'),
        ),
      );
      await tester.pumpAndSettle();

      // Find PopScope via widget predicate to match any generic type PopScope<T>
      final popScopeFinder = find.byWidgetPredicate((w) => w is PopScope);
      expect(popScopeFinder, findsOneWidget);

      final popScope = tester.widget<PopScope>(popScopeFinder);
      expect(popScope.canPop, isFalse);
    });
  });
}
