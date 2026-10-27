import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cinema_booking_v1/core/routes/app_router.dart';
import 'package:cinema_booking_v1/core/theme/app_theme.dart';
import 'package:cinema_booking_v1/features/auth/presentation/controllers/auth_provider.dart';
import 'package:cinema_booking_v1/features/cinemas/data/cinema_model.dart';
import 'package:cinema_booking_v1/features/cinemas/presentation/controllers/cinema_provider.dart';
import 'package:cinema_booking_v1/features/cinemas/presentation/screens/cinema_map_screen.dart';
import 'package:cinema_booking_v1/shared/models/app_user.dart';
import 'package:cinema_booking_v1/shared/widgets/empty_state.dart';
import 'package:cinema_booking_v1/shared/widgets/error_state.dart';
import 'package:cinema_booking_v1/shared/widgets/skeleton_box.dart';

class FakeCinemaProvider extends ChangeNotifier implements CinemaProvider {
  bool _isLoading = false;
  String? _errorMessage;
  List<CinemaModel> _cinemas = [];
  CinemaModel? _selectedCinema;

  @override
  bool get isLoading => _isLoading;
  set isLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  @override
  String? get errorMessage => _errorMessage;
  set errorMessage(String? v) {
    _errorMessage = v;
    notifyListeners();
  }

  @override
  List<CinemaModel> get cinemas => _cinemas;
  void setCinemas(List<CinemaModel> list) {
    _cinemas = list;
    if (list.isNotEmpty && _selectedCinema == null) {
      _selectedCinema = list.first;
    }
    notifyListeners();
  }

  @override
  CinemaModel? get selectedCinema => _selectedCinema;

  @override
  Future<void> loadCinemas() async {}

  @override
  void selectCinema(CinemaModel cinema) {
    _selectedCinema = cinema;
    notifyListeners();
  }
}

class FakeCinemaAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  AppUser? get currentUser => null;
  @override
  AuthStatus get status => AuthStatus.unauthenticated;
  @override
  bool get isAuthenticated => false;
  @override
  bool get isLoading => false;
  @override
  String? get errorMessage => null;
  @override
  Future<bool> signIn(String email, String password) async => true;
  @override
  Future<bool> signUp({required String email, required String password, required String fullName, String? phone}) async => true;
  @override
  Future<void> signOut() async {}
  @override
  void clearError() {}
}

Widget createCinemaMapTestHarness({
  required FakeCinemaProvider cinemaProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<CinemaProvider>.value(value: cinemaProvider),
      ChangeNotifierProvider<AuthProvider>.value(value: FakeCinemaAuthProvider()),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.cinemaDetail) {
          final cinema = settings.arguments as CinemaModel;
          return MaterialPageRoute(
            builder: (_) => Scaffold(body: Text('CINEMA DETAIL: ${cinema.name}')),
          );
        }
        return MaterialPageRoute(
          builder: (_) => Scaffold(body: Text('ROUTE: ${settings.name}')),
        );
      },
      home: const CinemaMapScreen(),
    ),
  );
}

void main() {
  group('S17 Cinema Map Screen Widget Tests', () {
    late FakeCinemaProvider fakeCinema;

    const testCinema1 = CinemaModel(
      id: 'cn_01',
      name: 'Cinema Quận 1',
      address: '123 Nguyễn Du, Bến Nghé, Quận 1',
      lat: 10.7769,
      lng: 106.7009,
      distanceKm: 2.5,
    );

    const testCinema2 = CinemaModel(
      id: 'cn_02',
      name: 'Cinema Bình Thạnh',
      address: '45 Điện Biên Phủ, Phường 15, Bình Thạnh',
      lat: 10.7981,
      lng: 106.7153,
      distanceKm: 5.1,
    );

    setUp(() {
      fakeCinema = FakeCinemaProvider();
    });

    testWidgets('renders screen header, location button, and sheet header', (tester) async {
      fakeCinema.setCinemas([testCinema1, testCinema2]);

      await tester.pumpWidget(createCinemaMapTestHarness(cinemaProvider: fakeCinema));

      expect(find.text('CỤM RẠP'), findsOneWidget);
      expect(find.byKey(const Key('cinema_my_location_button')), findsOneWidget);
      expect(find.text('DANH SÁCH RẠP (2)'), findsOneWidget);
      expect(find.byKey(const Key('find_nearest_cinema_button')), findsOneWidget);
    });

    testWidgets('renders SkeletonBox when loading', (tester) async {
      fakeCinema.isLoading = true;

      await tester.pumpWidget(createCinemaMapTestHarness(cinemaProvider: fakeCinema));

      expect(find.byType(SkeletonBox), findsAtLeastNWidgets(1));
    });

    testWidgets('renders ErrorState with retry when error occurs', (tester) async {
      fakeCinema.errorMessage = 'Không thể tải danh sách rạp.';

      await tester.pumpWidget(createCinemaMapTestHarness(cinemaProvider: fakeCinema));

      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.text('Không thể tải danh sách rạp.'), findsOneWidget);
    });

    testWidgets('renders EmptyState when cinemas list is empty', (tester) async {
      fakeCinema.setCinemas([]);

      await tester.pumpWidget(createCinemaMapTestHarness(cinemaProvider: fakeCinema));

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('Không tìm thấy rạp chiếu'), findsOneWidget);
    });

    testWidgets('tapping cinema tile navigates to cinema detail', (tester) async {
      fakeCinema.setCinemas([testCinema1, testCinema2]);

      await tester.pumpWidget(createCinemaMapTestHarness(cinemaProvider: fakeCinema));

      expect(find.text('Cinema Quận 1'), findsOneWidget);
      expect(find.text('2.5 KM'), findsOneWidget);

      await tester.tap(find.byKey(const Key('cinema_list_tile_cn_01')));
      await tester.pumpAndSettle();

      expect(find.text('CINEMA DETAIL: Cinema Quận 1'), findsOneWidget);
    });
  });
}
