/// Specific exception thrown when a seat is already held or booked.
/// Thrown by SeatRepository when RPC returns `SEAT_TAKEN:<seat_id>`.
class SeatTakenException implements Exception {
  final String seatId;

  const SeatTakenException(this.seatId);

  @override
  String toString() => 'Ghế $seatId vừa có người chọn. Vui lòng chọn ghế khác.';
}

/// Generic API response wrapper.
class ApiResponse<T> {
  final T? data;
  final String? errorMessage;
  final bool isSuccess;

  const ApiResponse.success(this.data)
      : errorMessage = null,
        isSuccess = true;

  const ApiResponse.error(this.errorMessage)
      : data = null,
        isSuccess = false;
}
