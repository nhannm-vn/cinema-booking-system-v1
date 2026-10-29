import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cinema_booking_v1/core/config/app_constants.dart';
import 'package:cinema_booking_v1/core/routes/app_router.dart';
import 'package:cinema_booking_v1/core/theme/app_colors.dart';
import 'package:cinema_booking_v1/core/theme/app_theme.dart';
import 'package:cinema_booking_v1/core/utils/date_formatter.dart';
import 'package:cinema_booking_v1/features/auth/presentation/controllers/auth_provider.dart';
import 'package:cinema_booking_v1/features/booking/data/repositories/seat_repository.dart';
import 'package:cinema_booking_v1/features/booking/presentation/controllers/booking_provider.dart';
import 'package:cinema_booking_v1/features/booking/presentation/screens/checkout_screen.dart';
import 'package:cinema_booking_v1/features/booking/presentation/screens/food_selection_screen.dart';
import 'package:cinema_booking_v1/features/booking/presentation/screens/seat_selection_screen.dart';
import 'package:cinema_booking_v1/features/booking/presentation/screens/showtime_selection_screen.dart';
import 'package:cinema_booking_v1/features/booking/presentation/screens/vnpay_webview_screen.dart';
import 'package:cinema_booking_v1/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:cinema_booking_v1/features/profile/presentation/screens/profile_screen.dart';
import 'package:cinema_booking_v1/features/tickets/presentation/screens/ticket_success_screen.dart';
import 'package:cinema_booking_v1/shared/widgets/hold_timer.dart';
import '../e2e/test_fixtures.dart';

// =============================================================================
// MOCK & FAKE INFRASTRUCTURE FOR ADVERSARIAL STRESS TESTING
// =============================================================================

class MockAuthProviderForChallenger extends ChangeNotifier implements AuthProvider {
  AppUser? _user = const AppUser(
    id: 'usr_challenger_01',
    fullName: 'Challenger Customer',
    email: 'challenger@cinema.vn',
    phone: '0901234567',
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
        phone: phone ?? _user!.phone,
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

class FakeSeatRepository extends Fake implements SeatRepository {
  DateTime returnedHoldUntil = DateTime.now().add(const Duration(minutes: 5));
  bool releaseCalled = false;
  String? lastBookingCode;

  @override
  Future<DateTime> holdSeats({
    required String showtimeId,
    required String bookingCode,
    required List<String> seatIds,
    required Map<String, dynamic> booking,
    int holdMinutes = 5,
  }) async {
    lastBookingCode = bookingCode;
    return returnedHoldUntil;
  }

  @override
  Future<void> releaseHold(String bookingCode) async {
    releaseCalled = true;
    lastBookingCode = bookingCode;
  }
}

class MockSupabaseClient extends Fake implements SupabaseClient {
  final Map<String, dynamic>? voucherData;
  final bool shouldThrow;

  MockSupabaseClient({this.voucherData, this.shouldThrow = false});

  @override
  SupabaseQueryBuilder from(String table) {
    if (shouldThrow) throw Exception('DB connection failed');
    return MockSupabaseQueryBuilder(voucherData);
  }
}

class MockSupabaseQueryBuilder extends Fake implements SupabaseQueryBuilder {
  final Map<String, dynamic>? voucherData;

  MockSupabaseQueryBuilder(this.voucherData);

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select([String columns = '*']) {
    return MockPostgrestFilterBuilder(voucherData);
  }
}

class MockPostgrestFilterBuilder extends Fake
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  final Map<String, dynamic>? voucherData;

  MockPostgrestFilterBuilder(this.voucherData);

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> eq(String column, Object value) {
    return this;
  }

  @override
  PostgrestTransformBuilder<Map<String, dynamic>?> maybeSingle() {
    return MockPostgrestTransformBuilder(voucherData);
  }
}

class MockPostgrestTransformBuilder extends Fake
    implements PostgrestTransformBuilder<Map<String, dynamic>?> {
  final Map<String, dynamic>? voucherData;

  MockPostgrestTransformBuilder(this.voucherData);

  @override
  Future<U> then<U>(
    FutureOr<U> Function(Map<String, dynamic>? value) onValue, {
    Function? onError,
  }) {
    return Future<Map<String, dynamic>?>.value(voucherData).then(onValue, onError: onError);
  }
}

Widget createTestWrapper({
  required Widget child,
  BookingProvider? bookingProvider,
  AuthProvider? authProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(
        value: authProvider ?? MockAuthProviderForChallenger(),
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

// =============================================================================
// EMPIRICAL VERIFICATION SUITE
// =============================================================================

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initTestSupabase();
  });

  final testMovie = MovieModel(
    id: 'mov_mai_01',
    title: 'Mai',
    genres: const ['Tâm lý', 'Tình cảm'],
    durationMin: 131,
    ageRating: 'T18',
    releaseDate: DateTime.now().subtract(const Duration(days: 5)),
  );

  final testShowtime = ShowtimeModel(
    id: 'st_mai_challenger',
    movieId: 'mov_mai_01',
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

  // ---------------------------------------------------------------------------
  // REQUIREMENT 1: BookingModel round-trip serialization (fromMap(toMap()))
  // ---------------------------------------------------------------------------
  group('1. BookingModel Round-Trip Serialization & Invariant Fidelity', () {
    test('1.1 Round-trip with FULL optional fields populated preserves all data', () {
      final now = DateTime.now();
      final holdUntil = now.add(const Duration(minutes: 5));
      final showtimeStart = now.add(const Duration(hours: 4));
      final paidAt = now.subtract(const Duration(minutes: 10));
      final checkedInAt = now.subtract(const Duration(minutes: 2));

      final original = BookingModel(
        code: 'K7M2QX9P',
        userId: 'usr_challenger_99',
        channel: 'counter',
        soldBy: 'emp_staff_01',
        status: 'used',
        holdUntil: holdUntil,
        showtimeId: 'st_mai_challenger',
        cinemaId: 'cn_q1',
        movieTitle: 'Mai - Bản Đặc Biệt',
        posterUrl: 'https://example.com/mai_poster.jpg',
        ageRating: 'T18',
        cinemaName: 'Cinema Star Quận 1',
        roomName: 'Phòng 1 (IMAX)',
        format: '3D',
        showtimeStart: showtimeStart,
        seats: [
          {'id': 'B3', 'type': 'vip', 'price': 100000},
          {'id': 'B4', 'type': 'vip', 'price': 100000},
          {'id': 'C1', 'type': 'couple', 'price': 180000},
        ],
        foods: [
          {'id': 'f_01', 'name': 'Combo 2 Người', 'qty': 1, 'price': 110000},
          {'id': 'f_02', 'name': 'Nước Suối', 'qty': 2, 'price': 20000},
        ],
        foodStatus: 'delivered',
        priceSnapshot: {
          'ticket_total': 380000,
          'food_total': 150000,
          'discount': 38000,
          'total': 492000,
        },
        paymentMethod: 'vnpay',
        vnpTransactionNo: 'VNP14882903',
        paidAt: paidAt,
        checkedInBy: 'emp_checker_02',
        checkedInAt: checkedInAt,
        cancelReason: 'Khách đổi giờ chiếu',
        createdAt: now,
      );

      final map = original.toMap();
      final reconstituted = BookingModel.fromMap(map);

      // Verify every field
      expect(reconstituted.code, equals(original.code));
      expect(reconstituted.userId, equals(original.userId));
      expect(reconstituted.channel, equals('counter'));
      expect(reconstituted.soldBy, equals('emp_staff_01'));
      expect(reconstituted.status, equals('used'));
      expect(reconstituted.holdUntil?.toIso8601String(), equals(original.holdUntil?.toIso8601String()));
      expect(reconstituted.showtimeId, equals(original.showtimeId));
      expect(reconstituted.cinemaId, equals(original.cinemaId));
      expect(reconstituted.movieTitle, equals(original.movieTitle));
      expect(reconstituted.posterUrl, equals(original.posterUrl));
      expect(reconstituted.ageRating, equals(original.ageRating));
      expect(reconstituted.cinemaName, equals(original.cinemaName));
      expect(reconstituted.roomName, equals(original.roomName));
      expect(reconstituted.format, equals('3D'));
      expect(reconstituted.showtimeStart.toIso8601String(), equals(original.showtimeStart.toIso8601String()));
      expect(reconstituted.seats.length, equals(3));
      expect(reconstituted.seats[0]['id'], equals('B3'));
      expect(reconstituted.seats[2]['type'], equals('couple'));
      expect(reconstituted.foods.length, equals(2));
      expect(reconstituted.foods[0]['name'], equals('Combo 2 Người'));
      expect(reconstituted.foodStatus, equals('delivered'));
      expect(reconstituted.priceSnapshot['total'], equals(492000));
      expect(reconstituted.paymentMethod, equals('vnpay'));
      expect(reconstituted.vnpTransactionNo, equals('VNP14882903'));
      expect(reconstituted.paidAt?.toIso8601String(), equals(original.paidAt?.toIso8601String()));
      expect(reconstituted.checkedInBy, equals('emp_checker_02'));
      expect(reconstituted.checkedInAt?.toIso8601String(), equals(original.checkedInAt?.toIso8601String()));
      expect(reconstituted.cancelReason, equals('Khách đổi giờ chiếu'));
      expect(reconstituted.createdAt.toIso8601String(), equals(original.createdAt.toIso8601String()));

      // Getters verification
      expect(reconstituted.totalAmount, equals(492000));
      expect(reconstituted.ticketTotal, equals(380000));
      expect(reconstituted.foodTotal, equals(150000));
      expect(reconstituted.discount, equals(38000));
      expect(reconstituted.seatNamesSummary, equals('B3, B4, C1'));
      expect(reconstituted.foodSummary, equals('1x Combo 2 Người, 2x Nước Suối'));
    });

    test('1.2 Round-trip with MINIMAL fields (all optional fields null or defaults)', () {
      final now = DateTime.now();
      final original = BookingModel(
        code: 'MINIMAL8',
        status: 'holding',
        showtimeId: 'st_01',
        cinemaId: 'cn_01',
        movieTitle: 'Minimal Movie',
        cinemaName: 'Minimal Cinema',
        roomName: 'Phòng 2',
        format: '2D',
        showtimeStart: now.add(const Duration(hours: 1)),
        priceSnapshot: const {},
        createdAt: now,
      );

      final map = original.toMap();
      expect(map['user_id'], isNull);
      expect(map['sold_by'], isNull);
      expect(map['hold_until'], isNull);
      expect(map['poster_url'], isNull);
      expect(map['age_rating'], isNull);
      expect(map['payment_method'], isNull);
      expect(map['vnp_transaction_no'], isNull);
      expect(map['paid_at'], isNull);
      expect(map['checked_in_by'], isNull);
      expect(map['checked_in_at'], isNull);
      expect(map['cancel_reason'], isNull);
      expect(map['seats'], isEmpty);
      expect(map['foods'], isEmpty);
      expect(map['channel'], equals('online'));
      expect(map['food_status'], equals('none'));
      expect(map['created_at'], isNotNull);

      final reconstituted = BookingModel.fromMap(map);
      expect(reconstituted.code, equals('MINIMAL8'));
      expect(reconstituted.userId, isNull);
      expect(reconstituted.soldBy, isNull);
      expect(reconstituted.holdUntil, isNull);
      expect(reconstituted.posterUrl, isNull);
      expect(reconstituted.ageRating, isNull);
      expect(reconstituted.paymentMethod, isNull);
      expect(reconstituted.vnpTransactionNo, isNull);
      expect(reconstituted.paidAt, isNull);
      expect(reconstituted.checkedInBy, isNull);
      expect(reconstituted.checkedInAt, isNull);
      expect(reconstituted.cancelReason, isNull);
      expect(reconstituted.seats, isEmpty);
      expect(reconstituted.foods, isEmpty);
      expect(reconstituted.totalAmount, equals(0));
      expect(reconstituted.ticketTotal, equals(0));
      expect(reconstituted.foodTotal, equals(0));
      expect(reconstituted.discount, equals(0));
      expect(reconstituted.seatNamesSummary, isEmpty);
      expect(reconstituted.foodSummary, isEmpty);
    });

    test('1.3 Resiliency: fromMap handles omitted keys gracefully without throw', () {
      final now = DateTime.now();
      final mapWithMissingKeys = {
        'code': 'PARTIAL1',
        'status': 'paid',
        'showtime_id': 'st_part',
        'cinema_id': 'cn_part',
        'movie_title': 'Partial Title',
        'cinema_name': 'Partial Cinema',
        'room_name': 'Room P',
        'showtime_start': now.toIso8601String(),
        'created_at': now.toIso8601String(),
        // channel, format, food_status, seats, foods, price_snapshot omitted
      };

      final model = BookingModel.fromMap(mapWithMissingKeys);
      expect(model.channel, equals('online'));
      expect(model.format, equals('2D'));
      expect(model.foodStatus, equals('none'));
      expect(model.seats, isEmpty);
      expect(model.foods, isEmpty);
      expect(model.priceSnapshot, isEmpty);
      expect(model.totalAmount, equals(0));
    });

    test('1.4 Business rule getters: isNoShow, canCancel, and displayStatus state machine', () {
      final now = DateTime.now();

      // Case A: No-show (paid + not checked in + 16 mins after showtime start)
      final noShowBooking = BookingModel(
        code: 'NOSHOW01',
        status: 'paid',
        showtimeId: 'st_01',
        cinemaId: 'cn_01',
        movieTitle: 'Mai',
        cinemaName: 'Cinema 1',
        roomName: 'R1',
        format: '2D',
        showtimeStart: now.subtract(const Duration(minutes: 16)),
        checkedInAt: null,
        priceSnapshot: const {'total': 100000},
        createdAt: now.subtract(const Duration(hours: 1)),
      );
      expect(noShowBooking.isNoShow, isTrue);
      expect(noShowBooking.displayStatus, equals('noShow'));

      // Case B: Not no-show (paid + not checked in + only 10 mins after start)
      final withinGraceBooking = BookingModel(
        code: 'GRACE001',
        status: 'paid',
        showtimeId: 'st_01',
        cinemaId: 'cn_01',
        movieTitle: 'Mai',
        cinemaName: 'Cinema 1',
        roomName: 'R1',
        format: '2D',
        showtimeStart: now.subtract(const Duration(minutes: 10)),
        checkedInAt: null,
        priceSnapshot: const {'total': 100000},
        createdAt: now.subtract(const Duration(hours: 1)),
      );
      expect(withinGraceBooking.isNoShow, isFalse);
      expect(withinGraceBooking.displayStatus, equals('paid'));

      // Case C: Checked in already (never no-show even 30 mins after start)
      final checkedInBooking = BookingModel(
        code: 'CHECKD01',
        status: 'paid',
        showtimeId: 'st_01',
        cinemaId: 'cn_01',
        movieTitle: 'Mai',
        cinemaName: 'Cinema 1',
        roomName: 'R1',
        format: '2D',
        showtimeStart: now.subtract(const Duration(minutes: 30)),
        checkedInAt: now.subtract(const Duration(minutes: 35)),
        priceSnapshot: const {'total': 100000},
        createdAt: now.subtract(const Duration(hours: 2)),
      );
      expect(checkedInBooking.isNoShow, isFalse);

      // Case D: canCancel rule (paid + showtimeStart >= 2 hours away)
      final canCancelBooking = BookingModel(
        code: 'CANCEL01',
        status: 'paid',
        showtimeId: 'st_01',
        cinemaId: 'cn_01',
        movieTitle: 'Mai',
        cinemaName: 'Cinema 1',
        roomName: 'R1',
        format: '2D',
        showtimeStart: now.add(const Duration(hours: 3)),
        priceSnapshot: const {'total': 100000},
        createdAt: now,
      );
      expect(canCancelBooking.canCancel, isTrue);

      // Case E: cannot cancel if under 2 hours
      final cannotCancelBooking = BookingModel(
        code: 'NOCANC01',
        status: 'paid',
        showtimeId: 'st_01',
        cinemaId: 'cn_01',
        movieTitle: 'Mai',
        cinemaName: 'Cinema 1',
        roomName: 'R1',
        format: '2D',
        showtimeStart: now.add(const Duration(hours: 1, minutes: 30)),
        priceSnapshot: const {'total': 100000},
        createdAt: now,
      );
      expect(cannotCancelBooking.canCancel, isFalse);

      // Case F: holding expired display status
      final expiredHoldingBooking = BookingModel(
        code: 'EXPIRE01',
        status: 'holding',
        showtimeId: 'st_01',
        cinemaId: 'cn_01',
        movieTitle: 'Mai',
        cinemaName: 'Cinema 1',
        roomName: 'R1',
        format: '2D',
        showtimeStart: now.add(const Duration(hours: 2)),
        holdUntil: now.subtract(const Duration(seconds: 1)),
        priceSnapshot: const {},
        createdAt: now.subtract(const Duration(minutes: 6)),
      );
      expect(expiredHoldingBooking.displayStatus, equals('expired'));
    });
  });

  // ---------------------------------------------------------------------------
  // REQUIREMENT 2: 8-seat limit boundary stress testing
  // ---------------------------------------------------------------------------
  group('2. 8-Seat Limit Boundary Stress Testing', () {
    test('2.1 Sequential addition 1..8 succeeds; 9th seat is rejected with explicit error', () {
      final booking = BookingProvider();
      booking.setShowtime(testShowtime);

      // Step 1: Select 8 seats sequentially
      for (int i = 1; i <= AppConstants.maxSeatsPerBooking; i++) {
        booking.toggleSeat('A$i', SeatType.standard);
        expect(booking.selectedSeatIds.length, equals(i));
        expect(booking.errorMessage, isNull,
            reason: 'Selecting seat $i of 8 should succeed without error');
      }

      expect(booking.selectedSeatIds, equals(['A1', 'A2', 'A3', 'A4', 'A5', 'A6', 'A7', 'A8']));

      // Step 2: Attempt 9th seat ('A9') -> MUST BE REJECTED
      booking.toggleSeat('A9', SeatType.standard);
      expect(booking.selectedSeatIds.length, equals(8),
          reason: 'Seat count must strictly remain 8');
      expect(booking.selectedSeatIds.contains('A9'), isFalse,
          reason: '9th seat must not be registered');
      expect(booking.errorMessage, isNotNull);
      expect(booking.errorMessage, contains('tối đa 8 ghế'));

      // Step 3: Attempt 10th seat ('A10') -> ALSO MUST BE REJECTED
      booking.toggleSeat('A10', SeatType.vip);
      expect(booking.selectedSeatIds.length, equals(8));
      expect(booking.selectedSeatIds.contains('A10'), isFalse);
      expect(booking.errorMessage, contains('tối đa 8 ghế'));

      // Step 4: Deselect 1 seat ('A8') -> Count drops to 7
      booking.toggleSeat('A8', SeatType.standard);
      expect(booking.selectedSeatIds.length, equals(7));
      expect(booking.selectedSeatIds.contains('A8'), isFalse);

      // Step 5: Now selecting a new 8th seat ('B1') must SUCCEED and clear error
      booking.toggleSeat('B1', SeatType.standard);
      expect(booking.selectedSeatIds.length, equals(8));
      expect(booking.selectedSeatIds.contains('B1'), isTrue);
      expect(booking.errorMessage, isNull);
    });

    test('2.2 Rapid toggle idempotency and reset clears state cleanly', () {
      final booking = BookingProvider();
      booking.setShowtime(testShowtime);

      // Rapidly toggle the same seat 5 times
      for (int i = 1; i <= 5; i++) {
        booking.toggleSeat('C5', SeatType.vip);
        if (i.isOdd) {
          expect(booking.selectedSeatIds, contains('C5'));
        } else {
          expect(booking.selectedSeatIds, isNot(contains('C5')));
        }
      }
      expect(booking.selectedSeatIds.length, equals(1));

      // Reset
      booking.reset();
      expect(booking.selectedShowtime, isNull);
      expect(booking.selectedSeatIds, isEmpty);
      expect(booking.selectedFoods, isEmpty);
      expect(booking.errorMessage, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // REQUIREMENT 3: Voucher calculations & isolation from foodTotal
  // ---------------------------------------------------------------------------
  group('3. Voucher Calculations & Strict Isolation From Concessions', () {
    test('3.1 Percentage discount applies strictly to ticketTotal; foodTotal untouched', () async {
      // Setup mock Supabase returning 20% percent voucher
      final mockClient = MockSupabaseClient(voucherData: {
        'code': 'DISCOUNT20',
        'type': 'percent',
        'value': 20,
        'is_active': true,
        'max_uses': 100,
        'used_count': 10,
        'expires_at': DateTime.now().add(const Duration(days: 10)).toIso8601String(),
      });

      final booking = BookingProvider(null, mockClient);
      booking.setShowtime(testShowtime);

      // 2 standard seats: 80,000 * 2 = 160,000 (ticketTotal)
      booking.toggleSeat('A1', SeatType.standard);
      booking.toggleSeat('A2', SeatType.standard);
      final ticketTotal = booking.calculateTicketTotal();
      expect(ticketTotal, equals(160000));

      // Add foods: 2x Combo Solo @ 75,000 = 150,000 (foodTotal)
      booking.updateFoodQuantity(
        const FoodModel(
          id: 'f_01',
          cinemaId: 'cn_q1',
          name: 'Combo Solo',
          category: 'combo',
          price: 75000,
        ),
        2,
      );
      final foodTotal = booking.calculateFoodTotal();
      expect(foodTotal, equals(150000));

      // Apply 20% voucher
      final applied = await booking.applyVoucher('DISCOUNT20');
      expect(applied, isTrue);
      expect(booking.appliedVoucherCode, equals('DISCOUNT20'));
      expect(booking.voucherError, isNull);

      // Verification:
      // Discount = 20% of 160,000 = 32,000 VND
      expect(booking.discount, equals(32000));

      // Grand total = (160,000 - 32,000) + 150,000 = 128,000 + 150,000 = 278,000 VND
      expect(booking.calculateGrandTotal(), equals(278000));

      // Verify price snapshot dictionary
      final snapshot = booking.generatePriceSnapshot();
      expect(snapshot['ticket_total'], equals(160000));
      expect(snapshot['food_total'], equals(150000));
      expect(snapshot['discount'], equals(32000));
      expect(snapshot['total'], equals(278000));
    });

    test('3.2 100% percentage discount zeros out tickets, but leaves foodTotal intact', () async {
      final mockClient = MockSupabaseClient(voucherData: {
        'code': 'FREE100',
        'type': 'percent',
        'value': 100,
        'is_active': true,
      });

      final booking = BookingProvider(null, mockClient);
      booking.setShowtime(testShowtime);

      booking.toggleSeat('A1', SeatType.standard);
      final ticketTotal = booking.calculateTicketTotal(); // 80,000

      booking.updateFoodQuantity(
        const FoodModel(id: 'f_01', cinemaId: 'cn_q1', name: 'Bắp', category: 'popcorn', price: 50000),
        1,
      ); // 50,000 food

      await booking.applyVoucher('FREE100');
      expect(booking.discount, equals(ticketTotal));
      // Ticket is free, but customer MUST still pay 50,000 food
      expect(booking.calculateGrandTotal(), equals(50000));
    });

    test('3.3 Fixed amount discount < ticketTotal discounts tickets; foodTotal untouched', () async {
      final mockClient = MockSupabaseClient(voucherData: {
        'code': 'FIXED50K',
        'type': 'amount',
        'value': 50000,
        'is_active': true,
      });

      final booking = BookingProvider(null, mockClient);
      booking.setShowtime(testShowtime);

      booking.toggleSeat('A1', SeatType.standard);
      booking.toggleSeat('A2', SeatType.standard); // 160,000 tickets

      booking.updateFoodQuantity(
        const FoodModel(id: 'f_01', cinemaId: 'cn_q1', name: 'Nước', category: 'drink', price: 30000),
        2,
      ); // 60,000 food

      await booking.applyVoucher('FIXED50K');
      expect(booking.discount, equals(50000));
      // Grand total = (160,000 - 50,000) + 60,000 = 170,000 VND
      expect(booking.calculateGrandTotal(), equals(170000));
    });

    test('3.4 STRESS: Fixed amount voucher EXCEEDING ticketTotal is strictly capped at ticketTotal', () async {
      // 500,000 VND voucher applied to 80,000 VND tickets + 200,000 VND food
      final mockClient = MockSupabaseClient(voucherData: {
        'code': 'HUGE500K',
        'type': 'amount',
        'value': 500000,
        'is_active': true,
      });

      final booking = BookingProvider(null, mockClient);
      booking.setShowtime(testShowtime);

      booking.toggleSeat('A1', SeatType.standard); // 80,000 ticket
      booking.updateFoodQuantity(
        const FoodModel(id: 'f_01', cinemaId: 'cn_q1', name: 'Combo Đôi', category: 'combo', price: 200000),
        1,
      ); // 200,000 food

      await booking.applyVoucher('HUGE500K');

      // CRITICAL ORACLE: Discount MUST NOT exceed 80,000 VND
      expect(booking.discount, equals(80000),
          reason: 'Voucher discount must be capped at ticketTotal: min(80000, 500000) = 80000');

      // The remaining 420,000 VND voucher value must NEVER bleed into foodTotal!
      // Grand total MUST be 200,000 VND (NOT 0 VND, and NOT negative!)
      expect(booking.calculateGrandTotal(), equals(200000),
          reason: 'Concession total must remain 200,000 VND and not be discounted by ticket voucher');

      // Remove voucher restores original total
      booking.removeVoucher();
      expect(booking.appliedVoucherCode, isNull);
      expect(booking.discount, equals(0));
      expect(booking.calculateGrandTotal(), equals(280000));
    });

    test('3.5 Voucher validation failure modes: empty, inactive, expired, max uses exceeded', () async {
      final booking = BookingProvider();
      booking.setShowtime(testShowtime);

      // 1. Empty code
      final emptyResult = await booking.applyVoucher('');
      expect(emptyResult, isFalse);
      expect(booking.voucherError, equals('Vui lòng nhập mã giảm giá.'));

      // 2. Whitespace code
      final spaceResult = await booking.applyVoucher('   ');
      expect(spaceResult, isFalse);
      expect(booking.voucherError, equals('Vui lòng nhập mã giảm giá.'));

      // 3. Voucher not found in DB
      final notFoundClient = MockSupabaseClient(voucherData: null);
      final notFoundBooking = BookingProvider(null, notFoundClient);
      final nfResult = await notFoundBooking.applyVoucher('NONEXISTENT');
      expect(nfResult, isFalse);
      expect(notFoundBooking.voucherError, equals('Mã giảm giá không tồn tại.'));

      // 4. Inactive voucher
      final inactiveClient = MockSupabaseClient(voucherData: {
        'code': 'DISABLED',
        'is_active': false,
      });
      final inactiveBooking = BookingProvider(null, inactiveClient);
      final inResult = await inactiveBooking.applyVoucher('DISABLED');
      expect(inResult, isFalse);
      expect(inactiveBooking.voucherError, equals('Mã giảm giá không còn hoạt động.'));

      // 5. Expired voucher
      final expiredClient = MockSupabaseClient(voucherData: {
        'code': 'OLDVOUCHER',
        'is_active': true,
        'expires_at': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
      });
      final expiredBooking = BookingProvider(null, expiredClient);
      final expResult = await expiredBooking.applyVoucher('OLDVOUCHER');
      expect(expResult, isFalse);
      expect(expiredBooking.voucherError, equals('Mã giảm giá đã hết hạn.'));

      // 6. Max uses reached
      final maxUsesClient = MockSupabaseClient(voucherData: {
        'code': 'DEPLETED',
        'is_active': true,
        'max_uses': 50,
        'used_count': 50,
      });
      final maxUsesBooking = BookingProvider(null, maxUsesClient);
      final muResult = await maxUsesBooking.applyVoucher('DEPLETED');
      expect(muResult, isFalse);
      expect(maxUsesBooking.voucherError, equals('Mã giảm giá đã hết lượt sử dụng.'));
    });
  });

  // ---------------------------------------------------------------------------
  // REQUIREMENT 4: HoldTimer calculation & duration remaining
  // ---------------------------------------------------------------------------
  group('4. HoldTimer Duration & Remaining Calculations', () {
    test('4.1 DateFormatter.formatTimer boundary and format checks', () {
      expect(DateFormatter.formatTimer(Duration.zero), equals('00:00'));
      expect(DateFormatter.formatTimer(const Duration(seconds: -10)), equals('00:00'));
      expect(DateFormatter.formatTimer(const Duration(seconds: 1)), equals('00:01'));
      expect(DateFormatter.formatTimer(const Duration(seconds: 9)), equals('00:09'));
      expect(DateFormatter.formatTimer(const Duration(seconds: 59)), equals('00:59'));
      expect(DateFormatter.formatTimer(const Duration(seconds: 60)), equals('01:00'));
      expect(DateFormatter.formatTimer(const Duration(minutes: 4, seconds: 32)), equals('04:32'));
      expect(DateFormatter.formatTimer(const Duration(minutes: 9, seconds: 59)), equals('09:59'));
      expect(DateFormatter.formatTimer(const Duration(minutes: 10, seconds: 0)), equals('10:00'));
    });

    testWidgets('4.2 HoldTimer renders ink color when remaining >= 60 seconds', (tester) async {
      final holdUntil = DateTime.now().add(const Duration(minutes: 4, seconds: 30));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: HoldTimer(holdUntil: holdUntil),
          ),
        ),
      );

      await tester.pump();

      // Find timer text
      final textFinder = find.textContaining('GIỮ GHẾ CÒN');
      expect(textFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.style?.color, equals(AppColors.ink));

      final iconFinder = find.byIcon(Icons.access_time_filled);
      expect(iconFinder, findsOneWidget);
      final iconWidget = tester.widget<Icon>(iconFinder);
      expect(iconWidget.color, equals(AppColors.ink));
    });

    testWidgets('4.3 HoldTimer switches to warning color when remaining < 60 seconds', (tester) async {
      final holdUntil = DateTime.now().add(const Duration(seconds: 45));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: HoldTimer(holdUntil: holdUntil),
          ),
        ),
      );

      await tester.pump();

      final textFinder = find.textContaining('GIỮ GHẾ CÒN 00:4');
      expect(textFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.style?.color, equals(AppColors.warning));

      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.access_time_filled));
      expect(iconWidget.color, equals(AppColors.warning));
    });

    testWidgets('4.4 HoldTimer counts down and fires onExpired callback at 0', (tester) async {
      bool expiredCalled = false;
      // Expires in 50ms
      final holdUntil = DateTime.now().add(const Duration(milliseconds: 50));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: HoldTimer(
              holdUntil: holdUntil,
              onExpired: () => expiredCalled = true,
            ),
          ),
        ),
      );

      await tester.pump();
      expect(expiredCalled, isFalse);

      // Advance real time past holdUntil
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 100));
      });

      // Pump 1 second for the periodic timer tick
      await tester.pump(const Duration(seconds: 1));
      expect(expiredCalled, isTrue);
      expect(find.text('GIỮ GHẾ CÒN 00:00'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // REQUIREMENT 5: Route resolution in AppRouter for all Milestone 3 routes
  // ---------------------------------------------------------------------------
  group('5. AppRouter Milestone 3 Route Resolution', () {
    testWidgets('5.1 /showtimes resolves with various argument types without throw', (tester) async {
      // 1. With MovieModel
      final route1 = AppRouter.onGenerateRoute(
        RouteSettings(name: AppRoutes.showtimes, arguments: testMovie),
      ) as MaterialPageRoute;
      expect(route1.settings.name, equals(AppRoutes.showtimes));

      await tester.pumpWidget(
        createTestWrapper(child: Builder(builder: (c) => route1.builder(c))),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ShowtimeSelectionScreen), findsOneWidget);

      // 2. With String movieId
      final route2 = AppRouter.onGenerateRoute(
        const RouteSettings(name: AppRoutes.showtimes, arguments: 'mov_mai_01'),
      ) as MaterialPageRoute;
      await tester.pumpWidget(
        createTestWrapper(child: Builder(builder: (c) => route2.builder(c))),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ShowtimeSelectionScreen), findsOneWidget);

      // 3. With Map arguments
      final route3 = AppRouter.onGenerateRoute(
        const RouteSettings(
          name: AppRoutes.showtimes,
          arguments: {
            'movieId': 'mov_01',
            'movieTitle': 'Lật Mặt 7',
            'cinemaId': 'cn_q1',
            'cinemaName': 'Cinema Star Quận 1',
          },
        ),
      ) as MaterialPageRoute;
      await tester.pumpWidget(
        createTestWrapper(child: Builder(builder: (c) => route3.builder(c))),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ShowtimeSelectionScreen), findsOneWidget);
    });

    testWidgets('5.2 /seat-select resolves to SeatSelectionScreen', (tester) async {
      final route = AppRouter.onGenerateRoute(
        const RouteSettings(name: AppRoutes.seatSelect),
      ) as MaterialPageRoute;
      expect(route.settings.name, equals(AppRoutes.seatSelect));

      final booking = BookingProvider();
      booking.setShowtime(testShowtime);

      await tester.pumpWidget(
        createTestWrapper(
          child: Builder(builder: (c) => route.builder(c)),
          bookingProvider: booking,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SeatSelectionScreen), findsOneWidget);
    });

    testWidgets('5.3 /food-select resolves to FoodSelectionScreen', (tester) async {
      final route = AppRouter.onGenerateRoute(
        const RouteSettings(name: AppRoutes.foodSelect),
      ) as MaterialPageRoute;
      expect(route.settings.name, equals(AppRoutes.foodSelect));

      final booking = BookingProvider();
      booking.setShowtime(testShowtime);

      await tester.pumpWidget(
        createTestWrapper(
          child: Builder(builder: (c) => route.builder(c)),
          bookingProvider: booking,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FoodSelectionScreen), findsOneWidget);
    });

    testWidgets('5.4 /checkout resolves to CheckoutScreen', (tester) async {
      final route = AppRouter.onGenerateRoute(
        const RouteSettings(name: AppRoutes.checkout),
      ) as MaterialPageRoute;
      expect(route.settings.name, equals(AppRoutes.checkout));

      final booking = BookingProvider();
      booking.setShowtime(testShowtime);
      booking.toggleSeat('A1', SeatType.standard);

      await tester.pumpWidget(
        createTestWrapper(
          child: Builder(builder: (c) => route.builder(c)),
          bookingProvider: booking,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CheckoutScreen), findsOneWidget);
    });

    testWidgets('5.5 /vnpay-webview resolves to VNPayWebviewScreen with map arguments', (tester) async {
      final route = AppRouter.onGenerateRoute(
        const RouteSettings(
          name: AppRoutes.vnpayWebview,
          arguments: {
            'paymentUrl': 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html?test=1',
            'bookingCode': 'CHALLENG',
            'txnRef': 'TXN_998877',
          },
        ),
      ) as MaterialPageRoute;
      expect(route.settings.name, equals(AppRoutes.vnpayWebview));

      await tester.pumpWidget(
        createTestWrapper(child: Builder(builder: (c) => route.builder(c))),
      );
      await tester.pumpAndSettle();
      expect(find.byType(VNPayWebviewScreen), findsOneWidget);
    });

    testWidgets('5.6 /ticket-success resolves to TicketSuccessScreen with bookingCode', (tester) async {
      final route = AppRouter.onGenerateRoute(
        const RouteSettings(
          name: AppRoutes.ticketSuccess,
          arguments: 'CHALLENG',
        ),
      ) as MaterialPageRoute;
      expect(route.settings.name, equals(AppRoutes.ticketSuccess));

      await tester.pumpWidget(
        createTestWrapper(child: Builder(builder: (c) => route.builder(c))),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TicketSuccessScreen), findsOneWidget);
    });

    testWidgets('5.7 /profile resolves to ProfileScreen', (tester) async {
      final route = AppRouter.onGenerateRoute(
        const RouteSettings(name: AppRoutes.profile),
      ) as MaterialPageRoute;
      expect(route.settings.name, equals(AppRoutes.profile));

      await tester.pumpWidget(
        createTestWrapper(child: Builder(builder: (c) => route.builder(c))),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('5.8 /edit-profile resolves to EditProfileScreen', (tester) async {
      final route = AppRouter.onGenerateRoute(
        const RouteSettings(name: AppRoutes.editProfile),
      ) as MaterialPageRoute;
      expect(route.settings.name, equals(AppRoutes.editProfile));

      await tester.pumpWidget(
        createTestWrapper(child: Builder(builder: (c) => route.builder(c))),
      );
      await tester.pumpAndSettle();
      expect(find.byType(EditProfileScreen), findsOneWidget);
    });
  });
}
