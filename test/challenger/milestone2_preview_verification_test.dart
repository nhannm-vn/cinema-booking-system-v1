import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cinema_booking_v1/core/routes/app_router.dart';
import 'package:cinema_booking_v1/core/theme/app_theme.dart';
import 'package:cinema_booking_v1/features/auth/presentation/controllers/auth_provider.dart';
import 'package:cinema_booking_v1/features/cinemas/presentation/controllers/cinema_provider.dart';
import 'package:cinema_booking_v1/features/cinemas/presentation/screens/cinema_detail_screen.dart';
import 'package:cinema_booking_v1/features/cinemas/presentation/screens/cinema_map_screen.dart';
import 'package:cinema_booking_v1/features/movies/presentation/controllers/movie_provider.dart';
import 'package:cinema_booking_v1/features/movies/presentation/screens/home_screen.dart';
import 'package:cinema_booking_v1/features/movies/presentation/screens/movie_detail_screen.dart';
import 'package:cinema_booking_v1/features/notifications/presentation/controllers/notification_provider.dart';
import 'package:cinema_booking_v1/features/notifications/presentation/screens/notification_center_screen.dart';
import 'package:cinema_booking_v1/shared/widgets/empty_state.dart';
import 'package:cinema_booking_v1/shared/widgets/error_state.dart';
import 'package:cinema_booking_v1/shared/widgets/skeleton_box.dart';
import '../e2e/test_fixtures.dart';

// =============================================================================
// TEST DOUBLES / MOCK PROVIDERS FOR PREVIEW CHALLENGER (M2.2)
// =============================================================================

class MockMovieProvider extends ChangeNotifier implements MovieProvider {
  bool _isLoading = false;
  String? _errorMessage;
  List<MovieModel> _allMovies = [];
  String _searchQuery = '';
  int loadMoviesCallCount = 0;

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
  String get searchQuery => _searchQuery;

  void setMovies(List<MovieModel> movies) {
    _allMovies = movies;
    notifyListeners();
  }

  @override
  List<MovieModel> get nowShowing =>
      _allMovies.where((m) => m.isNowShowing).toList();

  @override
  List<MovieModel> get upcoming =>
      _allMovies.where((m) => m.isUpcoming).toList();

  @override
  List<MovieModel> get searchResults {
    if (_searchQuery.trim().isEmpty) return [];
    final q = _searchQuery.toLowerCase();
    return _allMovies.where((m) => m.title.toLowerCase().contains(q)).toList();
  }

  @override
  Future<void> loadMovies() async {
    loadMoviesCallCount++;
    notifyListeners();
  }

  @override
  void search(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  @override
  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }
}

class MockCinemaProvider extends ChangeNotifier implements CinemaProvider {
  bool _isLoading = false;
  String? _errorMessage;
  List<CinemaModel> _cinemas = [];
  CinemaModel? _selectedCinema;
  int loadCinemasCallCount = 0;

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
  Future<void> loadCinemas() async {
    loadCinemasCallCount++;
    notifyListeners();
  }

  @override
  void selectCinema(CinemaModel cinema) {
    _selectedCinema = cinema;
    notifyListeners();
  }
}

class MockNotificationProvider extends ChangeNotifier implements NotificationProvider {
  bool _isLoading = false;
  String? _errorMessage;
  List<NotificationModel> _notifications = [];
  int loadNotificationsCallCount = 0;

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
  List<NotificationModel> get notifications => _notifications;
  void setNotifications(List<NotificationModel> list) {
    _notifications = list;
    notifyListeners();
  }

  @override
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  @override
  Future<void> loadNotifications() async {
    loadNotificationsCallCount++;
    notifyListeners();
  }

  @override
  Future<void> markAllAsRead() async {
    _notifications = _notifications
        .map((n) => NotificationModel(
              id: n.id,
              userId: n.userId,
              type: n.type,
              title: n.title,
              body: n.body,
              bookingCode: n.bookingCode,
              isRead: true,
              createdAt: n.createdAt,
            ))
        .toList();
    notifyListeners();
  }
}

class MockAuthProvider extends ChangeNotifier implements AuthProvider {
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
  Future<bool> updateProfile({required String fullName, String? phone}) async => true;
  @override
  Future<void> signOut() async {}
  @override
  void clearError() {}
}

// =============================================================================
// MAIN TEST SUITE
// =============================================================================

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initTestSupabase();
  });

  void setMobileView(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  final testMovie = MovieModel(
    id: 'mov_test_01',
    title: 'Dune: Hành Tinh Cát 2',
    genres: const ['Khoa học viễn tưởng', 'Hành động'],
    durationMin: 166,
    ageRating: 'T16',
    releaseDate: DateTime.now().subtract(const Duration(days: 5)),
    isActive: true,
    description: 'Hành trình trả thù và bảo vệ tương lai thiên hà.',
    director: 'Denis Villeneuve',
    castMembers: const ['Timothée Chalamet', 'Zendaya'],
  );

  const testCinema = CinemaModel(
    id: 'cn_test_01',
    name: 'Cinema Star Landmark 81',
    address: '720A Điện Biên Phủ, Phường 22, Bình Thạnh',
    phone: '02899998888',
    openingHours: '08:00 - 01:00',
    lat: 10.7950,
    lng: 106.7218,
    distanceKm: 3.5,
  );

  Widget createHarness({
    required Widget child,
    MockMovieProvider? movieProvider,
    MockCinemaProvider? cinemaProvider,
    MockNotificationProvider? notifProvider,
    MockAuthProvider? authProvider,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<MovieProvider>.value(value: movieProvider ?? MockMovieProvider()),
        ChangeNotifierProvider<CinemaProvider>.value(value: cinemaProvider ?? MockCinemaProvider()),
        ChangeNotifierProvider<NotificationProvider>.value(value: notifProvider ?? MockNotificationProvider()),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider ?? MockAuthProvider()),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: child,
      ),
    );
  }

  // ===========================================================================
  // REQUIREMENT 1: UI STATES ON S03 HOME, S17 CINEMA MAP, S30 NOTIFICATIONS
  // ===========================================================================
  group('Empirical Challenge 1: UI States on S03 Home Discovery', () {
    testWidgets('1.1 S03 Loading: renders SkeletonBox widgets', (tester) async {
      setMobileView(tester);
      final movieProvider = MockMovieProvider()..isLoading = true;

      await tester.pumpWidget(createHarness(
        child: const HomeScreen(),
        movieProvider: movieProvider,
      ));

      expect(find.byType(SkeletonBox), findsAtLeastNWidgets(1));
    });

    testWidgets('1.2 S03 Empty: renders EmptyState when no movies exist', (tester) async {
      setMobileView(tester);
      final movieProvider = MockMovieProvider()..setMovies([]);

      await tester.pumpWidget(createHarness(
        child: const HomeScreen(),
        movieProvider: movieProvider,
      ));

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('Chưa có phim chiếu'), findsOneWidget);
    });

    testWidgets('1.3 S03 Empty Search: renders EmptyState when search yields no matches', (tester) async {
      setMobileView(tester);
      final movieProvider = MockMovieProvider()..setMovies([testMovie]);

      await tester.pumpWidget(createHarness(
        child: const HomeScreen(),
        movieProvider: movieProvider,
      ));

      await tester.enterText(find.byKey(const Key('home_search_field')), 'UnmatchedMovieXYZ');
      await tester.pumpAndSettle();

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('Không tìm thấy phim phù hợp'), findsOneWidget);
    });

    testWidgets('1.4 S03 Error: renders ErrorState and functional retry button triggers loadMovies', (tester) async {
      setMobileView(tester);
      final movieProvider = MockMovieProvider()..errorMessage = 'Lỗi kết nối máy chủ.';

      await tester.pumpWidget(createHarness(
        child: const HomeScreen(),
        movieProvider: movieProvider,
      ));

      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.text('Lỗi kết nối máy chủ.'), findsOneWidget);

      final retryBtnFinder = find.text('THỬ LẠI');
      expect(retryBtnFinder, findsOneWidget);

      final initialCalls = movieProvider.loadMoviesCallCount;
      await tester.tap(retryBtnFinder);
      await tester.pump();

      expect(movieProvider.loadMoviesCallCount, initialCalls + 1,
          reason: 'Tapping THỬ LẠI button must invoke loadMovies on MovieProvider');
    });
  });

  group('Empirical Challenge 1 (Cont): UI States on S17 Cinema Map', () {
    testWidgets('1.5 S17 Loading: renders SkeletonBox widgets in bottom sheet', (tester) async {
      setMobileView(tester);
      final cinemaProvider = MockCinemaProvider()..isLoading = true;

      await tester.pumpWidget(createHarness(
        child: const CinemaMapScreen(),
        cinemaProvider: cinemaProvider,
      ));

      expect(find.byType(SkeletonBox), findsAtLeastNWidgets(1));
    });

    testWidgets('1.6 S17 Empty: renders EmptyState when cinemas list is empty', (tester) async {
      setMobileView(tester);
      final cinemaProvider = MockCinemaProvider()..setCinemas([]);

      await tester.pumpWidget(createHarness(
        child: const CinemaMapScreen(),
        cinemaProvider: cinemaProvider,
      ));

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('Không tìm thấy rạp chiếu'), findsOneWidget);
    });

    testWidgets('1.7 S17 Error: renders ErrorState and functional retry button triggers loadCinemas', (tester) async {
      setMobileView(tester);
      final cinemaProvider = MockCinemaProvider()..errorMessage = 'Không thể tải danh sách cụm rạp.';

      await tester.pumpWidget(createHarness(
        child: const CinemaMapScreen(),
        cinemaProvider: cinemaProvider,
      ));

      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.text('Không thể tải danh sách cụm rạp.'), findsOneWidget);

      final retryFinder = find.text('THỬ LẠI');
      expect(retryFinder, findsOneWidget);

      final initialCalls = cinemaProvider.loadCinemasCallCount;
      await tester.tap(retryFinder);
      await tester.pump();

      expect(cinemaProvider.loadCinemasCallCount, initialCalls + 1,
          reason: 'Tapping THỬ LẠI button must invoke loadCinemas on CinemaProvider');
    });
  });

  group('Empirical Challenge 1 (Cont): UI States on S30 Notification Center', () {
    testWidgets('1.8 S30 Loading: renders SkeletonBox widgets in list', (tester) async {
      setMobileView(tester);
      final notifProvider = MockNotificationProvider()..isLoading = true;

      await tester.pumpWidget(createHarness(
        child: const NotificationCenterScreen(),
        notifProvider: notifProvider,
      ));

      expect(find.byType(SkeletonBox), findsAtLeastNWidgets(1));
    });

    testWidgets('1.9 S30 Empty: renders EmptyState when notifications list is empty', (tester) async {
      setMobileView(tester);
      final notifProvider = MockNotificationProvider()..setNotifications([]);

      await tester.pumpWidget(createHarness(
        child: const NotificationCenterScreen(),
        notifProvider: notifProvider,
      ));

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('Bạn không có thông báo nào'), findsOneWidget);
    });

    testWidgets('1.10 S30 Error: renders ErrorState and functional retry button triggers loadNotifications', (tester) async {
      setMobileView(tester);
      final notifProvider = MockNotificationProvider()..errorMessage = 'Không thể tải danh sách thông báo.';

      await tester.pumpWidget(createHarness(
        child: const NotificationCenterScreen(),
        notifProvider: notifProvider,
      ));

      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.text('Không thể tải danh sách thông báo.'), findsOneWidget);

      final retryFinder = find.text('THỬ LẠI');
      expect(retryFinder, findsOneWidget);

      final initialCalls = notifProvider.loadNotificationsCallCount;
      await tester.tap(retryFinder);
      await tester.pump();

      expect(notifProvider.loadNotificationsCallCount, initialCalls + 1,
          reason: 'Tapping THỬ LẠI button must invoke loadNotifications on NotificationProvider');
    });
  });

  // ===========================================================================
  // REQUIREMENT 2: S04 MOVIE DETAIL ARGUMENT EXTRACTION VIA APPROUTER
  // ===========================================================================
  group('Empirical Challenge 2: S04 Movie Detail Argument Extraction via AppRouter', () {
    testWidgets('2.1 Navigating with MovieModel object extracts and renders movie details', (tester) async {
      setMobileView(tester);

      late BuildContext savedContext;
      await tester.pumpWidget(createHarness(
        child: Builder(builder: (ctx) {
          savedContext = ctx;
          return const Scaffold(body: Text('LAUNCHER'));
        }),
      ));

      Navigator.pushNamed(savedContext, AppRoutes.movieDetail, arguments: testMovie);
      await tester.pumpAndSettle();

      expect(find.byType(MovieDetailScreen), findsOneWidget);
      expect(find.text('Dune: Hành Tinh Cát 2'), findsOneWidget);
      expect(find.text('166'), findsOneWidget);
      expect(find.text('T16'), findsAtLeastNWidgets(1));
      expect(find.text('Denis Villeneuve'), findsOneWidget);
    });

    testWidgets('2.2 Navigating with Map containing movie extracts and renders movie details', (tester) async {
      setMobileView(tester);

      late BuildContext savedContext;
      await tester.pumpWidget(createHarness(
        child: Builder(builder: (ctx) {
          savedContext = ctx;
          return const Scaffold(body: Text('LAUNCHER'));
        }),
      ));

      Navigator.pushNamed(savedContext, AppRoutes.movieDetail, arguments: {'movie': testMovie});
      await tester.pumpAndSettle();

      expect(find.byType(MovieDetailScreen), findsOneWidget);
      expect(find.text('Dune: Hành Tinh Cát 2'), findsOneWidget);
    });

    testWidgets('2.3 Navigating with String movieId extracts movieId into MovieDetailScreen', (tester) async {
      setMobileView(tester);

      late BuildContext savedContext;
      await tester.pumpWidget(createHarness(
        child: Builder(builder: (ctx) {
          savedContext = ctx;
          return const Scaffold(body: Text('LAUNCHER'));
        }),
      ));

      Navigator.pushNamed(savedContext, AppRoutes.movieDetail, arguments: 'mov_unknown_id');
      await tester.pumpAndSettle();

      expect(find.byType(MovieDetailScreen), findsOneWidget);
      final screen = tester.widget<MovieDetailScreen>(find.byType(MovieDetailScreen));
      expect(screen.movieId, 'mov_unknown_id');
      expect(screen.movie, isNull);
    });

    testWidgets('2.4 Navigating with Map containing movieId extracts movieId into MovieDetailScreen', (tester) async {
      setMobileView(tester);

      late BuildContext savedContext;
      await tester.pumpWidget(createHarness(
        child: Builder(builder: (ctx) {
          savedContext = ctx;
          return const Scaffold(body: Text('LAUNCHER'));
        }),
      ));

      Navigator.pushNamed(savedContext, AppRoutes.movieDetail, arguments: {'movieId': 'mov_map_id'});
      await tester.pumpAndSettle();

      expect(find.byType(MovieDetailScreen), findsOneWidget);
      final screen = tester.widget<MovieDetailScreen>(find.byType(MovieDetailScreen));
      expect(screen.movieId, 'mov_map_id');
      expect(screen.movie, isNull);
    });

    testWidgets('2.5 Navigating with null arguments gracefully renders ErrorState without throwing', (tester) async {
      setMobileView(tester);

      late BuildContext savedContext;
      await tester.pumpWidget(createHarness(
        child: Builder(builder: (ctx) {
          savedContext = ctx;
          return const Scaffold(body: Text('LAUNCHER'));
        }),
      ));

      Navigator.pushNamed(savedContext, AppRoutes.movieDetail, arguments: null);
      await tester.pumpAndSettle();

      expect(find.byType(MovieDetailScreen), findsOneWidget);
      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.text('Không tìm thấy thông tin phim.'), findsOneWidget);
    });
  });

  // ===========================================================================
  // REQUIREMENT 3: S17B CINEMA DETAIL ARGUMENT EXTRACTION VIA APPROUTER
  // ===========================================================================
  group('Empirical Challenge 3: S17B Cinema Detail Argument Extraction via AppRouter', () {
    testWidgets('3.1 Navigating with CinemaModel object extracts and renders cinema details', (tester) async {
      setMobileView(tester);

      late BuildContext savedContext;
      await tester.pumpWidget(createHarness(
        child: Builder(builder: (ctx) {
          savedContext = ctx;
          return const Scaffold(body: Text('LAUNCHER'));
        }),
      ));

      Navigator.pushNamed(savedContext, AppRoutes.cinemaDetail, arguments: testCinema);
      await tester.pumpAndSettle();

      expect(find.byType(CinemaDetailScreen), findsOneWidget);
      expect(find.text('Cinema Star Landmark 81'), findsAtLeastNWidgets(1));
      expect(find.text('720A Điện Biên Phủ, Phường 22, Bình Thạnh'), findsOneWidget);
      expect(find.text('02899998888'), findsOneWidget);
      expect(find.text('3.5 KM TỪ VỊ TRÍ CỦA BẠN'), findsOneWidget);
    });

    testWidgets('3.2 Navigating with Map containing cinema extracts and renders cinema details', (tester) async {
      setMobileView(tester);

      late BuildContext savedContext;
      await tester.pumpWidget(createHarness(
        child: Builder(builder: (ctx) {
          savedContext = ctx;
          return const Scaffold(body: Text('LAUNCHER'));
        }),
      ));

      Navigator.pushNamed(savedContext, AppRoutes.cinemaDetail, arguments: {'cinema': testCinema});
      await tester.pumpAndSettle();

      expect(find.byType(CinemaDetailScreen), findsOneWidget);
      expect(find.text('Cinema Star Landmark 81'), findsAtLeastNWidgets(1));
    });

    testWidgets('3.3 Navigating with String cinemaId extracts cinemaId into CinemaDetailScreen', (tester) async {
      setMobileView(tester);

      late BuildContext savedContext;
      await tester.pumpWidget(createHarness(
        child: Builder(builder: (ctx) {
          savedContext = ctx;
          return const Scaffold(body: Text('LAUNCHER'));
        }),
      ));

      Navigator.pushNamed(savedContext, AppRoutes.cinemaDetail, arguments: 'cn_unknown_id');
      await tester.pumpAndSettle();

      expect(find.byType(CinemaDetailScreen), findsOneWidget);
      final screen = tester.widget<CinemaDetailScreen>(find.byType(CinemaDetailScreen));
      expect(screen.cinemaId, 'cn_unknown_id');
      expect(screen.cinema, isNull);
    });

    testWidgets('3.4 Navigating with Map containing cinemaId extracts cinemaId into CinemaDetailScreen', (tester) async {
      setMobileView(tester);

      late BuildContext savedContext;
      await tester.pumpWidget(createHarness(
        child: Builder(builder: (ctx) {
          savedContext = ctx;
          return const Scaffold(body: Text('LAUNCHER'));
        }),
      ));

      Navigator.pushNamed(savedContext, AppRoutes.cinemaDetail, arguments: {'cinemaId': 'cn_map_id'});
      await tester.pumpAndSettle();

      expect(find.byType(CinemaDetailScreen), findsOneWidget);
      final screen = tester.widget<CinemaDetailScreen>(find.byType(CinemaDetailScreen));
      expect(screen.cinemaId, 'cn_map_id');
      expect(screen.cinema, isNull);
    });

    testWidgets('3.5 Navigating with null arguments gracefully renders ErrorState without throwing', (tester) async {
      setMobileView(tester);

      late BuildContext savedContext;
      await tester.pumpWidget(createHarness(
        child: Builder(builder: (ctx) {
          savedContext = ctx;
          return const Scaffold(body: Text('LAUNCHER'));
        }),
      ));

      Navigator.pushNamed(savedContext, AppRoutes.cinemaDetail, arguments: null);
      await tester.pumpAndSettle();

      expect(find.byType(CinemaDetailScreen), findsOneWidget);
      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.text('Không tìm thấy thông tin rạp.'), findsOneWidget);
    });
  });
}
