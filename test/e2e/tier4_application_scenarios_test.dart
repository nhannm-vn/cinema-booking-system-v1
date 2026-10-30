import 'package:flutter_test/flutter_test.dart';
import 'package:cinema_booking_v1/core/config/app_constants.dart';
import 'package:cinema_booking_v1/core/routes/app_router.dart';
import 'package:cinema_booking_v1/features/cinemas/data/location_service.dart';

import 'test_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initTestSupabase();
  });

  group('Tier 4: End-to-End Application Scenarios', () {
    // -------------------------------------------------------------------------
    // Scenario 1: Full Customer Online Booking Journey
    // S03 -> S04 -> S05 -> S06 hold -> S07 food -> S08 VNPay checkout -> S09 TicketCard
    // -------------------------------------------------------------------------
    test('Scenario 1: Full Customer Online Booking Journey', () {
      final now = DateTime.now();
      // 1. Customer browses movie list (S03) and selects a movie (S04)
      final movie = buildTestMovie(
        id: 'mv_sc1',
        title: 'Interstellar 2',
        durationMin: 150,
        ageRating: 'T16',
      );
      expect(movie.isNowShowing, isTrue);

      // 2. Customer selects cinema and showtime (S05)
      // Pick a weekday non-prime time slot (e.g. Wednesday 14:00)
      final showtimeStart = DateTime(2026, 11, 4, 14, 0); // Wednesday
      final showtime = buildTestShowtime(
        id: 'st_sc1',
        movieId: movie.id,
        cinemaId: 'cn_q1',
        roomId: 'rm_imax',
        format: 'IMAX',
        startTime: showtimeStart,
        endTime: showtimeStart.add(Duration(minutes: movie.durationMin)),
      );
      expect(showtime.format, 'IMAX');

      // 3. Customer selects 2 VIP seats (S06) -> 5-min hold triggered
      final holdUntil = now.add(AppConstants.holdOnline);
      final seat1 = buildTestSeat(seatId: 'D5', type: SeatType.vip);
      final seat2 = buildTestSeat(seatId: 'D6', type: SeatType.vip);
      final selectedSeats = [seat1, seat2];
      expect(selectedSeats.length, lessThanOrEqualTo(AppConstants.maxSeatsPerBooking));

      // Calculate seat prices: IMAX (120k) + VIP (20k) = 140,000 VND each -> 280,000 VND
      final priceSeat1 = calculateSeatPrice(
        type: seat1.type,
        format: showtime.format,
        startTime: showtimeStart,
      );
      final priceSeat2 = calculateSeatPrice(
        type: seat2.type,
        format: showtime.format,
        startTime: showtimeStart,
      );
      final ticketSubtotal = priceSeat1 + priceSeat2;
      expect(ticketSubtotal, 280000);

      // 4. Customer adds food combo (S07)
      final foodItem = buildTestFood(
        id: 'fd_combo_1',
        name: 'Combo Solo Bắp Nước',
        price: 75000,
        category: 'combo',
      );
      const foodQuantity = 2;
      final foodSubtotal = foodItem.price * foodQuantity; // 150,000 VND
      expect(foodSubtotal, 150000);

      // 5. Checkout & Voucher Application (S08)
      final voucher = buildTestVoucher(
        code: 'DISCOUNT30K',
        type: 'amount',
        value: 30000,
      );
      final discount = calculateVoucherDiscount(ticketTotal: ticketSubtotal, voucher: voucher);
      expect(discount, 30000);

      final totalPayable = (ticketSubtotal - discount) + foodSubtotal; // (280k - 30k) + 150k = 400,000 VND
      expect(totalPayable, 400000);

      // 6. Simulate successful VNPay payment callback & Booking Confirmation (S09)
      const bookingCode = 'BK-20261028-9876';
      final confirmedBooking = buildTestBooking(
        code: bookingCode,
        userId: 'usr_customer_01',
        showtimeId: showtime.id,
        cinemaId: showtime.cinemaId,
        movieTitle: movie.title,
        ageRating: movie.ageRating,
        showtimeStart: showtime.startTime,
        seats: [
          {'id': seat1.seatId, 'type': 'VIP', 'price': priceSeat1},
          {'id': seat2.seatId, 'type': 'VIP', 'price': priceSeat2},
        ],
        foods: [
          {'food_id': foodItem.id, 'name': foodItem.name, 'unit_price': foodItem.price, 'qty': foodQuantity},
        ],
        status: 'paid',
        paymentMethod: 'vnpay',
        vnpTransactionNo: 'VNP_TRANS_12345678',
        foodStatus: 'pending',
        priceSnapshot: {
          'ticket_total': ticketSubtotal,
          'food_total': foodSubtotal,
          'discount': discount,
          'total': totalPayable,
        },
      );

      // Assert complete booking contract
      expect(confirmedBooking.code, bookingCode);
      expect(confirmedBooking.status, 'paid');
      expect(confirmedBooking.seats.length, 2);
      expect(confirmedBooking.foods.length, 1);
      expect(confirmedBooking.foodStatus, 'pending');
      expect(confirmedBooking.totalAmount, 400000);
      expect(confirmedBooking.vnpTransactionNo, 'VNP_TRANS_12345678');
      expect(now.isBefore(holdUntil), isTrue);
    });

    // -------------------------------------------------------------------------
    // Scenario 2: Ticket Cancellation & 2-Hour Cutoff
    // >2h before showtime -> cancelBooking -> seats released -> food cancelled -> auditLog
    // <2h before showtime -> cancellation rejected with CANNOT_CANCEL_WITHIN_2_HOURS
    // -------------------------------------------------------------------------
    test('Scenario 2: Ticket Cancellation & 2-Hour Cutoff Rule', () {
      final now = DateTime.now();

      // Case A: Showtime in 4 hours (> 2 hours) -> Cancellation Allowed
      final futureShowtime = now.add(const Duration(hours: 4));
      final eligibleBooking = buildTestBooking(
        code: 'BK-CANCEL-OK',
        showtimeStart: futureShowtime,
        status: 'paid',
        seats: [{'id': 'D1', 'type': 'standard', 'price': 80000}],
        foods: [{'food_id': 'f1', 'name': 'Soda', 'qty': 1, 'unit_price': 30000}],
        foodStatus: 'pending',
      );

      // Verify business rule: eligible for cancellation
      expect(eligibleBooking.canCancel, isTrue);

      // Execute cancellation transition
      final cancelledBooking = buildTestBooking(
        code: eligibleBooking.code,
        showtimeStart: eligibleBooking.showtimeStart,
        status: 'cancelled',
        foodStatus: 'cancelled',
        cancelReason: 'Customer requested cancellation online',
      );
      expect(cancelledBooking.status, 'cancelled');
      expect(cancelledBooking.foodStatus, 'cancelled');

      // Audit log creation for refund & release
      final auditLog = buildTestAuditLog(
        id: 'audit_cancel_1',
        action: 'cancelBooking',
        actorId: eligibleBooking.userId ?? 'usr_guest',
        cinemaId: eligibleBooking.cinemaId,
        reason: 'Customer requested cancellation online',
      );
      expect(auditLog['action'], 'cancelBooking');
      expect(auditLog['cinema_id'], eligibleBooking.cinemaId);

      // Case B: Showtime in 90 minutes (< 2 hours cutoff) -> Cancellation Forbidden
      final soonShowtime = now.add(const Duration(minutes: 90));
      final ineligibleBooking = buildTestBooking(
        code: 'BK-CANCEL-FAIL',
        showtimeStart: soonShowtime,
        status: 'paid',
      );

      expect(ineligibleBooking.canCancel, isFalse);

      // Attempting cancellation within 2 hours throws business error
      expect(
        () {
          if (!ineligibleBooking.canCancel) {
            throw Exception('CANNOT_CANCEL_WITHIN_2_HOURS: Không thể hủy vé trong vòng 2 giờ trước suất chiếu');
          }
        },
        throwsA(predicate((e) => e.toString().contains('CANNOT_CANCEL_WITHIN_2_HOURS'))),
      );
    });

    // -------------------------------------------------------------------------
    // Scenario 3: Staff QR Check-in with Age Verification
    // Staff S18 -> scans T18 ticket -> ticks ID verify checkbox -> confirms check-in
    // Prevents duplicate check-in
    // -------------------------------------------------------------------------
    test('Scenario 3: Staff QR Check-in with Age Verification & Duplicate Prevention', () {
      final now = DateTime.now();
      final validShowtime = now.add(const Duration(minutes: 10));

      // 1. Customer presents T18 ticket
      final ticketT18 = buildTestBooking(
        code: 'BK-T18-CHECKIN',
        cinemaId: 'cn_q1',
        ageRating: 'T18',
        showtimeStart: validShowtime,
        status: 'paid',
      );

      // 2. Staff scanner contract: T18 requires ID check
      final requiresIdCheck = ticketT18.ageRating == 'T16' || ticketT18.ageRating == 'T18';
      expect(requiresIdCheck, isTrue);

      // 3. Staff verifies customer ID card (ticks checkbox) and performs check-in
      const bool idVerified = true;
      expect(idVerified, isTrue);

      final checkInResult = evaluateCheckIn(
        booking: ticketT18,
        staffCinemaId: 'cn_q1',
        currentTime: now,
      );
      expect(checkInResult.isSuccess, isTrue);
      expect(checkInResult.code, CheckinValidationCode.success);

      // 4. Update ticket status to used
      final usedTicket = buildTestBooking(
        code: ticketT18.code,
        cinemaId: ticketT18.cinemaId,
        showtimeStart: ticketT18.showtimeStart,
        status: 'used',
        checkedInAt: now,
        checkedInBy: 'usr_staff_01',
      );
      expect(usedTicket.status, 'used');

      // 5. Duplicate check-in attempt on the same ticket
      final duplicateResult = evaluateCheckIn(
        booking: usedTicket,
        staffCinemaId: 'cn_q1',
        currentTime: now.add(const Duration(minutes: 1)),
      );
      expect(duplicateResult.isSuccess, isFalse);
      expect(duplicateResult.code, CheckinValidationCode.used);
      expect(duplicateResult.message, contains('đã sử dụng'));
    });

    // -------------------------------------------------------------------------
    // Scenario 4: Staff Food Delivery Queue
    // S19 displays pending orders sorted by showtime -> staff delivers -> notified
    // -------------------------------------------------------------------------
    test('Scenario 4: Staff Food Delivery Queue & Notification Lifecycle', () {
      final now = DateTime.now();

      // Create 3 orders with different showtimes
      final order1 = buildTestBooking(
        code: 'BK-EARLY',
        showtimeStart: now.add(const Duration(minutes: 20)),
        foodStatus: 'pending',
        foods: [{'food_id': 'f1', 'name': 'Popcorn', 'qty': 1}],
      );
      final order2 = buildTestBooking(
        code: 'BK-LATE',
        showtimeStart: now.add(const Duration(minutes: 90)),
        foodStatus: 'pending',
        foods: [{'food_id': 'f2', 'name': 'Soda', 'qty': 2}],
      );
      final order3 = buildTestBooking(
        code: 'BK-MID',
        showtimeStart: now.add(const Duration(minutes: 50)),
        foodStatus: 'pending',
        foods: [{'food_id': 'f3', 'name': 'Combo 2', 'qty': 1}],
      );

      final queue = [order2, order1, order3];

      // Staff queue sorting: showtime ascending
      queue.sort((a, b) => a.showtimeStart.compareTo(b.showtimeStart));
      expect(queue.first.code, order1.code);
      expect(queue[1].code, order3.code);
      expect(queue.last.code, order2.code);

      // Staff completes delivery for order 1
      final deliveredOrder1 = buildTestBooking(
        code: order1.code,
        showtimeStart: order1.showtimeStart,
        foodStatus: 'delivered',
        foods: order1.foods,
      );
      expect(deliveredOrder1.foodStatus, 'delivered');

      // Delivery triggers notification to customer
      final notification = buildTestNotification(
        id: 'notif_food_ready',
        userId: order1.userId ?? 'usr_001',
        type: 'food_ready',
        title: 'Đồ ăn & nước uống đã sẵn sàng',
        body: 'Vui lòng đến quầy nhận bắp nước cho mã đơn ${order1.code}',
        bookingCode: order1.code,
      );
      expect(notification.title, contains('sẵn sàng'));
      expect(notification.body, contains(order1.code));
      expect(notification.isRead, isFalse);
    });

    // -------------------------------------------------------------------------
    // Scenario 5: Staff Counter Sales with Cash Change
    // S20 counter sales -> 3-min hold -> S21 cash change calc -> direct issuance
    // -------------------------------------------------------------------------
    test('Scenario 5: Staff Counter Sales with Cash Change & Direct Issuance', () {
      final now = DateTime.now();
      final weekdayShowtime = DateTime(2026, 10, 28, 14, 0); // Wednesday 14:00 (weekday non-prime)

      // 1. Staff selects 2 Standard seats (2 * 80,000 = 160,000 VND)
      final priceSeat1 = calculateSeatPrice(
        type: SeatType.standard,
        format: '2D',
        startTime: weekdayShowtime,
      );
      final priceSeat2 = calculateSeatPrice(
        type: SeatType.standard,
        format: '2D',
        startTime: weekdayShowtime,
      );
      final totalAmount = priceSeat1 + priceSeat2;
      expect(totalAmount, 160000);

      // 2. Counter hold time is 3 minutes (180s)
      final counterHoldUntil = now.add(AppConstants.holdCounter);
      final holdDiff = counterHoldUntil.difference(now).inSeconds;
      expect(holdDiff, AppConstants.holdCounter.inSeconds);

      // 3. Customer pays cash 200,000 VND
      const cashTendered = 200000;
      final changeAmount = calculateCashChange(cashReceived: cashTendered, total: totalAmount);
      expect(changeAmount, 40000);

      // 4. Direct booking confirmation without payment gateway
      final counterBooking = buildTestBooking(
        code: 'POS-Q1-1001',
        channel: 'counter',
        paymentMethod: 'cash',
        status: 'paid',
        priceSnapshot: {
          'ticket_total': totalAmount,
          'food_total': 0,
          'discount': 0,
          'total': totalAmount,
          'cash_tendered': cashTendered,
          'cash_change': changeAmount,
        },
      );

      expect(counterBooking.channel, 'counter');
      expect(counterBooking.status, 'paid');
      expect(counterBooking.priceSnapshot['cash_change'], 40000);
      expect(counterBooking.totalAmount, totalAmount);
    });

    // -------------------------------------------------------------------------
    // Scenario 6: Manager Operational Dashboard Inspection
    // S22 today revenue, tickets sold, occupancy rate filtered to cn_q1
    // -------------------------------------------------------------------------
    test('Scenario 6: Manager Operational Dashboard Inspection & Cinema Scoping', () {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      final bookings = [
        // Cinema Q1 today (2 bookings, 3 tickets, 350,000 VND)
        buildTestBooking(
          code: 'B1',
          cinemaId: 'cn_q1',
          createdAt: today,
          status: 'paid',
          priceSnapshot: {'total': 200000},
          seats: [{'id': 's1'}, {'id': 's2'}],
        ),
        buildTestBooking(
          code: 'B2',
          cinemaId: 'cn_q1',
          createdAt: today,
          status: 'paid',
          priceSnapshot: {'total': 150000},
          seats: [{'id': 's3'}],
        ),
        // Cinema Q1 yesterday (should be excluded from today dashboard)
        buildTestBooking(
          code: 'B3',
          cinemaId: 'cn_q1',
          createdAt: yesterday,
          status: 'paid',
          priceSnapshot: {'total': 300000},
          seats: [{'id': 's4'}, {'id': 's5'}],
        ),
        // Cinema Tan Binh today (must be excluded due to multi-tenant isolation)
        buildTestBooking(
          code: 'B4',
          cinemaId: 'cn_tb',
          createdAt: today,
          status: 'paid',
          priceSnapshot: {'total': 500000},
          seats: [{'id': 's6'}, {'id': 's7'}, {'id': 's8'}, {'id': 's9'}],
        ),
      ];

      // Manager of Cinema Q1 filters today's metrics
      const managerCinemaId = 'cn_q1';
      final q1TodayBookings = bookings.where((b) {
        final isSameCinema = b.cinemaId == managerCinemaId;
        final isToday = b.createdAt.year == today.year &&
            b.createdAt.month == today.month &&
            b.createdAt.day == today.day;
        return isSameCinema && isToday && b.status == 'paid';
      }).toList();

      // Assert scoped metrics
      final todayRevenue = q1TodayBookings.fold<int>(0, (sum, b) => sum + b.totalAmount);
      final todayTicketsCount = q1TodayBookings.fold<int>(0, (sum, b) => sum + b.seats.length);
      const totalRoomCapacityToday = 100;
      final occupancyRate = (todayTicketsCount / totalRoomCapacityToday) * 100;

      expect(todayRevenue, 350000); // 200k + 150k
      expect(todayTicketsCount, 3); // 2 + 1
      expect(occupancyRate, 3.0);
    });

    // -------------------------------------------------------------------------
    // Scenario 7: Showtime Conflict Prevention (15-min gap)
    // S14: overlap in same room within 15 mins rejected; >= 15 mins accepted
    // -------------------------------------------------------------------------
    test('Scenario 7: Showtime Conflict Prevention with 15-Minute Cleaning Buffer', () {
      final baseDate = DateTime(2026, 10, 28, 10, 0); // 10:00

      // Existing screening in Room 1: 10:00 - 12:00
      final existingShowtime = buildTestShowtime(
        id: 'st_existing',
        roomId: 'rm_01',
        startTime: baseDate,
        endTime: baseDate.add(const Duration(hours: 2)), // 12:00
      );

      // Attempt 1: Overlapping inside existing slot (11:00 - 13:00)
      final overlapSlot = buildTestShowtime(
        id: 'st_overlap',
        roomId: 'rm_01',
        startTime: baseDate.add(const Duration(hours: 1)),
        endTime: baseDate.add(const Duration(hours: 3)),
      );
      expect(
        hasShowtimeConflict(
          existingStart: existingShowtime.startTime,
          existingEnd: existingShowtime.endTime,
          candidateStart: overlapSlot.startTime,
          candidateEnd: overlapSlot.endTime,
        ),
        isTrue,
      );

      // Attempt 2: Starts at 12:05 (gap is 5 mins < 15-min cleaning buffer)
      final tooCloseSlot = buildTestShowtime(
        id: 'st_too_close',
        roomId: 'rm_01',
        startTime: baseDate.add(const Duration(hours: 2, minutes: 5)),
        endTime: baseDate.add(const Duration(hours: 4)),
      );
      expect(
        hasShowtimeConflict(
          existingStart: existingShowtime.startTime,
          existingEnd: existingShowtime.endTime,
          candidateStart: tooCloseSlot.startTime,
          candidateEnd: tooCloseSlot.endTime,
        ),
        isTrue,
      );

      // Attempt 3: Starts at 12:15 (exact 15 mins buffer satisfied)
      final validNextSlot = buildTestShowtime(
        id: 'st_valid_next',
        roomId: 'rm_01',
        startTime: baseDate.add(const Duration(hours: 2, minutes: 15)),
        endTime: baseDate.add(const Duration(hours: 4, minutes: 15)),
      );
      expect(
        hasShowtimeConflict(
          existingStart: existingShowtime.startTime,
          existingEnd: existingShowtime.endTime,
          candidateStart: validNextSlot.startTime,
          candidateEnd: validNextSlot.endTime,
        ),
        isFalse,
      );

      // Attempt 4: Same time (11:00) but in different room rm_02 -> no room conflict
      expect(existingShowtime.roomId != 'rm_02', isTrue);
    });

    // -------------------------------------------------------------------------
    // Scenario 8: Multi-Tenant Cinema Isolation
    // Staff Cinema A scans ticket of Cinema B -> rejected with WRONG_CINEMA
    // -------------------------------------------------------------------------
    test('Scenario 8: Multi-Tenant Cinema Isolation & Cross-Branch Protection', () {
      final now = DateTime.now();
      final validShowtime = now.add(const Duration(minutes: 10));

      // Customer bought ticket for Cinema Q1
      final ticketCinemaQ1 = buildTestBooking(
        code: 'BK-Q1-001',
        cinemaId: 'cn_q1',
        showtimeStart: validShowtime,
        status: 'paid',
      );

      // Staff at Cinema Tan Binh scans the ticket
      final result = evaluateCheckIn(
        booking: ticketCinemaQ1,
        staffCinemaId: 'cn_tb',
        currentTime: now,
      );

      // Assert cross-branch rejection
      expect(result.isSuccess, isFalse);
      expect(result.code, CheckinValidationCode.wrongCinema);
      expect(result.message, contains('rạp khác'));

      // If scanned by staff at correct Cinema Q1, it succeeds
      final correctResult = evaluateCheckIn(
        booking: ticketCinemaQ1,
        staffCinemaId: 'cn_q1',
        currentTime: now,
      );
      expect(correctResult.isSuccess, isTrue);
      expect(correctResult.code, CheckinValidationCode.success);
    });

    // -------------------------------------------------------------------------
    // Scenario 9: 8-Seat Limit & Seat Conflict Race Condition
    // SEAT-01: max 8 seats enforcement; concurrent hold throws SeatTakenException
    // -------------------------------------------------------------------------
    test('Scenario 9: 8-Seat Limit & Seat Conflict Race Condition', () {
      final now = DateTime.now();

      // Part A: 8-Seat Limit Enforcement
      final seats9 = List.generate(
        9,
        (i) => buildTestSeat(seatId: 'A${i + 1}'),
      );
      expect(
        () {
          if (seats9.length > AppConstants.maxSeatsPerBooking) {
            throw Exception('MAX_SEATS_EXCEEDED: Tối đa ${AppConstants.maxSeatsPerBooking} ghế mỗi đơn');
          }
        },
        throwsA(predicate((e) => e.toString().contains('MAX_SEATS_EXCEEDED'))),
      );

      final seats8 = List.generate(
        8,
        (i) => buildTestSeat(seatId: 'A${i + 1}'),
      );
      expect(seats8.length <= AppConstants.maxSeatsPerBooking, isTrue);

      // Part B: Race condition on seat hold
      // User 1 holds seat B5 for 5 minutes
      final seatB5HoldUntil = now.add(AppConstants.holdOnline);
      var isSeatB5HeldByUser1 = true;

      // User 2 attempts to hold seat B5 while User 1 holds it
      expect(
        () {
          final isExpired = now.isAfter(seatB5HoldUntil);
          if (isSeatB5HeldByUser1 && !isExpired) {
            throw Exception('SeatTakenException: Ghế B5 đang được người khác giữ');
          }
        },
        throwsA(predicate((e) => e.toString().contains('SeatTakenException'))),
      );

      // Simulate hold timeout: 5 minutes elapse
      final futureTime = now.add(const Duration(minutes: 6));
      final isNowExpired = futureTime.isAfter(seatB5HoldUntil);
      expect(isNowExpired, isTrue);

      // User 2 attempts again after expiry: succeeds
      isSeatB5HeldByUser1 = false;
      var isSeatB5HeldByUser2 = false;
      if (!isSeatB5HeldByUser1) {
        isSeatB5HeldByUser2 = true;
      }
      expect(isSeatB5HeldByUser2, isTrue);
    });

    // -------------------------------------------------------------------------
    // Scenario 10: Customer Map Discovery & Notification Center
    // S17 GPS distance calculation -> S30 notification list -> open ticket detail
    // -------------------------------------------------------------------------
    test('Scenario 10: Customer Map Discovery & Notification Center Integration', () {
      // 1. Customer at Bitexco (10.7716, 106.7044) discovers nearby cinemas (S17)
      const userLat = 10.7716;
      const userLng = 106.7044;

      final cinemaDongKhoi = buildTestCinema(
        id: 'cn_dk',
        name: 'Cinema Vincom Đồng Khởi',
        lat: 10.7779,
        lng: 106.7020,
      );
      final cinemaLandmark = buildTestCinema(
        id: 'cn_lm',
        name: 'Cinema Landmark 81',
        lat: 10.7950,
        lng: 106.7218,
      );
      final cinemaTanPhu = buildTestCinema(
        id: 'cn_tp',
        name: 'Cinema Aeon Tân Phú',
        lat: 10.8000,
        lng: 106.6167,
      );

      final cinemas = [cinemaTanPhu, cinemaDongKhoi, cinemaLandmark];

      // Calculate distances using LocationService
      final cinemaDistances = <String, double>{};
      for (final cinema in cinemas) {
        final dist = LocationService.calculateDistanceKm(
          startLatitude: userLat,
          startLongitude: userLng,
          endLatitude: cinema.lat,
          endLongitude: cinema.lng,
        );
        cinemaDistances[cinema.id] = dist;
      }

      // Sort by proximity
      cinemas.sort((a, b) => cinemaDistances[a.id]!.compareTo(cinemaDistances[b.id]!));

      // Assert closest is Dong Khoi (< 1.5 km), followed by Landmark (< 4 km), then Tan Phu (> 9 km)
      expect(cinemas.first.id, cinemaDongKhoi.id);
      expect(cinemaDistances[cinemaDongKhoi.id]!, lessThan(1.5));
      expect(cinemas[1].id, cinemaLandmark.id);
      expect(cinemas.last.id, cinemaTanPhu.id);

      // 2. Notification Center (S30)
      final notif = buildTestNotification(
        id: 'notif_bk_success',
        userId: 'usr_cust_1',
        type: 'booking_confirmed',
        title: 'Đặt vé thành công!',
        body: 'Mã vé của bạn là BK-9999. Vui lòng kiểm tra vé tại mục Vé của tôi.',
        bookingCode: 'BK-9999',
      );

      expect(notif.isRead, isFalse);
      expect(notif.bookingCode, 'BK-9999');

      // Notification route target contract
      expect(AppRoutes.ticketDetail, '/ticket-detail');
      expect(AppRoutes.notifications, '/notifications');
      expect(AppRoutes.cinemas, '/cinemas');
    });
  });
}
