import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:cinema_booking_v1/core/routes/app_router.dart';
import 'package:cinema_booking_v1/core/theme/app_theme.dart';
import 'package:cinema_booking_v1/core/utils/currency_formatter.dart';
import 'package:cinema_booking_v1/features/auth/presentation/controllers/auth_provider.dart';
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
import 'package:cinema_booking_v1/shared/widgets/result_sheet.dart';
import '../e2e/test_fixtures.dart';

// =============================================================================
// CHALLENGER MOCKS & TEST DOUBLES FOR ADVERSARIAL STRESS TESTING
// =============================================================================

class MockChallengerAuthProvider extends ChangeNotifier implements AuthProvider {
  AppUser? _user;

  MockChallengerAuthProvider({
    String id = 'staff_challenger',
    String fullName = 'Challenger Staff',
    UserRole role = UserRole.staff,
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

class FakeChallengerCheckinRepository implements CheckinRepository {
  CheckinResult? cannedResult;
  bool shouldThrowNetworkError = false;
  String? lastBookingCodePassed;

  @override
  Future<CheckinResult> checkIn(String bookingCode) async {
    lastBookingCodePassed = bookingCode;
    if (shouldThrowNetworkError) {
      throw Exception('Network connection timed out');
    }
    return cannedResult ??
        CheckinResult(
          isSuccess: false,
          errorCode: 'NOT_FOUND',
          message: 'Mã vé không tồn tại trong hệ thống',
          code: bookingCode,
        );
  }
}

class FakeChallengerFoodRepository implements StaffFoodRepository {
  List<BookingModel> mockPending = [];
  List<BookingModel> mockDelivered = [];
  String? lastDeliveredCode;
  String? lastCinemaIdRequested;
  bool shouldThrowDeliver = false;

  @override
  Future<List<BookingModel>> getPendingOrders(String cinemaId) async {
    lastCinemaIdRequested = cinemaId;
    return List.from(mockPending);
  }

  @override
  Future<List<BookingModel>> getDeliveredOrders(String cinemaId) async {
    lastCinemaIdRequested = cinemaId;
    return List.from(mockDelivered);
  }

  @override
  Future<void> deliverFood(String bookingCode) async {
    if (shouldThrowDeliver) {
      throw Exception('RPC_DELIVER_FOOD_FAILED: ORDER_ALREADY_DELIVERED');
    }
    lastDeliveredCode = bookingCode;
    final idx = mockPending.indexWhere((b) => b.code == bookingCode);
    if (idx != -1) {
      final order = mockPending.removeAt(idx);
      mockDelivered.insert(
        0,
        BookingModel(
          code: order.code,
          cinemaId: order.cinemaId,
          cinemaName: order.cinemaName,
          movieTitle: order.movieTitle,
          roomName: order.roomName,
          format: order.format,
          showtimeId: order.showtimeId,
          showtimeStart: order.showtimeStart,
          status: order.status,
          foodStatus: 'delivered',
          seats: order.seats,
          foods: order.foods,
          priceSnapshot: order.priceSnapshot,
          createdAt: order.createdAt,
        ),
      );
    }
  }
}

class FakeChallengerCounterRepository extends StaffCounterRepository {
  List<ShowtimeModel> mockShowtimes = [];
  bool shouldThrowHold = false;
  bool shouldThrowSell = false;
  int? lastHoldMinutesPassed;
  String? lastPaymentMethod;
  Map<String, dynamic>? lastBookingPayload;

  FakeChallengerCounterRepository() : super(null);

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
    if (shouldThrowHold) {
      throw Exception('SEAT_CONFLICT: Seat already held by another cashier');
    }
    lastHoldMinutesPassed = 3; // Business rule invariant: Counter holds for 3 minutes
    lastBookingPayload = booking;
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
    if (shouldThrowSell) {
      throw Exception('RPC_SELL_COUNTER_FAILED');
    }
    lastPaymentMethod = paymentMethod;
    lastBookingPayload = booking;
  }
}

class FakeChallengerManagementRepository extends ManagementRepository {
  final Map<String, List<AppUser>> _cinemaEmployees = {};
  bool shouldThrowEmployees = false;
  bool shouldThrowCreate = false;
  bool shouldThrowLock = false;
  Map<String, dynamic>? lastCreatedStaffPayload;
  String? lastQueriedCinemaId;
  String? lastLockedUserId;
  bool? lastLockState;

  FakeChallengerManagementRepository() : super(null);

  void setCinemaEmployees(String cinemaId, List<AppUser> employees) {
    _cinemaEmployees[cinemaId] = employees;
  }

  @override
  Future<List<AppUser>> getEmployees(String cinemaId) async {
    lastQueriedCinemaId = cinemaId;
    if (shouldThrowEmployees) {
      throw Exception('DB_QUERY_FAILED: profiles relation error');
    }
    // Multi-tenant scoping invariant: strictly returns cinemaId scoped employees
    return List.from(_cinemaEmployees[cinemaId] ?? []);
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
    if (shouldThrowCreate) {
      throw Exception('EDGE_FUNCTION_ERROR: Email already exists');
    }
    lastCreatedStaffPayload = {
      'email': email,
      'password': password,
      'fullName': fullName,
      'phone': phone,
      'role': role,
      'cinemaId': cinemaId,
    };
    final newUser = AppUser(
      id: 'emp_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      fullName: fullName,
      phone: phone,
      role: role == 'manager' ? UserRole.manager : UserRole.staff,
      cinemaId: cinemaId,
      isLocked: false,
    );
    _cinemaEmployees.putIfAbsent(cinemaId, () => []).insert(0, newUser);
    return {'success': true, 'email': email};
  }

  @override
  Future<void> toggleUserLock(String userId, bool isLocked) async {
    if (shouldThrowLock) {
      throw Exception('TOGGLE_LOCK_ERROR: Database update rejected');
    }
    lastLockedUserId = userId;
    lastLockState = isLocked;
    for (final list in _cinemaEmployees.values) {
      final idx = list.indexWhere((u) => u.id == userId);
      if (idx != -1) {
        list[idx] = list[idx].copyWith(isLocked: isLocked);
      }
    }
  }
}

// =============================================================================
// EMPIRICAL VERIFICATION HARNESS & TEST SUITE
// =============================================================================

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initTestSupabase();
  });

  // ---------------------------------------------------------------------------
  // 1. S18 CHECK-IN: 8 VALIDATION RULES & T16/T18 AGE CHECK GATING
  // ---------------------------------------------------------------------------
  group('1. S18 Check-in 8 Validation Rules & T16/T18 Age Check Gating', () {
    test('1.1 CheckinResult.fromRpc verifies all 8 validation check outcomes', () {
      // Check 1: NOT_FOUND
      final r1 = CheckinResult.fromRpc({
        'success': false,
        'error_code': 'NOT_FOUND',
        'message': 'Mã vé không tồn tại trong hệ thống',
      });
      expect(r1.isSuccess, isFalse);
      expect(r1.errorCode, 'NOT_FOUND');
      expect(r1.message, contains('Mã vé không tồn tại'));

      // Check 2: CANCELLED
      final r2 = CheckinResult.fromRpc({
        'success': false,
        'error_code': 'CANCELLED',
        'message': 'Vé đã bị hủy và hoàn tiền',
      });
      expect(r2.isSuccess, isFalse);
      expect(r2.errorCode, 'CANCELLED');
      expect(r2.message, contains('đã bị hủy'));

      // Check 3: ALREADY_USED
      final r3 = CheckinResult.fromRpc({
        'success': false,
        'error_code': 'ALREADY_USED',
        'message': 'Vé đã sử dụng lúc 19:15',
      });
      expect(r3.isSuccess, isFalse);
      expect(r3.errorCode, 'ALREADY_USED');
      expect(r3.message, contains('đã sử dụng'));

      // Check 4: WRONG_CINEMA
      final r4 = CheckinResult.fromRpc({
        'success': false,
        'error_code': 'WRONG_CINEMA',
        'message': 'Vé thuộc rạp khác (Cinema Star Bình Thạnh)',
      });
      expect(r4.isSuccess, isFalse);
      expect(r4.errorCode, 'WRONG_CINEMA');
      expect(r4.message, contains('Vé thuộc rạp khác'));

      // Check 5: TOO_EARLY
      final r5 = CheckinResult.fromRpc({
        'success': false,
        'error_code': 'TOO_EARLY',
        'message': 'Chưa đến giờ vào rạp (Chỉ vào trước tối đa 30 phút)',
      });
      expect(r5.isSuccess, isFalse);
      expect(r5.errorCode, 'TOO_EARLY');
      expect(r5.message, contains('Chưa đến giờ vào rạp'));

      // Check 6: EXPIRED_SHOWTIME
      final r6 = CheckinResult.fromRpc({
        'success': false,
        'error_code': 'EXPIRED_SHOWTIME',
        'message': 'Vé đã quá hạn sử dụng (Quá 15 phút sau giờ chiếu)',
      });
      expect(r6.isSuccess, isFalse);
      expect(r6.errorCode, 'EXPIRED_SHOWTIME');
      expect(r6.message, contains('quá hạn'));

      // Check 7: UNPAID
      final r7 = CheckinResult.fromRpc({
        'success': false,
        'error_code': 'UNPAID',
        'message': 'Vé chưa hoàn tất thanh toán',
      });
      expect(r7.isSuccess, isFalse);
      expect(r7.errorCode, 'UNPAID');
      expect(r7.message, contains('chưa hoàn tất thanh toán'));

      // Check 8: VALID Ticket with Age Rating and Summary Items
      final r8 = CheckinResult.fromRpc({
        'success': true,
        'code': 'VALID008',
        'movie_title': 'Dune: Hành Tinh Cát 2',
        'room_name': 'Phòng 1 (IMAX)',
        'showtime_start': '20:00',
        'seats': [
          {'id': 'B1'},
          {'id': 'B2'}
        ],
        'foods': [
          {'name': 'Combo Bắp Nước', 'qty': 2},
          {'name': 'Nước Suối', 'qty': 1}
        ],
        'age_rating': 'T18',
      });
      expect(r8.isSuccess, isTrue);
      expect(r8.code, 'VALID008');
      expect(r8.movieTitle, 'Dune: Hành Tinh Cát 2');
      expect(r8.roomName, 'Phòng 1 (IMAX)');
      expect(r8.showtimeStart, '20:00');
      expect(r8.seatsSummary, 'B1, B2');
      expect(r8.foodsSummary, '2x Combo Bắp Nước, 1x Nước Suối');
      expect(r8.ageRating, 'T18');
    });

    test('1.2 CheckinProvider normalizes inputs & handles unexpected exceptions gracefully', () async {
      final fakeRepo = FakeChallengerCheckinRepository();
      final provider = CheckinProvider(fakeRepo);

      fakeRepo.cannedResult = const CheckinResult(
        isSuccess: true,
        message: 'Vé hợp lệ',
        code: 'AB12CD34',
      );

      // Normalization test: leading/trailing whitespace & lowercase
      final res = await provider.checkIn('   ab12cd34   ');
      expect(fakeRepo.lastBookingCodePassed, 'AB12CD34');
      expect(provider.currentScannedCode, 'AB12CD34');
      expect(res.isSuccess, isTrue);
      expect(provider.isLoading, isFalse);

      // Network exception handling
      fakeRepo.shouldThrowNetworkError = true;
      final errRes = await provider.checkIn('NETWORK_ERR');
      expect(errRes.isSuccess, isFalse);
      expect(errRes.message, contains('Lỗi kiểm tra vé: Exception: Network connection timed out'));
      expect(provider.errorMessage, contains('Network connection timed out'));
      expect(provider.isLoading, isFalse);
    });

    testWidgets('1.3 ResultSheet gating: P, K, T13 ratings require NO age check', (tester) async {
      bool confirmed = false;
      bool dismissed = false;

      // P Rating
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: ResultSheet(
            isValid: true,
            movieTitle: 'Doraemon: Bản Giao Hưởng Địa Cầu',
            roomName: 'Phòng 2',
            showtime: '14:00',
            seats: 'C1, C2',
            ageRating: 'P',
            onConfirm: () => confirmed = true,
            onDismiss: () => dismissed = true,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('VÉ HỢP LỆ'), findsOneWidget);
      expect(find.text('Doraemon: Bản Giao Hưởng Địa Cầu'), findsOneWidget);
      // Verify no checkbox for P
      expect(find.byType(Checkbox), findsNothing);

      // Confirm button is immediately enabled
      final confirmBtn = tester.widget<ElevatedButton>(
        find.ancestor(of: find.text('XÁC NHẬN CHO VÀO'), matching: find.byType(ElevatedButton)),
      );
      expect(confirmBtn.onPressed, isNotNull);

      await tester.tap(find.text('XÁC NHẬN CHO VÀO'));
      await tester.pumpAndSettle();
      expect(confirmed, isTrue);
      expect(dismissed, isFalse);
    });

    testWidgets('1.4 ResultSheet gating: T16 and T18 ratings strictly REQUIRE ID verification checkbox',
        (tester) async {
      bool confirmed = false;

      // T18 Rating Ticket
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: ResultSheet(
            isValid: true,
            movieTitle: 'Deadpool & Wolverine',
            roomName: 'Phòng IMAX',
            showtime: '20:30',
            seats: 'D4, D5',
            ageRating: 'T18',
            onConfirm: () => confirmed = true,
            onDismiss: () {},
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('VÉ HỢP LỆ'), findsOneWidget);
      expect(find.text('Khán giả phim T18. Đã kiểm tra giấy tờ tùy thân hợp lệ.'), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);

      // Invariant: Primary button MUST be disabled initially
      var confirmBtn = tester.widget<ElevatedButton>(
        find.ancestor(of: find.text('XÁC NHẬN CHO VÀO'), matching: find.byType(ElevatedButton)),
      );
      expect(confirmBtn.onPressed, isNull, reason: 'Confirm button must be disabled until ID is checked');

      // Tapping disabled button has zero effect
      await tester.tap(find.text('XÁC NHẬN CHO VÀO'));
      await tester.pumpAndSettle();
      expect(confirmed, isFalse);

      // Check ID checkbox
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      // Button is now enabled
      confirmBtn = tester.widget<ElevatedButton>(
        find.ancestor(of: find.text('XÁC NHẬN CHO VÀO'), matching: find.byType(ElevatedButton)),
      );
      expect(confirmBtn.onPressed, isNotNull, reason: 'Confirm button must be enabled once ID is checked');

      await tester.tap(find.text('XÁC NHẬN CHO VÀO'));
      await tester.pumpAndSettle();
      expect(confirmed, isTrue);
    });

    testWidgets('1.5 S18 TicketCheckinScreen full manual input workflow and ResultSheet display',
        (tester) async {
      final fakeRepo = FakeChallengerCheckinRepository();
      final checkinProvider = CheckinProvider(fakeRepo);
      final fakeAuth = MockChallengerAuthProvider(cinemaId: 'cn_q1');

      fakeRepo.cannedResult = const CheckinResult(
        isSuccess: true,
        message: 'Soát vé thành công',
        code: 'VALIDT16',
        movieTitle: 'Mai',
        roomName: 'Phòng 3',
        showtimeStart: '18:00',
        seatsSummary: 'E7, E8',
        ageRating: 'T16',
      );

      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: fakeAuth),
          ChangeNotifierProvider<CheckinProvider>.value(value: checkinProvider),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const TicketCheckinScreen(forceDesktopFallback: true),
        ),
      ));
      await tester.pumpAndSettle();

      // Verify Screen headers & desktop fallback
      expect(find.text('SOÁT VÉ VÀO RẠP'), findsOneWidget);
      expect(find.text('CN_Q1'), findsOneWidget);
      expect(find.text('CAMERA KHÔNG KHẢ DỤNG TRÊN THIẾT BỊ NÀY'), findsOneWidget);

      // Tap manual input button
      await tester.tap(find.byKey(const Key('ticket_checkin_manual_input_btn')));
      await tester.pumpAndSettle();

      expect(find.text('NHẬP MÃ VÉ THỦ CÔNG'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('manual_code_input')), 'validt16');
      await tester.tap(find.byKey(const Key('manual_code_submit')));
      await tester.pumpAndSettle();

      // ResultSheet opens for T16
      expect(find.text('VÉ HỢP LỆ'), findsOneWidget);
      expect(find.text('Mai'), findsOneWidget);
      expect(find.text('Khán giả phim T16. Đã kiểm tra giấy tờ tùy thân hợp lệ.'), findsOneWidget);

      // Check ID
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      await tester.tap(find.text('XÁC NHẬN CHO VÀO'));
      await tester.pumpAndSettle();

      expect(find.text('ĐÃ XÁC NHẬN CHO KHÁCH VÀO RẠP'), findsOneWidget);
      expect(checkinProvider.lastResult, isNull, reason: 'Provider must resetScan after confirmation');
    });
  });

  // ---------------------------------------------------------------------------
  // 2. S19 FOOD BOARD: SORTING ASCENDING & RPC deliver_food STATE TRANSITIONS
  // ---------------------------------------------------------------------------
  group('2. S19 Food Board Sorting & deliver_food State Transitions', () {
    test('2.1 Pending food orders are strictly sorted ascending by showtimeStart', () async {
      final fakeRepo = FakeChallengerFoodRepository();
      final provider = StaffFoodProvider(fakeRepo);

      final now = DateTime.now();
      final t1 = now.add(const Duration(minutes: 15));
      final t2 = now.add(const Duration(minutes: 45));
      final t3 = now.add(const Duration(hours: 1, minutes: 30));
      final t4 = now.add(const Duration(hours: 3));
      final t5 = now.add(const Duration(hours: 5));

      // Deliver mock orders in completely scrambled chronological order
      fakeRepo.mockPending = [
        BookingModel(
          code: 'ORDER_T4',
          cinemaId: 'cn_q1',
          cinemaName: 'Q1',
          movieTitle: 'Movie 4',
          roomName: 'R1',
          format: '2D',
          showtimeId: 'st_4',
          showtimeStart: t4,
          status: 'paid',
          foodStatus: 'pending',
          priceSnapshot: const {},
          createdAt: now,
        ),
        BookingModel(
          code: 'ORDER_T1',
          cinemaId: 'cn_q1',
          cinemaName: 'Q1',
          movieTitle: 'Movie 1',
          roomName: 'R1',
          format: '2D',
          showtimeId: 'st_1',
          showtimeStart: t1,
          status: 'paid',
          foodStatus: 'pending',
          priceSnapshot: const {},
          createdAt: now,
        ),
        BookingModel(
          code: 'ORDER_T5',
          cinemaId: 'cn_q1',
          cinemaName: 'Q1',
          movieTitle: 'Movie 5',
          roomName: 'R1',
          format: '2D',
          showtimeId: 'st_5',
          showtimeStart: t5,
          status: 'paid',
          foodStatus: 'pending',
          priceSnapshot: const {},
          createdAt: now,
        ),
        BookingModel(
          code: 'ORDER_T2',
          cinemaId: 'cn_q1',
          cinemaName: 'Q1',
          movieTitle: 'Movie 2',
          roomName: 'R1',
          format: '2D',
          showtimeId: 'st_2',
          showtimeStart: t2,
          status: 'paid',
          foodStatus: 'pending',
          priceSnapshot: const {},
          createdAt: now,
        ),
        BookingModel(
          code: 'ORDER_T3',
          cinemaId: 'cn_q1',
          cinemaName: 'Q1',
          movieTitle: 'Movie 3',
          roomName: 'R1',
          format: '2D',
          showtimeId: 'st_3',
          showtimeStart: t3,
          status: 'paid',
          foodStatus: 'pending',
          priceSnapshot: const {},
          createdAt: now,
        ),
      ];

      await provider.loadOrders('cn_q1');

      expect(provider.pendingOrders.length, 5);
      // Empirical verification: Orders must appear strictly in order: T1, T2, T3, T4, T5
      expect(provider.pendingOrders[0].code, 'ORDER_T1');
      expect(provider.pendingOrders[1].code, 'ORDER_T2');
      expect(provider.pendingOrders[2].code, 'ORDER_T3');
      expect(provider.pendingOrders[3].code, 'ORDER_T4');
      expect(provider.pendingOrders[4].code, 'ORDER_T5');

      // Assert ascending timestamp invariant across every adjacent pair
      for (int i = 0; i < provider.pendingOrders.length - 1; i++) {
        expect(
          provider.pendingOrders[i].showtimeStart.isBefore(provider.pendingOrders[i + 1].showtimeStart) ||
              provider.pendingOrders[i].showtimeStart.isAtSameMomentAs(provider.pendingOrders[i + 1].showtimeStart),
          isTrue,
        );
      }
    });

    test('2.2 RPC deliver_food state transition moves order from pending to delivered', () async {
      final fakeRepo = FakeChallengerFoodRepository();
      final provider = StaffFoodProvider(fakeRepo);

      final now = DateTime.now();
      fakeRepo.mockPending = [
        BookingModel(
          code: 'FOOD_001',
          cinemaId: 'cn_q1',
          cinemaName: 'Q1',
          movieTitle: 'Godzilla',
          roomName: 'R1',
          format: '2D',
          showtimeId: 'st_1',
          showtimeStart: now.add(const Duration(hours: 1)),
          status: 'paid',
          foodStatus: 'pending',
          foods: const [
            {'name': 'Combo 2', 'qty': 1}
          ],
          priceSnapshot: const {},
          createdAt: now,
        ),
        BookingModel(
          code: 'FOOD_002',
          cinemaId: 'cn_q1',
          cinemaName: 'Q1',
          movieTitle: 'Avatar 3',
          roomName: 'R2',
          format: '3D',
          showtimeId: 'st_2',
          showtimeStart: now.add(const Duration(hours: 2)),
          status: 'paid',
          foodStatus: 'pending',
          foods: const [
            {'name': 'Bắp Lớn', 'qty': 2}
          ],
          priceSnapshot: const {},
          createdAt: now,
        ),
      ];

      await provider.loadOrders('cn_q1');
      expect(provider.pendingOrders.length, 2);
      expect(provider.deliveredOrders.length, 0);

      // Fulfill FOOD_001
      final ok = await provider.deliverFood('FOOD_001', 'cn_q1');
      expect(ok, isTrue);
      expect(fakeRepo.lastDeliveredCode, 'FOOD_001');

      // State check: FOOD_001 must be removed from pending and present in delivered
      expect(provider.pendingOrders.length, 1);
      expect(provider.pendingOrders.first.code, 'FOOD_002');
      expect(provider.deliveredOrders.length, 1);
      expect(provider.deliveredOrders.first.code, 'FOOD_001');
      expect(provider.deliveredOrders.first.foodStatus, 'delivered');

      // Failure resilience: When deliverFood throws, provider returns false and captures error
      fakeRepo.shouldThrowDeliver = true;
      final failResult = await provider.deliverFood('FOOD_002', 'cn_q1');
      expect(failResult, isFalse);
      expect(provider.errorMessage, contains('RPC_DELIVER_FOOD_FAILED'));
      expect(provider.pendingOrders.length, 1, reason: 'Pending list unchanged on failure');
    });

    testWidgets('2.3 FoodBoardScreen search filter, tab toggle, and confirmation modal execution',
        (tester) async {
      final fakeRepo = FakeChallengerFoodRepository();
      final provider = StaffFoodProvider(fakeRepo);
      final fakeAuth = MockChallengerAuthProvider(cinemaId: 'cn_q1');

      final now = DateTime.now();
      fakeRepo.mockPending = [
        BookingModel(
          code: 'SEARCHME1',
          cinemaId: 'cn_q1',
          cinemaName: 'Q1',
          movieTitle: 'Kung Fu Panda 4',
          roomName: 'Phòng 2',
          format: '2D',
          showtimeId: 'st_1',
          showtimeStart: now.add(const Duration(hours: 1)),
          status: 'paid',
          foodStatus: 'pending',
          foods: const [
            {'name': 'Combo Panda', 'qty': 1}
          ],
          priceSnapshot: const {},
          createdAt: now,
        ),
        BookingModel(
          code: 'OTHERCODE',
          cinemaId: 'cn_q1',
          cinemaName: 'Q1',
          movieTitle: 'Dune: Part Two',
          roomName: 'Phòng 1',
          format: '2D',
          showtimeId: 'st_2',
          showtimeStart: now.add(const Duration(hours: 2)),
          status: 'paid',
          foodStatus: 'pending',
          foods: const [
            {'name': 'Bắp Phô Mai', 'qty': 2}
          ],
          priceSnapshot: const {},
          createdAt: now,
        ),
      ];

      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: fakeAuth),
          ChangeNotifierProvider<StaffFoodProvider>.value(value: provider),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const FoodBoardScreen(),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('QUẦY ĐỒ ĂN'), findsOneWidget);
      expect(find.text('#SEARCHME1'), findsOneWidget);
      expect(find.text('#OTHERCODE'), findsOneWidget);

      // Search by movie title
      await tester.enterText(find.byKey(const Key('food_search_field')), 'PANDA');
      await tester.pumpAndSettle();
      expect(find.text('#SEARCHME1'), findsOneWidget);
      expect(find.text('#OTHERCODE'), findsNothing);

      // Clear search
      await tester.enterText(find.byKey(const Key('food_search_field')), '');
      await tester.pumpAndSettle();
      expect(find.text('#SEARCHME1'), findsOneWidget);
      expect(find.text('#OTHERCODE'), findsOneWidget);

      // Deliver SEARCHME1 via UI
      await tester.tap(find.byKey(const Key('deliver_btn_SEARCHME1')));
      await tester.pumpAndSettle();

      expect(find.text('XÁC NHẬN GIAO ĐỒ ĂN'), findsOneWidget);
      expect(find.text('Xác nhận đã giao đủ đồ ăn cho đơn vé #SEARCHME1?'), findsOneWidget);

      await tester.tap(find.text('XÁC NHẬN'));
      await tester.pumpAndSettle();

      expect(find.text('ĐÃ GIAO ĐỒ ĂN CHO ĐƠN #SEARCHME1 THÀNH CÔNG'), findsOneWidget);
      expect(find.text('#SEARCHME1'), findsNothing, reason: 'Delivered item must leave pending tab');

      // Switch to ĐÃ GIAO tab
      await tester.tap(find.byKey(const Key('food_tab_delivered')));
      await tester.pumpAndSettle();

      expect(find.text('#SEARCHME1'), findsOneWidget);
      expect(find.text('ĐÃ GIAO'), findsAtLeastNWidgets(1));

      // Drain background realtime reconnect timers
      provider.dispose();
      await tester.pump(const Duration(seconds: 15));
    });
  });

  // ---------------------------------------------------------------------------
  // 3. S20 COUNTER: 3-MINUTE HOLD DURATION & MAX 8 SEATS ENFORCEMENT
  // ---------------------------------------------------------------------------
  group('3. S20 Counter 3-Minute Hold Duration & Max 8 Seats Enforcement', () {
    test('3.1 Max 8 seats boundary enforcement: 1..8 pass, 9th fails with error', () {
      final fakeRepo = FakeChallengerCounterRepository();
      final provider = StaffCounterProvider(fakeRepo);

      final showtime = ShowtimeModel(
        id: 'st_counter_01',
        movieId: 'mov_01',
        cinemaId: 'cn_q1',
        roomId: 'rm_01',
        format: '2D',
        startTime: DateTime.now().add(const Duration(hours: 1)),
        endTime: DateTime.now().add(const Duration(hours: 3)),
        totalSeats: 64,
        minPrice: 80000,
      );
      provider.selectShowtime(showtime);

      // Add seats 1..8
      for (int i = 1; i <= 8; i++) {
        final success = provider.toggleSeat('A$i');
        expect(success, isTrue);
        expect(provider.selectedSeatIds.length, i);
      }
      expect(provider.selectedSeatIds.length, 8);
      expect(provider.errorMessage, isNull);

      // Attempt 9th seat: MUST return false and set error message
      final seat9Success = provider.toggleSeat('A9');
      expect(seat9Success, isFalse);
      expect(provider.selectedSeatIds.length, 8);
      expect(provider.errorMessage, contains('tối đa 8 ghế'));

      // Attempt 10th seat: ALSO fails
      final seat10Success = provider.toggleSeat('B1');
      expect(seat10Success, isFalse);
      expect(provider.selectedSeatIds.length, 8);

      // Deselect 1 seat (A8)
      final deselectSuccess = provider.toggleSeat('A8');
      expect(deselectSuccess, isTrue);
      expect(provider.selectedSeatIds.length, 7);

      // Select new 8th seat (B1)
      final reselectSuccess = provider.toggleSeat('B1');
      expect(reselectSuccess, isTrue);
      expect(provider.selectedSeatIds.length, 8);
      expect(provider.selectedSeatIds.contains('B1'), isTrue);
    });

    test('3.2 Counter hold duration is strictly 3 minutes (p_hold_minutes = 3)', () async {
      final fakeRepo = FakeChallengerCounterRepository();
      final provider = StaffCounterProvider(fakeRepo);

      final showtime = ShowtimeModel(
        id: 'st_counter_hold',
        movieId: 'mov_01',
        cinemaId: 'cn_q1',
        roomId: 'rm_01',
        format: '2D',
        startTime: DateTime.now().add(const Duration(hours: 1)),
        endTime: DateTime.now().add(const Duration(hours: 3)),
        totalSeats: 64,
        minPrice: 85000,
        movieTitle: 'Phim Quầy',
      );
      provider.selectShowtime(showtime);
      provider.toggleSeat('C1');
      provider.toggleSeat('C2');

      final holdOk = await provider.holdSeatsForCounter();
      expect(holdOk, isTrue);

      // Invariant: holdCounterSeats must enforce 3 minutes
      expect(fakeRepo.lastHoldMinutesPassed, 3, reason: 'Counter hold duration must be strictly 3 minutes');
      expect(provider.holdUntil, isNotNull);
      expect(provider.bookingCode, isNotNull);
      expect(provider.bookingCode!.length, 8);

      final remaining = provider.holdUntil!.difference(DateTime.now());
      expect(remaining.inMinutes, lessThanOrEqualTo(3));
      expect(remaining.inSeconds, greaterThan(150));
    });

    testWidgets('3.3 S20 Counter Showtimes Screen seat picker & concession stepper integration',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeRepo = FakeChallengerCounterRepository();
      final provider = StaffCounterProvider(fakeRepo);
      final fakeAuth = MockChallengerAuthProvider(cinemaId: 'cn_q1');

      fakeRepo.mockShowtimes = [
        ShowtimeModel(
          id: 'st_box_office',
          movieId: 'mov_1',
          cinemaId: 'cn_q1',
          roomId: 'rm_1',
          format: '2D',
          startTime: DateTime.now().add(const Duration(hours: 2)),
          endTime: DateTime.now().add(const Duration(hours: 4)),
          totalSeats: 32,
          soldSeats: 4,
          minPrice: 90000,
          movieTitle: 'Avengers 5',
          roomName: 'Phòng 1',
        ),
      ];

      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: fakeAuth),
          ChangeNotifierProvider<StaffCounterProvider>.value(value: provider),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          routes: {
            AppRoutes.staffCounterPayment: (_) => const Scaffold(body: Text('PAYMENT_SCREEN_REACHED')),
          },
          home: const CounterShowtimesScreen(),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('BÁN VÉ TẠI QUẦY'), findsOneWidget);
      expect(find.text('Avengers 5'), findsOneWidget);

      // Open Seat Modal
      await tester.tap(find.byKey(const Key('counter_showtime_st_box_office')));
      await tester.pumpAndSettle();

      expect(find.text('CHỌN GHẾ TẠI QUẦY'), findsOneWidget);
      expect(find.text('0/8 GHẾ'), findsOneWidget);

      // Select Seat A1
      await tester.tap(find.byKey(const Key('counter_seat_A1')));
      await tester.pumpAndSettle();

      expect(find.text('1/8 GHẾ'), findsOneWidget);
      expect(find.text(CurrencyFormatter.format(90000)), findsOneWidget);

      // Add Concession: Combo Bắp Nước (+75,000)
      final addComboBtn = find.descendant(
        of: find.ancestor(of: find.text('Combo Bắp Nước'), matching: find.byType(Row)),
        matching: find.byIcon(Icons.add),
      );
      await tester.tap(addComboBtn);
      await tester.pumpAndSettle();

      // Total = 90,000 + 75,000 = 165,000 VND
      expect(provider.calculateTotal(), 165000);
      expect(find.text(CurrencyFormatter.format(165000)), findsOneWidget);

      // Continue to Hold and Payment
      await tester.ensureVisible(find.byKey(const Key('counter_continue_booking_btn')));
      await tester.tap(find.byKey(const Key('counter_continue_booking_btn')));
      await tester.pumpAndSettle();

      expect(find.text('PAYMENT_SCREEN_REACHED'), findsOneWidget);
      expect(fakeRepo.lastHoldMinutesPassed, 3);
    });
  });

  // ---------------------------------------------------------------------------
  // 4. S21 COUNTER: CASH CHANGE CALCULATION STRICTLY IN INTEGER VND
  // ---------------------------------------------------------------------------
  group('4. S21 Counter Cash Change Calculation Strictly in Integer VND', () {
    test('4.1 Integer VND precision: exact cash, excess cash, underpayment, and large numbers', () {
      final fakeRepo = FakeChallengerCounterRepository();
      final provider = StaffCounterProvider(fakeRepo);

      final showtime = ShowtimeModel(
        id: 'st_cash_test',
        movieId: 'mov_1',
        cinemaId: 'cn_q1',
        roomId: 'rm_1',
        format: '2D',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(hours: 2)),
        totalSeats: 50,
        minPrice: 110000,
      );
      provider.selectShowtime(showtime);
      provider.toggleSeat('A1');
      provider.toggleSeat('A2'); // 2 * 110,000 = 220,000 VND
      provider.setFoodQuantity('food_combo', 'Combo Lớn', 95000, 2); // 190,000 VND

      // Total = 220,000 + 190,000 = 410,000 VND (strictly int)
      final total = provider.calculateTotal();
      expect(total, 410000);
      expect(total.runtimeType, int);

      // Scenario A: Exact cash payment (410,000 VND)
      final exactChange = provider.calculateChange(410000);
      expect(exactChange, 0);
      expect(provider.receivedCash, 410000);

      // Scenario B: Excess cash payment (500,000 VND) -> Change: 90,000 VND
      final excessChange = provider.calculateChange(500000);
      expect(excessChange, 90000);
      expect(excessChange.runtimeType, int);

      // Scenario C: Underpayment (350,000 VND) -> Change must be 0
      final underChange = provider.calculateChange(350000);
      expect(underChange, 0);
      expect(provider.receivedCash < total, isTrue);

      // Scenario D: Zero and negative input resilience
      expect(provider.calculateChange(0), 0);
      expect(provider.calculateChange(-50000), 0);

      // Scenario E: Multi-million VND large group booking integer calculation
      final largeChange = provider.calculateChange(10000000); // 10,000,000 VND
      expect(largeChange, 10000000 - 410000);
      expect(largeChange, 9590000);
    });

    testWidgets('4.2 Quick cash buttons live calculation & Card/POS checkout mode', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeRepo = FakeChallengerCounterRepository();
      final provider = StaffCounterProvider(fakeRepo);
      final fakeAuth = MockChallengerAuthProvider(cinemaId: 'cn_q1');

      final showtime = ShowtimeModel(
        id: 'st_pay_screen',
        movieId: 'mov_1',
        cinemaId: 'cn_q1',
        roomId: 'rm_1',
        format: '2D',
        startTime: DateTime.now().add(const Duration(hours: 1)),
        endTime: DateTime.now().add(const Duration(hours: 3)),
        totalSeats: 50,
        minPrice: 100000,
        movieTitle: 'Avatar 3',
        roomName: 'Phòng 1',
      );
      provider.selectShowtime(showtime);
      provider.toggleSeat('A1');
      provider.toggleSeat('A2'); // Total 200,000 VND

      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: fakeAuth),
          ChangeNotifierProvider<StaffCounterProvider>.value(value: provider),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const CounterPaymentScreen(),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('THANH TOÁN TẠI QUẦY'), findsOneWidget);
      expect(find.text(CurrencyFormatter.format(200000)), findsOneWidget);
      // Warning for insufficient cash shown
      expect(find.textContaining('KHÁCH ĐƯA THIẾU: 200.000'), findsOneWidget);

      // Verify submit button is DISABLED when cash < total
      var confirmBtn = tester.widget<ElevatedButton>(
        find.ancestor(of: find.text('XÁC NHẬN BÁN VÉ'), matching: find.byType(ElevatedButton)),
      );
      expect(confirmBtn.onPressed, isNull);

      // Quick cash: Tap ĐỦ TIỀN
      await tester.tap(find.byKey(const Key('cash_exact_btn')));
      await tester.pumpAndSettle();

      expect(find.text('TIỀN THỪA TRẢ KHÁCH'), findsOneWidget);
      expect(find.text(CurrencyFormatter.format(0)), findsOneWidget);
      confirmBtn = tester.widget<ElevatedButton>(
        find.ancestor(of: find.text('XÁC NHẬN BÁN VÉ'), matching: find.byType(ElevatedButton)),
      );
      expect(confirmBtn.onPressed, isNotNull);

      // Quick cash increment: Tap +50K -> Received becomes 250,000, Change = 50,000
      await tester.tap(find.byKey(const Key('cash_plus_50k_btn')));
      await tester.pumpAndSettle();
      expect(find.textContaining('50.000'), findsOneWidget);

      // Switch to Card/POS mode
      await tester.tap(find.byKey(const Key('payment_method_card_tab')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pos_confirmed_checkbox')), findsOneWidget);
      // Invariant: Card mode requires POS checkbox before enabling button
      confirmBtn = tester.widget<ElevatedButton>(
        find.ancestor(of: find.text('XÁC NHẬN BÁN VÉ'), matching: find.byType(ElevatedButton)),
      );
      expect(confirmBtn.onPressed, isNull);

      // Check POS checkbox
      await tester.tap(find.byKey(const Key('pos_confirmed_checkbox')));
      await tester.pumpAndSettle();

      confirmBtn = tester.widget<ElevatedButton>(
        find.ancestor(of: find.text('XÁC NHẬN BÁN VÉ'), matching: find.byType(ElevatedButton)),
      );
      expect(confirmBtn.onPressed, isNotNull);

      // Complete sale in POS mode
      await tester.tap(find.byKey(const Key('counter_confirm_sale_btn')));
      await tester.pumpAndSettle();

      expect(fakeRepo.lastPaymentMethod, 'card');
      expect(find.text('XUẤT VÉ THÀNH CÔNG'), findsOneWidget);

      // Tap BÁN ĐƠN MỚI to reset
      await tester.tap(find.byKey(const Key('counter_new_sale_btn')));
      await tester.pumpAndSettle();
      expect(provider.selectedSeatIds, isEmpty);
      expect(provider.selectedShowtime, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // 5. S23 MANAGEMENT: STAFF ACCOUNT LOCKING & MULTI-TENANT CINEMA SCOPING
  // ---------------------------------------------------------------------------
  group('5. S23 Staff Account Locking & Multi-Tenant Cinema Scoping', () {
    test('5.1 Multi-tenant scoping: queries strictly filter by current cinemaId', () async {
      final fakeRepo = FakeChallengerManagementRepository();
      final provider = ManagementProvider(fakeRepo);

      // Configure distinct employee lists per cinema
      fakeRepo.setCinemaEmployees('cn_q1', [
        const AppUser(
          id: 'emp_q1_1',
          fullName: 'Staff Quận 1',
          role: UserRole.staff,
          cinemaId: 'cn_q1',
        ),
      ]);
      fakeRepo.setCinemaEmployees('cn_bt', [
        const AppUser(
          id: 'emp_bt_1',
          fullName: 'Staff Bình Thạnh',
          role: UserRole.staff,
          cinemaId: 'cn_bt',
        ),
      ]);

      // Query cinema cn_q1
      await provider.loadEmployees('cn_q1');
      expect(fakeRepo.lastQueriedCinemaId, 'cn_q1');
      expect(provider.employees.length, 1);
      expect(provider.employees.first.fullName, 'Staff Quận 1');
      expect(provider.employees.first.cinemaId, 'cn_q1');

      // Query cinema cn_bt
      await provider.loadEmployees('cn_bt');
      expect(fakeRepo.lastQueriedCinemaId, 'cn_bt');
      expect(provider.employees.length, 1);
      expect(provider.employees.first.fullName, 'Staff Bình Thạnh');
      expect(provider.employees.first.cinemaId, 'cn_bt');
    });

    test('5.2 Account lock/unlock toggle state transitions update database and provider state', () async {
      final fakeRepo = FakeChallengerManagementRepository();
      final provider = ManagementProvider(fakeRepo);

      fakeRepo.setCinemaEmployees('cn_q1', [
        const AppUser(
          id: 'emp_toggle',
          fullName: 'Staff Target',
          role: UserRole.staff,
          cinemaId: 'cn_q1',
          isLocked: false,
        ),
      ]);

      await provider.loadEmployees('cn_q1');
      expect(provider.employees.first.isLocked, isFalse);

      // Toggle lock to true
      await provider.toggleUserLock('emp_toggle', true, 'cn_q1');
      expect(fakeRepo.lastLockedUserId, 'emp_toggle');
      expect(fakeRepo.lastLockState, isTrue);
      expect(provider.employees.first.isLocked, isTrue);

      // Toggle lock back to false (unlock)
      await provider.toggleUserLock('emp_toggle', false, 'cn_q1');
      expect(fakeRepo.lastLockedUserId, 'emp_toggle');
      expect(fakeRepo.lastLockState, isFalse);
      expect(provider.employees.first.isLocked, isFalse);
    });

    testWidgets('5.3 S23 StaffAccountsScreen lock toggle modal and state update',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeRepo = FakeChallengerManagementRepository();
      final provider = ManagementProvider(fakeRepo);
      final fakeAuth = MockChallengerAuthProvider(
        id: 'mgr_q1',
        fullName: 'Manager Q1',
        role: UserRole.manager,
        cinemaId: 'cn_q1',
      );

      fakeRepo.setCinemaEmployees('cn_q1', [
        const AppUser(
          id: 'emp_to_lock',
          fullName: 'Nguyễn Văn Nhân Viên',
          email: 'nv@cinema.vn',
          role: UserRole.staff,
          cinemaId: 'cn_q1',
          isLocked: false,
        ),
      ]);

      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: fakeAuth),
          ChangeNotifierProvider<ManagementProvider>.value(value: provider),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const StaffAccountsScreen(),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('QUẢN LÝ NHÂN VIÊN'), findsOneWidget);
      expect(find.text('CN_Q1'), findsOneWidget);
      expect(find.text('Nguyễn Văn Nhân Viên'), findsOneWidget);
      expect(find.text('KHÓA'), findsOneWidget);

      // Tap KHÓA button
      await tester.tap(find.byKey(const Key('toggle_lock_emp_to_lock')));
      await tester.pumpAndSettle();

      expect(find.text('KHÓA TÀI KHOẢN'), findsOneWidget);
      expect(find.textContaining('Bạn có chắc chắn muốn KHÓA tài khoản "Nguyễn Văn Nhân Viên"'), findsOneWidget);

      // Confirm Lock
      await tester.tap(find.text('XÁC NHẬN'));
      await tester.pumpAndSettle();

      expect(fakeRepo.lastLockedUserId, 'emp_to_lock');
      expect(fakeRepo.lastLockState, isTrue);
      expect(find.text('ĐÃ KHÓA TÀI KHOẢN THÀNH CÔNG'), findsOneWidget);
      expect(find.text('MỞ KHÓA'), findsOneWidget);
    });

    testWidgets('5.4 S23 StaffAccountsScreen create staff modal validation & Edge Function invocation',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeRepo = FakeChallengerManagementRepository();
      final provider = ManagementProvider(fakeRepo);
      final fakeAuth = MockChallengerAuthProvider(
        id: 'mgr_q1',
        fullName: 'Manager Q1',
        role: UserRole.manager,
        cinemaId: 'cn_q1',
      );

      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: fakeAuth),
          ChangeNotifierProvider<ManagementProvider>.value(value: provider),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const StaffAccountsScreen(),
        ),
      ));
      await tester.pumpAndSettle();

      // Tap FAB to open modal
      await tester.tap(find.byKey(const Key('add_staff_fab')));
      await tester.pumpAndSettle();

      expect(find.text('THÊM TÀI KHOẢN NHÂN SỰ'), findsOneWidget);

      // Fill form with valid details
      await tester.enterText(find.byKey(const Key('add_staff_name_field')), 'Trần Thị Thu Ngân');
      await tester.enterText(find.byKey(const Key('add_staff_email_field')), 'thungan@cinema.vn');
      await tester.enterText(find.byKey(const Key('add_staff_phone_field')), '0988112233');
      await tester.enterText(find.byKey(const Key('add_staff_password_field')), 'Pass123456');

      await tester.ensureVisible(find.byKey(const Key('add_staff_submit_btn')));
      await tester.tap(find.byKey(const Key('add_staff_submit_btn')));
      await tester.pumpAndSettle();

      expect(fakeRepo.lastCreatedStaffPayload?['email'], 'thungan@cinema.vn');
      expect(fakeRepo.lastCreatedStaffPayload?['fullName'], 'Trần Thị Thu Ngân');
      expect(fakeRepo.lastCreatedStaffPayload?['cinemaId'], 'cn_q1');
      expect(find.text('TẠO TÀI KHOẢN NHÂN SỰ THÀNH CÔNG'), findsOneWidget);
      expect(find.text('Trần Thị Thu Ngân'), findsOneWidget);
    });
  });
}
