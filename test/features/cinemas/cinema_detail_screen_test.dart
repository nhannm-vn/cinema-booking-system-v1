import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cinema_booking_v1/core/routes/app_router.dart';
import 'package:cinema_booking_v1/core/theme/app_theme.dart';
import 'package:cinema_booking_v1/features/cinemas/data/cinema_model.dart';
import 'package:cinema_booking_v1/features/cinemas/presentation/screens/cinema_detail_screen.dart';

Widget createCinemaDetailTestHarness({
  required CinemaModel cinema,
}) {
  return MaterialApp(
    theme: AppTheme.dark,
    onGenerateRoute: (settings) {
      if (settings.name == AppRoutes.showtimes) {
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => Scaffold(body: Text('SHOWTIMES AT: ${args['cinemaName']}')),
        );
      }
      return MaterialPageRoute(
        builder: (_) => Scaffold(body: Text('ROUTE: ${settings.name}')),
      );
    },
    home: CinemaDetailScreen(cinema: cinema),
  );
}

void main() {
  group('S17B Cinema Detail Screen Widget Tests', () {
    const testCinema = CinemaModel(
      id: 'cn_test_01',
      name: 'Cinema Landmark 81',
      address: '720A Điện Biên Phủ, Phường 22, Bình Thạnh, TP.HCM',
      phone: '02899998888',
      openingHours: '08:00 - 01:00 (Hàng ngày)',
      lat: 10.7950,
      lng: 106.7218,
      distanceKm: 3.8,
    );

    testWidgets('renders cinema metadata, address, hotline, and distance badge', (tester) async {
      await tester.pumpWidget(createCinemaDetailTestHarness(cinema: testCinema));

      expect(find.text('Cinema Landmark 81'), findsAtLeastNWidgets(1));
      expect(find.text('3.8 KM TỪ VỊ TRÍ CỦA BẠN'), findsOneWidget);
      expect(find.text('720A Điện Biên Phủ, Phường 22, Bình Thạnh, TP.HCM'), findsOneWidget);
      expect(find.text('02899998888'), findsOneWidget);
      expect(find.text('08:00 - 01:00 (Hàng ngày)'), findsOneWidget);
      expect(find.byKey(const Key('cinema_directions_button')), findsOneWidget);
      expect(find.byKey(const Key('cinema_view_showtimes_cta')), findsOneWidget);
    });

    testWidgets('tapping XEM SUẤT CHIẾU HÔM NAY navigates to showtimes', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createCinemaDetailTestHarness(cinema: testCinema));

      await tester.tap(find.byKey(const Key('cinema_view_showtimes_cta')));
      await tester.pumpAndSettle();

      expect(find.text('SHOWTIMES AT: Cinema Landmark 81'), findsOneWidget);
    });
  });
}
