/// Business constants for Cinema Booking App.
/// References: BUSINESS_RULES.md Section 16 & PROJECT_STRUCTURE.md
abstract final class AppConstants {
  /// Số ghế tối đa mỗi lần đặt
  static const int maxSeatsPerBooking = 8;

  /// Thời gian giữ ghế online (5 phút)
  static const Duration holdOnline = Duration(minutes: 5);

  /// Thời gian giữ ghế quầy (3 phút)
  static const Duration holdCounter = Duration(minutes: 3);

  /// Khoảng nghỉ tối thiểu giữa hai suất chiếu cùng phòng (15 phút)
  static const Duration gapBetweenShowtimes = Duration(minutes: 15);

  /// Cho phép vào rạp trước giờ chiếu tối đa (30 phút)
  static const Duration checkInEarly = Duration(minutes: 30);

  /// Cho phép vào rạp sau giờ chiếu tối đa (15 phút)
  static const Duration checkInLate = Duration(minutes: 15);

  /// Quá giờ chiếu coi như vắng mặt nếu chưa soát vé (15 phút)
  static const Duration noShowAfter = Duration(minutes: 15);

  /// Thời gian hủy vé trước giờ chiếu (tối thiểu 2 giờ)
  static const Duration cancelBefore = Duration(hours: 2);

  /// Cảnh báo sắp hết giờ giữ ghế (< 60 giây)
  static const Duration paymentWarning = Duration(seconds: 60);

  /// Giới hạn số lượng booking hủy trong 1 batch commit (200)
  static const int cancelBatchLimit = 200;
}
