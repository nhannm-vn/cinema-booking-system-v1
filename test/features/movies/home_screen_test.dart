import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cinema_booking_v1/core/routes/app_router.dart';
import 'package:cinema_booking_v1/core/theme/app_theme.dart';
import 'package:cinema_booking_v1/features/auth/presentation/controllers/auth_provider.dart';
import 'package:cinema_booking_v1/features/movies/data/movie_model.dart';
import 'package:cinema_booking_v1/features/movies/presentation/controllers/movie_provider.dart';
import 'package:cinema_booking_v1/features/movies/presentation/screens/home_screen.dart';
import 'package:cinema_booking_v1/features/notifications/data/notification_repository.dart';
import 'package:cinema_booking_v1/features/notifications/presentation/controllers/notification_provider.dart';
import 'package:cinema_booking_v1/shared/models/app_user.dart';
import 'package:cinema_booking_v1/shared/widgets/empty_state.dart';
import 'package:cinema_booking_v1/shared/widgets/error_state.dart';
import 'package:cinema_booking_v1/shared/widgets/skeleton_box.dart';

class FakeMovieProvider extends ChangeNotifier implements MovieProvider {
  bool _isLoading = false;
  String? _errorMessage;
  List<MovieModel> _allMovies = [];
  String _searchQuery = '';
  bool loadMoviesCalled = false;

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
    loadMoviesCalled = true;
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

class FakeNotificationProvider extends ChangeNotifier implements NotificationProvider {
  int _unreadCount = 0;
  final List<NotificationModel> _notifications = [];

  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => null;

  @override
  List<NotificationModel> get notifications => _notifications;

  @override
  int get unreadCount => _unreadCount;
  set unreadCount(int count) {
    _unreadCount = count;
    notifyListeners();
  }

  @override
  Future<void> loadNotifications() async {}

  @override
  Future<void> markAllAsRead() async {
    _unreadCount = 0;
    notifyListeners();
  }
}

class FakeAuthHomeProvider extends ChangeNotifier implements AuthProvider {
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

Widget createHomeTestHarness({
  required FakeMovieProvider movieProvider,
  required FakeNotificationProvider notifProvider,
  FakeAuthHomeProvider? authProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<MovieProvider>.value(value: movieProvider),
      ChangeNotifierProvider<NotificationProvider>.value(value: notifProvider),
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider ?? FakeAuthHomeProvider()),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.movieDetail) {
          final movie = settings.arguments as MovieModel;
          return MaterialPageRoute(
            builder: (_) => Scaffold(body: Text('MOVIE DETAIL: ${movie.title}')),
          );
        }
        return MaterialPageRoute(
          builder: (_) => Scaffold(body: Text('ROUTE: ${settings.name}')),
        );
      },
      home: const HomeScreen(),
    ),
  );
}

void main() {
  group('S03 Home Screen Widget Tests', () {
    late FakeMovieProvider fakeMovies;
    late FakeNotificationProvider fakeNotifs;

    final testNowShowingMovie = MovieModel(
      id: 'mov_01',
      title: 'Dune: Part Two',
      genres: const ['Hành động', 'Khoa học viễn tưởng'],
      durationMin: 166,
      ageRating: 'T16',
      releaseDate: DateTime.now().subtract(const Duration(days: 3)),
      isActive: true,
      description: 'Hành trình của Paul Atreides tiếp tục trên sa mạc Arrakis.',
    );

    final testUpcomingMovie = MovieModel(
      id: 'mov_02',
      title: 'Deadpool & Wolverine',
      genres: const ['Hài', 'Hành động'],
      durationMin: 128,
      ageRating: 'T18',
      releaseDate: DateTime.now().add(const Duration(days: 10)),
      isActive: true,
      description: 'Sự trở lại của Wade Wilson và Logan.',
    );

    void setMobileView(WidgetTester tester) {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    setUp(() {
      fakeMovies = FakeMovieProvider();
      fakeNotifs = FakeNotificationProvider();
    });

    testWidgets('renders SkeletonBox when loading', (tester) async {
      setMobileView(tester);
      fakeMovies.isLoading = true;

      await tester.pumpWidget(createHomeTestHarness(
        movieProvider: fakeMovies,
        notifProvider: fakeNotifs,
      ));

      expect(find.byType(SkeletonBox), findsAtLeastNWidgets(1));
    });

    testWidgets('renders ErrorState with retry when error occurs', (tester) async {
      setMobileView(tester);
      fakeMovies.errorMessage = 'Lỗi kết nối máy chủ.';

      await tester.pumpWidget(createHomeTestHarness(
        movieProvider: fakeMovies,
        notifProvider: fakeNotifs,
      ));

      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.text('Lỗi kết nối máy chủ.'), findsOneWidget);
      expect(find.text('THỬ LẠI'), findsOneWidget);
    });

    testWidgets('renders EmptyState when no movies exist', (tester) async {
      setMobileView(tester);
      fakeMovies.setMovies([]);

      await tester.pumpWidget(createHomeTestHarness(
        movieProvider: fakeMovies,
        notifProvider: fakeNotifs,
      ));

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('Chưa có phim chiếu'), findsOneWidget);
    });

    testWidgets('renders Now Showing and Upcoming movies correctly', (tester) async {
      setMobileView(tester);
      fakeMovies.setMovies([testNowShowingMovie, testUpcomingMovie]);

      await tester.pumpWidget(createHomeTestHarness(
        movieProvider: fakeMovies,
        notifProvider: fakeNotifs,
      ));

      expect(find.text('CINEMA STAR'), findsOneWidget);
      expect(find.text('ĐANG CHIẾU'), findsOneWidget);
      expect(find.text('SẮP CHIẾU'), findsOneWidget);
      expect(find.text('Dune: Part Two'), findsAtLeastNWidgets(1));
      expect(find.text('Deadpool & Wolverine'), findsOneWidget);
    });

    testWidgets('search filters movies and displays matching results', (tester) async {
      setMobileView(tester);
      fakeMovies.setMovies([testNowShowingMovie, testUpcomingMovie]);

      await tester.pumpWidget(createHomeTestHarness(
        movieProvider: fakeMovies,
        notifProvider: fakeNotifs,
      ));

      await tester.enterText(find.byKey(const Key('home_search_field')), 'Dune');
      await tester.pumpAndSettle();

      expect(find.text('KẾT QUẢ TÌM KIẾM (1)'), findsOneWidget);
      expect(find.text('Dune: Part Two'), findsOneWidget);
      expect(find.text('Deadpool & Wolverine'), findsNothing);
    });

    testWidgets('shows EmptyState when search finds no match', (tester) async {
      setMobileView(tester);
      fakeMovies.setMovies([testNowShowingMovie, testUpcomingMovie]);

      await tester.pumpWidget(createHomeTestHarness(
        movieProvider: fakeMovies,
        notifProvider: fakeNotifs,
      ));

      await tester.enterText(find.byKey(const Key('home_search_field')), 'Avatar');
      await tester.pumpAndSettle();

      expect(find.text('Không tìm thấy phim phù hợp'), findsOneWidget);
    });

    testWidgets('tapping movie card navigates to movie detail', (tester) async {
      setMobileView(tester);
      fakeMovies.setMovies([testNowShowingMovie]);

      await tester.pumpWidget(createHomeTestHarness(
        movieProvider: fakeMovies,
        notifProvider: fakeNotifs,
      ));

      await tester.tap(find.byKey(const Key('now_showing_card_mov_01')));
      await tester.pumpAndSettle();

      expect(find.text('MOVIE DETAIL: Dune: Part Two'), findsOneWidget);
    });

    testWidgets('renders CustomerBottomNav with 4 uppercase tabs', (tester) async {
      fakeMovies.setMovies([testNowShowingMovie]);

      await tester.pumpWidget(createHomeTestHarness(
        movieProvider: fakeMovies,
        notifProvider: fakeNotifs,
      ));

      expect(find.text('PHIM'), findsOneWidget);
      expect(find.text('RẠP'), findsOneWidget);
      expect(find.text('VÉ CỦA TÔI'), findsOneWidget);
      expect(find.text('TÀI KHOẢN'), findsOneWidget);
    });
  });
}
