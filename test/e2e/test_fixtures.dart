import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cinema_booking_v1/core/config/app_constants.dart';
import 'package:cinema_booking_v1/core/theme/app_theme.dart';
import 'package:cinema_booking_v1/features/auth/presentation/controllers/auth_provider.dart';
import 'package:cinema_booking_v1/features/booking/data/models/booking_model.dart';
import 'package:cinema_booking_v1/features/booking/data/models/food_model.dart';
import 'package:cinema_booking_v1/features/booking/data/models/room_model.dart';
import 'package:cinema_booking_v1/features/booking/data/models/seat_model.dart';
import 'package:cinema_booking_v1/features/booking/data/models/showtime_model.dart';
import 'package:cinema_booking_v1/features/booking/presentation/controllers/booking_provider.dart';
import 'package:cinema_booking_v1/features/cinemas/data/cinema_model.dart';
import 'package:cinema_booking_v1/features/cinemas/presentation/controllers/cinema_provider.dart';
import 'package:cinema_booking_v1/features/movies/data/movie_model.dart';
import 'package:cinema_booking_v1/features/movies/presentation/controllers/movie_provider.dart';
import 'package:cinema_booking_v1/features/notifications/data/notification_repository.dart';
import 'package:cinema_booking_v1/features/tickets/presentation/controllers/ticket_provider.dart';
import 'package:cinema_booking_v1/shared/models/app_user.dart';
import 'package:cinema_booking_v1/shared/widgets/seat_widget.dart';

export 'package:cinema_booking_v1/features/booking/data/models/booking_model.dart';
export 'package:cinema_booking_v1/features/booking/data/models/food_model.dart';
export 'package:cinema_booking_v1/features/booking/data/models/room_model.dart';
export 'package:cinema_booking_v1/features/booking/data/models/seat_model.dart';
export 'package:cinema_booking_v1/features/booking/data/models/showtime_model.dart';
export 'package:cinema_booking_v1/features/cinemas/data/cinema_model.dart';
export 'package:cinema_booking_v1/features/movies/data/movie_model.dart';
export 'package:cinema_booking_v1/features/notifications/data/notification_repository.dart';
export 'package:cinema_booking_v1/shared/models/api_response.dart';
export 'package:cinema_booking_v1/shared/models/app_user.dart';
export 'package:cinema_booking_v1/shared/widgets/seat_widget.dart';

/// Test fixtures and oracle simulators for opaque-box E2E testing.
/// Authoritative specifications: BUSINESS_RULES.md, TECH_STACK.md, ROLE_FLOWS.md.

// ==========================================
// 1. DATA BUILDERS
// ==========================================

AppUser buildTestUser({
  String id = 'usr_001',
  String email = 'khach1@cinema.vn',
  String fullName = 'Nguyễn Văn Khách',
  String? phone = '0901234567',
  UserRole role = UserRole.customer,
  String? cinemaId,
  bool isLocked = false,
}) {
  return AppUser(
    id: id,
    email: email,
    fullName: fullName,
    phone: phone,
    role: role,
    cinemaId: cinemaId,
    isLocked: isLocked,
  );
}

MovieModel buildTestMovie({
  String id = 'mov_001',
  String title = 'Mai',
  List<String> genres = const ['Tâm lý', 'Hài'],
  int durationMin = 131,
  String ageRating = 'T18',
  DateTime? releaseDate,
  bool isActive = true,
  String? trailerUrl = 'https://youtube.com/watch?v=sample',
  String? description = 'Bộ phim điện ảnh về số phận người phụ nữ tên Mai.',
  String? director,
}) {
  return MovieModel(
    id: id,
    title: title,
    genres: genres,
    durationMin: durationMin,
    ageRating: ageRating,
    releaseDate: releaseDate ?? DateTime.now().subtract(const Duration(days: 7)),
    isActive: isActive,
    trailerUrl: trailerUrl,
    description: description,
    director: director,
  );
}

CinemaModel buildTestCinema({
  String id = 'cn_q1',
  String name = 'Cinema Quận 1',
  String address = '123 Nguyễn Du, Bến Nghé, Quận 1, TP.HCM',
  String phone = '02812345678',
  double lat = 10.7769,
  double lng = 106.7009,
  bool isActive = true,
  double? distanceKm,
}) {
  return CinemaModel(
    id: id,
    name: name,
    address: address,
    phone: phone,
    lat: lat,
    lng: lng,
    isActive: isActive,
    distanceKm: distanceKm,
  );
}

RoomModel buildTestRoom({
  String id = 'rm_q1_01',
  String cinemaId = 'cn_q1',
  String name = 'Phòng 1 (IMAX Laser)',
  List<String> formats = const ['2D', '3D', 'IMAX'],
  int rows = 8,
  int cols = 12,
  List<String>? seatLayout,
  int seatCount = 96,
}) {
  return RoomModel(
    id: id,
    cinemaId: cinemaId,
    name: name,
    formats: formats,
    rows: rows,
    cols: cols,
    seatLayout: seatLayout ?? List.filled(96, 'S'),
    seatCount: seatCount,
  );
}

ShowtimeModel buildTestShowtime({
  String id = 'st_001',
  String movieId = 'mov_001',
  String cinemaId = 'cn_q1',
  String roomId = 'rm_q1_01',
  String format = '2D',
  DateTime? startTime,
  DateTime? endTime,
  int totalSeats = 96,
  int soldSeats = 0,
  int minPrice = 80000,
  String status = 'active',
  String? cancelReason,
  String movieTitle = 'Mai',
  String cinemaName = 'Cinema Quận 1',
  String roomName = 'Phòng 1 (IMAX Laser)',
}) {
  final start = startTime ?? DateTime.now().add(const Duration(hours: 3));
  final end = endTime ?? start.add(const Duration(minutes: 131));
  return ShowtimeModel(
    id: id,
    movieId: movieId,
    cinemaId: cinemaId,
    roomId: roomId,
    format: format,
    startTime: start,
    endTime: end,
    totalSeats: totalSeats,
    soldSeats: soldSeats,
    minPrice: minPrice,
    status: status,
    cancelReason: cancelReason,
    movieTitle: movieTitle,
    cinemaName: cinemaName,
    roomName: roomName,
  );
}

FoodModel buildTestFood({
  String id = 'fd_001',
  String cinemaId = 'cn_q1',
  String name = 'Bắp Phô Mai Vừa',
  String category = 'popcorn',
  int price = 45000,
  bool isAvailable = true,
  int quantity = 0,
}) {
  return FoodModel(
    id: id,
    cinemaId: cinemaId,
    name: name,
    category: category,
    price: price,
    isAvailable: isAvailable,
    quantity: quantity,
  );
}

SeatModel buildTestSeat({
  String showtimeId = 'st_001',
  String seatId = 'A5',
  SeatType type = SeatType.standard,
  String status = 'available',
  String? bookingCode,
  DateTime? holdUntil,
  int price = 80000,
}) {
  return SeatModel(
    showtimeId: showtimeId,
    seatId: seatId,
    type: type,
    status: status,
    bookingCode: bookingCode,
    holdUntil: holdUntil,
    price: price,
  );
}

BookingModel buildTestBooking({
  String code = 'K7M2QX9P',
  String? userId = 'usr_001',
  String channel = 'online',
  String? soldBy,
  String status = 'paid',
  DateTime? holdUntil,
  String showtimeId = 'st_001',
  String cinemaId = 'cn_q1',
  String movieTitle = 'Mai',
  String? posterUrl,
  String ageRating = 'T18',
  String cinemaName = 'Cinema Quận 1',
  String roomName = 'Phòng 1 (IMAX Laser)',
  String format = '2D',
  DateTime? showtimeStart,
  List<Map<String, dynamic>>? seats,
  List<Map<String, dynamic>>? foods,
  String foodStatus = 'pending',
  Map<String, dynamic>? priceSnapshot,
  String paymentMethod = 'vnpay',
  String? vnpTransactionNo = '14523984',
  DateTime? paidAt,
  String? checkedInBy,
  DateTime? checkedInAt,
  String? cancelReason,
  DateTime? createdAt,
}) {
  final start = showtimeStart ?? DateTime.now().add(const Duration(hours: 4));
  final defaultSeats = seats ?? [
    {'id': 'A5', 'type': 'standard', 'price': 80000},
    {'id': 'A6', 'type': 'standard', 'price': 80000},
  ];
  final defaultFoods = foods ?? [
    {'food_id': 'fd_001', 'name': 'Bắp Phô Mai Vừa', 'qty': 1, 'unit_price': 45000},
  ];
  final defaultPriceSnapshot = priceSnapshot ?? {
    'ticket_total': 160000,
    'food_total': 45000,
    'discount': 0,
    'total': 205000,
  };

  return BookingModel(
    code: code,
    userId: userId,
    channel: channel,
    soldBy: soldBy,
    status: status,
    holdUntil: holdUntil,
    showtimeId: showtimeId,
    cinemaId: cinemaId,
    movieTitle: movieTitle,
    posterUrl: posterUrl,
    ageRating: ageRating,
    cinemaName: cinemaName,
    roomName: roomName,
    format: format,
    showtimeStart: start,
    seats: defaultSeats,
    foods: defaultFoods,
    foodStatus: foodStatus,
    priceSnapshot: defaultPriceSnapshot,
    paymentMethod: paymentMethod,
    vnpTransactionNo: vnpTransactionNo,
    paidAt: paidAt ?? DateTime.now(),
    checkedInBy: checkedInBy,
    checkedInAt: checkedInAt,
    cancelReason: cancelReason,
    createdAt: createdAt ?? DateTime.now().subtract(const Duration(minutes: 30)),
  );
}

NotificationModel buildTestNotification({
  String id = 'notif_001',
  String userId = 'usr_001',
  String type = 'bookingPaid',
  String title = 'Đặt vé thành công',
  String body = 'Vé phim Mai tại Cinema Quận 1 đã sẵn sàng.',
  String? bookingCode = 'K7M2QX9P',
  bool isRead = false,
  DateTime? createdAt,
}) {
  return NotificationModel(
    id: id,
    userId: userId,
    type: type,
    title: title,
    body: body,
    bookingCode: bookingCode,
    isRead: isRead,
    createdAt: createdAt ?? DateTime.now(),
  );
}

Map<String, dynamic> buildTestVoucher({
  String code = 'GIAM20K',
  String type = 'amount', // 'amount' or 'percent'
  int value = 20000,
  int? maxDiscount,
  DateTime? expiryDate,
  int usedCount = 5,
  int maxUses = 100,
  bool isActive = true,
}) {
  return {
    'code': code,
    'type': type,
    'value': value,
    'max_discount': maxDiscount,
    'expiry_date': (expiryDate ?? DateTime.now().add(const Duration(days: 30))).toIso8601String(),
    'used_count': usedCount,
    'max_uses': maxUses,
    'is_active': isActive,
  };
}

Map<String, dynamic> buildTestAuditLog({
  String id = 'aud_001',
  String actorId = 'usr_staff_01',
  String actorRole = 'staff',
  String cinemaId = 'cn_q1',
  String action = 'checkIn',
  String entityType = 'booking',
  String entityId = 'K7M2QX9P',
  String? reason,
  DateTime? timestamp,
}) {
  return {
    'id': id,
    'actor_id': actorId,
    'actor_role': actorRole,
    'cinema_id': cinemaId,
    'action': action,
    'entity_type': entityType,
    'entity_id': entityId,
    'reason': reason,
    'timestamp': (timestamp ?? DateTime.now()).toIso8601String(),
  };
}

// ==========================================
// 2. ORACLE SIMULATORS & INVARIANT VERIFIERS
// ==========================================

/// Exact pricing formula from BUSINESS_RULES.md Section 4:
/// - Base: 2D = 80k, 3D = 100k, IMAX = 120k
/// - VIP: +20k
/// - Couple: 2 * Base + 20k + timeSurcharge
/// - Weekend: +10k (Fri, Sat, Sun)
/// - Prime: +10k (18:00 - 21:59)
int calculateSeatPrice({
  required String format,
  required SeatType type,
  required DateTime startTime,
  int base2D = 80000,
  int base3D = 100000,
  int baseImax = 120000,
  int vipSurcharge = 20000,
  int coupleSurcharge = 20000,
  int weekendSurcharge = 10000,
  int primeSurcharge = 10000,
}) {
  int base = base2D;
  if (format.toUpperCase() == '3D') base = base3D;
  if (format.toUpperCase() == 'IMAX') base = baseImax;

  final bool isWeekend = startTime.weekday == DateTime.friday ||
      startTime.weekday == DateTime.saturday ||
      startTime.weekday == DateTime.sunday;
  final bool isPrime = startTime.hour >= 18 && startTime.hour < 22;

  final int timeSurcharge = (isWeekend ? weekendSurcharge : 0) + (isPrime ? primeSurcharge : 0);

  if (type == SeatType.vip) {
    return base + vipSurcharge + timeSurcharge;
  } else if (type == SeatType.couple) {
    return (2 * base) + coupleSurcharge + timeSurcharge;
  } else {
    return base + timeSurcharge;
  }
}

/// Voucher calculation rules from BUSINESS_RULES.md Section 11:
/// - Only applies to ticketTotal, never foodTotal
int calculateVoucherDiscount({
  required int ticketTotal,
  required Map<String, dynamic> voucher,
}) {
  final bool isActive = voucher['is_active'] == true;
  final DateTime expiry = DateTime.parse(voucher['expiry_date'] as String);
  final int usedCount = voucher['used_count'] as int;
  final int maxUses = voucher['max_uses'] as int;

  if (!isActive || expiry.isBefore(DateTime.now()) || usedCount >= maxUses) {
    return 0;
  }

  final type = voucher['type'] as String;
  final value = voucher['value'] as int;

  if (type == 'amount') {
    return value.clamp(0, ticketTotal);
  } else if (type == 'percent') {
    final rawDiscount = (ticketTotal * value) ~/ 100;
    final int? maxDiscount = voucher['max_discount'] as int?;
    if (maxDiscount != null && rawDiscount > maxDiscount) {
      return maxDiscount;
    }
    return rawDiscount.clamp(0, ticketTotal);
  }
  return 0;
}

/// Check-in validation 8 checks from BUSINESS_RULES.md Section 8
enum CheckinValidationCode {
  success,
  notExists,
  cancelled,
  used,
  wrongCinema,
  tooEarly,
  expiredShowtime,
  unpaidHolding,
}

class CheckinEvaluationResult {
  final CheckinValidationCode code;
  final bool isSuccess;
  final String message;

  const CheckinEvaluationResult({
    required this.code,
    required this.isSuccess,
    required this.message,
  });
}

CheckinEvaluationResult evaluateCheckIn({
  BookingModel? booking,
  required String staffCinemaId,
  required DateTime currentTime,
}) {
  // Check 1: Non-existent code
  if (booking == null) {
    return const CheckinEvaluationResult(
      code: CheckinValidationCode.notExists,
      isSuccess: false,
      message: 'Mã vé không tồn tại trong hệ thống',
    );
  }

  // Check 2: status == cancelled
  if (booking.status == 'cancelled') {
    return const CheckinEvaluationResult(
      code: CheckinValidationCode.cancelled,
      isSuccess: false,
      message: 'Vé đã bị hủy và hoàn tiền',
    );
  }

  // Check 3: status == used
  if (booking.status == 'used') {
    return const CheckinEvaluationResult(
      code: CheckinValidationCode.used,
      isSuccess: false,
      message: 'Vé đã sử dụng',
    );
  }

  // Check 4: cinemaId mismatch
  if (booking.cinemaId != staffCinemaId) {
    return CheckinEvaluationResult(
      code: CheckinValidationCode.wrongCinema,
      isSuccess: false,
      message: 'Vé thuộc rạp khác (${booking.cinemaName})',
    );
  }

  // Check 7: Not paid yet
  if (booking.status != 'paid') {
    return const CheckinEvaluationResult(
      code: CheckinValidationCode.unpaidHolding,
      isSuccess: false,
      message: 'Vé chưa hoàn tất thanh toán',
    );
  }

  // Check 5: currentTime < showtimeStart - 30 minutes
  final earlyLimit = booking.showtimeStart.subtract(AppConstants.checkInEarly);
  if (currentTime.isBefore(earlyLimit)) {
    return const CheckinEvaluationResult(
      code: CheckinValidationCode.tooEarly,
      isSuccess: false,
      message: 'Chưa đến giờ vào rạp (Chỉ vào trước tối đa 30 phút)',
    );
  }

  // Check 6: currentTime > showtimeStart + 15 minutes (noShow)
  final lateLimit = booking.showtimeStart.add(AppConstants.checkInLate);
  if (currentTime.isAfter(lateLimit)) {
    return const CheckinEvaluationResult(
      code: CheckinValidationCode.expiredShowtime,
      isSuccess: false,
      message: 'Vé đã quá hạn sử dụng (Quá 15 phút sau giờ chiếu)',
    );
  }

  // Success
  return const CheckinEvaluationResult(
    code: CheckinValidationCode.success,
    isSuccess: true,
    message: 'Soát vé thành công',
  );
}

/// Showtime overlap check: 15-minute gap trigger (BUSINESS_RULES.md Section 3.3)
bool hasShowtimeConflict({
  required DateTime existingStart,
  required DateTime existingEnd,
  required DateTime candidateStart,
  required DateTime candidateEnd,
}) {
  // Existing showtime occupies [existingStart, existingEnd + 15m]
  const buffer = AppConstants.gapBetweenShowtimes;
  final effectiveExistingEnd = existingEnd.add(buffer);
  final effectiveCandidateEnd = candidateEnd.add(buffer);

  // Overlaps if candidateStart < effectiveExistingEnd AND existingStart < effectiveCandidateEnd
  return candidateStart.isBefore(effectiveExistingEnd) && existingStart.isBefore(effectiveCandidateEnd);
}

/// Cash change calculator (BUSINESS_RULES.md Section 6.3)
int calculateCashChange({required int cashReceived, required int total}) {
  if (cashReceived < total) {
    throw ArgumentError('Khách đưa thiếu tiền: $cashReceived < $total');
  }
  return cashReceived - total;
}

// ==========================================
// 3. WIDGET HARNESS & SUPABASE INITIALIZER
// ==========================================

Future<void> initTestSupabase() async {
  SharedPreferences.setMockInitialValues({});
  try {
    Supabase.instance;
  } catch (_) {
    await Supabase.initialize(
      url: 'https://test-project.supabase.co',
      // ignore: deprecated_member_use
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.e30.fakeKeyForTesting',
    );
  }
}

Widget createTestAppWrapper({
  required Widget child,
  AuthProvider? auth,
  BookingProvider? booking,
  MovieProvider? movie,
  CinemaProvider? cinema,
  TicketProvider? ticket,
}) {
  final app = MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(
      body: child,
    ),
  );

  final providers = [
    if (auth != null) ChangeNotifierProvider.value(value: auth),
    if (booking != null) ChangeNotifierProvider.value(value: booking),
    if (movie != null) ChangeNotifierProvider.value(value: movie),
    if (cinema != null) ChangeNotifierProvider.value(value: cinema),
    if (ticket != null) ChangeNotifierProvider.value(value: ticket),
  ];

  if (providers.isEmpty) {
    return app;
  }

  return MultiProvider(
    providers: providers,
    child: app,
  );
}
