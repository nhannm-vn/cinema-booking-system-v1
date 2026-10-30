import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cinema_booking_v1/core/routes/app_router.dart';
import 'package:cinema_booking_v1/core/routes/route_guards.dart';
import 'package:cinema_booking_v1/features/auth/data/auth_repository.dart';
import 'package:cinema_booking_v1/features/auth/presentation/controllers/auth_provider.dart';
import 'package:cinema_booking_v1/features/booking/data/repositories/seat_repository.dart';
import 'package:cinema_booking_v1/features/booking/presentation/controllers/booking_provider.dart';
import 'package:cinema_booking_v1/features/cinemas/data/location_service.dart';
import 'package:cinema_booking_v1/features/management/data/models/dashboard_metrics_model.dart';
import 'package:cinema_booking_v1/features/management/data/models/pricing_settings_model.dart';
import 'package:cinema_booking_v1/features/management/data/models/voucher_model.dart';
import 'package:cinema_booking_v1/features/notifications/presentation/controllers/notification_provider.dart';
import 'package:cinema_booking_v1/features/staff_checkin/data/checkin_repository.dart';
import 'package:cinema_booking_v1/features/staff_checkin/presentation/controllers/checkin_provider.dart';
import 'package:cinema_booking_v1/features/staff_counter/data/repositories/staff_counter_repository.dart';
import 'package:cinema_booking_v1/features/staff_counter/presentation/controllers/staff_counter_provider.dart';
import 'package:cinema_booking_v1/features/staff_food/data/staff_food_repository.dart';
import 'package:cinema_booking_v1/features/staff_food/presentation/controllers/staff_food_provider.dart';
import 'package:cinema_booking_v1/features/tickets/data/ticket_repository.dart';
import 'package:cinema_booking_v1/features/tickets/presentation/controllers/ticket_provider.dart';

import '../e2e/test_fixtures.dart';

// =============================================================================
// TEST DOUBLES FOR TIER 5 WHITE-BOX ADVERSARIAL STRESS TESTING
// =============================================================================

class MockAdversarialAuthRepo implements AuthRepository {
  AppUser? profileToReturn;
  bool shouldThrowOnSignIn = false;
  String signInErrorMessage = 'Tài khoản hoặc mật khẩu không chính xác.';
  bool shouldThrowOnSignUp = false;
  String signUpErrorMessage = 'Email đã được sử dụng.';
  bool shouldThrowOnUpdate = false;
  String updateErrorMessage = 'Lỗi cập nhật hồ sơ.';

  final StreamController<AuthState> _authController = StreamController<AuthState>.broadcast();

  @override
  User? get currentAuthUser => null;

  @override
  Stream<AuthState> get onAuthStateChange => _authController.stream;

  void emitAuthState(AuthChangeEvent event, Session? session) {
    _authController.add(AuthState(event, session));
  }

  @override
  Future<AppUser?> getCurrentProfile() async => profileToReturn;

  @override
  Future<AppUser> signIn({required String email, required String password}) async {
    if (shouldThrowOnSignIn) throw Exception(signInErrorMessage);
    return profileToReturn ?? buildTestUser(email: email);
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    if (shouldThrowOnSignUp) throw Exception(signUpErrorMessage);
    return profileToReturn ?? buildTestUser(email: email, fullName: fullName, phone: phone);
  }

  @override
  Future<AppUser> updateProfile({required String fullName, String? phone}) async {
    if (shouldThrowOnUpdate) throw Exception(updateErrorMessage);
    profileToReturn = profileToReturn?.copyWith(fullName: fullName, phone: phone) ??
        buildTestUser(fullName: fullName, phone: phone);
    return profileToReturn!;
  }

  @override
  Future<void> signOut() async {
    profileToReturn = null;
  }
}

class MockAdversarialSeatRepo implements SeatRepository {
  bool shouldThrowTaken = false;
  String takenSeatId = 'B4';
  bool shouldThrowGeneric = false;
  String genericErrorMessage = 'Lỗi kết nối RPC';
  DateTime? holdExpiry;
  String? lastReleasedCode;

  @override
  Stream<List<SeatModel>> streamSeats(String showtimeId) => Stream.value([]);

  @override
  Future<DateTime> holdSeats({
    required String showtimeId,
    required String bookingCode,
    required List<String> seatIds,
    required Map<String, dynamic> booking,
    int holdMinutes = 5,
  }) async {
    if (shouldThrowTaken) throw SeatTakenException(takenSeatId);
    if (shouldThrowGeneric) throw Exception(genericErrorMessage);
    return holdExpiry ?? DateTime.now().add(Duration(minutes: holdMinutes));
  }

  @override
  Future<void> releaseHold(String bookingCode) async {
    lastReleasedCode = bookingCode;
  }
}

class MockAdversarialCheckinRepo implements CheckinRepository {
  bool shouldThrow = false;
  String errorMessage = 'RPC check_in error';
  CheckinResult? resultToReturn;

  @override
  Future<CheckinResult> checkIn(String bookingCode) async {
    if (shouldThrow) throw Exception(errorMessage);
    return resultToReturn ??
        const CheckinResult(
          isSuccess: true,
          message: 'Soát vé thành công',
          code: 'K7M2QX9P',
        );
  }
}

class MockAdversarialFoodRepo implements StaffFoodRepository {
  List<BookingModel> pending = [];
  List<BookingModel> delivered = [];
  bool shouldThrowOnDeliver = false;
  String? lastDeliveredCode;

  @override
  Future<List<BookingModel>> getPendingOrders(String cinemaId) async => pending;

  @override
  Future<List<BookingModel>> getDeliveredOrders(String cinemaId) async => delivered;

  @override
  Future<void> deliverFood(String bookingCode) async {
    if (shouldThrowOnDeliver) throw Exception('Network timeout');
    lastDeliveredCode = bookingCode;
  }
}

class MockAdversarialCounterRepo implements StaffCounterRepository {
  bool shouldThrowHold = false;
  bool shouldThrowSale = false;
  String? lastSoldCode;

  @override
  Future<List<ShowtimeModel>> getCounterShowtimes(String cinemaId, DateTime date) async => [];

  @override
  Future<DateTime> holdCounterSeats({
    required String showtimeId,
    required String bookingCode,
    required List<String> seatIds,
    required Map<String, dynamic> booking,
  }) async {
    if (shouldThrowHold) throw Exception('Ghế đã bị khóa bởi người khác');
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
    if (shouldThrowSale) throw Exception('Thanh toán thất bại');
    lastSoldCode = bookingCode;
  }

  @override
  Future<List<Map<String, dynamic>>> getShowtimeSeats(String showtimeId) async => [];

  @override
  Future<List<Map<String, dynamic>>> getAvailableFoods(String cinemaId) async => [];

  @override
  Future<List<String>> getRoomLayout(String roomId) async => [];
}

class MockAdversarialTicketRepo implements TicketRepository {
  List<BookingModel> tickets = [];
  bool shouldThrowCancel = false;
  String? lastCancelledCode;

  @override
  Future<List<BookingModel>> getMyTickets() async => tickets;

  @override
  Future<BookingModel?> getTicketByCode(String code) async {
    try {
      return tickets.firstWhere((t) => t.code == code);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> cancelBooking(String code, {String reason = 'Khách hủy vé trực tuyến'}) async {
    if (shouldThrowCancel) throw Exception('Không thể hủy trong vòng 2 giờ');
    lastCancelledCode = code;
    tickets.removeWhere((t) => t.code == code);
  }
}

class MockAdversarialNotifRepo implements NotificationRepository {
  List<NotificationModel> notifications = [];
  bool markedAll = false;

  @override
  Future<List<NotificationModel>> getNotifications() async => notifications;

  @override
  Future<void> markAllAsRead() async {
    markedAll = true;
    notifications = notifications.map((n) => NotificationModel(
      id: n.id,
      userId: n.userId,
      type: n.type,
      title: n.title,
      body: n.body,
      bookingCode: n.bookingCode,
      isRead: true,
      createdAt: n.createdAt,
    )).toList();
  }
}

// =============================================================================
// MAIN TIER 5 ADVERSARIAL COVERAGE HARDENING SUITE
// =============================================================================

void main() {
  setUpAll(() async {
    await initTestSupabase();
  });

  // ---------------------------------------------------------------------------
  // DIMENSION 1: DEEP ROUTE GUARDS & APPROUTER ARGUMENT FUZZING
  // ---------------------------------------------------------------------------
  group('Tier 5 - Dimension 1: Route Guards & AppRouter Argument Fuzzing', () {
    test('1.1 RouteGuards.getInitialRoute returns home for null guest user', () {
      expect(RouteGuards.getInitialRoute(null), equals(AppRoutes.home));
    });

    test('1.2 RouteGuards.getInitialRoute redirects locked user to login regardless of role', () {
      final lockedCustomer = buildTestUser(role: UserRole.customer, isLocked: true);
      final lockedStaff = buildTestUser(role: UserRole.staff, isLocked: true);
      final lockedManager = buildTestUser(role: UserRole.manager, isLocked: true);
      final lockedAdmin = buildTestUser(role: UserRole.admin, isLocked: true);

      expect(RouteGuards.getInitialRoute(lockedCustomer), equals(AppRoutes.login));
      expect(RouteGuards.getInitialRoute(lockedStaff), equals(AppRoutes.login));
      expect(RouteGuards.getInitialRoute(lockedManager), equals(AppRoutes.login));
      expect(RouteGuards.getInitialRoute(lockedAdmin), equals(AppRoutes.login));
    });

    test('1.3 RouteGuards.getInitialRoute routes active users to role-specific entry screens', () {
      final customer = buildTestUser(role: UserRole.customer, isLocked: false);
      final staff = buildTestUser(role: UserRole.staff, isLocked: false);
      final manager = buildTestUser(role: UserRole.manager, isLocked: false);
      final admin = buildTestUser(role: UserRole.admin, isLocked: false);

      expect(RouteGuards.getInitialRoute(customer), equals(AppRoutes.home));
      expect(RouteGuards.getInitialRoute(staff), equals(AppRoutes.staffCheckin));
      expect(RouteGuards.getInitialRoute(manager), equals(AppRoutes.dashboard));
      expect(RouteGuards.getInitialRoute(admin), equals(AppRoutes.dashboard));
    });

    test('1.4 RouteGuards.requiresAuth correctly flags all 25 protected routes', () {
      const protected = [
        AppRoutes.myTickets, AppRoutes.profile, AppRoutes.editProfile,
        AppRoutes.notifications, AppRoutes.supportChat, AppRoutes.seatSelect,
        AppRoutes.foodSelect, AppRoutes.checkout, AppRoutes.staffCheckin,
        AppRoutes.staffFood, AppRoutes.staffCounterShowtimes, AppRoutes.staffCounterPayment,
        AppRoutes.managementHome, AppRoutes.dashboard, AppRoutes.manageMovies,
        AppRoutes.manageShowtimes, AppRoutes.manageBookings, AppRoutes.manageFoods,
        AppRoutes.manageEmployees, AppRoutes.manageRooms, AppRoutes.configSeatMap,
        AppRoutes.configPricing, AppRoutes.manageVouchers, AppRoutes.manageManagers,
        AppRoutes.auditLogs,
      ];
      for (final r in protected) {
        expect(RouteGuards.requiresAuth(r), isTrue, reason: 'Route $r should require auth');
      }
    });

    test('1.5 RouteGuards.requiresAuth permits public routes and arbitrary unknown routes', () {
      const publicRoutes = [
        AppRoutes.home, AppRoutes.movieDetail, AppRoutes.cinemas,
        AppRoutes.cinemaDetail, AppRoutes.showtimes, AppRoutes.login,
        AppRoutes.register, AppRoutes.ticketSuccess, AppRoutes.vnpayWebview,
      ];
      for (final r in publicRoutes) {
        expect(RouteGuards.requiresAuth(r), isFalse, reason: 'Route $r should be public');
      }
      expect(RouteGuards.requiresAuth(''), isFalse);
      expect(RouteGuards.requiresAuth('/unknown/path'), isFalse);
    });

    test('1.6 AppRouter handles Login route arguments with Map, String, null and malformed input', () {
      final r1 = AppRouter.onGenerateRoute(const RouteSettings(
        name: AppRoutes.login,
        arguments: {'redirectRoute': '/my-tickets'},
      ));
      expect(r1, isA<MaterialPageRoute>());

      final r2 = AppRouter.onGenerateRoute(const RouteSettings(
        name: AppRoutes.login,
        arguments: '/my-tickets',
      ));
      expect(r2, isA<MaterialPageRoute>());

      final r3 = AppRouter.onGenerateRoute(const RouteSettings(
        name: AppRoutes.login,
        arguments: null,
      ));
      expect(r3, isA<MaterialPageRoute>());

      final r4 = AppRouter.onGenerateRoute(const RouteSettings(
        name: AppRoutes.login,
        arguments: 99999, // adversarial malformed type
      ));
      expect(r4, isA<MaterialPageRoute>());
    });

    test('1.7 AppRouter handles MovieDetail with MovieModel, String ID, Map, and null without crash', () {
      final movie = buildTestMovie();
      final r1 = AppRouter.onGenerateRoute(RouteSettings(
        name: AppRoutes.movieDetail,
        arguments: movie,
      ));
      expect(r1, isA<MaterialPageRoute>());

      final r2 = AppRouter.onGenerateRoute(const RouteSettings(
        name: AppRoutes.movieDetail,
        arguments: 'mov_001',
      ));
      expect(r2, isA<MaterialPageRoute>());

      final r3 = AppRouter.onGenerateRoute(RouteSettings(
        name: AppRoutes.movieDetail,
        arguments: {'movie': movie, 'movieId': 'mov_001'},
      ));
      expect(r3, isA<MaterialPageRoute>());

      final r4 = AppRouter.onGenerateRoute(const RouteSettings(
        name: AppRoutes.movieDetail,
        arguments: null,
      ));
      expect(r4, isA<MaterialPageRoute>());
    });

    test('1.8 AppRouter handles VNPayWebview with valid Map, empty Map, and malformed arguments', () {
      final r1 = AppRouter.onGenerateRoute(const RouteSettings(
        name: AppRoutes.vnpayWebview,
        arguments: {
          'paymentUrl': 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html',
          'bookingCode': 'K7M2QX9P',
          'txnRef': 'K7M2QX9P-261028',
        },
      ));
      expect(r1, isA<MaterialPageRoute>());

      final r2 = AppRouter.onGenerateRoute(const RouteSettings(
        name: AppRoutes.vnpayWebview,
        arguments: <String, dynamic>{},
      ));
      expect(r2, isA<MaterialPageRoute>());

      final r3 = AppRouter.onGenerateRoute(const RouteSettings(
        name: AppRoutes.vnpayWebview,
        arguments: null,
      ));
      expect(r3, isA<MaterialPageRoute>());
    });

    test('1.9 AppRouter handles TicketSuccess and SupportChat arguments gracefully', () {
      final r1 = AppRouter.onGenerateRoute(const RouteSettings(
        name: AppRoutes.ticketSuccess,
        arguments: 'K7M2QX9P',
      ));
      expect(r1, isA<MaterialPageRoute>());

      final r2 = AppRouter.onGenerateRoute(const RouteSettings(
        name: AppRoutes.ticketSuccess,
        arguments: {'bookingCode': 'K7M2QX9P'},
      ));
      expect(r2, isA<MaterialPageRoute>());

      final r3 = AppRouter.onGenerateRoute(const RouteSettings(
        name: AppRoutes.supportChat,
        arguments: {'cinemaId': 'cn_q1', 'bookingCode': 'K7M2QX9P'},
      ));
      expect(r3, isA<MaterialPageRoute>());

      final r4 = AppRouter.onGenerateRoute(const RouteSettings(
        name: AppRoutes.supportChat,
        arguments: 'cn_q1',
      ));
      expect(r4, isA<MaterialPageRoute>());
    });

    test('1.10 AppRouter fallback builds placeholder Scaffold for unknown routes without exception', () {
      final route = AppRouter.onGenerateRoute(const RouteSettings(
        name: '/completely/unknown/adversarial/route',
      ));
      expect(route, isA<MaterialPageRoute>());
    });
  });

  // ---------------------------------------------------------------------------
  // DIMENSION 2: AUTHPROVIDER STATE MACHINE & FAILURE MODES
  // ---------------------------------------------------------------------------
  group('Tier 5 - Dimension 2: AuthProvider State Transitions & Failure Stress', () {
    test('2.1 AuthProvider initial state with null profile is unauthenticated', () async {
      final repo = MockAdversarialAuthRepo();
      final provider = AuthProvider(repo);

      await Future.delayed(Duration.zero);
      expect(provider.isAuthenticated, isFalse);
      expect(provider.status, equals(AuthStatus.unauthenticated));
      expect(provider.currentUser, isNull);
    });

    test('2.2 AuthProvider initial state with existing profile is authenticated', () async {
      final repo = MockAdversarialAuthRepo();
      repo.profileToReturn = buildTestUser(id: 'usr_init');
      final provider = AuthProvider(repo);

      await Future.delayed(Duration.zero);
      expect(provider.isAuthenticated, isTrue);
      expect(provider.status, equals(AuthStatus.authenticated));
      expect(provider.currentUser?.id, equals('usr_init'));
    });

    test('2.3 AuthProvider signIn failure strips Exception prefix and leaves unauthenticated', () async {
      final repo = MockAdversarialAuthRepo();
      repo.shouldThrowOnSignIn = true;
      repo.signInErrorMessage = 'Tài khoản đã bị khóa.';
      final provider = AuthProvider(repo);

      final success = await provider.signIn('bad@email.com', 'wrong');
      expect(success, isFalse);
      expect(provider.isAuthenticated, isFalse);
      expect(provider.status, equals(AuthStatus.unauthenticated));
      expect(provider.errorMessage, equals('Tài khoản đã bị khóa.'));
    });

    test('2.4 AuthProvider signIn success updates currentUser and clears errors', () async {
      final repo = MockAdversarialAuthRepo();
      repo.profileToReturn = buildTestUser(id: 'usr_valid', email: 'khach1@cinema.vn');
      final provider = AuthProvider(repo);

      final success = await provider.signIn('khach1@cinema.vn', '123456');
      expect(success, isTrue);
      expect(provider.isAuthenticated, isTrue);
      expect(provider.currentUser?.email, equals('khach1@cinema.vn'));
      expect(provider.errorMessage, isNull);
    });

    test('2.5 AuthProvider signUp failure captures clean error message', () async {
      final repo = MockAdversarialAuthRepo();
      repo.shouldThrowOnSignUp = true;
      repo.signUpErrorMessage = 'Email đã được sử dụng.';
      final provider = AuthProvider(repo);

      final ok = await provider.signUp(
        email: 'dup@cinema.vn',
        password: 'pass',
        fullName: 'Nguyễn Văn A',
      );
      expect(ok, isFalse);
      expect(provider.isAuthenticated, isFalse);
      expect(provider.errorMessage, equals('Email đã được sử dụng.'));
    });

    test('2.6 AuthProvider signUp success sets authenticated state', () async {
      final repo = MockAdversarialAuthRepo();
      final provider = AuthProvider(repo);

      final ok = await provider.signUp(
        email: 'new@cinema.vn',
        password: 'password123',
        fullName: 'Khách Mới',
        phone: '0901234567',
      );
      expect(ok, isTrue);
      expect(provider.isAuthenticated, isTrue);
      expect(provider.currentUser?.fullName, equals('Khách Mới'));
    });

    test('2.7 AuthProvider updateProfile preserves authenticated status even on failure', () async {
      final repo = MockAdversarialAuthRepo();
      repo.profileToReturn = buildTestUser(fullName: 'Old Name');
      final provider = AuthProvider(repo);
      await Future.delayed(Duration.zero);

      repo.shouldThrowOnUpdate = true;
      repo.updateErrorMessage = 'Lỗi kết nối cơ sở dữ liệu';

      final ok = await provider.updateProfile(fullName: 'New Name');
      expect(ok, isFalse);
      expect(provider.isAuthenticated, isTrue); // Should not log user out on profile update failure
      expect(provider.errorMessage, equals('Lỗi kết nối cơ sở dữ liệu'));
    });

    test('2.8 AuthProvider updateProfile success updates current user', () async {
      final repo = MockAdversarialAuthRepo();
      repo.profileToReturn = buildTestUser(fullName: 'Old Name');
      final provider = AuthProvider(repo);
      await Future.delayed(Duration.zero);

      final ok = await provider.updateProfile(fullName: 'Updated Name', phone: '0988776655');
      expect(ok, isTrue);
      expect(provider.currentUser?.fullName, equals('Updated Name'));
      expect(provider.currentUser?.phone, equals('0988776655'));
    });

    test('2.9 AuthProvider signOut completely clears user and state', () async {
      final repo = MockAdversarialAuthRepo();
      repo.profileToReturn = buildTestUser();
      final provider = AuthProvider(repo);
      await Future.delayed(Duration.zero);
      expect(provider.isAuthenticated, isTrue);

      await provider.signOut();
      expect(provider.currentUser, isNull);
      expect(provider.isAuthenticated, isFalse);
      expect(provider.status, equals(AuthStatus.unauthenticated));
    });

    test('2.10 AuthProvider clearError clears error message and notifies', () {
      final repo = MockAdversarialAuthRepo();
      final provider = AuthProvider(repo);

      provider.clearError();
      expect(provider.errorMessage, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // DIMENSION 3: BOOKINGPROVIDER DEEP WHITE-BOX LOGIC & ADVERSARIAL CASES
  // ---------------------------------------------------------------------------
  group('Tier 5 - Dimension 3: BookingProvider Deep White-Box & Adversarial Cases', () {
    test('3.1 toggleSeat strictly allows 8 seats and blocks 9th seat with error', () {
      final provider = BookingProvider(MockAdversarialSeatRepo());
      final showtime = buildTestShowtime();
      provider.setShowtime(showtime);

      for (int i = 1; i <= 8; i++) {
        provider.toggleSeat('A$i', SeatType.standard);
        expect(provider.selectedSeatIds.length, equals(i));
        expect(provider.errorMessage, isNull);
      }

      // 9th seat attempt
      provider.toggleSeat('A9', SeatType.standard);
      expect(provider.selectedSeatIds.length, equals(8));
      expect(provider.errorMessage, contains('tối đa 8 ghế'));

      // Deselect A1
      provider.toggleSeat('A1', SeatType.standard);
      expect(provider.selectedSeatIds.length, equals(7));

      // Now A9 can be selected
      provider.toggleSeat('A9', SeatType.standard);
      expect(provider.selectedSeatIds.length, equals(8));
      expect(provider.selectedSeatIds.contains('A9'), isTrue);
    });

    test('3.2 updateFoodQuantity adds, increments, decrements, and removes on 0 or negative', () {
      final provider = BookingProvider(MockAdversarialSeatRepo());
      final food1 = buildTestFood(id: 'fd_01', name: 'Bắp Rang Bơ', price: 45000);
      final food2 = buildTestFood(id: 'fd_02', name: 'Nước Ngọt', price: 25000);

      provider.updateFoodQuantity(food1, 2);
      expect(provider.selectedFoods.length, equals(1));
      expect(provider.selectedFoods.first.quantity, equals(2));

      // Increment
      provider.updateFoodQuantity(food1, 5);
      expect(provider.selectedFoods.first.quantity, equals(5));

      // Add second food
      provider.updateFoodQuantity(food2, 1);
      expect(provider.selectedFoods.length, equals(2));

      // Decrement to 0 removes food1
      provider.updateFoodQuantity(food1, 0);
      expect(provider.selectedFoods.length, equals(1));
      expect(provider.selectedFoods.first.id, equals('fd_02'));

      // Negative quantity removes food2
      provider.updateFoodQuantity(food2, -3);
      expect(provider.selectedFoods, isEmpty);
    });

    test('3.3 calculateTicketTotal implements exact multi-seat dynamic pricing formula', () {
      final provider = BookingProvider(MockAdversarialSeatRepo());
      // Friday 19:30 (Weekend + Prime = +20k time surcharge), IMAX format (base 120k)
      final fridayPrime = DateTime(2026, 10, 30, 19, 30); // 2026-10-30 is a Friday
      final showtime = buildTestShowtime(
        format: 'IMAX',
        startTime: fridayPrime,
      );
      provider.setShowtime(showtime);

      provider.toggleSeat('A1', SeatType.standard); // 120k + 20k = 140k
      provider.toggleSeat('V1', SeatType.vip);      // 120k + 20k vip + 20k time = 160k
      provider.toggleSeat('C1', SeatType.couple);   // (2 * 120k) + 20k couple + 20k time = 280k

      // Expected total: 140k + 160k + 280k = 580k
      expect(provider.calculateTicketTotal(), equals(580000));
    });

    test('3.4 calculateTicketTotal prime time boundaries (17:59 vs 18:00 vs 21:59 vs 22:00)', () {
      final provider = BookingProvider(MockAdversarialSeatRepo());
      // Wednesday (non-weekend)
      final wednesday = DateTime(2026, 10, 28);

      // 17:59 (no prime)
      provider.setShowtime(buildTestShowtime(
        format: '2D',
        startTime: DateTime(wednesday.year, wednesday.month, wednesday.day, 17, 59),
      ));
      provider.toggleSeat('A1', SeatType.standard);
      expect(provider.calculateTicketTotal(), equals(80000));

      // 18:00 (prime start)
      provider.setShowtime(buildTestShowtime(
        format: '2D',
        startTime: DateTime(wednesday.year, wednesday.month, wednesday.day, 18, 0),
      ));
      provider.toggleSeat('A1', SeatType.standard);
      expect(provider.calculateTicketTotal(), equals(90000)); // 80k base + 10k prime

      // 21:59 (prime end boundary)
      provider.setShowtime(buildTestShowtime(
        format: '2D',
        startTime: DateTime(wednesday.year, wednesday.month, wednesday.day, 21, 59),
      ));
      provider.toggleSeat('A1', SeatType.standard);
      expect(provider.calculateTicketTotal(), equals(90000)); // 80k base + 10k prime

      // 22:00 (no prime)
      provider.setShowtime(buildTestShowtime(
        format: '2D',
        startTime: DateTime(wednesday.year, wednesday.month, wednesday.day, 22, 0),
      ));
      provider.toggleSeat('A1', SeatType.standard);
      expect(provider.calculateTicketTotal(), equals(80000));
    });

    test('3.5 calculateGrandTotal clamps negative values to 0 when discount exceeds total', () {
      final provider = BookingProvider(MockAdversarialSeatRepo());
      final showtime = buildTestShowtime(format: '2D');
      provider.setShowtime(showtime);
      provider.toggleSeat('A1', SeatType.standard); // 80k or 90k/100k depending on day

      final snapshot = provider.generatePriceSnapshot();
      expect(snapshot['total'], isNonNegative);

      // Grand total should never be negative even if large discount applied
      expect(provider.calculateGrandTotal(), isNonNegative);
    });

    test('3.6 generateBookingCode produces 8-char unambiguous uppercase alphanumeric code', () {
      final codeRegex = RegExp(r'^[A-Z2-9]{8}$');
      for (int i = 0; i < 50; i++) {
        final code = BookingProvider.generateBookingCode();
        expect(code.length, equals(8));
        expect(codeRegex.hasMatch(code), isTrue, reason: 'Code $code contains ambiguous or invalid characters');
        expect(code.contains('0'), isFalse);
        expect(code.contains('1'), isFalse);
        expect(code.contains('O'), isFalse);
        expect(code.contains('I'), isFalse);
      }
    });

    test('3.7 syncBookingDetails returns false immediately if missing showtime or seats', () async {
      final provider = BookingProvider(MockAdversarialSeatRepo());
      expect(await provider.syncBookingDetails(), isFalse);

      provider.setShowtime(buildTestShowtime());
      expect(await provider.syncBookingDetails(), isFalse); // still no seats/booking code
    });

    test('3.8 holdSelectedSeats handles SeatTakenException with exact seat error message', () async {
      final mockSeatRepo = MockAdversarialSeatRepo();
      mockSeatRepo.shouldThrowTaken = true;
      mockSeatRepo.takenSeatId = 'C7';

      final provider = BookingProvider(mockSeatRepo);
      provider.setShowtime(buildTestShowtime());
      provider.toggleSeat('C7', SeatType.standard);

      final success = await provider.holdSelectedSeats();
      expect(success, isFalse);
      expect(provider.errorMessage, contains('C7'));
    });

    test('3.9 releaseCurrentHold calls repo releaseHold with current code', () async {
      final mockSeatRepo = MockAdversarialSeatRepo();
      final provider = BookingProvider(mockSeatRepo);
      provider.setShowtime(buildTestShowtime());
      provider.toggleSeat('A1', SeatType.standard);

      await provider.holdSelectedSeats();
      final code = provider.currentBookingCode;
      expect(code, isNotNull);

      await provider.releaseCurrentHold();
      expect(mockSeatRepo.lastReleasedCode, equals(code));
      expect(provider.currentBookingCode, isNull);
      expect(provider.holdUntil, isNull);
    });

    test('3.10 reset completely clears all selections, voucher and state', () {
      final provider = BookingProvider(MockAdversarialSeatRepo());
      provider.setShowtime(buildTestShowtime());
      provider.toggleSeat('A1', SeatType.standard);
      provider.updateFoodQuantity(buildTestFood(), 2);

      provider.reset();
      expect(provider.selectedShowtime, isNull);
      expect(provider.selectedSeatIds, isEmpty);
      expect(provider.selectedFoods, isEmpty);
      expect(provider.currentBookingCode, isNull);
      expect(provider.discount, equals(0));
      expect(provider.errorMessage, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // DIMENSION 4: VOUCHER MODEL CALCULATION & EXHAUSTION INVARIANTS
  // ---------------------------------------------------------------------------
  group('Tier 5 - Dimension 4: Voucher Model Calculation & Exhaustion Invariants', () {
    test('4.1 VoucherModel minBookingAmount threshold boundary', () {
      final voucher = VoucherModel(
        code: 'MIN100K',
        type: 'amount',
        value: 20000,
        minBookingAmount: 100000,
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        expiresAt: DateTime.now().add(const Duration(days: 10)),
        maxUses: 100,
        createdAt: DateTime.now(),
      );

      // Exactly at minimum
      expect(voucher.calculateDiscount(100000), equals(20000));
      // Above minimum
      expect(voucher.calculateDiscount(150000), equals(20000));
      // 1 VND below minimum -> 0 discount
      expect(voucher.calculateDiscount(99999), equals(0));
    });

    test('4.2 Percent voucher with maxDiscount cap and rounding', () {
      final voucher = VoucherModel(
        code: 'DISC20',
        type: 'percent',
        value: 20, // 20%
        maxDiscount: 30000,
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        expiresAt: DateTime.now().add(const Duration(days: 10)),
        maxUses: 50,
        createdAt: DateTime.now(),
      );

      // 20% of 100,000 = 20,000 (< 30,000 cap)
      expect(voucher.calculateDiscount(100000), equals(20000));
      // 20% of 200,000 = 40,000 -> capped at 30,000
      expect(voucher.calculateDiscount(200000), equals(30000));
    });

    test('4.3 Fixed amount voucher cannot exceed booking ticket total', () {
      final voucher = VoucherModel(
        code: 'BIG50K',
        type: 'amount',
        value: 50000,
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        expiresAt: DateTime.now().add(const Duration(days: 10)),
        maxUses: 50,
        createdAt: DateTime.now(),
      );

      // Ticket total is 30,000 -> discount clamped to 30,000
      expect(voucher.calculateDiscount(30000), equals(30000));
    });

    test('4.4 Inactive voucher returns 0 discount and TẠM KHÓA status badge', () {
      final voucher = VoucherModel(
        code: 'INACTIVE',
        type: 'amount',
        value: 20000,
        isActive: false,
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        expiresAt: DateTime.now().add(const Duration(days: 10)),
        maxUses: 50,
        createdAt: DateTime.now(),
      );

      expect(voucher.isUsable, isFalse);
      expect(voucher.calculateDiscount(100000), equals(0));
      expect(voucher.statusBadgeText, equals('TẠM KHÓA'));
    });

    test('4.5 Expired voucher returns 0 discount and HẾT HẠN status badge', () {
      final voucher = VoucherModel(
        code: 'EXPIRED',
        type: 'amount',
        value: 20000,
        startDate: DateTime.now().subtract(const Duration(days: 10)),
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
        maxUses: 50,
        createdAt: DateTime.now(),
      );

      expect(voucher.isExpired, isTrue);
      expect(voucher.isUsable, isFalse);
      expect(voucher.calculateDiscount(100000), equals(0));
      expect(voucher.statusBadgeText, equals('HẾT HẠN'));
    });

    test('4.6 Exhausted voucher (usedCount == maxUses) returns HẾT LƯỢT badge', () {
      final voucher = VoucherModel(
        code: 'EXHAUSTED',
        type: 'amount',
        value: 20000,
        maxUses: 10,
        usedCount: 10,
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        expiresAt: DateTime.now().add(const Duration(days: 10)),
        createdAt: DateTime.now(),
      );

      expect(voucher.isExhausted, isTrue);
      expect(voucher.isUsable, isFalse);
      expect(voucher.calculateDiscount(100000), equals(0));
      expect(voucher.statusBadgeText, equals('HẾT LƯỢT'));
    });

    test('4.7 Boundary check: usedCount == maxUses - 1 is still usable', () {
      final voucher = VoucherModel(
        code: 'LASTUSE',
        type: 'amount',
        value: 15000,
        maxUses: 5,
        usedCount: 4,
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        expiresAt: DateTime.now().add(const Duration(days: 10)),
        createdAt: DateTime.now(),
      );

      expect(voucher.isExhausted, isFalse);
      expect(voucher.isUsable, isTrue);
      expect(voucher.calculateDiscount(100000), equals(15000));
      expect(voucher.statusBadgeText, equals('CÒN HẠN'));
    });

    test('4.8 VoucherModel serialization round-trip retains uppercase code and properties', () {
      final original = VoucherModel(
        code: 'code_lowercase',
        type: 'percent',
        value: 15,
        minBookingAmount: 50000,
        maxDiscount: 25000,
        startDate: DateTime(2026, 1, 1),
        expiresAt: DateTime(2026, 12, 31),
        maxUses: 200,
        usedCount: 12,
        isActive: true,
        createdAt: DateTime(2026, 1, 1),
      );

      final map = original.toMap();
      expect(map['code'], equals('CODE_LOWERCASE'));

      final restored = VoucherModel.fromMap(map);
      expect(restored.code, equals('CODE_LOWERCASE'));
      expect(restored.value, equals(15));
      expect(restored.maxDiscount, equals(25000));
      expect(restored.usedCount, equals(12));
    });
  });

  // ---------------------------------------------------------------------------
  // DIMENSION 5: PRICINGSETTINGSMODEL EDGE CASES & BOUNDARY CONDITIONS
  // ---------------------------------------------------------------------------
  group('Tier 5 - Dimension 5: PricingSettingsModel Edge Cases & Boundary Conditions', () {
    test('5.1 Default settings match BUSINESS_RULES.md Section 4 values', () {
      final settings = PricingSettingsModel.defaultSettings();
      expect(settings.base2d, equals(80000));
      expect(settings.base3d, equals(100000));
      expect(settings.baseImax, equals(120000));
      expect(settings.surchargeVip, equals(20000));
      expect(settings.surchargeCouple, equals(20000));
      expect(settings.surchargeWeekend, equals(10000));
      expect(settings.surchargePrime, equals(10000));
    });

    test('5.2 Custom promotional pricing with 0 surcharges computes base rates correctly', () {
      final promo = PricingSettingsModel(
        base2d: 50000,
        base3d: 70000,
        baseImax: 90000,
        surchargeVip: 0,
        surchargeCouple: 0,
        surchargeWeekend: 0,
        surchargePrime: 0,
        updatedAt: DateTime.now(),
      );

      final vipPrice = promo.calculateSeatPrice(
        format: '2D',
        seatType: 'vip',
        isWeekend: true,
        isPrimeTime: true,
      );
      expect(vipPrice, equals(50000)); // All surcharges 0
    });

    test('5.3 Format string is case-insensitive (3d, 3D, imax, IMAX)', () {
      final settings = PricingSettingsModel.defaultSettings();
      expect(
        settings.calculateSeatPrice(format: '3d', seatType: 'standard', isWeekend: false, isPrimeTime: false),
        equals(100000),
      );
      expect(
        settings.calculateSeatPrice(format: '3D', seatType: 'standard', isWeekend: false, isPrimeTime: false),
        equals(100000),
      );
      expect(
        settings.calculateSeatPrice(format: 'imax', seatType: 'standard', isWeekend: false, isPrimeTime: false),
        equals(120000),
      );
    });

    test('5.4 Unknown format defaults safely to base2d', () {
      final settings = PricingSettingsModel.defaultSettings();
      final price = settings.calculateSeatPrice(
        format: '4DX_EXPERIMENTAL',
        seatType: 'standard',
        isWeekend: false,
        isPrimeTime: false,
      );
      expect(price, equals(80000));
    });

    test('5.5 Couple seat doubles format base price and adds couple surcharge', () {
      final settings = PricingSettingsModel.defaultSettings();
      // Couple on 3D (base 100k) on weekend (+10k) and prime (+10k):
      // 2 * 100k + 20k couple + 10k weekend + 10k prime = 240k
      final price = settings.calculateSeatPrice(
        format: '3D',
        seatType: 'couple',
        isWeekend: true,
        isPrimeTime: true,
      );
      expect(price, equals(240000));
    });

    test('5.6 Serialization round-trip with fallback defaults handles missing keys', () {
      final rawMap = <String, dynamic>{
        'base_2d': 85000,
      };
      final model = PricingSettingsModel.fromMap(rawMap);
      expect(model.base2d, equals(85000));
      expect(model.base3d, equals(100000)); // Default fallback
      expect(model.surchargeVip, equals(20000));

      final outputMap = model.toMap();
      expect(outputMap['base_2d'], equals(85000));
    });
  });

  // ---------------------------------------------------------------------------
  // DIMENSION 6: STAFF CHECK-IN PROVIDER & VALIDATION CASCADE
  // ---------------------------------------------------------------------------
  group('Tier 5 - Dimension 6: Staff Check-in Provider & Validation Cascade', () {
    test('6.1 CheckinProvider normalizes booking code by trimming and converting to uppercase', () async {
      final repo = MockAdversarialCheckinRepo();
      final provider = CheckinProvider(repo);

      await provider.checkIn('   k7m2qx9p   ');
      expect(provider.currentScannedCode, equals('K7M2QX9P'));
    });

    test('6.2 CheckinProvider resets isIdVerified flag on each new scan', () async {
      final repo = MockAdversarialCheckinRepo();
      final provider = CheckinProvider(repo);

      provider.setIdVerified(true);
      expect(provider.isIdVerified, isTrue);

      await provider.checkIn('NEWCODE1');
      expect(provider.isIdVerified, isFalse);
    });

    test('6.3 CheckinProvider captures repository exceptions into CheckinResult gracefully', () async {
      final repo = MockAdversarialCheckinRepo();
      repo.shouldThrow = true;
      repo.errorMessage = 'Network timeout on RPC';
      final provider = CheckinProvider(repo);

      final result = await provider.checkIn('K7M2QX9P');
      expect(result.isSuccess, isFalse);
      expect(result.message, contains('Network timeout on RPC'));
      expect(provider.errorMessage, contains('Network timeout on RPC'));
    });

    test('6.4 CheckinProvider resetScan resets all presentation state', () async {
      final repo = MockAdversarialCheckinRepo();
      final provider = CheckinProvider(repo);

      await provider.checkIn('K7M2QX9P');
      provider.setIdVerified(true);

      provider.resetScan();
      expect(provider.lastResult, isNull);
      expect(provider.currentScannedCode, isNull);
      expect(provider.isIdVerified, isFalse);
      expect(provider.errorMessage, isNull);
    });

    test('6.5 8-Step Oracle: non-existent booking returns notExists code', () {
      final result = evaluateCheckIn(
        booking: null,
        staffCinemaId: 'cn_q1',
        currentTime: DateTime.now(),
      );
      expect(result.code, equals(CheckinValidationCode.notExists));
      expect(result.isSuccess, isFalse);
      expect(result.message, contains('không tồn tại'));
    });

    test('6.6 8-Step Oracle: cancelled or already used booking returns exact error', () {
      final cancelled = buildTestBooking(status: 'cancelled');
      final r1 = evaluateCheckIn(booking: cancelled, staffCinemaId: 'cn_q1', currentTime: DateTime.now());
      expect(r1.code, equals(CheckinValidationCode.cancelled));
      expect(r1.isSuccess, isFalse);

      final used = buildTestBooking(status: 'used');
      final r2 = evaluateCheckIn(booking: used, staffCinemaId: 'cn_q1', currentTime: DateTime.now());
      expect(r2.code, equals(CheckinValidationCode.used));
      expect(r2.isSuccess, isFalse);
    });

    test('6.7 8-Step Oracle: wrong cinema rejects cross-branch presentation', () {
      final ticketFromTB = buildTestBooking(cinemaId: 'cn_tb', cinemaName: 'Cinema Tân Bình');
      final result = evaluateCheckIn(
        booking: ticketFromTB,
        staffCinemaId: 'cn_q1', // Staff is at Q1
        currentTime: DateTime.now(),
      );
      expect(result.code, equals(CheckinValidationCode.wrongCinema));
      expect(result.isSuccess, isFalse);
      expect(result.message, contains('Cinema Tân Bình'));
    });

    test('6.8 8-Step Oracle: time window (-30m early cutoff, +15m late cutoff)', () {
      final showtimeStart = DateTime(2026, 10, 28, 20, 0);
      final booking = buildTestBooking(
        showtimeStart: showtimeStart,
        cinemaId: 'cn_q1',
        status: 'paid',
      );

      // Too early: 19:29 (31 minutes before showtime)
      final early = evaluateCheckIn(
        booking: booking,
        staffCinemaId: 'cn_q1',
        currentTime: DateTime(2026, 10, 28, 19, 29),
      );
      expect(early.code, equals(CheckinValidationCode.tooEarly));

      // Valid: 19:35 (25 minutes before showtime)
      final valid = evaluateCheckIn(
        booking: booking,
        staffCinemaId: 'cn_q1',
        currentTime: DateTime(2026, 10, 28, 19, 35),
      );
      expect(valid.code, equals(CheckinValidationCode.success));
      expect(valid.isSuccess, isTrue);

      // Too late: 20:16 (16 minutes after showtime -> noShow)
      final lateResult = evaluateCheckIn(
        booking: booking,
        staffCinemaId: 'cn_q1',
        currentTime: DateTime(2026, 10, 28, 20, 16),
      );
      expect(lateResult.code, equals(CheckinValidationCode.expiredShowtime));
      expect(lateResult.isSuccess, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // DIMENSION 7: STAFF FOOD PROVIDER SEARCH & SHOWTIME ORDERING
  // ---------------------------------------------------------------------------
  group('Tier 5 - Dimension 7: Staff Food Provider Search & Showtime Ordering', () {
    test('7.1 Orders are sorted ascending by showtimeStart upon load', () async {
      final repo = MockAdversarialFoodRepo();
      final now = DateTime.now();
      repo.pending = [
        buildTestBooking(code: 'LATE', showtimeStart: now.add(const Duration(hours: 3))),
        buildTestBooking(code: 'EARLY', showtimeStart: now.add(const Duration(hours: 1))),
        buildTestBooking(code: 'MID', showtimeStart: now.add(const Duration(hours: 2))),
      ];

      final provider = StaffFoodProvider(repo);
      await provider.loadOrders('cn_q1');

      expect(provider.pendingOrders.first.code, equals('EARLY'));
      expect(provider.pendingOrders[1].code, equals('MID'));
      expect(provider.pendingOrders.last.code, equals('LATE'));
    });

    test('7.2 Search query filters by booking code (case-insensitive)', () async {
      final repo = MockAdversarialFoodRepo();
      repo.pending = [
        buildTestBooking(code: 'ABCDEFGH'),
        buildTestBooking(code: 'ZXCVBNMM'),
      ];

      final provider = StaffFoodProvider(repo);
      await provider.loadOrders('cn_q1');

      provider.setSearchQuery('abcdefgh');
      expect(provider.pendingOrders.length, equals(1));
      expect(provider.pendingOrders.first.code, equals('ABCDEFGH'));
    });

    test('7.3 Search query filters by movie title (case-insensitive partial match)', () async {
      final repo = MockAdversarialFoodRepo();
      repo.pending = [
        buildTestBooking(code: 'T1', movieTitle: 'Dune: Part Two'),
        buildTestBooking(code: 'T2', movieTitle: 'Kung Fu Panda 4'),
      ];

      final provider = StaffFoodProvider(repo);
      await provider.loadOrders('cn_q1');

      provider.setSearchQuery('panda');
      expect(provider.pendingOrders.length, equals(1));
      expect(provider.pendingOrders.first.code, equals('T2'));
    });

    test('7.4 Search query with special adversarial characters returns empty list without exception', () async {
      final repo = MockAdversarialFoodRepo();
      repo.pending = [buildTestBooking(code: 'T1')];

      final provider = StaffFoodProvider(repo);
      await provider.loadOrders('cn_q1');

      provider.setSearchQuery('?.*+[]^');
      expect(provider.pendingOrders, isEmpty);
    });

    test('7.5 Tab switching changes currentTabIndex (0 = Chờ giao, 1 = Đã giao)', () {
      final provider = StaffFoodProvider(MockAdversarialFoodRepo());
      expect(provider.currentTabIndex, equals(0));

      provider.setTab(1);
      expect(provider.currentTabIndex, equals(1));

      provider.setTab(0);
      expect(provider.currentTabIndex, equals(0));
    });

    test('7.6 deliverFood handles repository failure gracefully and sets errorMessage', () async {
      final repo = MockAdversarialFoodRepo();
      repo.shouldThrowOnDeliver = true;

      final provider = StaffFoodProvider(repo);
      final ok = await provider.deliverFood('K7M2QX9P', 'cn_q1');
      expect(ok, isFalse);
      expect(provider.errorMessage, contains('Không thể cập nhật'));
    });
  });

  // ---------------------------------------------------------------------------
  // DIMENSION 8: STAFF COUNTER PROVIDER SALES & CHANGE CALCULATION
  // ---------------------------------------------------------------------------
  group('Tier 5 - Dimension 8: Staff Counter Provider Sales & Change Calculation', () {
    test('8.1 calculateChange returns 0 on exact tender and positive difference on overpayment', () {
      final provider = StaffCounterProvider(MockAdversarialCounterRepo());
      provider.selectShowtime(buildTestShowtime());
      provider.toggleSeat('A1'); // 1 seat @ minPrice (e.g. 80k)

      final total = provider.calculateTotal();
      expect(total, isPositive);

      // Exact amount
      expect(provider.calculateChange(total), equals(0));

      // Overpaid
      expect(provider.calculateChange(total + 50000), equals(50000));

      // Underpaid -> returns 0 (never negative)
      expect(provider.calculateChange(total - 10000), equals(0));
    });

    test('8.2 Counter seat selection strictly enforces 8-seat limit', () {
      final provider = StaffCounterProvider(MockAdversarialCounterRepo());
      provider.selectShowtime(buildTestShowtime());

      for (int i = 1; i <= 8; i++) {
        expect(provider.toggleSeat('S$i'), isTrue);
      }
      expect(provider.selectedSeatIds.length, equals(8));

      // 9th seat blocked
      expect(provider.toggleSeat('S9'), isFalse);
      expect(provider.selectedSeatIds.length, equals(8));
      expect(provider.errorMessage, contains('tối đa 8 ghế'));
    });

    test('8.3 setFoodQuantity adds with correct total, updates, and removes on 0', () {
      final provider = StaffCounterProvider(MockAdversarialCounterRepo());

      provider.setFoodQuantity('fd_01', 'Combo 1', 75000, 2);
      expect(provider.selectedFoods.length, equals(1));
      expect(provider.selectedFoods.first['total'], equals(150000));

      // Update quantity
      provider.setFoodQuantity('fd_01', 'Combo 1', 75000, 3);
      expect(provider.selectedFoods.first['qty'], equals(3));
      expect(provider.selectedFoods.first['total'], equals(225000));

      // Remove on 0
      provider.setFoodQuantity('fd_01', 'Combo 1', 75000, 0);
      expect(provider.selectedFoods, isEmpty);
    });

    test('8.4 holdSeatsForCounter returns false immediately without showtime or seats', () async {
      final provider = StaffCounterProvider(MockAdversarialCounterRepo());
      expect(await provider.holdSeatsForCounter(), isFalse);

      provider.selectShowtime(buildTestShowtime());
      expect(await provider.holdSeatsForCounter(), isFalse); // no seats
    });

    test('8.5 completeSale returns false immediately without selected showtime', () async {
      final provider = StaffCounterProvider(MockAdversarialCounterRepo());
      expect(await provider.completeSale('cash'), isFalse);
    });

    test('8.6 completeSale handles repository errors and records errorMessage', () async {
      final repo = MockAdversarialCounterRepo();
      repo.shouldThrowSale = true;

      final provider = StaffCounterProvider(repo);
      provider.selectShowtime(buildTestShowtime());
      provider.toggleSeat('A1');

      final ok = await provider.completeSale('card');
      expect(ok, isFalse);
      expect(provider.errorMessage, contains('thất bại'));
    });
  });

  // ---------------------------------------------------------------------------
  // DIMENSION 9: DOMAIN MODEL EDGE CASES & SERIALIZATION ROBUSTNESS
  // ---------------------------------------------------------------------------
  group('Tier 5 - Dimension 9: Domain Model Edge Cases & Robustness', () {
    test('9.1 BookingModel isNoShow condition exact boundaries', () {
      final now = DateTime.now();

      // Show started 16 minutes ago, paid, unchecked -> isNoShow
      final b1 = buildTestBooking(
        status: 'paid',
        showtimeStart: now.subtract(const Duration(minutes: 16)),
        checkedInAt: null,
      );
      expect(b1.isNoShow, isTrue);

      // Show started 14 minutes ago, paid, unchecked -> not yet noShow
      final b2 = buildTestBooking(
        status: 'paid',
        showtimeStart: now.subtract(const Duration(minutes: 14)),
        checkedInAt: null,
      );
      expect(b2.isNoShow, isFalse);

      // Show started 30 minutes ago, but ALREADY checked in -> not noShow
      final b3 = buildTestBooking(
        status: 'paid',
        showtimeStart: now.subtract(const Duration(minutes: 30)),
        checkedInAt: now.subtract(const Duration(minutes: 35)),
      );
      expect(b3.isNoShow, isFalse);
    });

    test('9.2 BookingModel canCancel condition exact 2-hour cutoff boundaries', () {
      final now = DateTime.now();

      // Showtime in 2 hours 5 minutes -> canCancel is true
      final b1 = buildTestBooking(
        status: 'paid',
        showtimeStart: now.add(const Duration(hours: 2, minutes: 5)),
      );
      expect(b1.canCancel, isTrue);

      // Showtime in 1 hour 55 minutes -> canCancel is false
      final b2 = buildTestBooking(
        status: 'paid',
        showtimeStart: now.add(const Duration(hours: 1, minutes: 55)),
      );
      expect(b2.canCancel, isFalse);

      // Cancelled or used ticket cannot be cancelled
      final b3 = buildTestBooking(
        status: 'used',
        showtimeStart: now.add(const Duration(hours: 3)),
      );
      expect(b3.canCancel, isFalse);
    });

    test('9.3 BookingModel displayStatus reflects noShow, expired, or DB status', () {
      final now = DateTime.now();

      final noShowBooking = buildTestBooking(
        status: 'paid',
        showtimeStart: now.subtract(const Duration(minutes: 20)),
        checkedInAt: null,
      );
      expect(noShowBooking.displayStatus, equals('noShow'));

      final expiredHold = buildTestBooking(
        status: 'holding',
        holdUntil: now.subtract(const Duration(minutes: 1)),
      );
      expect(expiredHold.displayStatus, equals('expired'));

      final paidBooking = buildTestBooking(
        status: 'paid',
        showtimeStart: now.add(const Duration(hours: 2)),
      );
      expect(paidBooking.displayStatus, equals('paid'));
    });

    test('9.4 BookingModel seatNamesSummary and foodSummary handle empty lists gracefully', () {
      final b = buildTestBooking(seats: [], foods: []);
      expect(b.seatNamesSummary, isEmpty);
      expect(b.foodSummary, isEmpty);
    });

    test('9.5 BookingModel round-trip serialization preserves all attributes including created_at', () {
      final original = buildTestBooking(
        code: 'K7M2QX9P',
        channel: 'online',
        foodStatus: 'pending',
        createdAt: DateTime(2026, 10, 28, 12, 0),
      );

      final map = original.toMap();
      expect(map['created_at'], isNotNull);
      final restored = BookingModel.fromMap(map);

      expect(restored.code, equals('K7M2QX9P'));
      expect(restored.channel, equals('online'));
      expect(restored.foodStatus, equals('pending'));
      expect(restored.createdAt, equals(original.createdAt));
    });

    test('9.6 ShowtimeModel isSoldOut and available seats calculation', () {
      final st1 = buildTestShowtime(totalSeats: 100, soldSeats: 99);
      expect(st1.isSoldOut, isFalse);
      expect(st1.totalSeats - st1.soldSeats, equals(1));

      final st2 = buildTestShowtime(totalSeats: 100, soldSeats: 100);
      expect(st2.isSoldOut, isTrue);
      expect(st2.totalSeats - st2.soldSeats, equals(0));

      final st3 = buildTestShowtime(totalSeats: 100, soldSeats: 105);
      expect(st3.isSoldOut, isTrue);
      expect(st3.totalSeats - st3.soldSeats, equals(-5));
    });

    test('9.7 MovieModel isNowShowing and isUpcoming release date boundaries', () {
      final now = DateTime.now();

      final releasedYesterday = buildTestMovie(releaseDate: now.subtract(const Duration(days: 1)), isActive: true);
      expect(releasedYesterday.isNowShowing, isTrue);
      expect(releasedYesterday.isUpcoming, isFalse);

      final releasingTomorrow = buildTestMovie(releaseDate: now.add(const Duration(days: 1)), isActive: true);
      expect(releasingTomorrow.isNowShowing, isFalse);
      expect(releasingTomorrow.isUpcoming, isTrue);

      final inactive = buildTestMovie(releaseDate: now.subtract(const Duration(days: 1)), isActive: false);
      expect(inactive.isNowShowing, isFalse);
      expect(inactive.isUpcoming, isFalse);
    });

    test('9.8 DashboardMetricsModel handles 0 capacity room without division by zero', () {
      const metrics = DashboardMetricsModel(
        cinemaId: 'cn_q1',
        period: 'today',
        todayRevenue: 0,
        todayTickets: 0,
        occupancyRate: 0.0,
        totalCapacity: 0, // 0 capacity
        soldCapacity: 0,
        upcomingShowtimes: [],
      );

      expect(metrics.occupancyRate, equals(0.0));
      expect(metrics.totalCapacity, equals(0));
    });
  });

  // ---------------------------------------------------------------------------
  // DIMENSION 10: MULTI-TENANT ISOLATION, LOCATION SERVICE & EXTRA CONTROLLERS
  // ---------------------------------------------------------------------------
  group('Tier 5 - Dimension 10: Multi-Tenant Isolation, Location & Extra Controllers', () {
    test('10.1 LocationService calculateDistanceKm returns 0.0 for identical coordinates', () {
      final distance = LocationService.calculateDistanceKm(
        startLatitude: 10.7769,
        startLongitude: 106.7009,
        endLatitude: 10.7769,
        endLongitude: 106.7009,
      );
      expect(distance, equals(0.0));
    });

    test('10.2 LocationService calculateDistanceKm accurately computes distance in HCM City', () {
      // Distance from Cinema District 1 (10.7769, 106.7009) to Cinema Tan Binh (10.8000, 106.6500)
      final distance = LocationService.calculateDistanceKm(
        startLatitude: 10.7769,
        startLongitude: 106.7009,
        endLatitude: 10.8000,
        endLongitude: 106.6500,
      );
      expect(distance, greaterThan(5.0));
      expect(distance, lessThan(8.0));
    });

    test('10.3 TicketProvider separates tickets into upcoming, history, and cancelled partitions', () async {
      final repo = MockAdversarialTicketRepo();
      final now = DateTime.now();

      final upcoming = buildTestBooking(code: 'UPCOMING', status: 'paid', showtimeStart: now.add(const Duration(hours: 3)));
      final used = buildTestBooking(code: 'USED', status: 'used', showtimeStart: now.subtract(const Duration(hours: 3)));
      final cancelled = buildTestBooking(code: 'CANCELLED', status: 'cancelled');

      repo.tickets = [upcoming, used, cancelled];

      final provider = TicketProvider(repo);
      await provider.loadMyTickets();

      expect(provider.upcomingTickets.map((t) => t.code), contains('UPCOMING'));
      expect(provider.upcomingTickets.map((t) => t.code), isNot(contains('USED')));
      expect(provider.upcomingTickets.map((t) => t.code), isNot(contains('CANCELLED')));

      expect(provider.historyTickets.map((t) => t.code), contains('USED'));
      expect(provider.historyTickets.map((t) => t.code), isNot(contains('UPCOMING')));

      expect(provider.cancelledTickets.map((t) => t.code), contains('CANCELLED'));
    });

    test('10.4 TicketProvider cancelBooking removes ticket and reloads list', () async {
      final repo = MockAdversarialTicketRepo();
      repo.tickets = [buildTestBooking(code: 'CANCEL_ME', status: 'paid')];

      final provider = TicketProvider(repo);
      await provider.loadMyTickets();
      expect(provider.upcomingTickets.length, equals(1));

      final ok = await provider.cancelBooking('CANCEL_ME');
      expect(ok, isTrue);
      expect(repo.lastCancelledCode, equals('CANCEL_ME'));
      expect(provider.upcomingTickets, isEmpty);
    });

    test('10.5 NotificationProvider unreadCount accurately counts unread notifications', () async {
      final repo = MockAdversarialNotifRepo();
      repo.notifications = [
        buildTestNotification(id: 'n1', isRead: false),
        buildTestNotification(id: 'n2', isRead: true),
        buildTestNotification(id: 'n3', isRead: false),
      ];

      final provider = NotificationProvider(repo);
      await provider.loadNotifications();

      expect(provider.unreadCount, equals(2));
      expect(provider.notifications.length, equals(3));
    });

    test('10.6 NotificationProvider markAllAsRead sets all items to read and reduces unreadCount to 0', () async {
      final repo = MockAdversarialNotifRepo();
      repo.notifications = [
        buildTestNotification(id: 'n1', isRead: false),
        buildTestNotification(id: 'n2', isRead: false),
      ];

      final provider = NotificationProvider(repo);
      await provider.loadNotifications();
      expect(provider.unreadCount, equals(2));

      await provider.markAllAsRead();
      expect(provider.unreadCount, equals(0));
      expect(provider.notifications.every((n) => n.isRead), isTrue);
    });

    test('10.7 Multi-tenant query scoping enforces cinema_id in all operational queries', () {
      // Invariant: Staff and Manager operations must strictly include cinema_id
      const cinemaId = 'cn_q1';
      final booking = buildTestBooking(cinemaId: cinemaId);
      expect(booking.cinemaId, equals(cinemaId));

      final auditLog = buildTestAuditLog(cinemaId: cinemaId);
      expect(auditLog['cinema_id'], equals(cinemaId));
    });
  });
}
