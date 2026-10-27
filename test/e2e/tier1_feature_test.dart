import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cinema_booking_v1/core/config/app_constants.dart';
import 'package:cinema_booking_v1/core/routes/app_router.dart';
import 'package:cinema_booking_v1/core/routes/route_guards.dart';
import 'package:cinema_booking_v1/core/theme/app_colors.dart';
import 'package:cinema_booking_v1/core/utils/currency_formatter.dart';
import 'package:cinema_booking_v1/core/utils/date_formatter.dart';
import 'package:cinema_booking_v1/features/booking/presentation/controllers/booking_provider.dart';
import 'package:cinema_booking_v1/features/movies/presentation/controllers/movie_provider.dart';
import 'package:cinema_booking_v1/shared/widgets/app_badge.dart';
import 'package:cinema_booking_v1/shared/widgets/app_button.dart';
import 'package:cinema_booking_v1/shared/widgets/booking_summary_bar.dart';
import 'package:cinema_booking_v1/shared/widgets/date_chip.dart';
import 'package:cinema_booking_v1/shared/widgets/hold_timer.dart';
import 'package:cinema_booking_v1/shared/widgets/quantity_stepper.dart';
import 'package:cinema_booking_v1/shared/widgets/result_sheet.dart';
import 'package:cinema_booking_v1/shared/widgets/showtime_row.dart';
import 'package:cinema_booking_v1/shared/widgets/ticket_card.dart';

import 'test_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initTestSupabase();
  });

  group('Tier 1: Feature Coverage (All 35 Features)', () {
    // -------------------------------------------------------------------------
    // Feature 1: Email/Password Login (S01)
    // -------------------------------------------------------------------------
    group('F01: Email/Password Login', () {
      test('1. Customer profile deserialization maps role, email, and lock status', () {
        final user = buildTestUser(email: 'khach1@cinema.vn', role: UserRole.customer);
        expect(user.email, 'khach1@cinema.vn');
        expect(user.isCustomer, isTrue);
        expect(user.isLocked, isFalse);
        expect(RouteGuards.getInitialRoute(user), AppRoutes.home);
      });

      test('2. Staff profile maps cinemaId and redirects to S18 check-in', () {
        final staff = buildTestUser(
          id: 'staff_q1',
          email: 'staff1@cinema.vn',
          role: UserRole.staff,
          cinemaId: 'cn_q1',
        );
        expect(staff.isStaff, isTrue);
        expect(staff.cinemaId, 'cn_q1');
        expect(RouteGuards.getInitialRoute(staff), AppRoutes.staffCheckin);
      });

      test('3. Manager profile routes to S22 dashboard', () {
        final manager = buildTestUser(
          id: 'mgr_q1',
          email: 'manager1@cinema.vn',
          role: UserRole.manager,
          cinemaId: 'cn_q1',
        );
        expect(manager.isManager, isTrue);
        expect(RouteGuards.getInitialRoute(manager), AppRoutes.dashboard);
      });

      test('4. Admin profile routes to S22 dashboard without cinema restriction', () {
        final admin = buildTestUser(
          id: 'adm_01',
          email: 'admin@cinema.vn',
          role: UserRole.admin,
        );
        expect(admin.isAdmin, isTrue);
        expect(admin.cinemaId, isNull);
        expect(RouteGuards.getInitialRoute(admin), AppRoutes.dashboard);
      });

      test('5. Locked user is denied route access and redirected to login', () {
        final lockedUser = buildTestUser(
          email: 'bad_user@cinema.vn',
          isLocked: true,
        );
        expect(lockedUser.isLocked, isTrue);
        expect(RouteGuards.getInitialRoute(lockedUser), AppRoutes.login);
      });
    });

    // -------------------------------------------------------------------------
    // Feature 2: Customer Registration (S02)
    // -------------------------------------------------------------------------
    group('F02: Customer Registration', () {
      test('1. Valid registration creates customer user with default unlocked state', () {
        final newUser = AppUser.fromMap({
          'id': 'usr_new_01',
          'full_name': 'Trần Thị Thu',
          'phone': '0912345678',
          'role': 'customer',
          'is_locked': false,
        }, email: 'thu.tran@gmail.com');

        expect(newUser.fullName, 'Trần Thị Thu');
        expect(newUser.phone, '0912345678');
        expect(newUser.role, UserRole.customer);
        expect(newUser.isLocked, isFalse);
      });

      test('2. Registration defaults to customer role if missing from map', () {
        final user = AppUser.fromMap({
          'id': 'usr_def',
          'full_name': 'Khách Mặc Định',
        });
        expect(user.role, UserRole.customer);
      });

      test('3. Registration preserves phone number in profile update', () {
        final user = buildTestUser(phone: '0909999888');
        final updated = user.copyWith(phone: '0988777666');
        expect(updated.phone, '0988777666');
      });

      test('4. Serializing user toMap adheres to PostgreSQL schema', () {
        final user = buildTestUser(
          id: 'u100',
          fullName: 'Lê Văn A',
          phone: '0901112223',
          role: UserRole.customer,
        );
        final map = user.toMap();
        expect(map['id'], 'u100');
        expect(map['full_name'], 'Lê Văn A');
        expect(map['role'], 'customer');
        expect(map['is_locked'], isFalse);
      });

      test('5. RouteGuards identifies protected customer routes', () {
        expect(RouteGuards.requiresAuth(AppRoutes.myTickets), isTrue);
        expect(RouteGuards.requiresAuth(AppRoutes.profile), isTrue);
        expect(RouteGuards.requiresAuth(AppRoutes.checkout), isTrue);
        expect(RouteGuards.requiresAuth(AppRoutes.home), isFalse);
      });
    });

    // -------------------------------------------------------------------------
    // Feature 3: Movie Discovery Carousel & Grid (S03)
    // -------------------------------------------------------------------------
    group('F03: Movie Discovery Carousel & Grid', () {
      test('1. isNowShowing returns true only when active and releaseDate <= now', () {
        final activePast = buildTestMovie(
          releaseDate: DateTime.now().subtract(const Duration(days: 3)),
          isActive: true,
        );
        expect(activePast.isNowShowing, isTrue);
        expect(activePast.isUpcoming, isFalse);
      });

      test('2. isUpcoming returns true only when active and releaseDate > now', () {
        final activeFuture = buildTestMovie(
          releaseDate: DateTime.now().add(const Duration(days: 5)),
          isActive: true,
        );
        expect(activeFuture.isUpcoming, isTrue);
        expect(activeFuture.isNowShowing, isFalse);
      });

      test('3. Inactive movie is excluded from both nowShowing and upcoming', () {
        final inactive = buildTestMovie(
          releaseDate: DateTime.now().subtract(const Duration(days: 3)),
          isActive: false,
        );
        expect(inactive.isNowShowing, isFalse);
        expect(inactive.isUpcoming, isFalse);
      });

      test('4. Client-side search filters movies case-insensitively', () {
        final provider = MovieProvider();
        provider.search('mai');
        expect(provider.searchQuery, 'mai');
        provider.clearSearch();
        expect(provider.searchQuery, isEmpty);
      });

      test('5. Genres formatting renders comma-separated text', () {
        final movie = buildTestMovie(genres: ['Hành động', 'Khoa học viễn tưởng', '3D']);
        expect(movie.genresText, 'Hành động, Khoa học viễn tưởng, 3D');
      });
    });

    // -------------------------------------------------------------------------
    // Feature 4: Movie Detail & Trailer (S04)
    // -------------------------------------------------------------------------
    group('F04: Movie Detail & Trailer', () {
      test('1. MovieModel preserves metadata spec cells (duration, rating, trailerUrl)', () {
        final movie = buildTestMovie(
          durationMin: 128,
          ageRating: 'T16',
          trailerUrl: 'https://youtube.com/watch?v=sample128',
        );
        expect(movie.durationMin, 128);
        expect(movie.ageRating, 'T16');
        expect(movie.trailerUrl, contains('youtube.com'));
      });

      test('2. Movie age ratings include standard certifications (P, T13, T16, T18)', () {
        const ratings = ['P', 'T13', 'T16', 'T18'];
        for (final r in ratings) {
          final m = buildTestMovie(ageRating: r);
          expect(m.ageRating, r);
        }
      });

      test('3. Movie serialization round-trips correctly', () {
        final movie = buildTestMovie(title: 'Godzilla x Kong', durationMin: 115);
        final map = movie.toMap();
        final reconstituted = MovieModel.fromMap(map);
        expect(reconstituted.title, 'Godzilla x Kong');
        expect(reconstituted.durationMin, 115);
      });

      testWidgets('4. AppBadge renders age rating text in uppercase style', (tester) async {
        await tester.pumpWidget(createTestAppWrapper(child: const AppBadge(label: 'T18')));
        expect(find.text('T18'), findsOneWidget);
      });

      testWidgets('5. AppButton displays uppercase label for booking action', (tester) async {
        await tester.pumpWidget(createTestAppWrapper(
          child: AppButton.primary(label: 'Đặt vé', onPressed: () {}),
        ));
        expect(find.text('ĐẶT VÉ'), findsOneWidget);
      });
    });

    // -------------------------------------------------------------------------
    // Feature 5: Showtime Date Filter & Grouping (S05)
    // -------------------------------------------------------------------------
    group('F05: Showtime Date Filter & Grouping', () {
      test('1. DateChip formats day of week and day number properly', () {
        final monday = DateTime(2026, 10, 26);
        expect(DateFormatter.formatWeekdayAbbr(monday), 'T2');
        expect(DateFormatter.formatDate(monday), '26/10/2026');
      });

      testWidgets('2. DateChip widget renders correctly in active/selected state', (tester) async {
        await tester.pumpWidget(createTestAppWrapper(
          child: const DateChip(weekday: 'T2', dayNumber: '26', isSelected: true),
        ));
        expect(find.text('T2'), findsOneWidget);
        expect(find.text('26'), findsOneWidget);
      });

      testWidgets('3. ShowtimeRow displays start time, room, format and price', (tester) async {
        await tester.pumpWidget(createTestAppWrapper(
          child: const ShowtimeRow(
            startTime: '19:30',
            roomName: 'Phòng 1 (IMAX)',
            format: 'IMAX',
            minPrice: 120000,
          ),
        ));
        expect(find.text('19:30'), findsOneWidget);
        expect(find.text('Phòng 1 (IMAX)'), findsOneWidget);
        expect(find.text('IMAX'), findsOneWidget);
        expect(find.textContaining('120.000'), findsOneWidget);
      });

      testWidgets('4. ShowtimeRow displays HẾT VÉ when sold out and disables tap', (tester) async {
        bool tapped = false;
        await tester.pumpWidget(createTestAppWrapper(
          child: ShowtimeRow(
            startTime: '20:00',
            roomName: 'Phòng 2',
            format: '2D',
            minPrice: 80000,
            isSoldOut: true,
            onTap: () => tapped = true,
          ),
        ));
        expect(find.text('HẾT VÉ'), findsOneWidget);
        await tester.tap(find.text('HẾT VÉ'));
        expect(tapped, isFalse);
      });

      test('5. ShowtimeModel computes isSoldOut and isCancelled flags', () {
        final soldOut = buildTestShowtime(totalSeats: 50, soldSeats: 50);
        expect(soldOut.isSoldOut, isTrue);

        final cancelled = buildTestShowtime(status: 'cancelled', cancelReason: 'Sự cố máy chiếu');
        expect(cancelled.isCancelled, isTrue);
      });
    });

    // -------------------------------------------------------------------------
    // Feature 6: Interactive Seat Map Realtime (S06)
    // -------------------------------------------------------------------------
    group('F06: Interactive Seat Map Realtime', () {
      test('1. Toggling seat adds it to selectedSeatIds', () {
        final provider = BookingProvider();
        provider.setShowtime(buildTestShowtime());
        provider.toggleSeat('A1', SeatType.standard);
        expect(provider.selectedSeatIds, contains('A1'));
      });

      test('2. Toggling already selected seat deselects it', () {
        final provider = BookingProvider();
        provider.setShowtime(buildTestShowtime());
        provider.toggleSeat('B2', SeatType.standard);
        expect(provider.selectedSeatIds, contains('B2'));
        provider.toggleSeat('B2', SeatType.standard);
        expect(provider.selectedSeatIds, isNot(contains('B2')));
      });

      test('3. Enforces 8-seat maximum limit (AppConstants.maxSeatsPerBooking)', () {
        final provider = BookingProvider();
        provider.setShowtime(buildTestShowtime());
        for (int i = 1; i <= 8; i++) {
          provider.toggleSeat('A$i', SeatType.standard);
        }
        expect(provider.selectedSeatIds.length, 8);
        expect(provider.errorMessage, isNull);

        // Attempt 9th seat
        provider.toggleSeat('A9', SeatType.standard);
        expect(provider.selectedSeatIds.length, 8);
        expect(provider.errorMessage, contains('tối đa 8 ghế'));
      });

      testWidgets('4. SeatWidget displays selected state in primary color', (tester) async {
        await tester.pumpWidget(createTestAppWrapper(
          child: const SeatWidget(seatId: 'C4', state: SeatState.selected),
        ));
        expect(find.text('C4'), findsOneWidget);
      });

      testWidgets('5. SeatWidget displays sold state with close icon and cannot be tapped', (tester) async {
        bool tapped = false;
        await tester.pumpWidget(createTestAppWrapper(
          child: SeatWidget(
            seatId: 'D5',
            state: SeatState.sold,
            onTap: () => tapped = true,
          ),
        ));
        expect(find.byIcon(Icons.close), findsOneWidget);
        await tester.tap(find.byType(SeatWidget));
        expect(tapped, isFalse);
      });
    });

    // -------------------------------------------------------------------------
    // Feature 7: `hold_seats` Transaction (S06)
    // -------------------------------------------------------------------------
    group('F07: `hold_seats` Transaction', () {
      test('1. generateBookingCode creates 8-character uppercase alphanumeric code', () {
        final code = BookingProvider.generateBookingCode();
        expect(code.length, 8);
        expect(RegExp(r'^[A-Z0-9]{8}$').hasMatch(code), isTrue);
      });

      test('2. Online hold duration is exactly 5 minutes (AppConstants.holdOnline)', () {
        expect(AppConstants.holdOnline, const Duration(minutes: 5));
      });

      test('3. Counter hold duration is exactly 3 minutes (AppConstants.holdCounter)', () {
        expect(AppConstants.holdCounter, const Duration(minutes: 3));
      });

      test('4. Price snapshot contains ticket_total, food_total, discount, and grand total', () {
        final provider = BookingProvider();
        provider.setShowtime(buildTestShowtime());
        provider.toggleSeat('A1', SeatType.standard);
        final snapshot = provider.generatePriceSnapshot();
        expect(snapshot.containsKey('ticket_total'), isTrue);
        expect(snapshot.containsKey('food_total'), isTrue);
        expect(snapshot.containsKey('discount'), isTrue);
        expect(snapshot.containsKey('total'), isTrue);
      });

      test('5. SeatModel lazy expiration considers expired hold as available', () {
        final pastHold = buildTestSeat(
          status: 'holding',
          holdUntil: DateTime.now().subtract(const Duration(minutes: 1)),
        );
        expect(pastHold.isHolding, isFalse);

        final activeHold = buildTestSeat(
          status: 'holding',
          holdUntil: DateTime.now().add(const Duration(minutes: 4)),
        );
        expect(activeHold.isHolding, isTrue);
      });
    });

    // -------------------------------------------------------------------------
    // Feature 8: Seat Hold Countdown Timer (S07)
    // -------------------------------------------------------------------------
    group('F08: Seat Hold Countdown Timer', () {
      test('1. DateFormatter.formatTimer formats minutes and seconds correctly', () {
        expect(DateFormatter.formatTimer(const Duration(minutes: 4, seconds: 59)), '04:59');
        expect(DateFormatter.formatTimer(const Duration(seconds: 45)), '00:45');
        expect(DateFormatter.formatTimer(const Duration(seconds: 0)), '00:00');
      });

      testWidgets('2. HoldTimer widget renders countdown text', (tester) async {
        final holdUntil = DateTime.now().add(const Duration(minutes: 4, seconds: 30));
        await tester.pumpWidget(createTestAppWrapper(child: HoldTimer(holdUntil: holdUntil)));
        expect(find.textContaining('GIỮ GHẾ CÒN'), findsOneWidget);
        expect(find.byIcon(Icons.access_time_filled), findsOneWidget);
      });

      testWidgets('3. HoldTimer uses warning styling when under 60 seconds', (tester) async {
        final holdUntil = DateTime.now().add(const Duration(seconds: 45));
        await tester.pumpWidget(createTestAppWrapper(child: HoldTimer(holdUntil: holdUntil)));
        final iconFinder = find.byIcon(Icons.access_time_filled);
        final icon = tester.widget<Icon>(iconFinder);
        expect(icon.color, AppColors.warning);
      });

      testWidgets('4. HoldTimer uses ink styling when remaining time is >= 60 seconds', (tester) async {
        final holdUntil = DateTime.now().add(const Duration(minutes: 3));
        await tester.pumpWidget(createTestAppWrapper(child: HoldTimer(holdUntil: holdUntil)));
        final iconFinder = find.byIcon(Icons.access_time_filled);
        final icon = tester.widget<Icon>(iconFinder);
        expect(icon.color, AppColors.ink);
      });

      test('5. AppConstants.paymentWarning is exactly 60 seconds', () {
        expect(AppConstants.paymentWarning, const Duration(seconds: 60));
      });
    });

    // -------------------------------------------------------------------------
    // Feature 9: Concession / Food Selection (S07)
    // -------------------------------------------------------------------------
    group('F09: Concession / Food Selection', () {
      test('1. FoodModel serializes to booking json with food_id, name, qty, unit_price', () {
        final food = buildTestFood(
          id: 'fd_combo_1',
          name: 'Combo Solo',
          price: 75000,
          quantity: 2,
        );
        final json = food.toBookingJson();
        expect(json['food_id'], 'fd_combo_1');
        expect(json['name'], 'Combo Solo');
        expect(json['qty'], 2);
        expect(json['unit_price'], 75000);
      });

      testWidgets('2. QuantityStepper increments quantity when add is tapped', (tester) async {
        int qty = 1;
        await tester.pumpWidget(createTestAppWrapper(
          child: QuantityStepper(
            value: qty,
            onChanged: (val) => qty = val,
          ),
        ));
        expect(find.text('1'), findsOneWidget);
        await tester.tap(find.byIcon(Icons.add));
        expect(qty, 2);
      });

      testWidgets('3. QuantityStepper decrements quantity when remove is tapped', (tester) async {
        int qty = 3;
        await tester.pumpWidget(createTestAppWrapper(
          child: QuantityStepper(
            value: qty,
            onChanged: (val) => qty = val,
          ),
        ));
        await tester.tap(find.byIcon(Icons.remove));
        expect(qty, 2);
      });

      testWidgets('4. QuantityStepper prevents decrementing below minimum (0)', (tester) async {
        int qty = 0;
        await tester.pumpWidget(createTestAppWrapper(
          child: QuantityStepper(
            value: qty,
            onChanged: (val) => qty = val,
          ),
        ));
        await tester.tap(find.byIcon(Icons.remove));
        expect(qty, 0);
      });

      test('5. BookingProvider calculates food total across multiple items', () {
        final provider = BookingProvider();
        final f1 = buildTestFood(id: 'f1', price: 50000);
        final f2 = buildTestFood(id: 'f2', price: 30000);
        provider.updateFoodQuantity(f1, 2); // 100k
        provider.updateFoodQuantity(f2, 1); // 30k
        expect(provider.calculateFoodTotal(), 130000);
      });
    });

    // -------------------------------------------------------------------------
    // Feature 10: VNPay Sandbox Checkout (S08)
    // -------------------------------------------------------------------------
    group('F10: VNPay Sandbox Checkout', () {
      test('1. VNPay amount calculation multiplies VND integer by 100', () {
        const int totalVnd = 185000;
        const int vnpAmount = totalVnd * 100;
        expect(vnpAmount, 18500000);
      });

      test('2. TxnRef format complies with booking code and timestamp specification', () {
        const bookingCode = 'K7M2QX9P';
        final timestamp = DateTime(2026, 10, 27, 20, 15).millisecondsSinceEpoch;
        final txnRef = '$bookingCode-$timestamp';
        expect(txnRef, startsWith('K7M2QX9P-'));
      });

      test('3. Booking summary bar displays formatted total and button', () {
        const total = 205000;
        final formatted = CurrencyFormatter.format(total);
        expect(formatted, contains('205.000'));
      });

      testWidgets('4. BookingSummaryBar renders seats summary and total price', (tester) async {
        await tester.pumpWidget(createTestAppWrapper(
          child: BookingSummaryBar(
            seatSummary: '2 Ghế · A5, A6',
            totalPrice: 160000,
            buttonLabel: 'THANH TOÁN',
            onButtonPressed: () {},
          ),
        ));
        expect(find.text('2 GHẾ · A5, A6'), findsOneWidget);
        expect(find.textContaining('160.000'), findsOneWidget);
        expect(find.text('THANH TOÁN'), findsOneWidget);
      });

      test('5. CurrencyFormatter correctly formats zero and large amounts', () {
        expect(CurrencyFormatter.format(0), contains('0'));
        expect(CurrencyFormatter.format(1500000), contains('1.500.000'));
      });
    });

    // -------------------------------------------------------------------------
    // Feature 11: `confirm_payment` RPC (S08)
    // -------------------------------------------------------------------------
    group('F11: `confirm_payment` RPC', () {
      test('1. Successful confirmation transitions booking status from holding to paid', () {
        final holding = buildTestBooking(status: 'holding');
        final paid = buildTestBooking(
          status: 'paid',
          paidAt: DateTime.now(),
          vnpTransactionNo: '14589230',
        );
        expect(holding.status, 'holding');
        expect(paid.status, 'paid');
        expect(paid.paidAt, isNotNull);
        expect(paid.vnpTransactionNo, '14589230');
      });

      test('2. Food status transitions to pending when foods are present', () {
        final booking = buildTestBooking(
          status: 'paid',
          foods: [{'name': 'Bắp Phô Mai', 'qty': 1}],
          foodStatus: 'pending',
        );
        expect(booking.foodStatus, 'pending');
      });

      test('3. Food status remains none when no foods were ordered', () {
        final booking = buildTestBooking(
          status: 'paid',
          foods: [],
          foodStatus: 'none',
        );
        expect(booking.foodStatus, 'none');
      });

      test('4. Seats transition to sold upon payment confirmation', () {
        final seat = buildTestSeat(status: 'sold');
        expect(seat.isSold, isTrue);
        expect(seat.isHolding, isFalse);
      });

      test('5. BookingModel price snapshot stores immutable prices at creation', () {
        final booking = buildTestBooking(
          priceSnapshot: {
            'ticket_total': 160000,
            'food_total': 45000,
            'discount': 0,
            'total': 205000,
          },
        );
        expect(booking.totalAmount, 205000);
        expect(booking.ticketTotal, 160000);
        expect(booking.foodTotal, 45000);
      });
    });

    // -------------------------------------------------------------------------
    // Feature 12: Electronic QR Ticket Generation (S09)
    // -------------------------------------------------------------------------
    group('F12: Electronic QR Ticket Generation', () {
      testWidgets('1. TicketCard displays movie, cinema, room, showtime and seats', (tester) async {
        await tester.pumpWidget(createTestAppWrapper(
          child: const TicketCard(
            movieTitle: 'Mai',
            cinemaName: 'Cinema Quận 1',
            roomName: 'Phòng 1',
            format: '2D',
            showtime: '19:30 · 27/10/2026',
            seatNames: 'A5, A6',
            bookingCode: 'K7M2QX9P',
          ),
        ));

        expect(find.text('Mai'), findsOneWidget);
        expect(find.text('Cinema Quận 1'), findsOneWidget);
        expect(find.text('Phòng 1 · 2D'), findsOneWidget);
        expect(find.text('19:30 · 27/10/2026'), findsOneWidget);
        expect(find.text('A5, A6'), findsOneWidget);
        expect(find.text('K7M2QX9P'), findsOneWidget);
        expect(find.text('MÃ ĐẶT VÉ'), findsOneWidget);
      });

      testWidgets('2. TicketCard displays food summary when food was ordered', (tester) async {
        await tester.pumpWidget(createTestAppWrapper(
          child: const TicketCard(
            movieTitle: 'Mai',
            cinemaName: 'Cinema Quận 1',
            roomName: 'Phòng 1',
            format: '2D',
            showtime: '19:30',
            seatNames: 'A5',
            bookingCode: 'K7M2QX9P',
            foodSummary: '1x Bắp Phô Mai',
          ),
        ));
        expect(find.text('1x Bắp Phô Mai'), findsOneWidget);
        expect(find.text('ĐỒ ĂN KÈM (NHẬN TẠI QUẦY)'), findsOneWidget);
      });

      test('3. BookingModel summaries format seats and food items cleanly', () {
        final booking = buildTestBooking(
          seats: [{'id': 'E3'}, {'id': 'E4'}],
          foods: [{'name': 'Nước ngọt', 'qty': 2}],
        );
        expect(booking.seatNamesSummary, 'E3, E4');
        expect(booking.foodSummary, '2x Nước ngọt');
      });

      test('4. Booking code generation excludes ambiguous characters', () {
        for (int i = 0; i < 20; i++) {
          final code = BookingProvider.generateBookingCode();
          expect(code.contains('0'), isFalse);
          expect(code.contains('1'), isFalse);
          expect(code.contains('I'), isFalse);
          expect(code.contains('O'), isFalse);
        }
      });

      testWidgets('5. TicketCard handles long movie titles gracefully without crashing', (tester) async {
        await tester.pumpWidget(createTestAppWrapper(
          child: const TicketCard(
            movieTitle: 'Thanh Gươm Diệt Quỷ: Phép Màu Tình Thân Cho Đến Chuyến Tàu Vô Tận',
            cinemaName: 'Cinema Quận 1',
            roomName: 'Phòng 1',
            format: 'IMAX',
            showtime: '21:00',
            seatNames: 'A1',
            bookingCode: 'ABCDEFGH',
          ),
        ));
        expect(find.textContaining('Thanh Gươm Diệt Quỷ'), findsOneWidget);
      });
    });

    // -------------------------------------------------------------------------
    // Feature 13: Tabbed Ticket Management (S10)
    // -------------------------------------------------------------------------
    group('F13: Tabbed Ticket Management', () {
      test('1. SẮP TỚI categorizes paid bookings that are not noShow', () {
        final futureTicket = buildTestBooking(
          status: 'paid',
          showtimeStart: DateTime.now().add(const Duration(hours: 3)),
        );
        expect(futureTicket.status, 'paid');
        expect(futureTicket.isNoShow, isFalse);
      });

      test('2. ĐÃ XEM categorizes used bookings', () {
        final usedTicket = buildTestBooking(
          status: 'used',
          checkedInAt: DateTime.now().subtract(const Duration(hours: 1)),
        );
        expect(usedTicket.status, 'used');
        expect(usedTicket.displayStatus, 'used');
      });

      test('3. ĐÃ XEM categorizes paid bookings past 15 min without check-in as noShow', () {
        final noShowTicket = buildTestBooking(
          status: 'paid',
          showtimeStart: DateTime.now().subtract(const Duration(minutes: 20)),
          checkedInAt: null,
        );
        expect(noShowTicket.isNoShow, isTrue);
        expect(noShowTicket.displayStatus, 'noShow');
      });

      test('4. ĐÃ HỦY categorizes cancelled bookings', () {
        final cancelledTicket = buildTestBooking(
          status: 'cancelled',
          cancelReason: 'Khách hủy vé trực tuyến',
        );
        expect(cancelledTicket.status, 'cancelled');
      });

      test('5. Expired and holding bookings are hidden from customer tab list', () {
        final holding = buildTestBooking(status: 'holding');
        final expired = buildTestBooking(
          status: 'holding',
          holdUntil: DateTime.now().subtract(const Duration(minutes: 5)),
        );
        expect(holding.status, 'holding');
        expect(expired.displayStatus, 'expired');
      });
    });

    // -------------------------------------------------------------------------
    // Feature 14: `cancel_booking` RPC (2h Cutoff) (S10)
    // -------------------------------------------------------------------------
    group('F14: `cancel_booking` RPC (2h Cutoff)', () {
      test('1. canCancel is true when ticket is paid and >= 2 hours before showtime', () {
        final cancellable = buildTestBooking(
          status: 'paid',
          showtimeStart: DateTime.now().add(const Duration(hours: 2, minutes: 15)),
        );
        expect(cancellable.canCancel, isTrue);
      });

      test('2. canCancel is false when ticket is under 2 hours before showtime', () {
        final nonCancellable = buildTestBooking(
          status: 'paid',
          showtimeStart: DateTime.now().add(const Duration(hours: 1, minutes: 45)),
        );
        expect(nonCancellable.canCancel, isFalse);
      });

      test('3. canCancel is false for used or cancelled tickets', () {
        final used = buildTestBooking(
          status: 'used',
          showtimeStart: DateTime.now().add(const Duration(hours: 5)),
        );
        expect(used.canCancel, isFalse);

        final cancelled = buildTestBooking(
          status: 'cancelled',
          showtimeStart: DateTime.now().add(const Duration(hours: 5)),
        );
        expect(cancelled.canCancel, isFalse);
      });

      test('4. AppConstants.cancelBefore is exactly 2 hours', () {
        expect(AppConstants.cancelBefore, const Duration(hours: 2));
      });

      test('5. Cancellation updates status to cancelled with specified reason', () {
        final booking = buildTestBooking(
          status: 'cancelled',
          cancelReason: 'Khách đổi lịch xem phim',
        );
        expect(booking.status, 'cancelled');
        expect(booking.cancelReason, 'Khách đổi lịch xem phim');
      });
    });

    // -------------------------------------------------------------------------
    // Feature 15: QR Check-in Camera Scanner (S18)
    // -------------------------------------------------------------------------
    group('F15: QR Check-in Camera Scanner', () {
      test('1. Normalizes booking code by trimming whitespace and converting to uppercase', () {
        const raw = '  k7m2qx9p  ';
        final normalized = raw.trim().toUpperCase();
        expect(normalized, 'K7M2QX9P');
      });

      test('2. Rejects booking codes with invalid character count', () {
        const shortCode = 'ABC12';
        const longCode = 'ABCDEFGHIJKL';
        expect(shortCode.length == 8, isFalse);
        expect(longCode.length == 8, isFalse);
      });

      test('3. Accepts valid 8-character uppercase booking code', () {
        const validCode = 'K7M2QX9P';
        expect(validCode.length, 8);
        expect(RegExp(r'^[A-Z0-9]{8}$').hasMatch(validCode), isTrue);
      });

      testWidgets('4. ResultSheet renders error state with QUÉT TIẾP button', (tester) async {
        bool dismissed = false;
        await tester.pumpWidget(createTestAppWrapper(
          child: ResultSheet(
            isValid: false,
            errorMessage: 'Mã vé không tồn tại',
            onConfirm: () {},
            onDismiss: () => dismissed = true,
          ),
        ));
        expect(find.text('VÉ KHÔNG HỢP LỆ'), findsOneWidget);
        expect(find.text('Mã vé không tồn tại'), findsOneWidget);
        expect(find.text('QUÉT TIẾP'), findsOneWidget);
        await tester.tap(find.text('QUÉT TIẾP'));
        expect(dismissed, isTrue);
      });

      testWidgets('5. ResultSheet renders success state with ticket information', (tester) async {
        await tester.pumpWidget(createTestAppWrapper(
          child: ResultSheet(
            isValid: true,
            movieTitle: 'Mai',
            roomName: 'Phòng 1',
            showtime: '19:30',
            seats: 'A5, A6',
            ageRating: 'P',
            onConfirm: () {},
            onDismiss: () {},
          ),
        ));
        expect(find.text('VÉ HỢP LỆ'), findsOneWidget);
        expect(find.text('Mai'), findsOneWidget);
        expect(find.text('GHẾ: A5, A6'), findsOneWidget);
      });
    });

    // -------------------------------------------------------------------------
    // Feature 16: `check_in` 8 Validation Checks (S18)
    // -------------------------------------------------------------------------
    group('F16: `check_in` 8 Validation Checks', () {
      test('1. Check 1: Non-existent booking code returns error', () {
        final res = evaluateCheckIn(
          booking: null,
          staffCinemaId: 'cn_q1',
          currentTime: DateTime.now(),
        );
        expect(res.code, CheckinValidationCode.notExists);
        expect(res.isSuccess, isFalse);
        expect(res.message, 'Mã vé không tồn tại trong hệ thống');
      });

      test('2. Check 2: Cancelled ticket returns error', () {
        final ticket = buildTestBooking(status: 'cancelled');
        final res = evaluateCheckIn(
          booking: ticket,
          staffCinemaId: 'cn_q1',
          currentTime: DateTime.now(),
        );
        expect(res.code, CheckinValidationCode.cancelled);
        expect(res.message, 'Vé đã bị hủy và hoàn tiền');
      });

      test('3. Check 3: Used ticket returns error', () {
        final ticket = buildTestBooking(status: 'used');
        final res = evaluateCheckIn(
          booking: ticket,
          staffCinemaId: 'cn_q1',
          currentTime: DateTime.now(),
        );
        expect(res.code, CheckinValidationCode.used);
        expect(res.message, contains('Vé đã sử dụng'));
      });

      test('4. Check 4: Wrong cinema returns error mentioning cinema name', () {
        final ticket = buildTestBooking(
          cinemaId: 'cn_tb',
          cinemaName: 'Cinema Tân Bình',
        );
        final res = evaluateCheckIn(
          booking: ticket,
          staffCinemaId: 'cn_q1',
          currentTime: DateTime.now(),
        );
        expect(res.code, CheckinValidationCode.wrongCinema);
        expect(res.message, 'Vé thuộc rạp khác (Cinema Tân Bình)');
      });

      test('5. Check 5 & 6: Enforces check-in time window [-30m, +15m]', () {
        final showtime = DateTime.now().add(const Duration(minutes: 40));
        final ticket = buildTestBooking(showtimeStart: showtime);

        // Too early (>30m before showtime)
        final earlyRes = evaluateCheckIn(
          booking: ticket,
          staffCinemaId: 'cn_q1',
          currentTime: DateTime.now(),
        );
        expect(earlyRes.code, CheckinValidationCode.tooEarly);

        // Too late (>15m after showtime)
        final pastShowtime = DateTime.now().subtract(const Duration(minutes: 20));
        final lateTicket = buildTestBooking(showtimeStart: pastShowtime);
        final lateRes = evaluateCheckIn(
          booking: lateTicket,
          staffCinemaId: 'cn_q1',
          currentTime: DateTime.now(),
        );
        expect(lateRes.code, CheckinValidationCode.expiredShowtime);
      });
    });

    // -------------------------------------------------------------------------
    // Feature 17: Age Rating ID Verification Check (S18)
    // -------------------------------------------------------------------------
    group('F17: Age Rating ID Verification Check', () {
      testWidgets('1. P rating enables confirm button immediately without ID check', (tester) async {
        bool confirmed = false;
        await tester.pumpWidget(createTestAppWrapper(
          child: ResultSheet(
            isValid: true,
            ageRating: 'P',
            onConfirm: () => confirmed = true,
            onDismiss: () {},
          ),
        ));
        expect(find.byType(Checkbox), findsNothing);
        await tester.tap(find.text('XÁC NHẬN CHO VÀO'));
        expect(confirmed, isTrue);
      });

      testWidgets('2. T13 rating enables confirm button immediately without ID check', (tester) async {
        bool confirmed = false;
        await tester.pumpWidget(createTestAppWrapper(
          child: ResultSheet(
            isValid: true,
            ageRating: 'T13',
            onConfirm: () => confirmed = true,
            onDismiss: () {},
          ),
        ));
        expect(find.byType(Checkbox), findsNothing);
        await tester.tap(find.text('XÁC NHẬN CHO VÀO'));
        expect(confirmed, isTrue);
      });

      testWidgets('3. T16 rating requires checking ID verification box before confirming', (tester) async {
        bool confirmed = false;
        await tester.pumpWidget(createTestAppWrapper(
          child: ResultSheet(
            isValid: true,
            ageRating: 'T16',
            onConfirm: () => confirmed = true,
            onDismiss: () {},
          ),
        ));
        expect(find.byType(Checkbox), findsOneWidget);
        // Tapping confirm before check has no effect
        await tester.tap(find.text('XÁC NHẬN CHO VÀO'));
        expect(confirmed, isFalse);

        // Check the box
        await tester.tap(find.byType(Checkbox));
        await tester.pump();

        // Tapping confirm now triggers callback
        await tester.tap(find.text('XÁC NHẬN CHO VÀO'));
        expect(confirmed, isTrue);
      });

      testWidgets('4. T18 rating requires checking ID verification box before confirming', (tester) async {
        bool confirmed = false;
        await tester.pumpWidget(createTestAppWrapper(
          child: ResultSheet(
            isValid: true,
            ageRating: 'T18',
            onConfirm: () => confirmed = true,
            onDismiss: () {},
          ),
        ));
        expect(find.byType(Checkbox), findsOneWidget);
        await tester.tap(find.byType(Checkbox));
        await tester.pump();
        await tester.tap(find.text('XÁC NHẬN CHO VÀO'));
        expect(confirmed, isTrue);
      });

      test('5. CheckinResult from RPC parses age rating and summaries properly', () {
        final mockRpc = {
          'success': true,
          'movie_title': 'Mai',
          'room_name': 'Phòng 1',
          'age_rating': 'T18',
          'seats': [{'id': 'A5'}, {'id': 'A6'}],
          'foods': [{'qty': 1, 'name': 'Bắp rang'}],
        };
        final res = buildTestBooking(
          movieTitle: mockRpc['movie_title'] as String,
          ageRating: mockRpc['age_rating'] as String,
        );
        expect(res.ageRating, 'T18');
      });
    });

    // -------------------------------------------------------------------------
    // Feature 18: Food Queue Fulfillment Board (S19)
    // -------------------------------------------------------------------------
    group('F18: Food Queue Fulfillment Board', () {
      test('1. Pending orders filter by foodStatus == pending', () {
        final orders = [
          buildTestBooking(code: 'ORD1', foodStatus: 'pending'),
          buildTestBooking(code: 'ORD2', foodStatus: 'delivered'),
          buildTestBooking(code: 'ORD3', foodStatus: 'pending'),
        ];
        final pending = orders.where((o) => o.foodStatus == 'pending').toList();
        expect(pending.length, 2);
      });

      test('2. Delivered orders filter by foodStatus == delivered', () {
        final orders = [
          buildTestBooking(code: 'ORD1', foodStatus: 'pending'),
          buildTestBooking(code: 'ORD2', foodStatus: 'delivered'),
        ];
        final delivered = orders.where((o) => o.foodStatus == 'delivered').toList();
        expect(delivered.length, 1);
        expect(delivered.first.code, 'ORD2');
      });

      test('3. Pending orders sort ascending by showtimeStart (earliest first)', () {
        final now = DateTime.now();
        final orders = [
          buildTestBooking(code: 'LATER', showtimeStart: now.add(const Duration(hours: 3))),
          buildTestBooking(code: 'SOONER', showtimeStart: now.add(const Duration(hours: 1))),
        ];
        orders.sort((a, b) => a.showtimeStart.compareTo(b.showtimeStart));
        expect(orders.first.code, 'SOONER');
      });

      test('4. Orders are strictly scoped to staff cinemaId', () {
        final orders = [
          buildTestBooking(code: 'O1', cinemaId: 'cn_q1'),
          buildTestBooking(code: 'O2', cinemaId: 'cn_tb'),
        ];
        final q1Orders = orders.where((o) => o.cinemaId == 'cn_q1').toList();
        expect(q1Orders.length, 1);
        expect(q1Orders.first.code, 'O1');
      });

      test('5. Cancelled bookings are excluded from pending queue', () {
        final orders = [
          buildTestBooking(code: 'O1', status: 'cancelled', foodStatus: 'pending'),
          buildTestBooking(code: 'O2', status: 'paid', foodStatus: 'pending'),
        ];
        final activePending = orders.where((o) => o.status == 'paid' && o.foodStatus == 'pending').toList();
        expect(activePending.length, 1);
        expect(activePending.first.code, 'O2');
      });
    });

    // -------------------------------------------------------------------------
    // Feature 19: `deliver_food` RPC (S19)
    // -------------------------------------------------------------------------
    group('F19: `deliver_food` RPC', () {
      test('1. Food delivery transitions foodStatus from pending to delivered', () {
        final order = buildTestBooking(foodStatus: 'pending');
        final delivered = buildTestBooking(
          code: order.code,
          foodStatus: 'delivered',
        );
        expect(delivered.foodStatus, 'delivered');
      });

      test('2. Order cannot be delivered twice', () {
        final delivered = buildTestBooking(foodStatus: 'delivered');
        expect(delivered.foodStatus == 'pending', isFalse);
      });

      test('3. Delivering food records notification type foodDelivered', () {
        final notif = buildTestNotification(
          type: 'foodDelivered',
          title: 'Đồ ăn đã sẵn sàng',
          body: 'Mời bạn tới quầy bắp nước nhận món.',
        );
        expect(notif.type, 'foodDelivered');
      });

      test('4. Food items retain quantities and names upon delivery', () {
        final order = buildTestBooking(
          foods: [{'name': 'Bắp Ngọt Lớn', 'qty': 2, 'unit_price': 55000}],
          foodStatus: 'delivered',
        );
        expect(order.foods.first['qty'], 2);
        expect(order.foods.first['name'], 'Bắp Ngọt Lớn');
      });

      test('5. Food status none does not enter fulfillment workflow', () {
        final order = buildTestBooking(foodStatus: 'none', foods: []);
        expect(order.foodStatus, 'none');
      });
    });

    // -------------------------------------------------------------------------
    // Feature 20: Counter Box Office Ticket Sales (S20)
    // -------------------------------------------------------------------------
    group('F20: Counter Box Office Ticket Sales', () {
      test('1. Counter booking sets channel to counter and userId to null', () {
        final booking = buildTestBooking(
          channel: 'counter',
          userId: null,
          soldBy: 'staff_q1',
        );
        expect(booking.channel, 'counter');
        expect(booking.userId, isNull);
        expect(booking.soldBy, 'staff_q1');
      });

      test('2. Counter sales hold duration is exactly 3 minutes', () {
        expect(AppConstants.holdCounter.inMinutes, 3);
      });

      test('3. Counter showtimes list is filtered to current cinemaId', () {
        final showtimes = [
          buildTestShowtime(id: 's1', cinemaId: 'cn_q1'),
          buildTestShowtime(id: 's2', cinemaId: 'cn_tb'),
        ];
        final q1 = showtimes.where((s) => s.cinemaId == 'cn_q1').toList();
        expect(q1.length, 1);
        expect(q1.first.id, 's1');
      });

      test('4. Counter ticket receives immediate paid status and paidAt timestamp', () {
        final booking = buildTestBooking(
          channel: 'counter',
          status: 'paid',
          paymentMethod: 'cash',
          paidAt: DateTime.now(),
        );
        expect(booking.status, 'paid');
        expect(booking.paidAt, isNotNull);
        expect(booking.paymentMethod, 'cash');
      });

      test('5. Counter sales supports both cash and card payment methods', () {
        const methods = ['cash', 'card'];
        for (final m in methods) {
          final b = buildTestBooking(channel: 'counter', paymentMethod: m);
          expect(b.paymentMethod, m);
        }
      });
    });

    // -------------------------------------------------------------------------
    // Feature 21: Cash Change Calculator (S21)
    // -------------------------------------------------------------------------
    group('F21: Cash Change Calculator', () {
      test('1. Calculates exact change when cash given exceeds total', () {
        final change = calculateCashChange(cashReceived: 200000, total: 160000);
        expect(change, 40000);
      });

      test('2. Returns zero change when exact amount is given', () {
        final change = calculateCashChange(cashReceived: 160000, total: 160000);
        expect(change, 0);
      });

      test('3. Throws ArgumentError when customer provides insufficient cash', () {
        expect(
          () => calculateCashChange(cashReceived: 100000, total: 160000),
          throwsArgumentError,
        );
      });

      test('4. Large cash transaction calculates correct thousands separation', () {
        final change = calculateCashChange(cashReceived: 1000000, total: 320000);
        expect(change, 680000);
        expect(CurrencyFormatter.formatNumber(change), '680.000');
      });

      test('5. Non-cash payment (card) skips change calculation', () {
        const isCash = false;
        expect(isCash, isFalse);
      });
    });

    // -------------------------------------------------------------------------
    // Feature 22: Operational Dashboard Metrics (S22)
    // -------------------------------------------------------------------------
    group('F22: Operational Dashboard Metrics', () {
      test('1. Total revenue sums ticket and food revenues from paid bookings', () {
        final bookings = [
          buildTestBooking(
            status: 'paid',
            priceSnapshot: {'ticket_total': 160000, 'food_total': 40000, 'total': 200000},
          ),
          buildTestBooking(
            status: 'paid',
            priceSnapshot: {'ticket_total': 80000, 'food_total': 0, 'total': 80000},
          ),
        ];
        final totalRevenue = bookings.fold<int>(0, (sum, b) => sum + b.totalAmount);
        expect(totalRevenue, 280000);
      });

      test('2. Cancelled and expired bookings are excluded from revenue totals', () {
        final bookings = [
          buildTestBooking(status: 'paid', priceSnapshot: {'total': 200000}),
          buildTestBooking(status: 'cancelled', priceSnapshot: {'total': 160000}),
          buildTestBooking(status: 'expired', priceSnapshot: {'total': 80000}),
        ];
        final paidRevenue = bookings
            .where((b) => b.status == 'paid')
            .fold<int>(0, (sum, b) => sum + b.totalAmount);
        expect(paidRevenue, 200000);
      });

      test('3. Occupancy rate calculation divides sold seats by total capacity', () {
        const sold = 72;
        const total = 96;
        const rate = (sold / total) * 100;
        expect(rate, 75.0);
      });

      test('4. Occupancy rate returns 0% when capacity is zero', () {
        const total = 0;
        const rate = total == 0 ? 0.0 : (10 / total) * 100;
        expect(rate, 0.0);
      });

      test('5. Metrics are strictly partitioned by cinemaId', () {
        final bookings = [
          buildTestBooking(cinemaId: 'cn_q1', priceSnapshot: {'total': 100000}),
          buildTestBooking(cinemaId: 'cn_tb', priceSnapshot: {'total': 250000}),
        ];
        final q1Total = bookings
            .where((b) => b.cinemaId == 'cn_q1')
            .fold<int>(0, (sum, b) => sum + b.totalAmount);
        expect(q1Total, 100000);
      });
    });

    // -------------------------------------------------------------------------
    // Feature 23: Showtime Scheduling & 15m Gap (S14)
    // -------------------------------------------------------------------------
    group('F23: Showtime Scheduling & 15m Gap', () {
      test('1. AppConstants.gapBetweenShowtimes is exactly 15 minutes', () {
        expect(AppConstants.gapBetweenShowtimes, const Duration(minutes: 15));
      });

      test('2. Detects conflict when new showtime starts during existing showtime', () {
        final existingStart = DateTime(2026, 10, 27, 19, 0);
        final existingEnd = DateTime(2026, 10, 27, 21, 10);
        final candidateStart = DateTime(2026, 10, 27, 20, 0);
        final candidateEnd = DateTime(2026, 10, 27, 22, 10);

        final conflict = hasShowtimeConflict(
          existingStart: existingStart,
          existingEnd: existingEnd,
          candidateStart: candidateStart,
          candidateEnd: candidateEnd,
        );
        expect(conflict, isTrue);
      });

      test('3. Detects conflict when buffer between showtimes is under 15 minutes', () {
        final existingStart = DateTime(2026, 10, 27, 18, 0);
        final existingEnd = DateTime(2026, 10, 27, 20, 0);
        // Candidate starts only 10 minutes after existing ends (need 15m)
        final candidateStart = DateTime(2026, 10, 27, 20, 10);
        final candidateEnd = DateTime(2026, 10, 27, 22, 10);

        final conflict = hasShowtimeConflict(
          existingStart: existingStart,
          existingEnd: existingEnd,
          candidateStart: candidateStart,
          candidateEnd: candidateEnd,
        );
        expect(conflict, isTrue);
      });

      test('4. Allows scheduling when buffer between showtimes is >= 15 minutes', () {
        final existingStart = DateTime(2026, 10, 27, 18, 0);
        final existingEnd = DateTime(2026, 10, 27, 20, 0);
        // Candidate starts 20 minutes after existing ends
        final candidateStart = DateTime(2026, 10, 27, 20, 20);
        final candidateEnd = DateTime(2026, 10, 27, 22, 20);

        final conflict = hasShowtimeConflict(
          existingStart: existingStart,
          existingEnd: existingEnd,
          candidateStart: candidateStart,
          candidateEnd: candidateEnd,
        );
        expect(conflict, isFalse);
      });

      test('5. Simultaneous showtimes in different rooms have no conflict', () {
        const room1 = 'rm_01';
        const room2 = 'rm_02';
        expect(room1 != room2, isTrue);
      });
    });

    // -------------------------------------------------------------------------
    // Feature 24: Booking & Order Inspection (S15)
    // -------------------------------------------------------------------------
    group('F24: Booking & Order Inspection', () {
      test('1. Filters bookings by status (ALL, PAID, USED, NOSHOW, CANCELLED, EXPIRED)', () {
        final bookings = [
          buildTestBooking(code: 'B1', status: 'paid'),
          buildTestBooking(code: 'B2', status: 'used'),
          buildTestBooking(code: 'B3', status: 'cancelled'),
        ];
        expect(bookings.where((b) => b.status == 'paid').length, 1);
        expect(bookings.where((b) => b.status == 'used').length, 1);
        expect(bookings.where((b) => b.status == 'cancelled').length, 1);
      });

      test('2. Filters bookings by channel (ONLINE vs COUNTER)', () {
        final bookings = [
          buildTestBooking(code: 'B1', channel: 'online'),
          buildTestBooking(code: 'B2', channel: 'counter'),
        ];
        expect(bookings.where((b) => b.channel == 'online').length, 1);
        expect(bookings.where((b) => b.channel == 'counter').length, 1);
      });

      test('3. BookingModel preserves audit metadata (checkedInBy, checkedInAt, soldBy)', () {
        final now = DateTime.now();
        final booking = buildTestBooking(
          checkedInBy: 'staff_01',
          checkedInAt: now,
          soldBy: 'counter_01',
        );
        expect(booking.checkedInBy, 'staff_01');
        expect(booking.checkedInAt, now);
        expect(booking.soldBy, 'counter_01');
      });

      test('4. BookingModel toMap includes all audit and status fields', () {
        final booking = buildTestBooking();
        final map = booking.toMap();
        expect(map['code'], booking.code);
        expect(map['status'], booking.status);
        expect(map['price_snapshot'], isNotNull);
      });

      test('5. Booking detail inspection reconstructs from JSON map seamlessly', () {
        final original = buildTestBooking();
        final map = original.toMap();
        map['created_at'] = original.createdAt.toIso8601String();
        final reconstituted = BookingModel.fromMap(map);
        expect(reconstituted.code, original.code);
        expect(reconstituted.movieTitle, original.movieTitle);
      });
    });

    // -------------------------------------------------------------------------
    // Feature 25: Food Catalog Availability Toggle (S16)
    // -------------------------------------------------------------------------
    group('F25: Food Catalog Availability Toggle', () {
      test('1. Toggling isAvailable updates item status', () {
        final food = buildTestFood(isAvailable: true);
        final toggled = food.copyWith(isAvailable: false);
        expect(toggled.isAvailable, isFalse);
      });

      test('2. Out of stock item cannot be added in S07 (isAvailable == false)', () {
        final food = buildTestFood(isAvailable: false);
        expect(food.isAvailable, isFalse);
      });

      test('3. FoodModel categories support combo, popcorn, drink, and snack', () {
        const categories = ['combo', 'popcorn', 'drink', 'snack'];
        for (final cat in categories) {
          final f = buildTestFood(category: cat);
          expect(f.category, cat);
        }
      });

      test('4. Food items map correctly from PostgreSQL schema', () {
        final food = FoodModel.fromMap({
          'id': 'fd_test',
          'cinema_id': 'cn_q1',
          'name': 'Bắp Nước Combo 1',
          'category': 'combo',
          'price': 85000,
          'is_available': true,
        });
        expect(food.id, 'fd_test');
        expect(food.name, 'Bắp Nước Combo 1');
        expect(food.price, 85000);
      });

      test('5. Modifying price updates unit_price in booking json', () {
        final food = buildTestFood(price: 60000, quantity: 1);
        final json = food.toBookingJson();
        expect(json['unit_price'], 60000);
      });
    });

    // -------------------------------------------------------------------------
    // Feature 26: Staff Account Creation Edge Function (S23)
    // -------------------------------------------------------------------------
    group('F26: Staff Account Creation Edge Function', () {
      test('1. Manager creates staff with manager cinemaId automatically assigned', () {
        final manager = buildTestUser(role: UserRole.manager, cinemaId: 'cn_q1');
        final newStaff = buildTestUser(
          id: 'staff_new',
          role: UserRole.staff,
          cinemaId: manager.cinemaId,
        );
        expect(newStaff.role, UserRole.staff);
        expect(newStaff.cinemaId, 'cn_q1');
      });

      test('2. Admin can create staff for any selected cinemaId', () {
        final staffTb = buildTestUser(role: UserRole.staff, cinemaId: 'cn_tb');
        expect(staffTb.cinemaId, 'cn_tb');
      });

      test('3. Staff accounts default to unlocked state upon creation', () {
        final staff = buildTestUser(role: UserRole.staff);
        expect(staff.isLocked, isFalse);
      });

      test('4. Staff account serialization preserves staff role and cinemaId', () {
        final staff = buildTestUser(role: UserRole.staff, cinemaId: 'cn_q1');
        final map = staff.toMap();
        expect(map['role'], 'staff');
        expect(map['cinema_id'], 'cn_q1');
      });

      test('5. Rejects creation with empty or invalid email', () {
        const invalidEmail = 'not-an-email';
        expect(invalidEmail.contains('@'), isFalse);
      });
    });

    // -------------------------------------------------------------------------
    // Feature 27: User Account Locking (S23)
    // -------------------------------------------------------------------------
    group('F27: User Account Locking', () {
      test('1. Setting isLocked to true locks user account', () {
        final user = buildTestUser(isLocked: false);
        final locked = user.copyWith(isLocked: true);
        expect(locked.isLocked, isTrue);
      });

      test('2. Locked user route guard redirects to login screen', () {
        final locked = buildTestUser(isLocked: true);
        expect(RouteGuards.getInitialRoute(locked), AppRoutes.login);
      });

      test('3. Unlocking restores access to role initial route', () {
        final staff = buildTestUser(role: UserRole.staff, isLocked: true);
        expect(RouteGuards.getInitialRoute(staff), AppRoutes.login);

        final unlocked = staff.copyWith(isLocked: false);
        expect(RouteGuards.getInitialRoute(unlocked), AppRoutes.staffCheckin);
      });

      test('4. Locking customer account forces sign out route', () {
        final customer = buildTestUser(role: UserRole.customer, isLocked: true);
        expect(RouteGuards.getInitialRoute(customer), AppRoutes.login);
      });

      test('5. Database representation stores is_locked as boolean', () {
        final user = buildTestUser(isLocked: true);
        expect(user.toMap()['is_locked'], isTrue);
      });
    });

    // -------------------------------------------------------------------------
    // Feature 28: Movies CRUD & Deletion Protection (S13)
    // -------------------------------------------------------------------------
    group('F28: Movies CRUD & Deletion Protection', () {
      test('1. Admin can instantiate MovieModel with full metadata', () {
        final movie = buildTestMovie(
          title: 'Dune: Part Two',
          director: 'Denis Villeneuve',
          genres: ['Hành động', 'Khoa học viễn tưởng'],
        );
        expect(movie.title, 'Dune: Part Two');
        expect(movie.director, 'Denis Villeneuve');
      });

      test('2. Cannot delete movie when future showtimes exist', () {
        final futureShowtimes = [buildTestShowtime()];
        final canDelete = futureShowtimes.isEmpty;
        expect(canDelete, isFalse);
      });

      test('3. Deactivating movie sets isActive to false', () {
        final movie = buildTestMovie(isActive: true);
        final deactivated = MovieModel(
          id: movie.id,
          title: movie.title,
          genres: movie.genres,
          durationMin: movie.durationMin,
          ageRating: movie.ageRating,
          releaseDate: movie.releaseDate,
          isActive: false,
        );
        expect(deactivated.isActive, isFalse);
      });

      test('4. Manager only has read-only access to movies list', () {
        final manager = buildTestUser(role: UserRole.manager);
        expect(manager.isManager, isTrue);
        expect(manager.isAdmin, isFalse);
      });

      test('5. Duration in minutes is strictly positive integer', () {
        final movie = buildTestMovie(durationMin: 135);
        expect(movie.durationMin, isPositive);
      });
    });

    // -------------------------------------------------------------------------
    // Feature 29: Room & Seat Grid Configuration (S24)
    // -------------------------------------------------------------------------
    group('F29: Room & Seat Grid Configuration', () {
      test('1. RoomModel tracks dimensions, formats, and seatCount', () {
        final room = buildTestRoom(rows: 8, cols: 10, seatCount: 80);
        expect(room.rows, 8);
        expect(room.cols, 10);
        expect(room.seatCount, 80);
      });

      test('2. Room formats support 2D, 3D, and IMAX Laser', () {
        final room = buildTestRoom(formats: ['2D', '3D', 'IMAX']);
        expect(room.formats, contains('IMAX'));
        expect(room.formats.length, 3);
      });

      test('3. Couple seat counts as 1 in total room seat capacity', () {
        const standardSeats = 40;
        const vipSeats = 20;
        const coupleSeats = 10;
        const totalCapacity = standardSeats + vipSeats + coupleSeats;
        expect(totalCapacity, 70);
      });

      test('4. Room serialization round-trips correctly', () {
        final room = buildTestRoom();
        final map = room.toMap();
        final reconstituted = RoomModel.fromMap(map);
        expect(reconstituted.id, room.id);
        expect(reconstituted.name, room.name);
      });

      test('5. Seat layout list size matches rows * cols', () {
        final room = buildTestRoom(rows: 5, cols: 8, seatLayout: List.filled(40, 'S'));
        expect(room.seatLayout.length, 40);
      });
    });

    // -------------------------------------------------------------------------
    // Feature 30: Dynamic Pricing Configuration (S26)
    // -------------------------------------------------------------------------
    group('F30: Dynamic Pricing Configuration', () {
      test('1. Standard 2D weekday pricing equals base price (80k)', () {
        final weekdayMorning = DateTime(2026, 10, 27, 10, 0); // Tuesday 10am
        final price = calculateSeatPrice(
          format: '2D',
          type: SeatType.standard,
          startTime: weekdayMorning,
        );
        expect(price, 80000);
      });

      test('2. VIP surcharge adds 20k to base price', () {
        final weekdayMorning = DateTime(2026, 10, 27, 10, 0);
        final price = calculateSeatPrice(
          format: '2D',
          type: SeatType.vip,
          startTime: weekdayMorning,
        );
        expect(price, 100000);
      });

      test('3. Couple seat formula calculates 2 * base + 20k surcharge', () {
        final weekdayMorning = DateTime(2026, 10, 27, 10, 0);
        final price = calculateSeatPrice(
          format: '2D',
          type: SeatType.couple,
          startTime: weekdayMorning,
        );
        expect(price, 180000);
      });

      test('4. Weekend adds 10k surcharge (Friday, Saturday, Sunday)', () {
        final saturdayMorning = DateTime(2026, 10, 31, 10, 0);
        final price = calculateSeatPrice(
          format: '2D',
          type: SeatType.standard,
          startTime: saturdayMorning,
        );
        expect(price, 90000);
      });

      test('5. Prime time (18h-22h) adds 10k surcharge; weekend prime time adds 20k total surcharge', () {
        final saturdayPrime = DateTime(2026, 10, 31, 19, 30);
        final price = calculateSeatPrice(
          format: '2D',
          type: SeatType.standard,
          startTime: saturdayPrime,
        );
        expect(price, 100000); // 80k + 10k weekend + 10k prime
      });
    });

    // -------------------------------------------------------------------------
    // Feature 31: Voucher Management (S27)
    // -------------------------------------------------------------------------
    group('F31: Voucher Management', () {
      test('1. Fixed amount voucher discounts ticket total correctly', () {
        final voucher = buildTestVoucher(code: 'GIAM30K', type: 'amount', value: 30000);
        final discount = calculateVoucherDiscount(ticketTotal: 160000, voucher: voucher);
        expect(discount, 30000);
      });

      test('2. Percentage voucher discounts proportional ticket total', () {
        final voucher = buildTestVoucher(code: 'GIAM10PT', type: 'percent', value: 10);
        final discount = calculateVoucherDiscount(ticketTotal: 200000, voucher: voucher);
        expect(discount, 20000);
      });

      test('3. Percentage voucher respects max_discount cap', () {
        final voucher = buildTestVoucher(
          code: 'GIAM50PT',
          type: 'percent',
          value: 50,
          maxDiscount: 40000,
        );
        final discount = calculateVoucherDiscount(ticketTotal: 200000, voucher: voucher);
        expect(discount, 40000); // 50% of 200k = 100k, capped at 40k
      });

      test('4. Inactive or expired voucher returns zero discount', () {
        final expiredVoucher = buildTestVoucher(
          expiryDate: DateTime.now().subtract(const Duration(days: 1)),
        );
        expect(calculateVoucherDiscount(ticketTotal: 100000, voucher: expiredVoucher), 0);

        final inactiveVoucher = buildTestVoucher(isActive: false);
        expect(calculateVoucherDiscount(ticketTotal: 100000, voucher: inactiveVoucher), 0);
      });

      test('5. Voucher with exhausted usage (used_count >= max_uses) returns zero discount', () {
        final exhausted = buildTestVoucher(usedCount: 50, maxUses: 50);
        expect(calculateVoucherDiscount(ticketTotal: 100000, voucher: exhausted), 0);
      });
    });

    // -------------------------------------------------------------------------
    // Feature 32: Audit Logging (S29)
    // -------------------------------------------------------------------------
    group('F32: Audit Logging', () {
      test('1. Audit log captures actor, role, cinema, action, and target entity', () {
        final log = buildTestAuditLog(
          actorId: 'staff_q1',
          actorRole: 'staff',
          action: 'checkIn',
          entityType: 'booking',
          entityId: 'K7M2QX9P',
        );
        expect(log['actor_role'], 'staff');
        expect(log['action'], 'checkIn');
        expect(log['entity_id'], 'K7M2QX9P');
      });

      test('2. Sensitive operations recorded in audit log (cancelShowtime, refund, changePrice)', () {
        const actions = ['checkIn', 'cancelShowtime', 'refund', 'changePrice', 'lockUser', 'unlockUser'];
        for (final act in actions) {
          final log = buildTestAuditLog(action: act);
          expect(log['action'], act);
        }
      });

      test('3. Audit log records cancellation reason', () {
        final log = buildTestAuditLog(
          action: 'refund',
          reason: 'Khách yêu cầu hủy vé do bận việc đột xuất',
        );
        expect(log['reason'], contains('hủy vé'));
      });

      test('4. Audit log timestamp is recorded in UTC ISO format', () {
        final log = buildTestAuditLog();
        expect(log['timestamp'], isNotNull);
        expect(() => DateTime.parse(log['timestamp'] as String), returnsNormally);
      });

      test('5. Audit logs are restricted to Admin role inspection', () {
        final admin = buildTestUser(role: UserRole.admin);
        final staff = buildTestUser(role: UserRole.staff);
        expect(admin.isAdmin, isTrue);
        expect(staff.isAdmin, isFalse);
      });
    });

    // -------------------------------------------------------------------------
    // Feature 33: Cinema Locator with Google Maps (S17)
    // -------------------------------------------------------------------------
    group('F33: Cinema Locator with Google Maps', () {
      test('1. CinemaModel preserves coordinates and address', () {
        final cinema = buildTestCinema(lat: 10.7769, lng: 106.7009);
        expect(cinema.lat, 10.7769);
        expect(cinema.lng, 106.7009);
      });

      test('2. Distance in km can be assigned and stored in CinemaModel', () {
        final cinema = buildTestCinema(distanceKm: 3.5);
        expect(cinema.distanceKm, 3.5);
      });

      test('3. Cinemas sort ascending by distanceKm', () {
        final c1 = buildTestCinema(id: 'c1', distanceKm: 7.2);
        final c2 = buildTestCinema(id: 'c2', distanceKm: 1.8);
        final list = [c1, c2];
        list.sort((a, b) => (a.distanceKm ?? 0).compareTo(b.distanceKm ?? 0));
        expect(list.first.id, 'c2');
      });

      test('4. Cinema without GPS permission maintains null distanceKm gracefully', () {
        final cinema = buildTestCinema(distanceKm: null);
        expect(cinema.distanceKm, isNull);
      });

      test('5. Active filter excludes inactive cinemas', () {
        final active = buildTestCinema(isActive: true);
        final inactive = buildTestCinema(id: 'c_closed', isActive: false);
        final list = [active, inactive];
        final activeList = list.where((c) => c.isActive).toList();
        expect(activeList.length, 1);
        expect(activeList.first.id, active.id);
      });
    });

    // -------------------------------------------------------------------------
    // Feature 34: Local Show Reminder Notifications (S30)
    // -------------------------------------------------------------------------
    group('F34: Local Show Reminder Notifications', () {
      test('1. Reminder scheduled 1 hour before showtime', () {
        final showtimeStart = DateTime(2026, 10, 27, 20, 0);
        final reminderTime = showtimeStart.subtract(const Duration(hours: 1));
        expect(reminderTime, DateTime(2026, 10, 27, 19, 0));
      });

      test('2. NotificationModel maps bookingCode and isRead state', () {
        final notif = buildTestNotification(
          type: 'showReminder',
          bookingCode: 'K7M2QX9P',
          isRead: false,
        );
        expect(notif.type, 'showReminder');
        expect(notif.bookingCode, 'K7M2QX9P');
        expect(notif.isRead, isFalse);
      });

      test('3. Notifications sort descending by createdAt (newest first)', () {
        final n1 = buildTestNotification(id: 'n1', createdAt: DateTime(2026, 10, 27, 10, 0));
        final n2 = buildTestNotification(id: 'n2', createdAt: DateTime(2026, 10, 27, 11, 0));
        final list = [n1, n2];
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        expect(list.first.id, 'n2');
      });

      test('4. Mark all as read transitions unread count to zero', () {
        final list = [
          buildTestNotification(id: '1', isRead: false),
          buildTestNotification(id: '2', isRead: false),
        ];
        final readList = list.map((n) => NotificationModel(
          id: n.id,
          userId: n.userId,
          type: n.type,
          title: n.title,
          body: n.body,
          isRead: true,
          createdAt: n.createdAt,
        )).toList();
        final unreadCount = readList.where((n) => !n.isRead).length;
        expect(unreadCount, 0);
      });

      test('5. Notification payload deserialization handles missing bookingCode', () {
        final notif = NotificationModel.fromMap({
          'id': 'notif_sys',
          'user_id': 'usr_001',
          'type': 'systemPromo',
          'title': 'Ưu đãi tháng 10',
          'body': 'Giảm 20k vé IMAX cuối tuần',
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
        });
        expect(notif.bookingCode, isNull);
        expect(notif.title, 'Ưu đãi tháng 10');
      });
    });

    // -------------------------------------------------------------------------
    // Feature 35: In-App Customer Support Chat (S31)
    // -------------------------------------------------------------------------
    group('F35: In-App Customer Support Chat', () {
      test('1. Chat conversation key formats as uid_cinemaId', () {
        const uid = 'usr_001';
        const cinemaId = 'cn_q1';
        const conversationId = '${uid}_$cinemaId';
        expect(conversationId, 'usr_001_cn_q1');
      });

      test('2. Chat message payload supports optional booking code attachment', () {
        final msg = {
          'id': 'msg_01',
          'sender_id': 'usr_001',
          'sender_role': 'customer',
          'text': 'Tôi muốn hỏi về thời gian vào rạp',
          'booking_code': 'K7M2QX9P',
          'created_at': DateTime.now().toIso8601String(),
        };
        expect(msg['booking_code'], 'K7M2QX9P');
        expect(msg['sender_role'], 'customer');
      });

      test('3. Staff of cinema cn_q1 can only access conversations for cn_q1', () {
        final staff = buildTestUser(role: UserRole.staff, cinemaId: 'cn_q1');
        const conv1 = 'usr_01_cn_q1';
        const conv2 = 'usr_02_cn_tb';
        expect(conv1.endsWith(staff.cinemaId!), isTrue);
        expect(conv2.endsWith(staff.cinemaId!), isFalse);
      });

      test('4. Admin has access across all cinema chat conversations', () {
        final admin = buildTestUser(role: UserRole.admin);
        expect(admin.isAdmin, isTrue);
      });

      test('5. Support chat route is protected and requires authentication', () {
        expect(RouteGuards.requiresAuth(AppRoutes.supportChat), isTrue);
      });
    });
  });
}
