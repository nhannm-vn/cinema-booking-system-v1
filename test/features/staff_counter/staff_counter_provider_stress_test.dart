import 'package:flutter_test/flutter_test.dart';
import 'package:cinema_booking_v1/features/booking/data/models/showtime_model.dart';
import 'package:cinema_booking_v1/features/staff_counter/presentation/controllers/staff_counter_provider.dart';
import 'package:cinema_booking_v1/features/staff_counter/data/repositories/staff_counter_repository.dart';

class FakeStaffCounterRepository extends StaffCounterRepository {
  bool shouldThrowHold = false;
  bool shouldThrowSell = false;
  DateTime? cannedHoldUntil;
  Map<String, dynamic>? lastBookingPayload;
  String? lastPaymentMethod;

  FakeStaffCounterRepository() : super(null);

  @override
  Future<List<ShowtimeModel>> getCounterShowtimes(String cinemaId, DateTime date) async {
    return [];
  }

  @override
  Future<DateTime> holdCounterSeats({
    required String showtimeId,
    required String bookingCode,
    required List<String> seatIds,
    required Map<String, dynamic> booking,
  }) async {
    if (shouldThrowHold) {
      throw Exception('SEAT_TAKEN: ${seatIds.first}');
    }
    lastBookingPayload = booking;
    return cannedHoldUntil ?? DateTime.now().add(const Duration(minutes: 3));
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
      throw Exception('PAYMENT_FAILED');
    }
    lastPaymentMethod = paymentMethod;
    lastBookingPayload = booking;
  }
}

ShowtimeModel _createDummyShowtime({int minPrice = 90000}) {
  return ShowtimeModel(
    id: 'st-stress-01',
    movieId: 'mov-01',
    cinemaId: 'cn_q1',
    roomId: 'room-01',
    format: '2D',
    startTime: DateTime.now().add(const Duration(hours: 1)),
    endTime: DateTime.now().add(const Duration(hours: 3)),
    totalSeats: 100,
    minPrice: minPrice,
    movieTitle: 'Dune: Part Two',
    cinemaName: 'CGV Vincom Đồng Khởi',
    roomName: 'Cinema 1',
  );
}

void main() {
  group('StaffCounterProvider - Empirical Stress & Boundary Harness', () {
    late FakeStaffCounterRepository fakeRepo;
    late StaffCounterProvider provider;

    setUp(() {
      fakeRepo = FakeStaffCounterRepository();
      provider = StaffCounterProvider(fakeRepo);
    });

    test('Boundary: Selecting 1..8 seats succeeds, 9th seat is rejected with error', () {
      final showtime = _createDummyShowtime(minPrice: 85000);
      provider.selectShowtime(showtime);

      // Select 8 seats successively
      for (int i = 1; i <= 8; i++) {
        final seatId = 'A$i';
        final result = provider.toggleSeat(seatId);
        expect(result, isTrue, reason: 'Selecting seat $seatId should succeed');
        expect(provider.selectedSeatIds.length, i);
      }
      expect(provider.selectedSeatIds.length, 8);
      expect(provider.errorMessage, isNull);

      // Attempt 9th seat
      final seat9Result = provider.toggleSeat('A9');
      expect(seat9Result, isFalse, reason: 'Selecting 9th seat must fail');
      expect(provider.selectedSeatIds.length, 8);
      expect(provider.errorMessage, contains('tối đa 8 ghế'));

      // Attempt 10th seat
      final seat10Result = provider.toggleSeat('B1');
      expect(seat10Result, isFalse, reason: 'Selecting 10th seat must fail');
      expect(provider.selectedSeatIds.length, 8);

      // Deselect 1 seat (A4)
      final deselectResult = provider.toggleSeat('A4');
      expect(deselectResult, isTrue, reason: 'Deselecting already selected seat must succeed');
      expect(provider.selectedSeatIds.length, 7);
      expect(provider.selectedSeatIds.contains('A4'), isFalse);

      // Now 8th seat can be filled with B1
      final reselectResult = provider.toggleSeat('B1');
      expect(reselectResult, isTrue);
      expect(provider.selectedSeatIds.length, 8);
      expect(provider.selectedSeatIds.contains('B1'), isTrue);

      // Attempting another seat now fails again
      expect(provider.toggleSeat('B2'), isFalse);
      expect(provider.selectedSeatIds.length, 8);
    });

    test('Stress: Rapid toggling and duplicate seat IDs maintain strictly max 8 seats', () {
      final showtime = _createDummyShowtime();
      provider.selectShowtime(showtime);

      final candidateSeats = List.generate(25, (i) => 'S${i + 1}');

      // Random-like deterministic sequence of seat toggles
      for (final seat in candidateSeats) {
        provider.toggleSeat(seat);
        expect(provider.selectedSeatIds.length, lessThanOrEqualTo(8));
      }

      expect(provider.selectedSeatIds.length, 8);

      // Toggle first 4 off
      for (int i = 0; i < 4; i++) {
        final seat = candidateSeats[i];
        expect(provider.selectedSeatIds.contains(seat), isTrue);
        provider.toggleSeat(seat);
        expect(provider.selectedSeatIds.contains(seat), isFalse);
      }
      expect(provider.selectedSeatIds.length, 4);

      // Toggle next 4 in
      for (int i = 8; i < 12; i++) {
        final seat = candidateSeats[i];
        final added = provider.toggleSeat(seat);
        expect(added, isTrue);
      }
      expect(provider.selectedSeatIds.length, 8);
    });

    test('Integer VND Cash Change: underpayment, exact payment, overpayment', () {
      final showtime = _createDummyShowtime(minPrice: 100000);
      provider.selectShowtime(showtime);

      provider.toggleSeat('C1');
      provider.toggleSeat('C2'); // 2 seats * 100,000 = 200,000 VND
      provider.setFoodQuantity('f-01', 'Combo Popcorn', 75000, 2); // 150,000 VND
      provider.setFoodQuantity('f-02', 'Nước Ngọt', 30000, 1); // 30,000 VND

      // Total = 200,000 + 150,000 + 30,000 = 380,000 VND
      final total = provider.calculateTotal();
      expect(total, 380000);

      // Case 1: Underpayment (given < total) -> change is 0, checkout disabled condition
      final underChange1 = provider.calculateChange(300000);
      expect(underChange1, 0);
      expect(provider.receivedCash, 300000);
      expect(provider.receivedCash < provider.calculateTotal(), isTrue,
          reason: 'Checkout should be disabled when received cash is less than total');

      final underChange2 = provider.calculateChange(0);
      expect(underChange2, 0);
      expect(provider.receivedCash, 0);
      expect(provider.receivedCash < provider.calculateTotal(), isTrue);

      final underChangeNegative = provider.calculateChange(-50000);
      expect(underChangeNegative, 0);
      expect(provider.receivedCash < provider.calculateTotal(), isTrue);

      // Case 2: Exact payment (given == total) -> change is 0, checkout enabled
      final exactChange = provider.calculateChange(380000);
      expect(exactChange, 0);
      expect(provider.receivedCash, 380000);
      expect(provider.receivedCash >= provider.calculateTotal(), isTrue,
          reason: 'Checkout should be enabled when received cash equals total');

      // Case 3: Overpayment (given > total) -> exact integer change returned, checkout enabled
      final overChange = provider.calculateChange(500000);
      expect(overChange, 120000, reason: '500,000 - 380,000 = 120,000 VND exact change');
      expect(provider.receivedCash, 500000);
      expect(provider.receivedCash >= provider.calculateTotal(), isTrue);

      // Case 4: Large VND amount (VIP counter booking, 64-bit integer integrity)
      final largeOverChange = provider.calculateChange(10000000); // 10,000,000 VND
      expect(largeOverChange, 9620000);
    });

    test('Food cart updates and price calculations correctly update total', () {
      final showtime = _createDummyShowtime(minPrice: 80000);
      provider.selectShowtime(showtime);
      provider.toggleSeat('D1'); // 80,000

      expect(provider.calculateTotal(), 80000);

      // Add food item
      provider.setFoodQuantity('f-01', 'Bắp Rang Bơ', 50000, 2); // +100,000
      expect(provider.calculateTotal(), 180000);

      // Update food item qty to 3
      provider.setFoodQuantity('f-01', 'Bắp Rang Bơ', 50000, 3); // +150,000
      expect(provider.calculateTotal(), 230000);

      // Remove food item by setting qty to 0
      provider.setFoodQuantity('f-01', 'Bắp Rang Bơ', 50000, 0);
      expect(provider.calculateTotal(), 80000);
      expect(provider.selectedFoods, isEmpty);
    });

    test('Hold seats and complete sale workflow with mock repository', () async {
      final showtime = _createDummyShowtime(minPrice: 100000);
      provider.selectShowtime(showtime);
      provider.toggleSeat('E1');

      // Hold seats
      final holdOk = await provider.holdSeatsForCounter();
      expect(holdOk, isTrue);
      expect(provider.bookingCode, isNotNull);
      expect(provider.bookingCode!.length, 8);
      expect(provider.holdUntil, isNotNull);
      expect(fakeRepo.lastBookingPayload, isNotNull);
      expect(fakeRepo.lastBookingPayload!['price_snapshot']['total'], 100000);

      // Complete sale with cash
      provider.calculateChange(100000);
      final saleOk = await provider.completeSale('cash');
      expect(saleOk, isTrue);
      expect(fakeRepo.lastPaymentMethod, 'cash');

      // Verify reset clears everything
      provider.reset();
      expect(provider.selectedShowtime, isNull);
      expect(provider.selectedSeatIds, isEmpty);
      expect(provider.selectedFoods, isEmpty);
      expect(provider.bookingCode, isNull);
      expect(provider.holdUntil, isNull);
      expect(provider.receivedCash, 0);
      expect(provider.errorMessage, isNull);
    });

    test('Hold seats fails gracefully when repository throws (e.g. SEAT_TAKEN)', () async {
      fakeRepo.shouldThrowHold = true;
      final showtime = _createDummyShowtime();
      provider.selectShowtime(showtime);
      provider.toggleSeat('F1');

      final holdOk = await provider.holdSeatsForCounter();
      expect(holdOk, isFalse);
      expect(provider.errorMessage, contains('Giữ ghế không thành công'));
      expect(provider.isLoading, isFalse);
    });

    test('Complete sale fails gracefully when repository throws', () async {
      final showtime = _createDummyShowtime();
      provider.selectShowtime(showtime);
      provider.toggleSeat('F1');
      await provider.holdSeatsForCounter();

      fakeRepo.shouldThrowSell = true;
      final saleOk = await provider.completeSale('card');
      expect(saleOk, isFalse);
      expect(provider.errorMessage, contains('Xuất vé tại quầy thất bại'));
      expect(provider.isLoading, isFalse);
    });
  });
}
