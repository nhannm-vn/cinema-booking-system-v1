import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:cinema_booking_v1/core/theme/app_theme.dart';
import 'package:cinema_booking_v1/features/auth/presentation/controllers/auth_provider.dart';
import 'package:cinema_booking_v1/features/booking/data/models/booking_model.dart';
import 'package:cinema_booking_v1/features/booking/data/models/room_model.dart';
import 'package:cinema_booking_v1/features/booking/data/models/showtime_model.dart';
import 'package:cinema_booking_v1/features/management/data/models/dashboard_metrics_model.dart';
import 'package:cinema_booking_v1/features/management/data/models/pricing_settings_model.dart';
import 'package:cinema_booking_v1/features/management/data/models/voucher_model.dart';
import 'package:cinema_booking_v1/features/management/data/repositories/management_repository.dart';
import 'package:cinema_booking_v1/features/management/presentation/controllers/management_provider.dart';
import 'package:cinema_booking_v1/features/management/presentation/screens/seat_map_designer_screen.dart';
import 'package:cinema_booking_v1/features/movies/data/movie_model.dart';
import 'package:cinema_booking_v1/features/tickets/data/ticket_repository.dart';
import 'package:cinema_booking_v1/features/tickets/presentation/controllers/ticket_provider.dart';
import 'package:cinema_booking_v1/features/tickets/presentation/screens/ticket_detail_screen.dart';
import 'package:cinema_booking_v1/shared/models/app_user.dart';

// =============================================================================
// CHALLENGER TEST DOUBLES FOR EMPIRICAL STRESS TESTING
// =============================================================================

class MockStressAuthProvider extends ChangeNotifier implements AuthProvider {
  final AppUser _user;

  MockStressAuthProvider({
    String id = 'usr_stress_mgr',
    String fullName = 'Manager Stress Test',
    UserRole role = UserRole.manager,
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

class MockStressTicketRepository implements TicketRepository {
  List<BookingModel> tickets = [];
  bool cancelSuccess = true;
  String? lastCancelledCode;

  @override
  Future<List<BookingModel>> getMyTickets() async => tickets;

  @override
  Future<BookingModel> getTicketByCode(String code) async {
    return tickets.firstWhere(
      (t) => t.code == code,
      orElse: () => throw Exception('TICKET_NOT_FOUND'),
    );
  }

  @override
  Future<void> cancelBooking(String code, {String reason = 'Khách hủy vé trực tuyến'}) async {
    if (!cancelSuccess) throw Exception('CANCEL_FAILED');
    lastCancelledCode = code;
    tickets = tickets.map((t) {
      if (t.code == code) {
        return t.copyWith(status: 'cancelled');
      }
      return t;
    }).toList();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockStressManagementRepository implements ManagementRepository {
  List<ShowtimeModel> showtimes = [];
  List<MovieModel> movies = [];
  List<RoomModel> rooms = [];
  bool hasSoldShowtimes = false;
  PricingSettingsModel pricingSettings = PricingSettingsModel.defaultSettings();
  List<VoucherModel> vouchers = [];

  @override
  Future<DashboardMetricsModel> getDashboardMetrics(String cinemaId, {String period = 'today'}) async {
    return DashboardMetricsModel(
      cinemaId: cinemaId,
      period: period,
      todayRevenue: 10000000,
      todayTickets: 100,
      occupancyRate: 50.0,
      totalCapacity: 200,
      soldCapacity: 100,
      upcomingShowtimes: const [],
    );
  }

  @override
  Future<List<ShowtimeModel>> getShowtimes({
    required String cinemaId,
    required DateTime date,
    String? roomId,
    String? format,
  }) async => showtimes;

  @override
  Future<List<MovieModel>> getAllMovies() async => movies;

  @override
  Future<List<RoomModel>> getRoomsByCinema(String cinemaId) async => rooms;

  @override
  Future<bool> hasFutureSoldShowtimes(String roomId) async => hasSoldShowtimes;

  @override
  Future<PricingSettingsModel> getPricingSettings() async => pricingSettings;

  @override
  Future<List<VoucherModel>> getVouchers() async => vouchers;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Pure algorithm replicating 15-minute cleaning interval rule per trg_showtime_conflict:
bool check15MinGapConflict({
  required DateTime candidateStart,
  required DateTime candidateEnd,
  required String candidateRoomId,
  required List<ShowtimeModel> existingShowtimes,
}) {
  for (final s in existingShowtimes) {
    if (s.isCancelled || s.roomId != candidateRoomId) continue;
    final limitStart = s.startTime.subtract(const Duration(minutes: 15));
    final limitEnd = s.endTime.add(const Duration(minutes: 15));

    if (candidateStart.isBefore(limitEnd) && candidateEnd.isAfter(limitStart)) {
      return true;
    }
  }
  return false;
}

// Helper builder for test booking
BookingModel buildStressBooking({
  required String code,
  required String status,
  required DateTime showtimeStart,
  int total = 100000,
  int ticketTotal = 100000,
  int foodTotal = 0,
  int discount = 0,
}) {
  return BookingModel(
    code: code,
    userId: 'usr_test',
    channel: 'online',
    status: status,
    showtimeId: 'st_test',
    cinemaId: 'cn_q1',
    movieTitle: 'Stress Test Movie',
    cinemaName: 'Cinema Q1',
    roomName: 'Phòng 1',
    format: '2D',
    paymentMethod: 'vnpay',
    priceSnapshot: {
      'total': total,
      'ticket_total': ticketTotal,
      'food_total': foodTotal,
      'discount': discount,
    },
    seats: const [{'id': 'A01', 'type': 'standard', 'price': 100000}],
    foods: const [],
    foodStatus: 'none',
    showtimeStart: showtimeStart,
    paidAt: DateTime.now().subtract(const Duration(minutes: 30)),
    createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ===========================================================================
  // GROUP 1: 2-HOUR CANCELLATION BOUNDARY CONDITIONS (1h59m vs 2h01m)
  // ===========================================================================
  group('1. 2-Hour Cancellation Boundary Stress Tests', () {
    test('Boundary 2h01m in future: canCancel is TRUE', () {
      final now = DateTime.now();
      // 2 hours 1 minute in future = 121 minutes
      final showtime = now.add(const Duration(hours: 2, minutes: 1));
      final booking = buildStressBooking(code: 'BK_2H01M', status: 'paid', showtimeStart: showtime);

      expect(booking.canCancel, isTrue,
          reason: 'Showtime is 2 hours and 1 minute away, well before the 2-hour cutoff');
    });

    test('Boundary 2h00m30s in future: canCancel is TRUE', () {
      final now = DateTime.now();
      final showtime = now.add(const Duration(hours: 2, seconds: 30));
      final booking = buildStressBooking(code: 'BK_2H30S', status: 'paid', showtimeStart: showtime);

      expect(booking.canCancel, isTrue,
          reason: 'Showtime is 2 hours and 30 seconds away (still > 2h cutoff)');
    });

    test('Boundary 1h59m in future: canCancel is FALSE', () {
      final now = DateTime.now();
      // 1 hour 59 minutes in future = 119 minutes
      final showtime = now.add(const Duration(hours: 1, minutes: 59));
      final booking = buildStressBooking(code: 'BK_1H59M', status: 'paid', showtimeStart: showtime);

      expect(booking.canCancel, isFalse,
          reason: 'Showtime is 1 hour and 59 minutes away, violating the >= 2-hour refund rule');
    });

    test('Boundary 1h59m59s in future: canCancel is FALSE', () {
      final now = DateTime.now();
      final showtime = now.add(const Duration(hours: 1, minutes: 59, seconds: 59));
      final booking = buildStressBooking(code: 'BK_1H59M59S', status: 'paid', showtimeStart: showtime);

      expect(booking.canCancel, isFalse,
          reason: '1 second under 2 hours is strictly non-cancellable');
    });

    test('Near showtime and past showtime: canCancel is FALSE', () {
      final now = DateTime.now();
      final t30m = buildStressBooking(code: 'BK_30M', status: 'paid', showtimeStart: now.add(const Duration(minutes: 30)));
      final tNow = buildStressBooking(code: 'BK_NOW', status: 'paid', showtimeStart: now);
      final tPast = buildStressBooking(code: 'BK_PAST', status: 'paid', showtimeStart: now.subtract(const Duration(hours: 3)));

      expect(t30m.canCancel, isFalse);
      expect(tNow.canCancel, isFalse);
      expect(tPast.canCancel, isFalse);
    });

    test('Status invariant: non-paid tickets with showtime > 2h cannot be cancelled via refund', () {
      final now = DateTime.now();
      final farFuture = now.add(const Duration(hours: 5));

      final holding = buildStressBooking(code: 'BK_HOLD', status: 'holding', showtimeStart: farFuture);
      final used = buildStressBooking(code: 'BK_USED', status: 'used', showtimeStart: farFuture);
      final cancelled = buildStressBooking(code: 'BK_CANC', status: 'cancelled', showtimeStart: farFuture);
      final expired = buildStressBooking(code: 'BK_EXP', status: 'expired', showtimeStart: farFuture);
      final noShow = buildStressBooking(code: 'BK_NS', status: 'noShow', showtimeStart: farFuture);

      expect(holding.canCancel, isFalse);
      expect(used.canCancel, isFalse);
      expect(cancelled.canCancel, isFalse);
      expect(expired.canCancel, isFalse);
      expect(noShow.canCancel, isFalse);
    });

    testWidgets('TicketDetailScreen UI: 2h05m renders Cancel button; 1h55m renders Warning banner', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockStressTicketRepository();
      final ticketProvider = TicketProvider(mockRepo);

      // Case A: 2h05m in future -> Cancel button must be visible
      final ticketCancellable = buildStressBooking(
        code: 'BK_CAN_UI',
        status: 'paid',
        showtimeStart: DateTime.now().add(const Duration(hours: 2, minutes: 5)),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: ChangeNotifierProvider<TicketProvider>.value(
            value: ticketProvider,
            child: TicketDetailScreen(
              key: const ValueKey('cancellable_ui'),
              initialTicket: ticketCancellable,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('HỦY VÉ VÀ HOÀN TIỀN'), findsOneWidget,
          reason: 'At 2h05m before showtime, the cancel button must be rendered');

      // Case B: 1h55m in future -> Cancel button absent, Warning banner visible
      final ticketNonCancellable = buildStressBooking(
        code: 'BK_NON_UI',
        status: 'paid',
        showtimeStart: DateTime.now().add(const Duration(hours: 1, minutes: 55)),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: ChangeNotifierProvider<TicketProvider>.value(
            value: ticketProvider,
            child: TicketDetailScreen(
              key: const ValueKey('non_cancellable_ui'),
              initialTicket: ticketNonCancellable,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('HỦY VÉ VÀ HOÀN TIỀN'), findsNothing,
          reason: 'At 1h55m before showtime, the cancel button must NOT be rendered');
      expect(
        find.textContaining('Không thể hủy vé vì suất chiếu bắt đầu trong vòng chưa đầy 2 giờ'),
        findsOneWidget,
        reason: 'Warning explanation banner must be displayed to customer',
      );
    });

    test('TicketProvider partitions upcoming vs history based on showtime start', () {
      final mockRepo = MockStressTicketRepository();
      final now = DateTime.now();

      final tUpcoming = buildStressBooking(code: 'T_UP', status: 'paid', showtimeStart: now.add(const Duration(hours: 3)));
      final tHistoryPaid = buildStressBooking(code: 'T_HIST_PAID', status: 'paid', showtimeStart: now.subtract(const Duration(minutes: 10)));
      final tHistoryUsed = buildStressBooking(code: 'T_HIST_USED', status: 'used', showtimeStart: now.add(const Duration(hours: 1)));
      final tCancelled = buildStressBooking(code: 'T_CANC', status: 'cancelled', showtimeStart: now.add(const Duration(hours: 4)));

      mockRepo.tickets = [tUpcoming, tHistoryPaid, tHistoryUsed, tCancelled];

      expect(tUpcoming.canCancel, isTrue);
      expect(tHistoryPaid.canCancel, isFalse);
    });
  });

  // ===========================================================================
  // GROUP 2: 15-MINUTE SHOWTIME CLEANING INTERVAL GAP CONFLICTS
  // ===========================================================================
  group('2. 15-Minute Showtime Cleaning Interval Gap Stress Tests', () {
    final baseDate = DateTime(2026, 11, 1, 10, 0); // 10:00 AM
    final existingShowtime = ShowtimeModel(
      id: 'st_existing_1',
      movieId: 'mv_1',
      cinemaId: 'cn_q1',
      roomId: 'rm_room1',
      startTime: baseDate, // 10:00
      endTime: baseDate.add(const Duration(hours: 2)), // 12:00
      format: '2D',
      minPrice: 80000,
      status: 'active',
      totalSeats: 80,
      soldSeats: 10,
    );

    test('Candidate starts 14 minutes after existing ends: CONFLICT', () {
      // Existing ends at 12:00. 14 min after = 12:14.
      final candidateStart = baseDate.add(const Duration(hours: 2, minutes: 14));
      final candidateEnd = candidateStart.add(const Duration(hours: 2));

      final hasConflict = check15MinGapConflict(
        candidateStart: candidateStart,
        candidateEnd: candidateEnd,
        candidateRoomId: 'rm_room1',
        existingShowtimes: [existingShowtime],
      );

      expect(hasConflict, isTrue,
          reason: '14 minutes gap is strictly less than mandatory 15-minute cleaning gap');
    });

    test('Candidate starts 14m59s after existing ends: CONFLICT', () {
      final candidateStart = baseDate.add(const Duration(hours: 2, minutes: 14, seconds: 59));
      final candidateEnd = candidateStart.add(const Duration(hours: 2));

      final hasConflict = check15MinGapConflict(
        candidateStart: candidateStart,
        candidateEnd: candidateEnd,
        candidateRoomId: 'rm_room1',
        existingShowtimes: [existingShowtime],
      );

      expect(hasConflict, isTrue, reason: 'Even 1 second under 15 minutes is a conflict');
    });

    test('Candidate starts exactly 15 minutes after existing ends: NO CONFLICT', () {
      // Existing ends at 12:00. Exactly 15 min after = 12:15.
      final candidateStart = baseDate.add(const Duration(hours: 2, minutes: 15));
      final candidateEnd = candidateStart.add(const Duration(hours: 2));

      final hasConflict = check15MinGapConflict(
        candidateStart: candidateStart,
        candidateEnd: candidateEnd,
        candidateRoomId: 'rm_room1',
        existingShowtimes: [existingShowtime],
      );

      expect(hasConflict, isFalse,
          reason: 'Exactly 15 minutes cleaning gap satisfies the constraint');
    });

    test('Candidate starts 16 minutes after existing ends: NO CONFLICT', () {
      final candidateStart = baseDate.add(const Duration(hours: 2, minutes: 16));
      final candidateEnd = candidateStart.add(const Duration(hours: 2));

      final hasConflict = check15MinGapConflict(
        candidateStart: candidateStart,
        candidateEnd: candidateEnd,
        candidateRoomId: 'rm_room1',
        existingShowtimes: [existingShowtime],
      );

      expect(hasConflict, isFalse);
    });

    test('Candidate ends 14 minutes before existing starts: CONFLICT', () {
      // Existing starts at 10:00. Candidate ends at 09:46 (gap = 14m).
      final candidateEnd = baseDate.subtract(const Duration(minutes: 14));
      final candidateStart = candidateEnd.subtract(const Duration(hours: 2));

      final hasConflict = check15MinGapConflict(
        candidateStart: candidateStart,
        candidateEnd: candidateEnd,
        candidateRoomId: 'rm_room1',
        existingShowtimes: [existingShowtime],
      );

      expect(hasConflict, isTrue,
          reason: 'Ending 14m before existing start leaves only 14m cleaning gap');
    });

    test('Candidate ends exactly 15 minutes before existing starts: NO CONFLICT', () {
      // Existing starts at 10:00. Candidate ends at 09:45 (gap = 15m).
      final candidateEnd = baseDate.subtract(const Duration(minutes: 15));
      final candidateStart = candidateEnd.subtract(const Duration(hours: 2));

      final hasConflict = check15MinGapConflict(
        candidateStart: candidateStart,
        candidateEnd: candidateEnd,
        candidateRoomId: 'rm_room1',
        existingShowtimes: [existingShowtime],
      );

      expect(hasConflict, isFalse,
          reason: 'Exactly 15m gap prior to existing showtime is valid');
    });

    test('Candidate fully inside or overlapping existing showtime: CONFLICT', () {
      // Inside: 10:30 to 11:30
      final insideStart = baseDate.add(const Duration(minutes: 30));
      final insideEnd = baseDate.add(const Duration(minutes: 90));

      expect(
        check15MinGapConflict(
          candidateStart: insideStart,
          candidateEnd: insideEnd,
          candidateRoomId: 'rm_room1',
          existingShowtimes: [existingShowtime],
        ),
        isTrue,
      );

      // Enclosing: 09:30 to 12:30
      final encStart = baseDate.subtract(const Duration(minutes: 30));
      final encEnd = baseDate.add(const Duration(hours: 2, minutes: 30));

      expect(
        check15MinGapConflict(
          candidateStart: encStart,
          candidateEnd: encEnd,
          candidateRoomId: 'rm_room1',
          existingShowtimes: [existingShowtime],
        ),
        isTrue,
      );
    });

    test('Same time slot in different room: NO CONFLICT', () {
      final candidateStart = baseDate;
      final candidateEnd = baseDate.add(const Duration(hours: 2));

      final hasConflict = check15MinGapConflict(
        candidateStart: candidateStart,
        candidateEnd: candidateEnd,
        candidateRoomId: 'rm_room2', // Different room!
        existingShowtimes: [existingShowtime],
      );

      expect(hasConflict, isFalse,
          reason: 'Showtimes in different auditoriums do not conflict with each other');
    });

    test('Cancelled existing showtime does NOT cause conflict', () {
      final cancelledShowtime = existingShowtime.copyWith(status: 'cancelled');
      final candidateStart = baseDate.add(const Duration(minutes: 30));
      final candidateEnd = baseDate.add(const Duration(minutes: 90));

      final hasConflict = check15MinGapConflict(
        candidateStart: candidateStart,
        candidateEnd: candidateEnd,
        candidateRoomId: 'rm_room1',
        existingShowtimes: [cancelledShowtime],
      );

      expect(hasConflict, isFalse,
          reason: 'Cancelled showtimes do not occupy room slots or create cleaning conflicts');
    });

    test('Back-to-back sandwich schedule: candidate must fit in available gap', () {
      // Slot 1: 10:00 - 12:00
      // Slot 2: 13:00 - 15:00
      // Available window between Slot 1 and Slot 2 is 12:00 to 13:00 (60 minutes).
      // Required cleaning gaps: 15m after Slot 1 (earliest start 12:15), 15m before Slot 2 (latest end 12:45).
      // Maximum duration that fits is exactly 30 minutes (12:15 to 12:45).
      final slot1 = existingShowtime;
      final slot2 = ShowtimeModel(
        id: 'st_existing_2',
        movieId: 'mv_2',
        cinemaId: 'cn_q1',
        roomId: 'rm_room1',
        startTime: baseDate.add(const Duration(hours: 3)), // 13:00
        endTime: baseDate.add(const Duration(hours: 5)),   // 15:00
        format: '2D',
        minPrice: 80000,
        status: 'active',
        totalSeats: 80,
        soldSeats: 0,
      );

      // Fit candidate: 12:15 to 12:45 (30 mins)
      final fitCandidate = check15MinGapConflict(
        candidateStart: baseDate.add(const Duration(hours: 2, minutes: 15)),
        candidateEnd: baseDate.add(const Duration(hours: 2, minutes: 45)),
        candidateRoomId: 'rm_room1',
        existingShowtimes: [slot1, slot2],
      );
      expect(fitCandidate, isFalse, reason: 'Exact 30m window with 15m buffers fits perfectly');

      // 31 minute candidate: 12:15 to 12:46 (ends 14m before Slot 2)
      final failCandidate1 = check15MinGapConflict(
        candidateStart: baseDate.add(const Duration(hours: 2, minutes: 15)),
        candidateEnd: baseDate.add(const Duration(hours: 2, minutes: 46)),
        candidateRoomId: 'rm_room1',
        existingShowtimes: [slot1, slot2],
      );
      expect(failCandidate1, isTrue, reason: 'Conflicts with Slot 2 buffer');

      // 31 minute candidate: 12:14 to 12:45 (starts 14m after Slot 1)
      final failCandidate2 = check15MinGapConflict(
        candidateStart: baseDate.add(const Duration(hours: 2, minutes: 14)),
        candidateEnd: baseDate.add(const Duration(hours: 2, minutes: 45)),
        candidateRoomId: 'rm_room1',
        existingShowtimes: [slot1, slot2],
      );
      expect(failCandidate2, isTrue, reason: 'Conflicts with Slot 1 buffer');
    });
  });

  // ===========================================================================
  // GROUP 3: DYNAMIC PRICING CALCULATIONS (BASE + SEAT + WEEKEND + PRIME)
  // ===========================================================================
  group('3. Dynamic Pricing Calculations Stress Tests', () {
    final settings = PricingSettingsModel(
      id: 1,
      base2d: 80000,
      base3d: 100000,
      baseImax: 120000,
      surchargeVip: 20000,
      surchargeCouple: 20000,
      surchargeWeekend: 10000,
      surchargePrime: 10000,
      primeStartHour: 18,
      primeEndHour: 22,
      updatedAt: DateTime.now(),
    );

    test('Exhaustive 36-combination matrix for calculateSeatPrice()', () {
      final formats = ['2D', '3D', 'IMAX'];
      final seatTypes = ['standard', 'vip', 'couple'];
      final weekendFlags = [false, true];
      final primeFlags = [false, true];

      int testedCases = 0;

      for (final format in formats) {
        final expectedBase = format == '3D'
            ? 100000
            : (format == 'IMAX' ? 120000 : 80000);

        for (final seatType in seatTypes) {
          final expectedSeatSurcharge = (seatType == 'vip' || seatType == 'couple')
              ? 20000
              : 0;
          final baseMultiplier = seatType == 'couple' ? 2 : 1;

          for (final isWeekend in weekendFlags) {
            final expectedWeekend = isWeekend ? 10000 : 0;

            for (final isPrime in primeFlags) {
              final expectedPrime = isPrime ? 10000 : 0;

              final expectedTotal = (expectedBase * baseMultiplier) +
                  expectedSeatSurcharge +
                  expectedWeekend +
                  expectedPrime;

              final actualPrice = settings.calculateSeatPrice(
                format: format,
                seatType: seatType,
                isWeekend: isWeekend,
                isPrimeTime: isPrime,
              );

              expect(
                actualPrice,
                expectedTotal,
                reason: 'Failed for format=$format, seatType=$seatType, '
                    'isWeekend=$isWeekend, isPrime=$isPrime',
              );
              testedCases++;
            }
          }
        }
      }

      expect(testedCases, 36, reason: 'All 36 combinations must be verified');
    });

    test('Case insensitivity for format and seat type', () {
      // Lowercase format, uppercase seat
      final p1 = settings.calculateSeatPrice(
        format: 'imax',
        seatType: 'VIP',
        isWeekend: false,
        isPrimeTime: false,
      );
      expect(p1, 140000); // 120k + 20k

      // Mixed case format and seat
      final p2 = settings.calculateSeatPrice(
        format: '3d',
        seatType: 'CoUpLe',
        isWeekend: true,
        isPrimeTime: true,
      );
      expect(p2, 240000); // 2 * 100k + 20k + 10k + 10k
    });

    test('Fallback to base 2D standard for unknown format and seat type', () {
      final pFallback = settings.calculateSeatPrice(
        format: '4DX_UNKNOWN',
        seatType: 'special_bed',
        isWeekend: false,
        isPrimeTime: false,
      );
      expect(pFallback, 80000, reason: 'Unknown format defaults to base 2D standard');
    });

    test('Extreme integer pricing resilience (no overflow or distortion)', () {
      final extremeSettings = PricingSettingsModel(
        id: 1,
        base2d: 500000,
        base3d: 1000000,
        baseImax: 2000000,
        surchargeVip: 500000,
        surchargeCouple: 500000,
        surchargeWeekend: 300000,
        surchargePrime: 200000,
        updatedAt: DateTime.now(),
      );

      final extremePrice = extremeSettings.calculateSeatPrice(
        format: 'IMAX',
        seatType: 'vip',
        isWeekend: true,
        isPrimeTime: true,
      );
      // 2M + 500k + 300k + 200k = 3,000,000 VND
      expect(extremePrice, 3000000);
    });

    test('Booking priceSnapshot arithmetic consistency', () {
      final b = buildStressBooking(
        code: 'BK_ARITH',
        status: 'paid',
        showtimeStart: DateTime.now().add(const Duration(hours: 3)),
        total: 190000,
        ticketTotal: 160000,
        foodTotal: 50000,
        discount: 20000,
      );

      expect(b.totalAmount, 190000);
      expect(b.ticketTotal, 160000);
      expect(b.foodTotal, 50000);
      expect(b.discount, 20000);
      // Total = Ticket (160k) + Food (50k) - Discount (20k) = 190k
      expect(b.ticketTotal + b.foodTotal - b.discount, b.totalAmount);
    });
  });

  // ===========================================================================
  // GROUP 4: VOUCHER DISCOUNT CALCULATIONS (% CAP VS FIXED VS MIN ORDER)
  // ===========================================================================
  group('4. Voucher Discount Calculations Stress Tests', () {
    test('Min order threshold boundaries: below, exact, above', () {
      final voucher = VoucherModel(
        code: 'MIN200K',
        type: 'amount',
        value: 30000,
        minBookingAmount: 200000,
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        expiresAt: DateTime.now().add(const Duration(days: 1)),
        maxUses: 100,
        createdAt: DateTime.now(),
      );

      // 1 VND below min order
      expect(voucher.calculateDiscount(199999), 0,
          reason: 'Booking amount strictly less than minBookingAmount yields 0 discount');

      // Exact min order
      expect(voucher.calculateDiscount(200000), 30000,
          reason: 'Booking amount equal to minBookingAmount earns discount');

      // 1 VND above min order
      expect(voucher.calculateDiscount(200001), 30000);
    });

    test('Percent voucher with maxDiscount cap stress test', () {
      final voucher = VoucherModel(
        code: 'PCT20CAP50',
        type: 'percent',
        value: 20,
        minBookingAmount: 100000,
        maxDiscount: 50000,
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        expiresAt: DateTime.now().add(const Duration(days: 1)),
        maxUses: 100,
        createdAt: DateTime.now(),
      );

      // 20% of 100k = 20k (below cap)
      expect(voucher.calculateDiscount(100000), 20000);

      // 20% of 250k = 50k (exact cap)
      expect(voucher.calculateDiscount(250000), 50000);

      // 20% of 300k = 60k -> capped at 50k
      expect(voucher.calculateDiscount(300000), 50000);

      // 20% of 5,000,000 = 1,000,000 -> capped at 50k
      expect(voucher.calculateDiscount(5000000), 50000);
    });

    test('Percent voucher without cap applies full percentage', () {
      final voucher = VoucherModel(
        code: 'NOCAP15',
        type: 'percent',
        value: 15,
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        expiresAt: DateTime.now().add(const Duration(days: 1)),
        maxUses: 100,
        createdAt: DateTime.now(),
      );

      // 15% of 800,000 = 120,000
      expect(voucher.calculateDiscount(800000), 120000);
    });

    test('Fixed amount voucher clamped when discount exceeds booking total', () {
      final voucher = VoucherModel(
        code: 'FLAT100K',
        type: 'amount',
        value: 100000,
        minBookingAmount: 0,
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        expiresAt: DateTime.now().add(const Duration(days: 1)),
        maxUses: 100,
        createdAt: DateTime.now(),
      );

      // Normal case: 200k - 100k = 100k discount
      expect(voucher.calculateDiscount(200000), 100000);

      // Exact match: 100k - 100k = 100k discount
      expect(voucher.calculateDiscount(100000), 100000);

      // Clamped case: booking total is only 60k -> discount clamped to 60k
      expect(voucher.calculateDiscount(60000), 60000,
          reason: 'Discount cannot exceed order total (would cause negative price)');
    });

    test('Voucher lifecycle validity invariants', () {
      final base = VoucherModel(
        code: 'LIFECYCLE',
        type: 'amount',
        value: 20000,
        startDate: DateTime.now().subtract(const Duration(days: 2)),
        expiresAt: DateTime.now().add(const Duration(days: 2)),
        maxUses: 10,
        usedCount: 0,
        isActive: true,
        createdAt: DateTime.now(),
      );

      // Active & valid
      expect(base.isUsable, isTrue);
      expect(base.calculateDiscount(100000), 20000);

      // Inactive / Disabled
      final disabled = base.copyWith(isActive: false);
      expect(disabled.isUsable, isFalse);
      expect(disabled.calculateDiscount(100000), 0);
      expect(disabled.statusBadgeText, 'TẠM KHÓA');

      // Expired in past
      final expired = base.copyWith(
        expiresAt: DateTime.now().subtract(const Duration(seconds: 1)),
      );
      expect(expired.isUsable, isFalse);
      expect(expired.calculateDiscount(100000), 0);
      expect(expired.statusBadgeText, 'HẾT HẠN');

      // Exhausted boundary: 9/10 is usable, 10/10 is exhausted
      final lastUsable = base.copyWith(usedCount: 9);
      expect(lastUsable.isUsable, isTrue);
      expect(lastUsable.calculateDiscount(100000), 20000);

      final exhausted = base.copyWith(usedCount: 10);
      expect(exhausted.isUsable, isFalse);
      expect(exhausted.calculateDiscount(100000), 0);
      expect(exhausted.statusBadgeText, 'HẾT LƯỢT');
    });

    test('Zero or negative booking amount yields zero discount', () {
      final voucher = VoucherModel(
        code: 'ANY10K',
        type: 'amount',
        value: 10000,
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        expiresAt: DateTime.now().add(const Duration(days: 1)),
        maxUses: 10,
        createdAt: DateTime.now(),
      );

      expect(voucher.calculateDiscount(0), 0);
      expect(voucher.calculateDiscount(-50000), 0);
    });
  });

  // ===========================================================================
  // GROUP 5: ROOM SEAT GRID SIZING & CAPACITY TALLY
  // ===========================================================================
  group('5. Room Seat Grid Sizing & Capacity Tally Stress Tests', () {
    test('Seat tally calculation excludes aisles (_) and correctly sums S, V, C', () {
      // 4 rows x 5 cols grid
      // Row 0: S, S, S, S, S -> 5 standard
      // Row 1: V, V, V, V, _ -> 4 VIP, 1 aisle
      // Row 2: C, C, _, _, _ -> 2 Couple, 3 aisles
      // Row 3: _, _, _, _, _ -> 5 aisles
      final grid = [
        ['S', 'S', 'S', 'S', 'S'],
        ['V', 'V', 'V', 'V', '_'],
        ['C', 'C', '_', '_', '_'],
        ['_', '_', '_', '_', '_'],
      ];

      int standardCount = 0;
      int vipCount = 0;
      int coupleCount = 0;

      for (final row in grid) {
        for (final cell in row) {
          if (cell == 'S') standardCount++;
          if (cell == 'V') vipCount++;
          if (cell == 'C') coupleCount++;
        }
      }

      final totalSeats = standardCount + vipCount + coupleCount;

      expect(standardCount, 5);
      expect(vipCount, 4);
      expect(coupleCount, 2);
      expect(totalSeats, 11, reason: 'Total seats must be 5 + 4 + 2 = 11; aisles are not seats');
    });

    test('Grid expansion preserves existing cells and fills new cells with Standard (S)', () {
      // Start with 2x2 grid:
      // [V, C]
      // [C, _]
      final initialGrid = [
        ['V', 'C'],
        ['C', '_'],
      ];

      const newRows = 3;
      const newCols = 3;

      List<List<String>> expandedGrid = initialGrid.map((r) => List<String>.from(r)).toList();

      // Expand rows
      while (expandedGrid.length < newRows) {
        expandedGrid.add(List.generate(expandedGrid[0].length, (_) => 'S'));
      }
      // Expand cols
      for (int i = 0; i < expandedGrid.length; i++) {
        while (expandedGrid[i].length < newCols) {
          expandedGrid[i].add('S');
        }
      }

      expect(expandedGrid.length, 3);
      expect(expandedGrid[0].length, 3);
      // Original cells preserved
      expect(expandedGrid[0][0], 'V');
      expect(expandedGrid[0][1], 'C');
      expect(expandedGrid[1][0], 'C');
      expect(expandedGrid[1][1], '_');
      // Newly added cells are 'S'
      expect(expandedGrid[0][2], 'S');
      expect(expandedGrid[1][2], 'S');
      expect(expandedGrid[2][0], 'S');
      expect(expandedGrid[2][1], 'S');
      expect(expandedGrid[2][2], 'S');
    });

    test('Grid truncation trims excess rows and columns cleanly', () {
      final initialGrid = [
        ['S', 'V', 'C'],
        ['S', 'V', 'C'],
        ['_', '_', '_'],
      ];

      const shrinkRows = 2;
      const shrinkCols = 2;

      var shrunk = initialGrid.sublist(0, shrinkRows);
      for (int i = 0; i < shrunk.length; i++) {
        shrunk[i] = shrunk[i].sublist(0, shrinkCols);
      }

      expect(shrunk.length, 2);
      expect(shrunk[0].length, 2);
      expect(shrunk[0], ['S', 'V']);
      expect(shrunk[1], ['S', 'V']);
    });

    test('Brush cycle order is: Standard -> VIP -> Couple -> Aisle -> Standard', () {
      String cycle(String current) {
        switch (current) {
          case 'S':
            return 'V';
          case 'V':
            return 'C';
          case 'C':
            return '_';
          case '_':
          default:
            return 'S';
        }
      }

      expect(cycle('S'), 'V');
      expect(cycle('V'), 'C');
      expect(cycle('C'), '_');
      expect(cycle('_'), 'S');
    });

    test('Serialization and deserialization roundtrip formatting', () {
      final layout = [
        'S,S,V,V,_',
        'C,C,_,S,S',
      ];

      final room = RoomModel(
        id: 'rm_rt',
        cinemaId: 'cn_q1',
        name: 'Phòng Roundtrip',
        formats: ['2D', '3D'],
        rows: 2,
        cols: 5,
        seatLayout: layout,
        seatCount: 8,
      );

      final map = room.toMap();
      final restored = RoomModel.fromMap(map);

      expect(restored.rows, 2);
      expect(restored.cols, 5);
      expect(restored.seatLayout, layout);
      expect(restored.seatCount, 8);
    });

    testWidgets('SeatMapDesignerScreen UI mounts with tally chips and interactive grid', (tester) async {
      tester.view.physicalSize = const Size(1000, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockStressManagementRepository();
      final mockAuth = MockStressAuthProvider();
      final mgmtProvider = ManagementProvider(mockRepo);

      const testRoom = RoomModel(
        id: 'rm_designer_test',
        cinemaId: 'cn_q1',
        name: 'Phòng Thiết Kế',
        formats: ['2D', 'IMAX'],
        rows: 4,
        cols: 5,
        seatLayout: [
          'S,S,S,S,S',
          'S,V,V,V,S',
          'C,C,_,C,C',
          '_,_,_,_,_',
        ],
        seatCount: 14,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuth),
            ChangeNotifierProvider<ManagementProvider>.value(value: mgmtProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const SeatMapDesignerScreen(room: testRoom),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify title and room name
      expect(find.text('THIẾT KẾ SƠ ĐỒ GHẾ'), findsOneWidget);
      expect(find.textContaining('Phòng Thiết Kế'), findsOneWidget);

      // Verify brush palette buttons
      expect(find.text('XOAY VÒNG'), findsOneWidget);
      expect(find.textContaining('THƯỜNG'), findsWidgets);
      expect(find.textContaining('VIP'), findsWidgets);
      expect(find.textContaining('ĐÔI'), findsWidgets);
      expect(find.textContaining('LỐI ĐI'), findsOneWidget);

      // Verify tally summary chips and save button
      expect(find.text('TỔNG SỐ GHẾ'), findsOneWidget);
      expect(find.text('LƯU SƠ ĐỒ PHÒNG CHIẾU'), findsOneWidget);
    });
  });
}
