/// Model dữ liệu thống kê cho S22 Dashboard.
class DashboardMetricsModel {
  final String cinemaId;
  final String period;
  final int todayRevenue;
  final int todayTickets;
  final double occupancyRate;
  final int totalCapacity;
  final int soldCapacity;
  final List<UpcomingShowtimeItem> upcomingShowtimes;

  const DashboardMetricsModel({
    required this.cinemaId,
    required this.period,
    required this.todayRevenue,
    required this.todayTickets,
    required this.occupancyRate,
    required this.totalCapacity,
    required this.soldCapacity,
    required this.upcomingShowtimes,
  });

  factory DashboardMetricsModel.fromMap(Map<String, dynamic> map) {
    final list = (map['upcoming_showtimes'] as List<dynamic>?) ?? [];
    return DashboardMetricsModel(
      cinemaId: (map['cinema_id'] as String?) ?? '',
      period: (map['period'] as String?) ?? 'today',
      todayRevenue: (map['today_revenue'] as num?)?.toInt() ?? 0,
      todayTickets: (map['today_tickets'] as num?)?.toInt() ?? 0,
      occupancyRate: (map['occupancy_rate'] as num?)?.toDouble() ?? 0.0,
      totalCapacity: (map['total_capacity'] as num?)?.toInt() ?? 0,
      soldCapacity: (map['sold_capacity'] as num?)?.toInt() ?? 0,
      upcomingShowtimes: list
          .map((item) => UpcomingShowtimeItem.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }
}

class UpcomingShowtimeItem {
  final String id;
  final String movieTitle;
  final String roomName;
  final String format;
  final DateTime startTime;
  final int totalSeats;
  final int soldSeats;

  const UpcomingShowtimeItem({
    required this.id,
    required this.movieTitle,
    required this.roomName,
    required this.format,
    required this.startTime,
    required this.totalSeats,
    required this.soldSeats,
  });

  factory UpcomingShowtimeItem.fromMap(Map<String, dynamic> map) {
    return UpcomingShowtimeItem(
      id: map['id'] as String,
      movieTitle: (map['movie_title'] as String?) ?? '',
      roomName: (map['room_name'] as String?) ?? '',
      format: (map['format'] as String?) ?? '2D',
      startTime: DateTime.parse(map['start_time'] as String).toLocal(),
      totalSeats: (map['total_seats'] as int?) ?? 0,
      soldSeats: (map['sold_seats'] as int?) ?? 0,
    );
  }
}
