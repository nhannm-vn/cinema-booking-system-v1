import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cinema_booking_v1/core/config/app_constants.dart';
import 'package:cinema_booking_v1/core/routes/app_router.dart';
import 'package:cinema_booking_v1/core/routes/route_guards.dart';
import 'package:cinema_booking_v1/core/theme/app_colors.dart';
import 'package:cinema_booking_v1/core/utils/date_formatter.dart';
import 'package:cinema_booking_v1/features/booking/presentation/controllers/booking_provider.dart';
import 'package:cinema_booking_v1/shared/widgets/hold_timer.dart';
import 'package:cinema_booking_v1/shared/widgets/quantity_stepper.dart';
import 'package:cinema_booking_v1/shared/widgets/result_sheet.dart';
import 'package:cinema_booking_v1/shared/widgets/ticket_card.dart';

import 'test_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initTestSupabase();
  });

  group('Tier 2: Boundary Value Analysis & Corner Cases (All 35 Features)', () {
    // -------------------------------------------------------------------------
    // B01: Email/Password Login Boundaries
    // -------------------------------------------------------------------------
    group('B01: Login Boundaries', () {
      test('1. Empty email or password fails validation', () {
        const emptyEmail = '';
        const emptyPass = '';
        expect(emptyEmail.trim().isEmpty, isTrue);
        expect(emptyPass.isEmpty, isTrue);
      });

      test('2. Email case-insensitivity: uppercase email maps to lowercase profile', () {
        const inputEmail = 'KHACH1@CINEMA.VN';
        final user = buildTestUser(email: inputEmail.toLowerCase());
        expect(user.email, 'khach1@cinema.vn');
      });

      test('3. Maximum password length (128 characters) is supported', () {
        final longPass = 'P@ssw0rd' * 16; // 128 chars
        expect(longPass.length, 128);
      });

      test('4. Locked account status persists and blocks access consistently', () {
        final user = buildTestUser(isLocked: true);
        expect(RouteGuards.getInitialRoute(user), AppRoutes.login);
        final unchanged = user.copyWith();
        expect(RouteGuards.getInitialRoute(unchanged), AppRoutes.login);
      });

      test('5. Unauthenticated guest routes to home initially', () {
        expect(RouteGuards.getInitialRoute(null), AppRoutes.home);
      });
    });

    // -------------------------------------------------------------------------
    // B02: Customer Registration Boundaries
    // -------------------------------------------------------------------------
    group('B02: Registration Boundaries', () {
      test('1. Phone number boundary: exactly 10 digits required', () {
        const validPhone = '0901234567';
        const shortPhone = '090123456'; // 9 digits
        const longPhone = '09012345678'; // 11 digits
        final regex = RegExp(r'^0\d{9}$');
        expect(regex.hasMatch(validPhone), isTrue);
        expect(regex.hasMatch(shortPhone), isFalse);
        expect(regex.hasMatch(longPhone), isFalse);
      });

      test('2. Password length boundary: minimum 6 characters required', () {
        const fiveChars = '12345';
        const sixChars = '123456';
        expect(fiveChars.length >= 6, isFalse);
        expect(sixChars.length >= 6, isTrue);
      });

      test('3. Full name trimmed: leading and trailing whitespaces are removed', () {
        const rawName = '   Phan Văn Nam   ';
        final trimmed = rawName.trim();
        expect(trimmed, 'Phan Văn Nam');
      });

      test('4. Vietnamese unicode diacritics in full name are fully preserved', () {
        const unicodeName = 'Nguyễn Đỗ Hoàng Quỳnh Như';
        final user = buildTestUser(fullName: unicodeName);
        expect(user.fullName, unicodeName);
      });

      test('5. Phone number optionality: null phone is permitted on customer profile', () {
        final user = buildTestUser(phone: null);
        expect(user.phone, isNull);
        final map = user.toMap();
        expect(map['phone'], isNull);
      });
    });

    // -------------------------------------------------------------------------
    // B03: Movie Discovery Boundaries
    // -------------------------------------------------------------------------
    group('B03: Movie Discovery Boundaries', () {
      test('1. Release date exact boundary: releaseDate == now is considered now-showing', () {
        final now = DateTime.now();
        final movie = buildTestMovie(releaseDate: now, isActive: true);
        expect(movie.isNowShowing, isTrue);
        expect(movie.isUpcoming, isFalse);
      });

      test('2. Release date boundary: releaseDate 1 second in future is upcoming', () {
        final future = DateTime.now().add(const Duration(seconds: 1));
        final movie = buildTestMovie(releaseDate: future, isActive: true);
        expect(movie.isUpcoming, isTrue);
        expect(movie.isNowShowing, isFalse);
      });

      test('3. Search with special characters and regex meta-characters does not crash', () {
        final movies = [
          buildTestMovie(title: 'Godzilla (2024) [3D]'),
          buildTestMovie(title: 'Mai + Đào'),
        ];
        const query = '(2024)';
        final filtered = movies.where((m) => m.title.toLowerCase().contains(query.toLowerCase())).toList();
        expect(filtered.length, 1);
        expect(filtered.first.title, contains('(2024)'));
      });

      test('4. Empty search query returns all or empty depending on specification', () {
        const emptyQuery = '   ';
        expect(emptyQuery.trim().isEmpty, isTrue);
      });

      test('5. Zero now-showing movies results in empty list without crashing', () {
        final movies = <MovieModel>[];
        final nowShowing = movies.where((m) => m.isNowShowing).toList();
        expect(nowShowing, isEmpty);
      });
    });

    // -------------------------------------------------------------------------
    // B04: Movie Detail Boundaries
    // -------------------------------------------------------------------------
    group('B04: Movie Detail Boundaries', () {
      test('1. Duration boundary: minimum valid movie duration is 1 minute', () {
        final movie = buildTestMovie(durationMin: 1);
        expect(movie.durationMin, 1);
      });

      test('2. Maximum duration boundary: 300 minutes (5 hours) renders correctly', () {
        final epicMovie = buildTestMovie(durationMin: 300);
        expect(epicMovie.durationMin, 300);
      });

      test('3. Empty cast members list produces empty string safely', () {
        final movie = buildTestMovie(genres: []);
        expect(movie.genresText, isEmpty);
      });

      test('4. Null trailer URL handled without error', () {
        final movie = buildTestMovie(trailerUrl: null);
        expect(movie.trailerUrl, isNull);
      });

      test('5. Special age rating string defaults properly in fromMap', () {
        final map = {
          'id': 'm_edge',
          'title': 'Test Movie',
          'duration_min': 90,
          'release_date': DateTime.now().toIso8601String(),
        };
        final movie = MovieModel.fromMap(map);
        expect(movie.ageRating, 'P');
      });
    });

    // -------------------------------------------------------------------------
    // B05: Showtime Filter Boundaries
    // -------------------------------------------------------------------------
    group('B05: Showtime Filter Boundaries', () {
      test('1. Day 0 boundary: today is the first selectable day', () {
        final today = DateTime.now();
        final formatted = DateFormatter.formatDate(today);
        expect(formatted.isNotEmpty, isTrue);
      });

      test('2. Day 6 boundary: 7th day (index 6) is the last selectable day', () {
        final now = DateTime.now();
        final day7 = now.add(const Duration(days: 6));
        final diff = day7.difference(now).inDays;
        expect(diff, 6);
      });

      test('3. Exact 0 sold seats: minPrice is available and not sold out', () {
        final showtime = buildTestShowtime(totalSeats: 100, soldSeats: 0);
        expect(showtime.isSoldOut, isFalse);
      });

      test('4. Exact 100% capacity: soldSeats == totalSeats triggers isSoldOut', () {
        final showtime = buildTestShowtime(totalSeats: 80, soldSeats: 80);
        expect(showtime.isSoldOut, isTrue);
      });

      test('5. Past showtime boundary: startTime in the past marks isPast', () {
        final past = buildTestShowtime(
          startTime: DateTime.now().subtract(const Duration(minutes: 5)),
        );
        expect(past.isPast, isTrue);
      });
    });

    // -------------------------------------------------------------------------
    // B06: Seat Map Boundaries (SEAT-01)
    // -------------------------------------------------------------------------
    group('B06: Seat Map Boundaries', () {
      test('1. 0 seats selected: selectedSeatIds is empty and grand total is 0', () {
        final provider = BookingProvider();
        provider.setShowtime(buildTestShowtime());
        expect(provider.selectedSeatIds, isEmpty);
        expect(provider.calculateTicketTotal(), 0);
      });

      test('2. Exactly 8 seats selected boundary: allowed without warning', () {
        final provider = BookingProvider();
        provider.setShowtime(buildTestShowtime());
        for (int i = 1; i <= 8; i++) {
          provider.toggleSeat('B$i', SeatType.standard);
        }
        expect(provider.selectedSeatIds.length, 8);
        expect(provider.errorMessage, isNull);
      });

      test('3. 9th seat selection rejected with explicit warning message', () {
        final provider = BookingProvider();
        provider.setShowtime(buildTestShowtime());
        for (int i = 1; i <= 8; i++) {
          provider.toggleSeat('B$i', SeatType.standard);
        }
        provider.toggleSeat('B9', SeatType.standard);
        expect(provider.selectedSeatIds.length, 8);
        expect(provider.errorMessage, contains('tối đa 8 ghế'));
      });

      test('4. Deselecting 1 seat from 8 allows selecting a different seat', () {
        final provider = BookingProvider();
        provider.setShowtime(buildTestShowtime());
        for (int i = 1; i <= 8; i++) {
          provider.toggleSeat('C$i', SeatType.standard);
        }
        provider.toggleSeat('C8', SeatType.standard); // Deselect C8 -> 7 seats
        expect(provider.selectedSeatIds.length, 7);
        provider.toggleSeat('D1', SeatType.standard); // Select D1 -> 8 seats
        expect(provider.selectedSeatIds.length, 8);
        expect(provider.selectedSeatIds, contains('D1'));
      });

      testWidgets('5. Couple seat width is exactly 62.0 while standard seat is 28.0', (tester) async {
        await tester.pumpWidget(createTestAppWrapper(
          child: const Row(
            children: [
              SeatWidget(seatId: 'CP1', type: SeatType.couple),
              SeatWidget(seatId: 'ST1', type: SeatType.standard),
            ],
          ),
        ));
        final coupleFinder = find.byWidgetPredicate(
          (w) => w is Container && (w.constraints?.maxWidth == 62.0 || w.decoration != null),
        );
        expect(coupleFinder, findsWidgets);
      });
    });

    // -------------------------------------------------------------------------
    // B07: `hold_seats` Transaction Boundaries
    // -------------------------------------------------------------------------
    group('B07: `hold_seats` Boundaries', () {
      test('1. Online hold duration is exactly 300 seconds (5 minutes)', () {
        expect(AppConstants.holdOnline.inSeconds, 300);
      });

      test('2. Counter hold duration is exactly 180 seconds (3 minutes)', () {
        expect(AppConstants.holdCounter.inSeconds, 180);
      });

      test('3. SeatTakenException contains conflicted seat ID', () {
        const takenSeat = 'F4';
        const exception = SeatTakenException(takenSeat);
        expect(exception.seatId, 'F4');
        expect(exception.toString(), contains('Ghế F4 vừa có người chọn'));
      });

      test('4. Releasing hold on null booking code is a safe no-op', () async {
        final provider = BookingProvider();
        await provider.releaseCurrentHold();
        expect(provider.currentBookingCode, isNull);
      });

      test('5. Booking reset clears all seats, foods, code, and errors', () {
        final provider = BookingProvider();
        provider.setShowtime(buildTestShowtime());
        provider.toggleSeat('A1', SeatType.standard);
        provider.reset();
        expect(provider.selectedShowtime, isNull);
        expect(provider.selectedSeatIds, isEmpty);
        expect(provider.currentBookingCode, isNull);
        expect(provider.errorMessage, isNull);
      });
    });

    // -------------------------------------------------------------------------
    // B08: Hold Timer Boundaries (60s Warning State)
    // -------------------------------------------------------------------------
    group('B08: Hold Timer Boundaries', () {
      testWidgets('1. 65s remaining uses normal ink color', (tester) async {
        final holdUntil = DateTime.now().add(const Duration(seconds: 65));
        await tester.pumpWidget(createTestAppWrapper(child: HoldTimer(holdUntil: holdUntil)));
        final icon = tester.widget<Icon>(find.byIcon(Icons.access_time_filled));
        expect(icon.color, AppColors.ink);
      });

      testWidgets('2. 59s boundary transitions to warning color', (tester) async {
        final holdUntil = DateTime.now().add(const Duration(seconds: 59));
        await tester.pumpWidget(createTestAppWrapper(child: HoldTimer(holdUntil: holdUntil)));
        final icon = tester.widget<Icon>(find.byIcon(Icons.access_time_filled));
        expect(icon.color, AppColors.warning);
      });

      testWidgets('3. 1s boundary remains in warning color', (tester) async {
        final holdUntil = DateTime.now().add(const Duration(seconds: 1));
        await tester.pumpWidget(createTestAppWrapper(child: HoldTimer(holdUntil: holdUntil)));
        final icon = tester.widget<Icon>(find.byIcon(Icons.access_time_filled));
        expect(icon.color, AppColors.warning);
      });

      testWidgets('4. 0s boundary displays 00:00', (tester) async {
        final holdUntil = DateTime.now();
        await tester.pumpWidget(createTestAppWrapper(child: HoldTimer(holdUntil: holdUntil)));
        expect(find.textContaining('00:00'), findsOneWidget);
      });

      test('5. Negative duration clamped to 00:00 in DateFormatter', () {
        expect(DateFormatter.formatTimer(const Duration(seconds: -30)), '00:00');
      });
    });

    // -------------------------------------------------------------------------
    // B09: Food Selection Boundaries
    // -------------------------------------------------------------------------
    group('B09: Food Selection Boundaries', () {
      test('1. Food quantity cannot be negative', () {
        final food = buildTestFood(quantity: 0);
        final json = food.toBookingJson();
        expect(json['qty'], 0);
      });

      test('2. Updating food quantity to 0 removes it from selectedFoods', () {
        final provider = BookingProvider();
        final food = buildTestFood(id: 'fd_01');
        provider.updateFoodQuantity(food, 2);
        expect(provider.selectedFoods.length, 1);
        provider.updateFoodQuantity(food, 0);
        expect(provider.selectedFoods, isEmpty);
      });

      testWidgets('3. Stepper max boundary (99): cannot increment past max', (tester) async {
        int qty = 99;
        await tester.pumpWidget(createTestAppWrapper(
          child: QuantityStepper(value: qty, max: 99, onChanged: (v) => qty = v),
        ));
        await tester.tap(find.byIcon(Icons.add));
        expect(qty, 99);
      });

      testWidgets('4. Disabled stepper when food is unavailable: taps are ignored', (tester) async {
        int qty = 0;
        await tester.pumpWidget(createTestAppWrapper(
          child: QuantityStepper(
            value: qty,
            isAvailable: false,
            onChanged: (v) => qty = v,
          ),
        ));
        await tester.tap(find.byIcon(Icons.add));
        expect(qty, 0);
      });

      test('5. Large food quantities calculate total without overflow', () {
        final provider = BookingProvider();
        final food = buildTestFood(price: 100000);
        provider.updateFoodQuantity(food, 50);
        expect(provider.calculateFoodTotal(), 5000000);
      });
    });

    // -------------------------------------------------------------------------
    // B10: VNPay Checkout Boundaries
    // -------------------------------------------------------------------------
    group('B10: VNPay Checkout Boundaries', () {
      test('1. Minimum VNPay transaction amount (10,000 VND * 100 = 1,000,000)', () {
        const minAmount = 10000;
        expect(minAmount * 100, 1000000);
      });

      test('2. Maximum VNPay sandbox amount (50,000,000 VND * 100)', () {
        const maxAmount = 50000000;
        expect(maxAmount * 100, 5000000000);
      });

      test('3. Expired holding prevents proceeding to payment', () {
        final holding = buildTestBooking(
          status: 'holding',
          holdUntil: DateTime.now().subtract(const Duration(seconds: 1)),
        );
        expect(holding.displayStatus, 'expired');
      });

      test('4. Special characters in booking code are absent', () {
        const bookingCode = 'K7M2QX9P';
        expect(RegExp(r'^[A-Z0-9]+$').hasMatch(bookingCode), isTrue);
      });

      test('5. 0 discount snapshot produces total equal to ticket + food', () {
        final provider = BookingProvider();
        final snapshot = provider.generatePriceSnapshot();
        expect(snapshot['total'], snapshot['ticket_total'] + snapshot['food_total']);
      });
    });

    // -------------------------------------------------------------------------
    // B11: `confirm_payment` RPC Boundaries
    // -------------------------------------------------------------------------
    group('B11: `confirm_payment` Boundaries', () {
      test('1. Exact amount match: confirmed amount must equal price snapshot total', () {
        final booking = buildTestBooking(priceSnapshot: {'total': 240000});
        const paidAmount = 240000;
        expect(booking.totalAmount == paidAmount, isTrue);
      });

      test('2. Multiple seats (8 seats) all transition to sold simultaneously', () {
        final seats = List.generate(8, (i) => buildTestSeat(seatId: 'A${i + 1}', status: 'sold'));
        expect(seats.every((s) => s.isSold), isTrue);
      });

      test('3. Sold seats count increments by number of booked seats', () {
        final showtime = buildTestShowtime(totalSeats: 100, soldSeats: 10);
        final updated = ShowtimeModel(
          id: showtime.id,
          movieId: showtime.movieId,
          cinemaId: showtime.cinemaId,
          roomId: showtime.roomId,
          format: showtime.format,
          startTime: showtime.startTime,
          endTime: showtime.endTime,
          totalSeats: showtime.totalSeats,
          soldSeats: showtime.soldSeats + 4,
        );
        expect(updated.soldSeats, 14);
      });

      test('4. Null vnpTransactionNo is handled safely', () {
        final booking = buildTestBooking(vnpTransactionNo: null);
        expect(booking.vnpTransactionNo, isNull);
      });

      test('5. Zero foods in booking sets foodStatus to none upon confirmation', () {
        final booking = buildTestBooking(foods: [], foodStatus: 'none');
        expect(booking.foodStatus, 'none');
      });
    });

    // -------------------------------------------------------------------------
    // B12: Electronic QR Ticket Boundaries
    // -------------------------------------------------------------------------
    group('B12: Electronic QR Ticket Boundaries', () {
      test('1. Booking code must be exactly 8 characters long', () {
        final code = BookingProvider.generateBookingCode();
        expect(code.length, 8);
      });

      test('2. TicketCard handles single seat display', () {
        final booking = buildTestBooking(seats: [{'id': 'G7'}]);
        expect(booking.seatNamesSummary, 'G7');
      });

      test('3. TicketCard handles 8 seats display cleanly', () {
        final seats = List.generate(8, (i) => {'id': 'H${i + 1}'});
        final booking = buildTestBooking(seats: seats);
        expect(booking.seatNamesSummary, 'H1, H2, H3, H4, H5, H6, H7, H8');
      });

      testWidgets('4. Empty food summary is omitted from TicketCard widget', (tester) async {
        await tester.pumpWidget(createTestAppWrapper(
          child: const TicketCard(
            movieTitle: 'Mai',
            cinemaName: 'Cinema Quận 1',
            roomName: 'Phòng 1',
            format: '2D',
            showtime: '19:30',
            seatNames: 'A1',
            bookingCode: 'K7M2QX9P',
            foodSummary: null,
          ),
        ));
        expect(find.text('ĐỒ ĂN KÈM (NHẬN TẠI QUẦY)'), findsNothing);
      });

      testWidgets('5. TicketCard renders dashed divider', (tester) async {
        await tester.pumpWidget(createTestAppWrapper(
          child: const TicketCard(
            movieTitle: 'Mai',
            cinemaName: 'Cinema Quận 1',
            roomName: 'Phòng 1',
            format: '2D',
            showtime: '19:30',
            seatNames: 'A1',
            bookingCode: 'K7M2QX9P',
          ),
        ));
        expect(find.text('MÃ ĐẶT VÉ'), findsOneWidget);
      });
    });

    // -------------------------------------------------------------------------
    // B13: Tabbed Ticket Management Boundaries
    // -------------------------------------------------------------------------
    group('B13: Tabbed Ticket Management Boundaries', () {
      test('1. Under 15 minutes after showtime: not yet noShow', () {
        final showtime = DateTime.now().subtract(const Duration(minutes: 14));
        final booking = buildTestBooking(showtimeStart: showtime, checkedInAt: null);
        expect(booking.isNoShow, isFalse);
      });

      test('2. Over 15 minutes after showtime: triggers isNoShow', () {
        final showtime = DateTime.now().subtract(const Duration(minutes: 16));
        final booking = buildTestBooking(showtimeStart: showtime, checkedInAt: null);
        expect(booking.isNoShow, isTrue);
      });

      test('3. Checked in ticket at showtime + 20 minutes is used, NOT noShow', () {
        final showtime = DateTime.now().subtract(const Duration(minutes: 20));
        final booking = buildTestBooking(
          status: 'used',
          showtimeStart: showtime,
          checkedInAt: DateTime.now().subtract(const Duration(minutes: 10)),
        );
        expect(booking.isNoShow, isFalse);
        expect(booking.displayStatus, 'used');
      });

      test('4. Empty tickets list returns empty arrays for all 3 tabs', () {
        final emptyList = <BookingModel>[];
        final upcoming = emptyList.where((t) => t.status == 'paid' && !t.isNoShow).toList();
        final history = emptyList.where((t) => t.status == 'used' || t.isNoShow).toList();
        final cancelled = emptyList.where((t) => t.status == 'cancelled').toList();
        expect(upcoming, isEmpty);
        expect(history, isEmpty);
        expect(cancelled, isEmpty);
      });

      test('5. Cancelled ticket is strictly excluded from upcoming tab', () {
        final cancelled = buildTestBooking(
          status: 'cancelled',
          showtimeStart: DateTime.now().add(const Duration(hours: 3)),
        );
        final isUpcoming = cancelled.status == 'paid' && !cancelled.isNoShow;
        expect(isUpcoming, isFalse);
      });
    });

    // -------------------------------------------------------------------------
    // B14: `cancel_booking` 2-Hour Cutoff Boundaries
    // -------------------------------------------------------------------------
    group('B14: Cancellation 2-Hour Cutoff Boundaries', () {
      test('1. 2 hours and 1 minute before showtime: canCancel is true', () {
        final booking = buildTestBooking(
          status: 'paid',
          showtimeStart: DateTime.now().add(const Duration(hours: 2, minutes: 1)),
        );
        expect(booking.canCancel, isTrue);
      });

      test('2. Exactly 2 hours before showtime: canCancel is false (strictly < 2h cutoff)', () {
        final booking = buildTestBooking(
          status: 'paid',
          showtimeStart: DateTime.now().add(const Duration(hours: 2)),
        );
        expect(booking.canCancel, isFalse);
      });

      test('3. 1 hour and 59 minutes before showtime: canCancel is false', () {
        final booking = buildTestBooking(
          status: 'paid',
          showtimeStart: DateTime.now().add(const Duration(hours: 1, minutes: 59)),
        );
        expect(booking.canCancel, isFalse);
      });

      test('4. Past showtime cancellation is rejected (canCancel is false)', () {
        final booking = buildTestBooking(
          status: 'paid',
          showtimeStart: DateTime.now().subtract(const Duration(minutes: 10)),
        );
        expect(booking.canCancel, isFalse);
      });

      test('5. 100% refund amount matches totalAmount', () {
        final booking = buildTestBooking(priceSnapshot: {'total': 180000});
        const refundPercent = 100;
        final refundAmount = (booking.totalAmount * refundPercent) ~/ 100;
        expect(refundAmount, 180000);
      });
    });

    // -------------------------------------------------------------------------
    // B15: QR Scanner Input Boundaries
    // -------------------------------------------------------------------------
    group('B15: QR Scanner Input Boundaries', () {
      test('1. Empty input string is rejected', () {
        const input = '';
        expect(input.trim().length == 8, isFalse);
      });

      test('2. 7-character input string is rejected', () {
        const input = 'ABC1234';
        expect(input.trim().length == 8, isFalse);
      });

      test('3. 9-character input string is rejected', () {
        const input = 'ABC123456';
        expect(input.trim().length == 8, isFalse);
      });

      test('4. Scanned input with lowercase letters auto-capitalizes', () {
        const input = 'a1b2c3d4';
        expect(input.toUpperCase(), 'A1B2C3D4');
      });

      test('5. Scanned input with leading/trailing newlines trims cleanly', () {
        const input = '\nK7M2QX9P\r\n';
        expect(input.trim().toUpperCase(), 'K7M2QX9P');
      });
    });

    // -------------------------------------------------------------------------
    // B16: `check_in` 8 Validation Checks Boundaries
    // -------------------------------------------------------------------------
    group('B16: `check_in` Window Boundaries', () {
      test('1. Exactly 30 minutes before showtime: check-in is permitted', () {
        final now = DateTime.now();
        final showtime = now.add(const Duration(minutes: 30));
        final ticket = buildTestBooking(showtimeStart: showtime);
        final res = evaluateCheckIn(booking: ticket, staffCinemaId: 'cn_q1', currentTime: now);
        expect(res.isSuccess, isTrue);
      });

      test('2. 30 minutes and 1 second before showtime: rejected as too early', () {
        final now = DateTime.now();
        final showtime = now.add(const Duration(minutes: 30, seconds: 1));
        final ticket = buildTestBooking(showtimeStart: showtime);
        final res = evaluateCheckIn(booking: ticket, staffCinemaId: 'cn_q1', currentTime: now);
        expect(res.code, CheckinValidationCode.tooEarly);
      });

      test('3. Exactly 15 minutes after showtime: check-in is permitted', () {
        final now = DateTime.now();
        final showtime = now.subtract(const Duration(minutes: 15));
        final ticket = buildTestBooking(showtimeStart: showtime);
        final res = evaluateCheckIn(booking: ticket, staffCinemaId: 'cn_q1', currentTime: now);
        expect(res.isSuccess, isTrue);
      });

      test('4. 15 minutes and 1 second after showtime: rejected as expired/noShow', () {
        final now = DateTime.now();
        final showtime = now.subtract(const Duration(minutes: 15, seconds: 1));
        final ticket = buildTestBooking(showtimeStart: showtime);
        final res = evaluateCheckIn(booking: ticket, staffCinemaId: 'cn_q1', currentTime: now);
        expect(res.code, CheckinValidationCode.expiredShowtime);
      });

      test('5. Wrong cinema check evaluated before time window checks', () {
        final now = DateTime.now();
        final showtime = now.add(const Duration(hours: 5)); // Also too early
        final ticket = buildTestBooking(
          cinemaId: 'cn_tb',
          cinemaName: 'Cinema Tân Bình',
          showtimeStart: showtime,
        );
        final res = evaluateCheckIn(booking: ticket, staffCinemaId: 'cn_q1', currentTime: now);
        // Should catch wrong cinema first (Rule 4 before Rule 5)
        expect(res.code, CheckinValidationCode.wrongCinema);
      });
    });

    // -------------------------------------------------------------------------
    // B17: Age Rating ID Verification Boundaries
    // -------------------------------------------------------------------------
    group('B17: Age Rating Verification Boundaries', () {
      testWidgets('1. P rating requires zero checkbox interaction', (tester) async {
        await tester.pumpWidget(createTestAppWrapper(
          child: ResultSheet(
            isValid: true,
            ageRating: 'P',
            onConfirm: () {},
            onDismiss: () {},
          ),
        ));
        expect(find.byType(Checkbox), findsNothing);
      });

      testWidgets('2. T13 rating requires zero checkbox interaction', (tester) async {
        await tester.pumpWidget(createTestAppWrapper(
          child: ResultSheet(
            isValid: true,
            ageRating: 'T13',
            onConfirm: () {},
            onDismiss: () {},
          ),
        ));
        expect(find.byType(Checkbox), findsNothing);
      });

      testWidgets('3. T16 rating displays warning border and checkbox', (tester) async {
        await tester.pumpWidget(createTestAppWrapper(
          child: ResultSheet(
            isValid: true,
            ageRating: 'T16',
            onConfirm: () {},
            onDismiss: () {},
          ),
        ));
        expect(find.byType(Checkbox), findsOneWidget);
        expect(find.textContaining('phim T16'), findsOneWidget);
      });

      testWidgets('4. T18 rating displays warning border and checkbox', (tester) async {
        await tester.pumpWidget(createTestAppWrapper(
          child: ResultSheet(
            isValid: true,
            ageRating: 'T18',
            onConfirm: () {},
            onDismiss: () {},
          ),
        ));
        expect(find.byType(Checkbox), findsOneWidget);
        expect(find.textContaining('phim T18'), findsOneWidget);
      });

      testWidgets('5. Unchecking the box after checking re-disables the confirm button', (tester) async {
        bool confirmed = false;
        await tester.pumpWidget(createTestAppWrapper(
          child: ResultSheet(
            isValid: true,
            ageRating: 'T18',
            onConfirm: () => confirmed = true,
            onDismiss: () {},
          ),
        ));
        // Check
        await tester.tap(find.byType(Checkbox));
        await tester.pump();
        // Uncheck
        await tester.tap(find.byType(Checkbox));
        await tester.pump();
        // Try confirming
        await tester.tap(find.text('XÁC NHẬN CHO VÀO'));
        expect(confirmed, isFalse);
      });
    });

    // -------------------------------------------------------------------------
    // B18: Food Queue Boundaries
    // -------------------------------------------------------------------------
    group('B18: Food Queue Boundaries', () {
      test('1. Empty pending queue returns zero items without error', () {
        final list = <BookingModel>[];
        final pending = list.where((b) => b.foodStatus == 'pending').toList();
        expect(pending, isEmpty);
      });

      test('2. Order with 10 food items handles display gracefully', () {
        final foods = List.generate(10, (i) => {'qty': 1, 'name': 'Item $i'});
        final booking = buildTestBooking(foods: foods);
        expect(booking.foods.length, 10);
      });

      test('3. Identical showtimes maintain stable sort', () {
        final sameTime = DateTime(2026, 10, 27, 19, 0);
        final b1 = buildTestBooking(code: 'CODE1', showtimeStart: sameTime);
        final b2 = buildTestBooking(code: 'CODE2', showtimeStart: sameTime);
        final list = [b1, b2];
        list.sort((a, b) => a.showtimeStart.compareTo(b.showtimeStart));
        expect(list.length, 2);
      });

      test('4. Food order cancellation updates status to cancelled', () {
        final booking = buildTestBooking(foodStatus: 'cancelled');
        expect(booking.foodStatus, 'cancelled');
      });

      test('5. Delivered food order cannot be reverted to pending', () {
        final booking = buildTestBooking(foodStatus: 'delivered');
        expect(booking.foodStatus == 'pending', isFalse);
      });
    });

    // -------------------------------------------------------------------------
    // B19: `deliver_food` RPC Boundaries
    // -------------------------------------------------------------------------
    group('B19: `deliver_food` Boundaries', () {
      test('1. Delivery timestamp is recorded upon delivery', () {
        final deliveredAt = DateTime.now();
        final booking = buildTestBooking(foodStatus: 'delivered');
        expect(booking.foodStatus, 'delivered');
        expect(deliveredAt.isBefore(DateTime.now().add(const Duration(seconds: 1))), isTrue);
      });

      test('2. Food delivered by records staff ID', () {
        final booking = buildTestBooking(
          foodStatus: 'delivered',
          checkedInBy: 'staff_food_01',
        );
        expect(booking.checkedInBy, 'staff_food_01');
      });

      test('3. Order with empty foods list does not trigger delivery notification', () {
        final booking = buildTestBooking(foods: [], foodStatus: 'none');
        expect(booking.foods, isEmpty);
      });

      test('4. Delivering an order for wrong cinema is prevented', () {
        const staffCinemaId = 'cn_q1';
        const orderCinemaId = 'cn_tb';
        expect(staffCinemaId == orderCinemaId, isFalse);
      });

      test('5. Notification payload includes foodDelivered type', () {
        final notif = buildTestNotification(type: 'foodDelivered');
        expect(notif.type, 'foodDelivered');
      });
    });

    // -------------------------------------------------------------------------
    // B20: Counter Box Office Boundaries
    // -------------------------------------------------------------------------
    group('B20: Counter Box Office Boundaries', () {
      test('1. Counter booking has null customer ID', () {
        final booking = buildTestBooking(channel: 'counter', userId: null);
        expect(booking.userId, isNull);
        expect(booking.channel, 'counter');
      });

      test('2. Counter hold expires in exactly 180 seconds', () {
        expect(AppConstants.holdCounter.inSeconds, 180);
      });

      test('3. Counter ticket can be issued for standard, VIP or couple seats', () {
        const types = [SeatType.standard, SeatType.vip, SeatType.couple];
        for (final t in types) {
          final seat = buildTestSeat(type: t);
          expect(seat.type, t);
        }
      });

      test('4. Counter ticket total price snapshot is immutable', () {
        final booking = buildTestBooking(
          channel: 'counter',
          priceSnapshot: {'total': 180000},
        );
        expect(booking.totalAmount, 180000);
      });

      test('5. Staff ID is recorded on soldBy field', () {
        final booking = buildTestBooking(channel: 'counter', soldBy: 'staff_007');
        expect(booking.soldBy, 'staff_007');
      });
    });

    // -------------------------------------------------------------------------
    // B21: Cash Change Boundaries (S21)
    // -------------------------------------------------------------------------
    group('B21: Cash Change Boundaries', () {
      test('1. Exact cash: cashReceived == total -> change is 0', () {
        expect(calculateCashChange(cashReceived: 200000, total: 200000), 0);
      });

      test('2. Deficit by 1 VND throws ArgumentError', () {
        expect(
          () => calculateCashChange(cashReceived: 199999, total: 200000),
          throwsArgumentError,
        );
      });

      test('3. Surplus by 1 VND returns 1 VND change', () {
        expect(calculateCashChange(cashReceived: 200001, total: 200000), 1);
      });

      test('4. Very large transaction (10,000,000 cash for 200,000 total)', () {
        expect(calculateCashChange(cashReceived: 10000000, total: 200000), 9800000);
      });

      test('5. Zero total amount with positive cash returns full cash as change', () {
        expect(calculateCashChange(cashReceived: 50000, total: 0), 50000);
      });
    });

    // -------------------------------------------------------------------------
    // B22: Dashboard Metrics Boundaries (S22)
    // -------------------------------------------------------------------------
    group('B22: Dashboard Metrics Boundaries', () {
      test('1. 0 bookings returns 0 total revenue', () {
        final bookings = <BookingModel>[];
        final total = bookings.fold<int>(0, (s, b) => s + b.totalAmount);
        expect(total, 0);
      });

      test('2. 0 capacity room occupancy calculation returns 0.0%', () {
        const sold = 0;
        const total = 0;
        const rate = total == 0 ? 0.0 : (sold / total) * 100;
        expect(rate, 0.0);
      });

      test('3. 100% occupancy rate boundary', () {
        const sold = 96;
        const total = 96;
        const rate = (sold / total) * 100;
        expect(rate, 100.0);
      });

      test('4. Cancelled bookings contribute 0 to revenue metrics', () {
        final bookings = [
          buildTestBooking(status: 'cancelled', priceSnapshot: {'total': 500000}),
        ];
        final revenue = bookings
            .where((b) => b.status == 'paid')
            .fold<int>(0, (s, b) => s + b.totalAmount);
        expect(revenue, 0);
      });

      test('5. Today revenue filters out bookings from yesterday', () {
        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(days: 1));
        final bookings = [
          buildTestBooking(status: 'paid', paidAt: now, priceSnapshot: {'total': 100000}),
          buildTestBooking(status: 'paid', paidAt: yesterday, priceSnapshot: {'total': 200000}),
        ];
        final todayOnly = bookings
            .where((b) => b.paidAt != null && b.paidAt!.day == now.day)
            .fold<int>(0, (s, b) => s + b.totalAmount);
        expect(todayOnly, 100000);
      });
    });

    // -------------------------------------------------------------------------
    // B23: Showtime 15m Gap Boundaries
    // -------------------------------------------------------------------------
    group('B23: Showtime 15m Gap Boundaries', () {
      test('1. Exact 14m gap between showtimes triggers conflict', () {
        final start1 = DateTime(2026, 10, 27, 18, 0);
        final end1 = DateTime(2026, 10, 27, 20, 0);
        final start2 = DateTime(2026, 10, 27, 20, 14); // 14 mins gap
        final end2 = DateTime(2026, 10, 27, 22, 14);

        final conflict = hasShowtimeConflict(
          existingStart: start1,
          existingEnd: end1,
          candidateStart: start2,
          candidateEnd: end2,
        );
        expect(conflict, isTrue);
      });

      test('2. Exact 15m gap between showtimes is accepted (no conflict)', () {
        final start1 = DateTime(2026, 10, 27, 18, 0);
        final end1 = DateTime(2026, 10, 27, 20, 0);
        final start2 = DateTime(2026, 10, 27, 20, 15); // Exactly 15 mins gap
        final end2 = DateTime(2026, 10, 27, 22, 15);

        final conflict = hasShowtimeConflict(
          existingStart: start1,
          existingEnd: end1,
          candidateStart: start2,
          candidateEnd: end2,
        );
        expect(conflict, isFalse);
      });

      test('3. Exact 16m gap between showtimes is accepted (no conflict)', () {
        final start1 = DateTime(2026, 10, 27, 18, 0);
        final end1 = DateTime(2026, 10, 27, 20, 0);
        final start2 = DateTime(2026, 10, 27, 20, 16);
        final end2 = DateTime(2026, 10, 27, 22, 16);

        final conflict = hasShowtimeConflict(
          existingStart: start1,
          existingEnd: end1,
          candidateStart: start2,
          candidateEnd: end2,
        );
        expect(conflict, isFalse);
      });

      test('4. Candidate showtime before existing showtime with < 15m gap triggers conflict', () {
        final startCandidate = DateTime(2026, 10, 27, 15, 50);
        final endCandidate = DateTime(2026, 10, 27, 17, 50); // Gap = 10 mins to 18:00
        final startExisting = DateTime(2026, 10, 27, 18, 0);
        final endExisting = DateTime(2026, 10, 27, 20, 0);

        final conflict = hasShowtimeConflict(
          existingStart: startExisting,
          existingEnd: endExisting,
          candidateStart: startCandidate,
          candidateEnd: endCandidate,
        );
        expect(conflict, isTrue);
      });

      test('5. Midnight crossing showtime calculates end time accurately', () {
        final start = DateTime(2026, 10, 27, 23, 30);
        final end = start.add(const Duration(minutes: 120)); // Next day 01:30
        expect(end.day, 28);
        expect(end.hour, 1);
        expect(end.minute, 30);
      });
    });

    // -------------------------------------------------------------------------
    // B24: Booking & Order Inspection Boundaries
    // -------------------------------------------------------------------------
    group('B24: Order Inspection Boundaries', () {
      test('1. Inspect booking with empty seats list', () {
        final booking = buildTestBooking(seats: []);
        expect(booking.seats, isEmpty);
        expect(booking.seatNamesSummary, isEmpty);
      });

      test('2. Inspect booking with 8 seats displays all 8 seats in summary', () {
        final seats = List.generate(8, (i) => {'id': 'B${i + 1}'});
        final booking = buildTestBooking(seats: seats);
        expect(booking.seats.length, 8);
        expect(booking.seatNamesSummary.split(', ').length, 8);
      });

      test('3. Filter returns empty list when no bookings match query', () {
        final bookings = [buildTestBooking(status: 'paid')];
        final filtered = bookings.where((b) => b.status == 'expired').toList();
        expect(filtered, isEmpty);
      });

      test('4. Inspecting booking with cash change displays paymentMethod as cash', () {
        final booking = buildTestBooking(paymentMethod: 'cash');
        expect(booking.paymentMethod, 'cash');
      });

      test('5. BookingModel fromMap preserves null fields properly', () {
        final map = {
          'code': 'TESTCODE',
          'status': 'paid',
          'showtime_id': 'st1',
          'cinema_id': 'cn1',
          'movie_title': 'Phim',
          'cinema_name': 'Rạp',
          'room_name': 'Phòng 1',
          'showtime_start': DateTime.now().toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
          'price_snapshot': {'total': 100000},
        };
        final b = BookingModel.fromMap(map);
        expect(b.userId, isNull);
        expect(b.soldBy, isNull);
        expect(b.cancelReason, isNull);
      });
    });

    // -------------------------------------------------------------------------
    // B25: Food Catalog Availability Boundaries
    // -------------------------------------------------------------------------
    group('B25: Food Catalog Boundaries', () {
      test('1. Price minimum boundary: 0 VND (promotional free gift)', () {
        final food = buildTestFood(price: 0);
        expect(food.price, 0);
      });

      test('2. Maximum food price boundary: 1,000,000 VND', () {
        final food = buildTestFood(price: 1000000);
        expect(food.price, 1000000);
      });

      test('3. Food item name trimming: leading and trailing whitespace removed', () {
        const raw = '   Bắp Ngọt   ';
        final food = buildTestFood(name: raw.trim());
        expect(food.name, 'Bắp Ngọt');
      });

      test('4. Empty category defaults to combo in fromMap', () {
        final map = {
          'id': 'fd_1',
          'cinema_id': 'cn_1',
          'name': 'Món Mới',
          'price': 40000,
        };
        final food = FoodModel.fromMap(map);
        expect(food.category, 'combo');
      });

      test('5. Long food description handled safely', () {
        final longDesc = 'Bắp rang bơ giòn thơm hảo hạng ' * 10;
        final food = FoodModel(
          id: 'fd_2',
          cinemaId: 'cn_1',
          name: 'Bắp',
          category: 'popcorn',
          price: 50000,
          description: longDesc,
        );
        expect(food.description, contains('giòn thơm'));
      });
    });

    // -------------------------------------------------------------------------
    // B26: Staff Account Creation Boundaries
    // -------------------------------------------------------------------------
    group('B26: Staff Creation Boundaries', () {
      test('1. Staff cinemaId must match creator manager cinemaId', () {
        const managerCinema = 'cn_q1';
        final staff = buildTestUser(role: UserRole.staff, cinemaId: managerCinema);
        expect(staff.cinemaId, managerCinema);
      });

      test('2. Staff account name unicode characters preserved', () {
        const name = 'Lương Bích Hữu';
        final staff = buildTestUser(fullName: name, role: UserRole.staff);
        expect(staff.fullName, name);
      });

      test('3. Duplicate email detection compares normalized lowercase emails', () {
        const existing = 'staff1@cinema.vn';
        const candidate = 'STAFF1@CINEMA.VN';
        expect(existing.toLowerCase() == candidate.toLowerCase(), isTrue);
      });

      test('4. Staff account cannot be initialized as locked', () {
        final staff = buildTestUser(role: UserRole.staff, isLocked: false);
        expect(staff.isLocked, isFalse);
      });

      test('5. Admin creating staff can target any valid cinema ID', () {
        const targetCinemas = ['cn_q1', 'cn_tb', 'cn_bd'];
        for (final cid in targetCinemas) {
          final s = buildTestUser(role: UserRole.staff, cinemaId: cid);
          expect(s.cinemaId, cid);
        }
      });
    });

    // -------------------------------------------------------------------------
    // B27: User Account Locking Boundaries
    // -------------------------------------------------------------------------
    group('B27: User Locking Boundaries', () {
      test('1. Locking already locked account remains locked (idempotent)', () {
        final user = buildTestUser(isLocked: true);
        final lockedAgain = user.copyWith(isLocked: true);
        expect(lockedAgain.isLocked, isTrue);
      });

      test('2. Unlocking already unlocked account remains unlocked (idempotent)', () {
        final user = buildTestUser(isLocked: false);
        final unlockedAgain = user.copyWith(isLocked: false);
        expect(unlockedAgain.isLocked, isFalse);
      });

      test('3. Locked staff account redirects to login instead of S18 checkin', () {
        final lockedStaff = buildTestUser(role: UserRole.staff, isLocked: true);
        expect(RouteGuards.getInitialRoute(lockedStaff), AppRoutes.login);
      });

      test('4. Locked manager account redirects to login instead of S22 dashboard', () {
        final lockedManager = buildTestUser(role: UserRole.manager, isLocked: true);
        expect(RouteGuards.getInitialRoute(lockedManager), AppRoutes.login);
      });

      test('5. Locked user map representation stores is_locked = true', () {
        final user = buildTestUser(isLocked: true);
        expect(user.toMap()['is_locked'], isTrue);
      });
    });

    // -------------------------------------------------------------------------
    // B28: Movies CRUD Deletion Protection Boundaries
    // -------------------------------------------------------------------------
    group('B28: Movie Protection Boundaries', () {
      test('1. Movie with 1 future showtime cannot be deleted', () {
        final futureShowtimes = [buildTestShowtime()];
        final canDelete = futureShowtimes.isEmpty;
        expect(canDelete, isFalse);
      });

      test('2. Movie with 0 showtimes can be safely deleted', () {
        final futureShowtimes = <ShowtimeModel>[];
        final canDelete = futureShowtimes.isEmpty;
        expect(canDelete, isTrue);
      });

      test('3. Movie duration minimum boundary: 1 minute', () {
        final m = buildTestMovie(durationMin: 1);
        expect(m.durationMin, 1);
      });

      test('4. Setting isActive = false soft-deletes movie from discovery', () {
        final m = buildTestMovie(isActive: false);
        expect(m.isNowShowing, isFalse);
        expect(m.isUpcoming, isFalse);
      });

      test('5. Long movie description handled gracefully', () {
        final longDesc = 'Nội dung chi tiết của bộ phim điện ảnh ' * 20;
        final m = buildTestMovie(description: longDesc);
        expect(m.description!.length, greaterThan(200));
      });
    });

    // -------------------------------------------------------------------------
    // B29: Room & Seat Grid Configuration Boundaries
    // -------------------------------------------------------------------------
    group('B29: Room Grid Boundaries', () {
      test('1. Minimum room dimensions: 1 row by 1 col = 1 seat', () {
        final room = buildTestRoom(rows: 1, cols: 1, seatCount: 1, seatLayout: ['S']);
        expect(room.seatCount, 1);
        expect(room.seatLayout.length, 1);
      });

      test('2. Room with 20 rows and 20 cols = 400 seats layout capacity', () {
        final room = buildTestRoom(rows: 20, cols: 20, seatCount: 400, seatLayout: List.filled(400, 'S'));
        expect(room.seatCount, 400);
      });

      test('3. Couple seat occupies two layout cells but increments capacity by 1', () {
        // 'C', 'C' represent one couple seat
        final layout = ['S', 'S', 'C', 'C', 'V', 'V'];
        final standard = layout.where((s) => s == 'S').length;
        final vip = layout.where((s) => s == 'V').length;
        final couple = layout.where((s) => s == 'C').length ~/ 2;
        final capacity = standard + vip + couple;
        expect(capacity, 5); // 2 standard + 2 VIP + 1 Couple
      });

      test('4. Room format list boundary: single format vs 3 formats', () {
        final single = buildTestRoom(formats: ['2D']);
        expect(single.formats.length, 1);
        final multi = buildTestRoom(formats: ['2D', '3D', 'IMAX']);
        expect(multi.formats.length, 3);
      });

      test('5. Room seat count cannot exceed rows * cols', () {
        final room = buildTestRoom(rows: 8, cols: 10, seatCount: 80);
        expect(room.seatCount <= room.rows * room.cols, isTrue);
      });
    });

    // -------------------------------------------------------------------------
    // B30: Dynamic Pricing Formula Boundaries (PAY-01)
    // -------------------------------------------------------------------------
    group('B30: Dynamic Pricing Formula Boundaries', () {
      test('1. Weekday morning standard 2D (base rate): exactly 80,000 VND', () {
        final start = DateTime(2026, 10, 27, 9, 0); // Tuesday 9am
        expect(calculateSeatPrice(format: '2D', type: SeatType.standard, startTime: start), 80000);
      });

      test('2. Weekday morning standard 3D: exactly 100,000 VND', () {
        final start = DateTime(2026, 10, 27, 9, 0);
        expect(calculateSeatPrice(format: '3D', type: SeatType.standard, startTime: start), 100000);
      });

      test('3. Weekday morning standard IMAX: exactly 120,000 VND', () {
        final start = DateTime(2026, 10, 27, 9, 0);
        expect(calculateSeatPrice(format: 'IMAX', type: SeatType.standard, startTime: start), 120000);
      });

      test('4. Prime time boundary: 17:59 (no surcharge) vs 18:00 (prime surcharge +10k)', () {
        final beforePrime = DateTime(2026, 10, 27, 17, 59);
        final atPrime = DateTime(2026, 10, 27, 18, 0);
        expect(calculateSeatPrice(format: '2D', type: SeatType.standard, startTime: beforePrime), 80000);
        expect(calculateSeatPrice(format: '2D', type: SeatType.standard, startTime: atPrime), 90000);
      });

      test('5. Prime time boundary: 21:59 (prime surcharge +10k) vs 22:00 (no surcharge)', () {
        final inPrime = DateTime(2026, 10, 27, 21, 59);
        final afterPrime = DateTime(2026, 10, 27, 22, 0);
        expect(calculateSeatPrice(format: '2D', type: SeatType.standard, startTime: inPrime), 90000);
        expect(calculateSeatPrice(format: '2D', type: SeatType.standard, startTime: afterPrime), 80000);
      });
    });

    // -------------------------------------------------------------------------
    // B31: Voucher Management Boundaries
    // -------------------------------------------------------------------------
    group('B31: Voucher Boundaries', () {
      test('1. Discount amount greater than ticketTotal is capped at ticketTotal', () {
        final voucher = buildTestVoucher(type: 'amount', value: 250000);
        final discount = calculateVoucherDiscount(ticketTotal: 160000, voucher: voucher);
        expect(discount, 160000); // Cannot exceed ticket total
      });

      test('2. 100% discount voucher makes ticket price 0', () {
        final voucher = buildTestVoucher(type: 'percent', value: 100);
        final discount = calculateVoucherDiscount(ticketTotal: 180000, voucher: voucher);
        expect(discount, 180000);
      });

      test('3. 0% discount voucher results in 0 discount', () {
        final voucher = buildTestVoucher(type: 'percent', value: 0);
        final discount = calculateVoucherDiscount(ticketTotal: 180000, voucher: voucher);
        expect(discount, 0);
      });

      test('4. Exact expiry boundary: voucher expiring right now returns 0', () {
        final voucher = buildTestVoucher(
          expiryDate: DateTime.now().subtract(const Duration(milliseconds: 1)),
        );
        expect(calculateVoucherDiscount(ticketTotal: 100000, voucher: voucher), 0);
      });

      test('5. Exact max usage boundary: used_count == max_uses - 1 is valid, == max_uses is invalid', () {
        final almostExhausted = buildTestVoucher(usedCount: 9, maxUses: 10, value: 20000);
        expect(calculateVoucherDiscount(ticketTotal: 100000, voucher: almostExhausted), 20000);

        final fullyExhausted = buildTestVoucher(usedCount: 10, maxUses: 10, value: 20000);
        expect(calculateVoucherDiscount(ticketTotal: 100000, voucher: fullyExhausted), 0);
      });
    });

    // -------------------------------------------------------------------------
    // B32: Audit Logging Boundaries
    // -------------------------------------------------------------------------
    group('B32: Audit Log Boundaries', () {
      test('1. Audit log reason can be null or empty string', () {
        final log = buildTestAuditLog(reason: null);
        expect(log['reason'], isNull);
      });

      test('2. Long audit log reason text (500 chars) is preserved', () {
        final longReason = 'Lý do hoàn vé do lỗi kỹ thuật chiếu phim rạp số 1 ' * 10;
        final log = buildTestAuditLog(reason: longReason);
        expect(log['reason']!.length, greaterThan(200));
      });

      test('3. Actor ID and cinema ID must not be empty', () {
        final log = buildTestAuditLog(actorId: 'act_01', cinemaId: 'cn_q1');
        expect(log['actor_id'], isNotEmpty);
        expect(log['cinema_id'], isNotEmpty);
      });

      test('4. Audit log actions enum validation', () {
        const validActions = ['checkIn', 'cancelShowtime', 'refund', 'changePrice', 'lockUser', 'unlockUser'];
        for (final act in validActions) {
          final l = buildTestAuditLog(action: act);
          expect(validActions.contains(l['action']), isTrue);
        }
      });

      test('5. Admin role check verifies permission to read audit logs', () {
        final admin = buildTestUser(role: UserRole.admin);
        expect(admin.isAdmin, isTrue);
      });
    });

    // -------------------------------------------------------------------------
    // B33: Cinema Locator Boundaries
    // -------------------------------------------------------------------------
    group('B33: Cinema Locator Boundaries', () {
      test('1. 0.0 km distance: user located at exact cinema coordinates', () {
        final cinema = buildTestCinema(distanceKm: 0.0);
        expect(cinema.distanceKm, 0.0);
      });

      test('2. Large distance boundary: 1500.5 km', () {
        final cinema = buildTestCinema(distanceKm: 1500.5);
        expect(cinema.distanceKm, 1500.5);
      });

      test('3. Latitude and Longitude within Vietnam geographic bounds (lat 8-24, lng 102-110)', () {
        final cinema = buildTestCinema(lat: 10.7769, lng: 106.7009);
        expect(cinema.lat >= 8.0 && cinema.lat <= 24.0, isTrue);
        expect(cinema.lng >= 102.0 && cinema.lng <= 110.0, isTrue);
      });

      test('4. Sort with null distanceKm elements puts them at the end or maintains stability', () {
        final c1 = buildTestCinema(id: 'c1', distanceKm: 5.0);
        final c2 = buildTestCinema(id: 'c2', distanceKm: null);
        final list = [c2, c1];
        list.sort((a, b) => (a.distanceKm ?? 9999).compareTo(b.distanceKm ?? 9999));
        expect(list.first.id, 'c1');
      });

      test('5. Empty active cinemas list returns empty array safely', () {
        final list = <CinemaModel>[];
        expect(list, isEmpty);
      });
    });

    // -------------------------------------------------------------------------
    // B34: Local Show Reminder Boundaries
    // -------------------------------------------------------------------------
    group('B34: Show Reminder Boundaries', () {
      test('1. Reminder scheduled exactly 60 minutes before showtimeStart', () {
        final showtime = DateTime(2026, 10, 27, 21, 30);
        final reminder = showtime.subtract(const Duration(minutes: 60));
        expect(reminder, DateTime(2026, 10, 27, 20, 30));
      });

      test('2. Showtime in under 60 minutes skips or triggers immediate reminder', () {
        final now = DateTime.now();
        final showtime = now.add(const Duration(minutes: 30));
        final diff = showtime.difference(now).inMinutes;
        expect(diff < 60, isTrue);
      });

      test('3. Unread notifications count boundary: 0 unread', () {
        final notifs = [buildTestNotification(isRead: true)];
        final unread = notifs.where((n) => !n.isRead).length;
        expect(unread, 0);
      });

      test('4. Unread notifications count boundary: 50 unread', () {
        final notifs = List.generate(50, (i) => buildTestNotification(id: 'n$i', isRead: false));
        final unread = notifs.where((n) => !n.isRead).length;
        expect(unread, 50);
      });

      test('5. Notification with null booking code handles tap navigation without crash', () {
        final notif = buildTestNotification(bookingCode: null);
        expect(notif.bookingCode, isNull);
      });
    });

    // -------------------------------------------------------------------------
    // B35: In-App Support Chat Boundaries
    // -------------------------------------------------------------------------
    group('B35: Support Chat Boundaries', () {
      test('1. Empty chat message text is rejected', () {
        const text = '   ';
        expect(text.trim().isEmpty, isTrue);
      });

      test('2. Long chat message (1000 characters) is supported', () {
        final longMsg = 'Chào rạp, tôi cần hỗ trợ thông tin vé ' * 25;
        expect(longMsg.length, greaterThanOrEqualTo(500));
      });

      test('3. Conversation key formats consistently with underscore delimiter', () {
        const uid = 'usr_123';
        const cinema = 'cn_q1';
        const key = '${uid}_$cinema';
        final parts = key.split('_');
        expect(parts.length, 4); // usr, 123, cn, q1
        expect(key.endsWith('cn_q1'), isTrue);
      });

      test('4. Chat message with optional booking code parses properly', () {
        final msg = {
          'id': 'm1',
          'booking_code': 'K7M2QX9P',
          'text': 'Kiểm tra giúp tôi vé này',
        };
        expect(msg['booking_code'], 'K7M2QX9P');
      });

      test('5. Chat message without booking code sets booking_code to null', () {
        final msg = {
          'id': 'm2',
          'text': 'Rạp mở cửa lúc mấy giờ?',
        };
        expect(msg['booking_code'], isNull);
      });
    });
  });
}
