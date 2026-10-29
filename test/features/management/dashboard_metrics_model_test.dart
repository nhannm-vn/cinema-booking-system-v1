import 'package:flutter_test/flutter_test.dart';
import 'package:cinema_booking_v1/features/management/data/models/dashboard_metrics_model.dart';

void main() {
  group('DashboardMetricsModel Tests', () {
    test('fromMap parses valid JSON payload correctly', () {
      final json = {
        'cinema_id': 'cn_q1',
        'period': 'today',
        'today_revenue': 25000000,
        'today_tickets': 210,
        'occupancy_rate': 68.5,
        'total_capacity': 300,
        'sold_capacity': 210,
        'upcoming_showtimes': [
          {
            'id': 'b1111111-1111-1111-1111-111111111101',
            'movie_title': 'Oppenheimer',
            'room_name': 'Phòng Chiếu 1 (IMAX)',
            'format': 'IMAX',
            'start_time': '2026-10-28T18:00:00Z',
            'total_seats': 75,
            'sold_seats': 45,
          }
        ]
      };

      final metrics = DashboardMetricsModel.fromMap(json);

      expect(metrics.cinemaId, 'cn_q1');
      expect(metrics.period, 'today');
      expect(metrics.todayRevenue, 25000000);
      expect(metrics.todayTickets, 210);
      expect(metrics.occupancyRate, 68.5);
      expect(metrics.totalCapacity, 300);
      expect(metrics.soldCapacity, 210);
      expect(metrics.upcomingShowtimes.length, 1);

      final showtime = metrics.upcomingShowtimes.first;
      expect(showtime.id, 'b1111111-1111-1111-1111-111111111101');
      expect(showtime.movieTitle, 'Oppenheimer');
      expect(showtime.roomName, 'Phòng Chiếu 1 (IMAX)');
      expect(showtime.format, 'IMAX');
      expect(showtime.totalSeats, 75);
      expect(showtime.soldSeats, 45);
    });

    test('fromMap handles null and missing fields gracefully', () {
      final json = <String, dynamic>{};
      final metrics = DashboardMetricsModel.fromMap(json);

      expect(metrics.cinemaId, '');
      expect(metrics.period, 'today');
      expect(metrics.todayRevenue, 0);
      expect(metrics.todayTickets, 0);
      expect(metrics.occupancyRate, 0.0);
      expect(metrics.totalCapacity, 0);
      expect(metrics.soldCapacity, 0);
      expect(metrics.upcomingShowtimes, isEmpty);
    });
  });
}
