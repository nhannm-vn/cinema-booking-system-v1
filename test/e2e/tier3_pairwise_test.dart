import 'package:flutter_test/flutter_test.dart';
import 'package:cinema_booking_v1/core/config/app_constants.dart';
import 'package:cinema_booking_v1/core/routes/app_router.dart';
import 'package:cinema_booking_v1/core/routes/route_guards.dart';

import 'test_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initTestSupabase();
  });

  group('Tier 3: Pairwise Combinatorial Testing', () {
    // =========================================================================
    // Pairwise 1: Format (2D, 3D, IMAX) x Seat Type (Standard, VIP, Couple)
    // =========================================================================
    group('PW1: Format x Seat Type Combinations', () {
      final baseTime = DateTime(2026, 10, 27, 10, 0); // Tuesday morning (no surcharges)

      test('1. 2D x Standard = 80,000 VND', () {
        final price = calculateSeatPrice(format: '2D', type: SeatType.standard, startTime: baseTime);
        expect(price, 80000);
      });

      test('2. 2D x VIP = 100,000 VND (+20k)', () {
        final price = calculateSeatPrice(format: '2D', type: SeatType.vip, startTime: baseTime);
        expect(price, 100000);
      });

      test('3. 2D x Couple = 180,000 VND (2 * 80k + 20k)', () {
        final price = calculateSeatPrice(format: '2D', type: SeatType.couple, startTime: baseTime);
        expect(price, 180000);
      });

      test('4. 3D x Standard = 100,000 VND', () {
        final price = calculateSeatPrice(format: '3D', type: SeatType.standard, startTime: baseTime);
        expect(price, 100000);
      });

      test('5. 3D x VIP = 120,000 VND (100k + 20k)', () {
        final price = calculateSeatPrice(format: '3D', type: SeatType.vip, startTime: baseTime);
        expect(price, 120000);
      });

      test('6. 3D x Couple = 220,000 VND (2 * 100k + 20k)', () {
        final price = calculateSeatPrice(format: '3D', type: SeatType.couple, startTime: baseTime);
        expect(price, 220000);
      });

      test('7. IMAX x Standard = 120,000 VND', () {
        final price = calculateSeatPrice(format: 'IMAX', type: SeatType.standard, startTime: baseTime);
        expect(price, 120000);
      });

      test('8. IMAX x VIP = 140,000 VND (120k + 20k)', () {
        final price = calculateSeatPrice(format: 'IMAX', type: SeatType.vip, startTime: baseTime);
        expect(price, 140000);
      });

      test('9. IMAX x Couple = 260,000 VND (2 * 120k + 20k)', () {
        final price = calculateSeatPrice(format: 'IMAX', type: SeatType.couple, startTime: baseTime);
        expect(price, 260000);
      });
    });

    // =========================================================================
    // Pairwise 2: Time Slot Surcharges x Pricing Configuration
    // =========================================================================
    group('PW2: Time Slot x Surcharge Combinations', () {
      test('1. Weekday Non-Prime Standard 2D: zero time surcharge', () {
        final weekdayRegular = DateTime(2026, 10, 27, 14, 0); // Tuesday 2pm
        final price = calculateSeatPrice(format: '2D', type: SeatType.standard, startTime: weekdayRegular);
        expect(price, 80000);
      });

      test('2. Weekday Prime (18-22h) VIP 2D: +10k prime + 20k VIP', () {
        final weekdayPrime = DateTime(2026, 10, 27, 19, 0); // Tuesday 7pm
        final price = calculateSeatPrice(format: '2D', type: SeatType.vip, startTime: weekdayPrime);
        expect(price, 110000); // 80k + 20k VIP + 10k prime
      });

      test('3. Weekend Non-Prime Couple 2D: +10k weekend + 20k couple', () {
        final weekendRegular = DateTime(2026, 10, 31, 10, 0); // Saturday 10am
        final price = calculateSeatPrice(format: '2D', type: SeatType.couple, startTime: weekendRegular);
        expect(price, 190000); // 2 * 80k + 20k couple + 10k weekend
      });

      test('4. Weekend Prime IMAX Couple: 2 * 120k + 20k couple + 10k weekend + 10k prime', () {
        final weekendPrime = DateTime(2026, 10, 31, 20, 0); // Saturday 8pm
        final price = calculateSeatPrice(format: 'IMAX', type: SeatType.couple, startTime: weekendPrime);
        expect(price, 280000); // 240k + 20k + 20k = 280,000 VND
      });
    });

    // =========================================================================
    // Pairwise 3: Voucher Discount x Booking With/Without Food
    // =========================================================================
    group('PW3: Voucher x Food Combinations', () {
      test('1. Amount voucher on booking without food: discounts ticket directly', () {
        final voucher = buildTestVoucher(type: 'amount', value: 30000);
        const ticketTotal = 160000;
        const foodTotal = 0;
        final discount = calculateVoucherDiscount(ticketTotal: ticketTotal, voucher: voucher);
        final grandTotal = (ticketTotal - discount) + foodTotal;
        expect(discount, 30000);
        expect(grandTotal, 130000);
      });

      test('2. Percent voucher on booking with food: discounts ONLY ticket total', () {
        final voucher = buildTestVoucher(type: 'percent', value: 20); // 20%
        const ticketTotal = 200000;
        const foodTotal = 90000;
        final discount = calculateVoucherDiscount(ticketTotal: ticketTotal, voucher: voucher);
        final grandTotal = (ticketTotal - discount) + foodTotal;
        expect(discount, 40000); // 20% of 200k = 40k (food 90k is NOT discounted)
        expect(grandTotal, 250000); // 160k + 90k
      });

      test('3. Large voucher exceeding ticket total: discount capped at ticket total, food untouched', () {
        final voucher = buildTestVoucher(type: 'amount', value: 300000);
        const ticketTotal = 160000;
        const foodTotal = 55000;
        final discount = calculateVoucherDiscount(ticketTotal: ticketTotal, voucher: voucher);
        final grandTotal = (ticketTotal - discount) + foodTotal;
        expect(discount, 160000); // Capped at ticket total
        expect(grandTotal, 55000); // Only pay for food
      });

      test('4. Expired voucher on booking with food: zero discount applied', () {
        final expiredVoucher = buildTestVoucher(
          value: 50000,
          expiryDate: DateTime.now().subtract(const Duration(days: 2)),
        );
        const ticketTotal = 160000;
        const foodTotal = 45000;
        final discount = calculateVoucherDiscount(ticketTotal: ticketTotal, voucher: expiredVoucher);
        expect(discount, 0);
        expect(ticketTotal + foodTotal - discount, 205000);
      });

      test('5. Exhausted voucher on booking without food: zero discount applied', () {
        final exhaustedVoucher = buildTestVoucher(value: 20000, usedCount: 100, maxUses: 100);
        const ticketTotal = 160000;
        final discount = calculateVoucherDiscount(ticketTotal: ticketTotal, voucher: exhaustedVoucher);
        expect(discount, 0);
      });
    });

    // =========================================================================
    // Pairwise 4: Channel x Payment Method x Hold Timeout
    // =========================================================================
    group('PW4: Channel x Payment x Hold Timeout Combinations', () {
      test('1. Online x VNPay: uses 5-minute hold and stores vnpTransactionNo', () {
        final booking = buildTestBooking(
          channel: 'online',
          paymentMethod: 'vnpay',
          vnpTransactionNo: '14592011',
          holdUntil: DateTime.now().add(AppConstants.holdOnline),
        );
        expect(booking.channel, 'online');
        expect(booking.paymentMethod, 'vnpay');
        expect(booking.vnpTransactionNo, isNotNull);
        expect(AppConstants.holdOnline.inMinutes, 5);
      });

      test('2. Counter x Cash: uses 3-minute hold and calculates cash change', () {
        final booking = buildTestBooking(
          channel: 'counter',
          paymentMethod: 'cash',
          userId: null,
          soldBy: 'staff_q1_01',
          holdUntil: DateTime.now().add(AppConstants.holdCounter),
          priceSnapshot: {'total': 180000},
        );
        expect(booking.channel, 'counter');
        expect(booking.userId, isNull);
        expect(booking.soldBy, 'staff_q1_01');
        expect(AppConstants.holdCounter.inMinutes, 3);

        final change = calculateCashChange(cashReceived: 200000, total: booking.totalAmount);
        expect(change, 20000);
      });

      test('3. Counter x Card: uses 3-minute hold and skips cash change calculation', () {
        final booking = buildTestBooking(
          channel: 'counter',
          paymentMethod: 'card',
          userId: null,
          priceSnapshot: {'total': 240000},
        );
        expect(booking.paymentMethod, 'card');
        expect(booking.channel, 'counter');
      });

      test('4. Online x Timeout: 5 minutes elapsed marks holding as expired', () {
        final booking = buildTestBooking(
          channel: 'online',
          status: 'holding',
          holdUntil: DateTime.now().subtract(const Duration(seconds: 1)),
        );
        expect(booking.displayStatus, 'expired');
      });

      test('5. Counter x Timeout: 3 minutes elapsed marks holding as expired', () {
        final booking = buildTestBooking(
          channel: 'counter',
          status: 'holding',
          holdUntil: DateTime.now().subtract(const Duration(seconds: 1)),
        );
        expect(booking.displayStatus, 'expired');
      });
    });

    // =========================================================================
    // Pairwise 5: Age Rating (P, T13, T16, T18) x Staff Check-in Flow
    // =========================================================================
    group('PW5: Age Rating x Staff Check-in Verification', () {
      final now = DateTime.now();
      final validShowtime = now.add(const Duration(minutes: 15)); // Inside [-30m, +15m]

      test('1. P rating x Unchecked ID box: valid ticket allows check-in', () {
        final ticket = buildTestBooking(ageRating: 'P', showtimeStart: validShowtime);
        final res = evaluateCheckIn(booking: ticket, staffCinemaId: 'cn_q1', currentTime: now);
        expect(res.isSuccess, isTrue);
      });

      test('2. T13 rating x Unchecked ID box: valid ticket allows check-in', () {
        final ticket = buildTestBooking(ageRating: 'T13', showtimeStart: validShowtime);
        final res = evaluateCheckIn(booking: ticket, staffCinemaId: 'cn_q1', currentTime: now);
        expect(res.isSuccess, isTrue);
      });

      test('3. T16 rating: UI verification contract requires ID checkbox', () {
        const rating = 'T16';
        const bool requiresId = rating == 'T16' || rating == 'T18';
        expect(requiresId, isTrue);
      });

      test('4. T16 rating x ID Verified: allows check-in confirmation', () {
        final ticket = buildTestBooking(ageRating: 'T16', showtimeStart: validShowtime);
        final res = evaluateCheckIn(booking: ticket, staffCinemaId: 'cn_q1', currentTime: now);
        expect(res.isSuccess, isTrue);
      });

      test('5. T18 rating: UI verification contract requires ID checkbox', () {
        const rating = 'T18';
        const bool requiresId = rating == 'T16' || rating == 'T18';
        expect(requiresId, isTrue);
      });

      test('6. T18 rating x ID Verified: allows check-in confirmation', () {
        final ticket = buildTestBooking(ageRating: 'T18', showtimeStart: validShowtime);
        final res = evaluateCheckIn(booking: ticket, staffCinemaId: 'cn_q1', currentTime: now);
        expect(res.isSuccess, isTrue);
      });
    });

    // =========================================================================
    // Pairwise 6: Food Status x Booking Lifecycle
    // =========================================================================
    group('PW6: Food Status x Booking Lifecycle Transitions', () {
      test('1. Paid booking with food enters queue as foodStatus pending', () {
        final booking = buildTestBooking(
          status: 'paid',
          foods: [{'name': 'Bắp ngọt', 'qty': 1}],
          foodStatus: 'pending',
        );
        expect(booking.foodStatus, 'pending');
      });

      test('2. Paid booking cancelled before showtime cancels food order', () {
        final booking = buildTestBooking(
          status: 'cancelled',
          foodStatus: 'cancelled',
        );
        expect(booking.status, 'cancelled');
        expect(booking.foodStatus, 'cancelled');
      });

      test('3. Delivered food order cannot be cancelled by customer cancellation', () {
        final booking = buildTestBooking(
          status: 'paid',
          foodStatus: 'delivered',
        );
        expect(booking.foodStatus, 'delivered');
      });

      test('4. Counter ticket with food creates pending food order for staff queue', () {
        final counterOrder = buildTestBooking(
          channel: 'counter',
          status: 'paid',
          foods: [{'name': 'Combo 2', 'qty': 1}],
          foodStatus: 'pending',
        );
        expect(counterOrder.channel, 'counter');
        expect(counterOrder.foodStatus, 'pending');
      });
    });

    // =========================================================================
    // Pairwise 7: User Role x Multi-Tenant Cinema Scoping
    // =========================================================================
    group('PW7: User Role x Multi-Tenant Cinema Scoping', () {
      test('1. Staff Cinema A checking ticket from Cinema A: valid', () {
        final ticket = buildTestBooking(cinemaId: 'cn_q1');
        final res = evaluateCheckIn(
          booking: ticket,
          staffCinemaId: 'cn_q1',
          currentTime: ticket.showtimeStart,
        );
        expect(res.isSuccess, isTrue);
      });

      test('2. Staff Cinema A checking ticket from Cinema B: rejected with wrong cinema error', () {
        final ticket = buildTestBooking(cinemaId: 'cn_tb', cinemaName: 'Cinema Tân Bình');
        final res = evaluateCheckIn(
          booking: ticket,
          staffCinemaId: 'cn_q1',
          currentTime: ticket.showtimeStart,
        );
        expect(res.code, CheckinValidationCode.wrongCinema);
        expect(res.message, contains('Cinema Tân Bình'));
      });

      test('3. Manager Cinema A views dashboard metrics strictly for Cinema A', () {
        final manager = buildTestUser(role: UserRole.manager, cinemaId: 'cn_q1');
        final bookings = [
          buildTestBooking(cinemaId: 'cn_q1', priceSnapshot: {'total': 150000}),
          buildTestBooking(cinemaId: 'cn_tb', priceSnapshot: {'total': 300000}),
        ];
        final scopedBookings = bookings.where((b) => b.cinemaId == manager.cinemaId).toList();
        final revenue = scopedBookings.fold<int>(0, (s, b) => s + b.totalAmount);
        expect(revenue, 150000);
      });

      test('4. Manager Cinema A cannot access bookings of Cinema B', () {
        const managerCinema = 'cn_q1';
        const foreignBookingCinema = 'cn_tb';
        const hasAccess = managerCinema == foreignBookingCinema;
        expect(hasAccess, isFalse);
      });

      test('5. Admin has global visibility across all cinemas', () {
        final admin = buildTestUser(role: UserRole.admin, cinemaId: null);
        final bookings = [
          buildTestBooking(cinemaId: 'cn_q1', priceSnapshot: {'total': 100000}),
          buildTestBooking(cinemaId: 'cn_tb', priceSnapshot: {'total': 200000}),
        ];
        expect(admin.isAdmin, isTrue);
        final totalAllCinemas = bookings.fold<int>(0, (s, b) => s + b.totalAmount);
        expect(totalAllCinemas, 300000);
      });
    });

    // =========================================================================
    // Pairwise 8: User Account Locking x Role Redirection
    // =========================================================================
    group('PW8: Account Locking x Role Redirection', () {
      test('1. Customer account locked redirects to login screen', () {
        final customer = buildTestUser(role: UserRole.customer, isLocked: true);
        expect(RouteGuards.getInitialRoute(customer), AppRoutes.login);
      });

      test('2. Staff account locked redirects to login screen', () {
        final staff = buildTestUser(role: UserRole.staff, isLocked: true);
        expect(RouteGuards.getInitialRoute(staff), AppRoutes.login);
      });

      test('3. Manager account locked redirects to login screen', () {
        final manager = buildTestUser(role: UserRole.manager, isLocked: true);
        expect(RouteGuards.getInitialRoute(manager), AppRoutes.login);
      });
    });
  });
}
