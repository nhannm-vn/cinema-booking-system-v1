import 'package:flutter_test/flutter_test.dart';
import 'package:cinema_booking_v1/features/management/data/models/dashboard_metrics_model.dart';
import 'package:cinema_booking_v1/features/management/data/repositories/management_repository.dart';
import 'package:cinema_booking_v1/features/management/presentation/controllers/management_provider.dart';
import 'package:cinema_booking_v1/features/booking/data/models/booking_model.dart';
import 'package:cinema_booking_v1/shared/models/app_user.dart';

class FakeManagementRepository extends ManagementRepository {
  DashboardMetricsModel? cannedMetrics;
  List<AppUser> cannedEmployees = [];
  List<BookingModel> cannedBookings = [];
  bool shouldThrowMetrics = false;
  bool shouldThrowShowtimeConflict = false;
  bool shouldThrowCancelShowtime = false;
  bool shouldThrowCreateStaff = false;
  bool shouldThrowBookings = false;

  FakeManagementRepository() : super(null);

  @override
  Future<DashboardMetricsModel> getDashboardMetrics(String cinemaId, {String period = 'today'}) async {
    if (shouldThrowMetrics) {
      throw Exception('DATABASE_ERROR: connection refused');
    }
    return cannedMetrics ??
        const DashboardMetricsModel(
          cinemaId: 'cn_q1',
          period: 'today',
          todayRevenue: 0,
          todayTickets: 0,
          occupancyRate: 0.0,
          totalCapacity: 0,
          soldCapacity: 0,
          upcomingShowtimes: [],
        );
  }

  @override
  Future<void> createShowtime({
    required String movieId,
    required String cinemaId,
    required String roomId,
    required String format,
    required DateTime startTime,
    required DateTime endTime,
    required int totalSeats,
  }) async {
    if (shouldThrowShowtimeConflict) {
      throw Exception('SHOWTIME_CONFLICT: Trùng với suất chiếu khác');
    }
  }

  @override
  Future<Map<String, dynamic>> cancelShowtime(String showtimeId, String reason) async {
    if (shouldThrowCancelShowtime) {
      throw Exception('SHOWTIME_ALREADY_STARTED');
    }
    return {'success': true, 'showtime_id': showtimeId};
  }

  @override
  Future<void> toggleFoodAvailability(String foodId, bool isAvailable) async {}

  @override
  Future<Map<String, dynamic>> createStaff({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
    required String cinemaId,
  }) async {
    if (shouldThrowCreateStaff) {
      throw Exception('EMAIL_ALREADY_EXISTS');
    }
    return {'success': true, 'email': email};
  }

  @override
  Future<void> toggleUserLock(String userId, bool isLocked) async {}

  @override
  Future<List<AppUser>> getEmployees(String cinemaId) async {
    return cannedEmployees;
  }

  @override
  Future<List<BookingModel>> getBookings(String cinemaId, {String? status, String? channel}) async {
    if (shouldThrowBookings) {
      throw Exception('FAILED_FETCH_BOOKINGS');
    }
    return cannedBookings;
  }
}

void main() {
  group('DashboardMetricsModel - Empirical Edge & Boundary Tests', () {
    test('Handles 0 revenue, 0 tickets, 0.0 occupancy, 0 capacities, empty showtimes', () {
      final json = {
        'cinema_id': 'cn_q1',
        'period': 'today',
        'today_revenue': 0,
        'today_tickets': 0,
        'occupancy_rate': 0.0,
        'total_capacity': 0,
        'sold_capacity': 0,
        'upcoming_showtimes': <dynamic>[],
      };

      final metrics = DashboardMetricsModel.fromMap(json);

      expect(metrics.cinemaId, 'cn_q1');
      expect(metrics.period, 'today');
      expect(metrics.todayRevenue, 0);
      expect(metrics.todayTickets, 0);
      expect(metrics.occupancyRate, 0.0);
      expect(metrics.totalCapacity, 0);
      expect(metrics.soldCapacity, 0);
      expect(metrics.upcomingShowtimes, isEmpty);
    });

    test('Handles numeric double types for integer fields gracefully', () {
      final json = {
        'cinema_id': 'cn_tb',
        'period': 'week',
        'today_revenue': 12500000.0, // double representation from num
        'today_tickets': 150.0,
        'occupancy_rate': 85.75,
        'total_capacity': 200.0,
        'sold_capacity': 171.0,
        'upcoming_showtimes': null,
      };

      final metrics = DashboardMetricsModel.fromMap(json);

      expect(metrics.cinemaId, 'cn_tb');
      expect(metrics.period, 'week');
      expect(metrics.todayRevenue, 12500000);
      expect(metrics.todayTickets, 150);
      expect(metrics.occupancyRate, 85.75);
      expect(metrics.totalCapacity, 200);
      expect(metrics.soldCapacity, 171);
      expect(metrics.upcomingShowtimes, isEmpty);
    });

    test('UpcomingShowtimeItem parses valid item and applies default values', () {
      final itemMap = {
        'id': 'st-item-01',
        'movie_title': 'Dune 2',
        'room_name': 'Room IMAX',
        'format': 'IMAX',
        'start_time': '2026-10-28T14:30:00Z',
        'total_seats': 80,
        'sold_seats': 20,
      };

      final item = UpcomingShowtimeItem.fromMap(itemMap);
      expect(item.id, 'st-item-01');
      expect(item.movieTitle, 'Dune 2');
      expect(item.roomName, 'Room IMAX');
      expect(item.format, 'IMAX');
      expect(item.startTime.isUtc, isFalse); // converted to local
      expect(item.totalSeats, 80);
      expect(item.soldSeats, 20);
    });

    test('UpcomingShowtimeItem handles optional/missing format, movie_title, room_name', () {
      final itemMap = {
        'id': 'st-item-02',
        'movie_title': null,
        'room_name': null,
        'format': null,
        'start_time': '2026-10-28T20:00:00Z',
        'total_seats': 0,
        'sold_seats': 0,
      };

      final item = UpcomingShowtimeItem.fromMap(itemMap);
      expect(item.id, 'st-item-02');
      expect(item.movieTitle, '');
      expect(item.roomName, '');
      expect(item.format, '2D');
      expect(item.totalSeats, 0);
      expect(item.soldSeats, 0);
    });
  });

  group('ManagementProvider - Empirical Edge & State Harness', () {
    late FakeManagementRepository fakeRepo;
    late ManagementProvider provider;

    setUp(() {
      fakeRepo = FakeManagementRepository();
      provider = ManagementProvider(fakeRepo);
    });

    test('loadDashboardMetrics successfully parses and exposes edge-case zero metrics', () async {
      fakeRepo.cannedMetrics = const DashboardMetricsModel(
        cinemaId: 'cn_bth',
        period: 'today',
        todayRevenue: 0,
        todayTickets: 0,
        occupancyRate: 0.0,
        totalCapacity: 0,
        soldCapacity: 0,
        upcomingShowtimes: [],
      );

      await provider.loadDashboardMetrics('cn_bth');

      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
      expect(provider.metrics, isNotNull);
      expect(provider.metrics!.cinemaId, 'cn_bth');
      expect(provider.metrics!.todayRevenue, 0);
      expect(provider.metrics!.todayTickets, 0);
      expect(provider.metrics!.occupancyRate, 0.0);
      expect(provider.metrics!.upcomingShowtimes, isEmpty);
    });

    test('loadDashboardMetrics captures error message on repository failure', () async {
      fakeRepo.shouldThrowMetrics = true;

      await provider.loadDashboardMetrics('cn_q1');

      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, contains('Không thể tải số liệu Dashboard'));
      expect(provider.metrics, isNull);
    });

    test('createShowtime handles SHOWTIME_CONFLICT error and sets specific message', () async {
      fakeRepo.shouldThrowShowtimeConflict = true;

      final result = await provider.createShowtime(
        movieId: 'mov-01',
        cinemaId: 'cn_q1',
        roomId: 'room-01',
        format: '2D',
        startTime: DateTime.now().add(const Duration(hours: 1)),
        endTime: DateTime.now().add(const Duration(hours: 3)),
        totalSeats: 100,
      );

      expect(result, isFalse);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, contains('SHOWTIME_CONFLICT'));
    });

    test('createShowtime succeeds and sets successMessage', () async {
      final result = await provider.createShowtime(
        movieId: 'mov-02',
        cinemaId: 'cn_q1',
        roomId: 'room-02',
        format: '3D',
        startTime: DateTime.now().add(const Duration(hours: 4)),
        endTime: DateTime.now().add(const Duration(hours: 6)),
        totalSeats: 80,
      );

      expect(result, isTrue);
      expect(provider.isLoading, isFalse);
      expect(provider.successMessage, 'Tạo suất chiếu thành công');
      expect(provider.errorMessage, isNull);
    });

    test('cancelShowtime handles failure and success messages correctly', () async {
      fakeRepo.shouldThrowCancelShowtime = true;

      final failResult = await provider.cancelShowtime('st-01', 'Bảo trì máy chiếu');
      expect(failResult, isFalse);
      expect(provider.errorMessage, contains('Hủy suất chiếu thất bại'));

      fakeRepo.shouldThrowCancelShowtime = false;
      final okResult = await provider.cancelShowtime('st-01', 'Lỗi kỹ thuật');
      expect(okResult, isTrue);
      expect(provider.successMessage, 'Hủy suất chiếu thành công');
    });

    test('createStaffAccount handles failure and success messages', () async {
      fakeRepo.shouldThrowCreateStaff = true;
      final failResult = await provider.createStaffAccount(
        email: 'staff_dup@cinema.vn',
        password: 'password123',
        fullName: 'Staff Duplicate',
        phone: '0901112233',
        role: 'staff',
        cinemaId: 'cn_q1',
      );
      expect(failResult, isFalse);
      expect(provider.errorMessage, contains('Tạo nhân viên thất bại'));

      fakeRepo.shouldThrowCreateStaff = false;
      final okResult = await provider.createStaffAccount(
        email: 'staff_new@cinema.vn',
        password: 'password123',
        fullName: 'Staff New',
        phone: '0901112233',
        role: 'staff',
        cinemaId: 'cn_q1',
      );
      expect(okResult, isTrue);
      expect(provider.successMessage, 'Tạo nhân viên thành công');
    });

    test('loadBookings handles empty list and failure states', () async {
      fakeRepo.cannedBookings = [];
      await provider.loadBookings('cn_q1');
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
      expect(provider.bookings, isEmpty);

      fakeRepo.shouldThrowBookings = true;
      await provider.loadBookings('cn_q1');
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, contains('Không thể tải danh sách đơn vé'));
    });
  });
}
