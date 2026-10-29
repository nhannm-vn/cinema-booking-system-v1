import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cinema_booking_v1/core/routes/app_router.dart';
import 'package:cinema_booking_v1/core/routes/route_guards.dart';
import 'package:cinema_booking_v1/core/theme/app_theme.dart';
import 'package:cinema_booking_v1/features/auth/presentation/controllers/auth_provider.dart';
import 'package:cinema_booking_v1/features/auth/presentation/screens/login_screen.dart';
import 'package:cinema_booking_v1/features/auth/presentation/screens/register_screen.dart';
import 'package:cinema_booking_v1/features/movies/data/movie_model.dart';
import 'package:cinema_booking_v1/features/movies/presentation/controllers/movie_provider.dart';
import 'package:cinema_booking_v1/features/movies/presentation/screens/home_screen.dart';
import 'package:cinema_booking_v1/features/notifications/data/notification_repository.dart';
import 'package:cinema_booking_v1/features/notifications/presentation/controllers/notification_provider.dart';
import 'package:cinema_booking_v1/shared/models/app_user.dart';
import 'package:cinema_booking_v1/shared/widgets/customer_bottom_nav.dart';
import 'package:cinema_booking_v1/shared/widgets/empty_state.dart';

// =============================================================================
// FAKE PROVIDERS FOR EMPIRICAL STRESS TESTING
// =============================================================================

class MockAuthProvider extends ChangeNotifier implements AuthProvider {
  AppUser? _currentUser;
  AuthStatus _status = AuthStatus.unauthenticated;
  String? _errorMessage;
  bool signInResult = true;
  bool signUpResult = true;
  bool signOutCalled = false;
  int signOutCount = 0;

  String? lastSignInEmail;
  String? lastSignInPassword;
  String? lastRegisteredEmail;
  String? lastRegisteredPassword;
  String? lastRegisteredName;
  String? lastRegisteredPhone;

  @override
  AppUser? get currentUser => _currentUser;

  set currentUser(AppUser? user) {
    _currentUser = user;
    _status = user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    notifyListeners();
  }

  @override
  AuthStatus get status => _status;

  @override
  bool get isAuthenticated => _currentUser != null;

  @override
  bool get isLoading => _status == AuthStatus.loading;

  @override
  String? get errorMessage => _errorMessage;

  set errorMessage(String? msg) {
    _errorMessage = msg;
    notifyListeners();
  }

  @override
  Future<bool> signIn(String email, String password) async {
    lastSignInEmail = email;
    lastSignInPassword = password;
    if (signInResult) {
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } else {
      _errorMessage = 'Tài khoản hoặc mật khẩu không chính xác.';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  @override
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    lastRegisteredEmail = email;
    lastRegisteredPassword = password;
    lastRegisteredName = fullName;
    lastRegisteredPhone = phone;

    if (signUpResult) {
      _currentUser = AppUser(
        id: 'usr_mock_new',
        fullName: fullName,
        email: email,
        phone: phone,
        role: UserRole.customer,
      );
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } else {
      _errorMessage = 'Đăng ký không thành công.';
      notifyListeners();
      return false;
    }
  }

  @override
  Future<bool> updateProfile({required String fullName, String? phone}) async {
    if (_currentUser != null) {
      _currentUser = AppUser(
        id: _currentUser!.id,
        fullName: fullName,
        email: _currentUser!.email,
        phone: phone ?? _currentUser!.phone,
        role: _currentUser!.role,
        cinemaId: _currentUser!.cinemaId,
        isLocked: _currentUser!.isLocked,
      );
      notifyListeners();
    }
    return true;
  }

  @override
  Future<void> signOut() async {
    signOutCalled = true;
    signOutCount++;
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  @override
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

class MockMovieProvider extends ChangeNotifier implements MovieProvider {
  bool _isLoading = false;
  String? _errorMessage;
  List<MovieModel> _allMovies = [];
  String _searchQuery = '';

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
  Future<void> loadMovies() async {}

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

class MockNotificationProvider extends ChangeNotifier implements NotificationProvider {
  final int _unreadCount = 0;
  final List<NotificationModel> _notifications = [];

  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => null;

  @override
  List<NotificationModel> get notifications => _notifications;

  @override
  int get unreadCount => _unreadCount;

  @override
  Future<void> loadNotifications() async {}

  @override
  Future<void> markAllAsRead() async {}
}

// =============================================================================
// TEST SUITE
// =============================================================================

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final pastDate = DateTime.now().subtract(const Duration(days: 30));
  final futureDate = DateTime.now().add(const Duration(days: 30));

  // Note: posterUrl & backdropUrl are null to prevent CachedNetworkImage network fetching in widget tests
  final testMoviesDataset = <MovieModel>[
    MovieModel(
      id: 'mov_vn_01',
      title: 'Đất Rừng Phương Nam',
      description: 'Hành trình tìm cha của bé An.',
      ageRating: 'P',
      durationMin: 134,
      genres: const ['Phiêu lưu', 'Gia đình'],
      releaseDate: pastDate,
      isActive: true,
    ),
    MovieModel(
      id: 'mov_vn_02',
      title: 'Kẻ Ăn Hồn',
      description: 'Bí ẩn ngôi làng Địa Ngục.',
      ageRating: 'T18',
      durationMin: 109,
      genres: const ['Kinh dị', 'Bí ẩn'],
      releaseDate: pastDate,
      isActive: true,
    ),
    MovieModel(
      id: 'mov_vn_03',
      title: 'Lật Mặt 7: Một Điều Ước',
      description: 'Câu chuyện cảm động về tình mẹ con.',
      ageRating: 'K',
      durationMin: 138,
      genres: const ['Gia đình', 'Tâm lý'],
      releaseDate: pastDate,
      isActive: true,
    ),
    MovieModel(
      id: 'mov_spec_04',
      title: 'Deadpool & Wolverine [IMAX 3D] (?.*+)',
      description: 'Hai siêu anh hùng hỗn chiến đa vũ trụ.',
      ageRating: 'T18',
      durationMin: 127,
      genres: const ['Hành động', 'Hài hước'],
      releaseDate: pastDate,
      isActive: true,
    ),
    MovieModel(
      id: 'mov_spec_05',
      title: 'Mai',
      description: 'Tác phẩm điện ảnh tâm lý xã hội của Trấn Thành.',
      ageRating: 'T18',
      durationMin: 131,
      genres: const ['Tâm lý', 'Tình cảm'],
      releaseDate: futureDate,
      isActive: true,
    ),
  ];

  void setMobileView(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget createAuthHarness({
    required Widget child,
    required MockAuthProvider authProvider,
    String? redirectRoute,
    Map<String, WidgetBuilder>? routes,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        routes: routes ?? {},
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              body: Text('DESTINATION: ${settings.name} | ARGS: ${settings.arguments}'),
            ),
            settings: settings,
          );
        },
        home: child,
      ),
    );
  }

  group('Group 1: Authentication Boundary & Stress Tests (S01 Login & S02 Register)', () {
    late MockAuthProvider mockAuth;

    setUp(() {
      mockAuth = MockAuthProvider();
    });

    testWidgets('1.1 Boundary: S01 rejects empty, whitespace, and malformed emails', (tester) async {
      setMobileView(tester);

      await tester.pumpWidget(createAuthHarness(
        child: const LoginScreen(),
        authProvider: mockAuth,
      ));

      final emailField = find.byKey(const Key('login_email_field'));
      final passField = find.byKey(const Key('login_password_field'));
      final submitBtn = find.byKey(const Key('login_submit_button'));

      // Test 1: Empty email
      await tester.enterText(emailField, '');
      await tester.enterText(passField, '123456');
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();
      expect(find.text('Vui lòng nhập email'), findsOneWidget);

      // Test 2: Whitespace only
      await tester.enterText(emailField, '     ');
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();
      expect(find.text('Vui lòng nhập email'), findsOneWidget);

      // Test 3: Malformed emails without @ or invalid structure
      final malformedList = [
        'plainaddress',
        '@missingusername.com',
        'username@.com',
        'username@domain..com',
        'username@domain',
        'username@domain.c', // 1 char TLD fails regex
        'username name@domain.com', // spaces
      ];

      for (final badEmail in malformedList) {
        await tester.enterText(emailField, badEmail);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();
        expect(find.text('Email không hợp lệ'), findsOneWidget,
            reason: 'Expected $badEmail to be rejected as invalid email');
      }

      // Test 4: Valid email clears error
      await tester.enterText(emailField, 'customer@cinema.vn');
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();
      expect(find.text('Email không hợp lệ'), findsNothing);
      expect(find.text('Vui lòng nhập email'), findsNothing);
    });

    testWidgets('1.2 Boundary: S01 rejects passwords with length < 6', (tester) async {
      setMobileView(tester);

      await tester.pumpWidget(createAuthHarness(
        child: const LoginScreen(),
        authProvider: mockAuth,
      ));

      final emailField = find.byKey(const Key('login_email_field'));
      final passField = find.byKey(const Key('login_password_field'));
      final submitBtn = find.byKey(const Key('login_submit_button'));

      await tester.enterText(emailField, 'customer@cinema.vn');

      // Test Empty password
      await tester.enterText(passField, '');
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();
      expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);

      // Boundary: 5 characters (MUST FAIL)
      await tester.enterText(passField, '12345');
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();
      expect(find.text('Mật khẩu phải từ 6 ký tự trở lên'), findsOneWidget);

      // Boundary: 6 characters (MUST PASS)
      await tester.enterText(passField, '123456');
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();
      expect(find.text('Mật khẩu phải từ 6 ký tự trở lên'), findsNothing);
    });

    testWidgets('1.3 Boundary: S02 Register validates full name, 9-digit vs 10-digit vs 11-digit phones', (tester) async {
      setMobileView(tester);

      await tester.pumpWidget(createAuthHarness(
        child: const RegisterScreen(),
        authProvider: mockAuth,
      ));

      final nameField = find.byKey(const Key('register_name_field'));
      final emailField = find.byKey(const Key('register_email_field'));
      final phoneField = find.byKey(const Key('register_phone_field'));
      final passField = find.byKey(const Key('register_password_field'));
      final confirmField = find.byKey(const Key('register_confirm_password_field'));
      final submitBtn = find.byKey(const Key('register_submit_button'));

      // 1. Name boundary: empty and 1 character
      await tester.enterText(nameField, '');
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();
      expect(find.text('Vui lòng nhập họ và tên'), findsOneWidget);

      await tester.enterText(nameField, 'A');
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();
      expect(find.text('Họ và tên phải từ 2 ký tự trở lên'), findsOneWidget);

      await tester.enterText(nameField, 'An'); // 2 chars passes
      await tester.enterText(emailField, 'test@cinema.vn');
      await tester.enterText(passField, '123456');
      await tester.enterText(confirmField, '123456');

      // 2. Phone boundary: 9-digit (FAIL)
      await tester.enterText(phoneField, '090123456'); // 9 digits
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();
      expect(find.text('Số điện thoại phải gồm 10 chữ số bắt đầu bằng số 0'), findsOneWidget);

      // 3. Phone boundary: 11-digit (FAIL)
      await tester.enterText(phoneField, '09012345678'); // 11 digits
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();
      expect(find.text('Số điện thoại phải gồm 10 chữ số bắt đầu bằng số 0'), findsOneWidget);

      // 4. Phone boundary: non-0 leading (FAIL)
      await tester.enterText(phoneField, '1901234567'); // starts with 1
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();
      expect(find.text('Số điện thoại phải gồm 10 chữ số bắt đầu bằng số 0'), findsOneWidget);

      // 5. Phone boundary: contains alphabet or symbols (FAIL)
      await tester.enterText(phoneField, '090123456a');
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();
      expect(find.text('Số điện thoại phải gồm 10 chữ số bắt đầu bằng số 0'), findsOneWidget);

      // 6. Phone boundary: exact 10 digits starting with 0 (PASS)
      await tester.enterText(phoneField, '0901234567');
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();
      expect(find.text('Số điện thoại phải gồm 10 chữ số bắt đầu bằng số 0'), findsNothing);
    });

    testWidgets('1.4 Boundary: S02 Register rejects mismatched confirm password', (tester) async {
      setMobileView(tester);

      await tester.pumpWidget(createAuthHarness(
        child: const RegisterScreen(),
        authProvider: mockAuth,
      ));

      final nameField = find.byKey(const Key('register_name_field'));
      final emailField = find.byKey(const Key('register_email_field'));
      final phoneField = find.byKey(const Key('register_phone_field'));
      final passField = find.byKey(const Key('register_password_field'));
      final confirmField = find.byKey(const Key('register_confirm_password_field'));
      final submitBtn = find.byKey(const Key('register_submit_button'));

      await tester.enterText(nameField, 'Nguyễn Văn A');
      await tester.enterText(emailField, 'test@cinema.vn');
      await tester.enterText(phoneField, '0901234567');

      // Password 5 chars
      await tester.enterText(passField, '12345');
      await tester.enterText(confirmField, '12345');
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();
      expect(find.text('Mật khẩu phải từ 6 ký tự trở lên'), findsOneWidget);

      // Password 6 chars, confirm mismatched
      await tester.enterText(passField, '123456');
      await tester.enterText(confirmField, '123457');
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();
      expect(find.text('Mật khẩu xác nhận không khớp'), findsOneWidget);

      // Password 6 chars, confirm matches exactly
      await tester.enterText(confirmField, '123456');
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();
      expect(find.text('Mật khẩu xác nhận không khớp'), findsNothing);
      expect(find.text('DESTINATION: /home | ARGS: null'), findsOneWidget);
    });

    testWidgets('1.5 Security: Locked user attempt login -> immediate sign out and error banner', (tester) async {
      setMobileView(tester);

      // Setup locked user
      const lockedUser = AppUser(
        id: 'usr_locked_999',
        fullName: 'Locked Bad Actor',
        email: 'locked@cinema.vn',
        role: UserRole.customer,
        isLocked: true, // LOCKED ACCOUNT
      );

      mockAuth.currentUser = lockedUser;

      await tester.pumpWidget(createAuthHarness(
        child: const LoginScreen(),
        authProvider: mockAuth,
      ));

      final emailField = find.byKey(const Key('login_email_field'));
      final passField = find.byKey(const Key('login_password_field'));
      final submitBtn = find.byKey(const Key('login_submit_button'));

      await tester.enterText(emailField, 'locked@cinema.vn');
      await tester.enterText(passField, '123456');
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // 1. Verify signOut was immediately called
      expect(mockAuth.signOutCalled, isTrue,
          reason: 'Locked user must be immediately signed out from Supabase Auth');

      // 2. Verify error banner displayed on screen
      expect(
        find.text('Tài khoản của bạn đã bị khóa. Vui lòng liên hệ ban quản lý.'),
        findsOneWidget,
        reason: 'Error banner must inform the user about account lock status',
      );

      // 3. Verify user remained on LoginScreen and was NOT routed to any destination
      expect(find.textContaining('DESTINATION:'), findsNothing);
      expect(find.text('ĐĂNG NHẬP'), findsAtLeastNWidgets(1));
    });

    testWidgets('1.6a Redirection: Customer routes to S03 Home upon login', (tester) async {
      setMobileView(tester);

      mockAuth.currentUser = const AppUser(
        id: 'usr_cust',
        fullName: 'Test Customer',
        email: 'customer@cinema.vn',
        role: UserRole.customer,
        isLocked: false,
      );

      await tester.pumpWidget(createAuthHarness(
        child: const LoginScreen(),
        authProvider: mockAuth,
      ));

      await tester.enterText(find.byKey(const Key('login_email_field')), 'customer@cinema.vn');
      await tester.enterText(find.byKey(const Key('login_password_field')), 'password123');
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('DESTINATION: /home | ARGS: null'), findsOneWidget);
    });

    testWidgets('1.6b Redirection: Staff routes to S18 Checkin upon login', (tester) async {
      setMobileView(tester);

      mockAuth.currentUser = const AppUser(
        id: 'usr_staff',
        fullName: 'Test Staff',
        email: 'staff@cinema.vn',
        role: UserRole.staff,
        cinemaId: 'cn_q1',
        isLocked: false,
      );

      await tester.pumpWidget(createAuthHarness(
        child: const LoginScreen(),
        authProvider: mockAuth,
      ));

      await tester.enterText(find.byKey(const Key('login_email_field')), 'staff@cinema.vn');
      await tester.enterText(find.byKey(const Key('login_password_field')), 'password123');
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('DESTINATION: /staff/checkin | ARGS: null'), findsOneWidget);
    });

    testWidgets('1.6c Redirection: Manager routes to S22 Dashboard upon login', (tester) async {
      setMobileView(tester);

      mockAuth.currentUser = const AppUser(
        id: 'usr_manager',
        fullName: 'Test Manager',
        email: 'manager@cinema.vn',
        role: UserRole.manager,
        cinemaId: 'cn_q1',
        isLocked: false,
      );

      await tester.pumpWidget(createAuthHarness(
        child: const LoginScreen(),
        authProvider: mockAuth,
      ));

      await tester.enterText(find.byKey(const Key('login_email_field')), 'manager@cinema.vn');
      await tester.enterText(find.byKey(const Key('login_password_field')), 'password123');
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('DESTINATION: /management/dashboard | ARGS: null'), findsOneWidget);
    });

    testWidgets('1.6d Redirection: Admin routes to S12 Management Menu upon login', (tester) async {
      setMobileView(tester);

      mockAuth.currentUser = const AppUser(
        id: 'usr_admin',
        fullName: 'Test Admin',
        email: 'admin@cinema.vn',
        role: UserRole.admin,
        isLocked: false,
      );

      await tester.pumpWidget(createAuthHarness(
        child: const LoginScreen(),
        authProvider: mockAuth,
      ));

      await tester.enterText(find.byKey(const Key('login_email_field')), 'admin@cinema.vn');
      await tester.enterText(find.byKey(const Key('login_password_field')), 'password123');
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('DESTINATION: /management | ARGS: null'), findsOneWidget);
    });

    testWidgets('1.7 Redirection: Guest deep-link redirectRoute redirects customer to target route', (tester) async {
      setMobileView(tester);

      mockAuth.currentUser = const AppUser(
        id: 'usr_deep_cust',
        fullName: 'Deep Link Customer',
        email: 'customer@cinema.vn',
        role: UserRole.customer,
        isLocked: false,
      );

      await tester.pumpWidget(createAuthHarness(
        child: const LoginScreen(redirectRoute: AppRoutes.myTickets),
        authProvider: mockAuth,
      ));

      await tester.enterText(find.byKey(const Key('login_email_field')), 'customer@cinema.vn');
      await tester.enterText(find.byKey(const Key('login_password_field')), 'password123');
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      expect(
        find.text('DESTINATION: /my-tickets | ARGS: null'),
        findsOneWidget,
        reason: 'Customer should be redirected to deep-link target route after login',
      );
    });
  });

  group('Group 2: S03 Movie Search Filtering Stress Tests', () {
    late MockMovieProvider mockMovies;
    late MockNotificationProvider mockNotifs;
    late MockAuthProvider mockAuth;

    setUp(() {
      mockMovies = MockMovieProvider();
      mockNotifs = MockNotificationProvider();
      mockAuth = MockAuthProvider();
      mockMovies.setMovies(testMoviesDataset);
    });

    Widget createHomeHarness() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<MovieProvider>.value(value: mockMovies),
          ChangeNotifierProvider<NotificationProvider>.value(value: mockNotifs),
          ChangeNotifierProvider<AuthProvider>.value(value: mockAuth),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          onGenerateRoute: (settings) {
            return MaterialPageRoute(
              builder: (_) => Scaffold(
                body: Text('DESTINATION: ${settings.name}'),
              ),
              settings: settings,
            );
          },
          home: const HomeScreen(),
        ),
      );
    }

    testWidgets('2.1 Stress: Regex meta-characters in search query do not crash the engine', (tester) async {
      setMobileView(tester);

      await tester.pumpWidget(createHomeHarness());
      await tester.pumpAndSettle();

      final searchField = find.byKey(const Key('home_search_field'));

      // List of dangerous regex characters that crash poorly configured RegExp searches
      final regexAttacks = [
        '?.*+[]',
        '([a-z]+', // Unclosed group
        '[a-z',    // Unclosed bracket
        '\\',      // Lone backslash
        '^.*\$',   // Anchors
        '+++',     // Invalid repetition
        '????',    // Quantifiers without target
        '{1,2',    // Unclosed brace
      ];

      for (final query in regexAttacks) {
        // Entering query must not throw FormatException
        await tester.enterText(searchField, query);
        await tester.pumpAndSettle();

        // Either finds matching movie if literal is present, or shows EmptyState
        if (query == '?.*+[]') {
          // One movie literally has '(?.*+)' - but '?.*+[]' has extra '[]' so no match
          expect(find.byType(EmptyState), findsOneWidget);
        } else {
          // The UI must remain stable and not crash
          expect(find.byType(HomeScreen), findsOneWidget);
        }
      }

      // Test literal match with meta-characters
      await tester.enterText(searchField, '(?.*+)');
      await tester.pumpAndSettle();
      expect(find.text('KẾT QUẢ TÌM KIẾM (1)'), findsOneWidget);
      expect(find.text('Deadpool & Wolverine [IMAX 3D] (?.*+)'), findsOneWidget);
    });

    testWidgets('2.2 Stress: Vietnamese Unicode diacritics and case-insensitivity match correctly', (tester) async {
      setMobileView(tester);

      await tester.pumpWidget(createHomeHarness());
      await tester.pumpAndSettle();

      final searchField = find.byKey(const Key('home_search_field'));

      final testCases = [
        ('đất', 'Đất Rừng Phương Nam'),
        ('ĐẤT', 'Đất Rừng Phương Nam'),
        ('Phương Nam', 'Đất Rừng Phương Nam'),
        ('PHƯƠNG NAM', 'Đất Rừng Phương Nam'),
        ('kẻ ăn hồn', 'Kẻ Ăn Hồn'),
        ('KẺ ĂN HỒN', 'Kẻ Ăn Hồn'),
        ('LẬT MẶT', 'Lật Mặt 7: Một Điều Ước'),
        ('điều ước', 'Lật Mặt 7: Một Điều Ước'),
        ('ĐIỀU ƯỚC', 'Lật Mặt 7: Một Điều Ước'),
        ('mai', 'Mai'),
        ('MAI', 'Mai'),
      ];

      for (final (query, expectedTitle) in testCases) {
        await tester.enterText(searchField, query);
        await tester.pumpAndSettle();

        expect(find.text(expectedTitle), findsAtLeastNWidgets(1),
            reason: 'Query "$query" must find "$expectedTitle" regardless of case or Unicode diacritics');
      }
    });

    testWidgets('2.3 Boundary: Empty and whitespace query strings revert to discovery view', (tester) async {
      setMobileView(tester);

      await tester.pumpWidget(createHomeHarness());
      await tester.pumpAndSettle();

      final searchField = find.byKey(const Key('home_search_field'));

      // Initial state: discovery view with sections
      expect(find.text('ĐANG CHIẾU'), findsOneWidget);
      expect(find.text('SẮP CHIẾU'), findsOneWidget);

      // Search some term first
      await tester.enterText(searchField, 'Mai');
      await tester.pumpAndSettle();
      expect(find.text('KẾT QUẢ TÌM KIẾM (1)'), findsOneWidget);
      expect(find.text('ĐANG CHIẾU'), findsNothing);

      // Whitespace variations
      final whitespaceInputs = ['', '   ', '\t', '\n', '   \t  '];
      for (final ws in whitespaceInputs) {
        await tester.enterText(searchField, ws);
        await tester.pumpAndSettle();

        // Must revert to discovery view (ĐANG CHIẾU present, search result header gone)
        expect(find.textContaining('KẾT QUẢ TÌM KIẾM'), findsNothing,
            reason: 'Whitespace-only query "$ws" should not trigger search mode');
        expect(find.text('ĐANG CHIẾU'), findsOneWidget);
      }

      // Test clear button functionality
      await tester.enterText(searchField, 'Deadpool');
      await tester.pumpAndSettle();
      expect(find.text('KẾT QUẢ TÌM KIẾM (1)'), findsOneWidget);

      // Find and tap clear button (Icons.clear)
      final clearBtn = find.byIcon(Icons.clear);
      expect(clearBtn, findsOneWidget);
      await tester.tap(clearBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('KẾT QUẢ TÌM KIẾM'), findsNothing);
      expect(find.text('ĐANG CHIẾU'), findsOneWidget);
    });
  });

  group('Group 3: CustomerBottomNav Guest Interception Tests', () {
    late MockAuthProvider mockAuth;

    setUp(() {
      mockAuth = MockAuthProvider();
    });

    Widget createNavHarness({
      required int currentIndex,
    }) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: mockAuth),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          onGenerateRoute: (settings) {
            return MaterialPageRoute(
              builder: (_) => Scaffold(
                body: Text('DESTINATION: ${settings.name} | ARGS: ${settings.arguments}'),
              ),
              settings: settings,
            );
          },
          home: Scaffold(
            bottomNavigationBar: CustomerBottomNav(currentIndex: currentIndex),
          ),
        ),
      );
    }

    testWidgets('3.1a Authenticated User: Tapping VÉ CỦA TÔI navigates directly to feature', (tester) async {
      mockAuth.currentUser = const AppUser(
        id: 'usr_auth_customer',
        fullName: 'Authenticated Customer',
        email: 'customer@cinema.vn',
        role: UserRole.customer,
      );

      await tester.pumpWidget(createNavHarness(currentIndex: 0));
      await tester.pumpAndSettle();

      await tester.tap(find.text('VÉ CỦA TÔI'));
      await tester.pumpAndSettle();

      expect(find.text('DESTINATION: /my-tickets | ARGS: null'), findsOneWidget);
    });

    testWidgets('3.1b Authenticated User: Tapping TÀI KHOẢN navigates directly to feature', (tester) async {
      mockAuth.currentUser = const AppUser(
        id: 'usr_auth_customer',
        fullName: 'Authenticated Customer',
        email: 'customer@cinema.vn',
        role: UserRole.customer,
      );

      await tester.pumpWidget(createNavHarness(currentIndex: 0));
      await tester.pumpAndSettle();

      await tester.tap(find.text('TÀI KHOẢN'));
      await tester.pumpAndSettle();

      expect(find.text('DESTINATION: /profile | ARGS: null'), findsOneWidget);
    });

    testWidgets('3.2 Guest Interception: Tapping VÉ CỦA TÔI intercepts and redirects to Login with deep link', (tester) async {
      mockAuth.currentUser = null; // GUEST USER

      await tester.pumpWidget(createNavHarness(currentIndex: 0));
      await tester.pumpAndSettle();

      await tester.tap(find.text('VÉ CỦA TÔI'));
      await tester.pumpAndSettle();

      // Verify guest is intercepted and routed to /login with redirectRoute set to /my-tickets
      expect(
        find.text('DESTINATION: /login | ARGS: {redirectRoute: /my-tickets}'),
        findsOneWidget,
        reason: 'Guest tapping VÉ CỦA TÔI must be intercepted and routed to login with redirectRoute',
      );
    });

    testWidgets('3.3 Guest Interception: Tapping TÀI KHOẢN intercepts and redirects to Login with deep link', (tester) async {
      mockAuth.currentUser = null; // GUEST USER

      await tester.pumpWidget(createNavHarness(currentIndex: 0));
      await tester.pumpAndSettle();

      await tester.tap(find.text('TÀI KHOẢN'));
      await tester.pumpAndSettle();

      // Verify guest is intercepted and routed to /login with redirectRoute set to /profile
      expect(
        find.text('DESTINATION: /login | ARGS: {redirectRoute: /profile}'),
        findsOneWidget,
        reason: 'Guest tapping TÀI KHOẢN must be intercepted and routed to login with redirectRoute',
      );
    });

    testWidgets('3.4a Unprotected Tabs: Guests can access RẠP without login prompt', (tester) async {
      mockAuth.currentUser = null; // GUEST USER

      await tester.pumpWidget(createNavHarness(currentIndex: 0));
      await tester.pumpAndSettle();

      await tester.tap(find.text('RẠP'));
      await tester.pumpAndSettle();

      expect(find.text('DESTINATION: /cinemas | ARGS: null'), findsOneWidget);
    });

    testWidgets('3.4b Unprotected Tabs: Guests can access PHIM without login prompt', (tester) async {
      mockAuth.currentUser = null; // GUEST USER

      await tester.pumpWidget(createNavHarness(currentIndex: 1));
      await tester.pumpAndSettle();

      await tester.tap(find.text('PHIM'));
      await tester.pumpAndSettle();

      expect(find.text('DESTINATION: /home | ARGS: null'), findsOneWidget);
    });

    testWidgets('3.5 Idempotence: Tapping currently active tab does nothing', (tester) async {
      mockAuth.currentUser = null;

      await tester.pumpWidget(createNavHarness(currentIndex: 0));
      await tester.pumpAndSettle();

      // Tapping 'PHIM' while already on Tab 0
      await tester.tap(find.text('PHIM'));
      await tester.pumpAndSettle();

      // Should not push any route
      expect(find.textContaining('DESTINATION:'), findsNothing);
    });
  });

  group('Group 4: RouteGuards Invariant Empirical Verification', () {
    test('4.1 requiresAuth returns true for all sensitive customer and internal routes', () {
      expect(RouteGuards.requiresAuth(AppRoutes.myTickets), isTrue);
      expect(RouteGuards.requiresAuth(AppRoutes.profile), isTrue);
      expect(RouteGuards.requiresAuth(AppRoutes.seatSelect), isTrue);
      expect(RouteGuards.requiresAuth(AppRoutes.foodSelect), isTrue);
      expect(RouteGuards.requiresAuth(AppRoutes.checkout), isTrue);
      expect(RouteGuards.requiresAuth(AppRoutes.staffCheckin), isTrue);
      expect(RouteGuards.requiresAuth(AppRoutes.dashboard), isTrue);
      expect(RouteGuards.requiresAuth(AppRoutes.managementHome), isTrue);

      // Public routes must return false
      expect(RouteGuards.requiresAuth(AppRoutes.home), isFalse);
      expect(RouteGuards.requiresAuth(AppRoutes.movieDetail), isFalse);
      expect(RouteGuards.requiresAuth(AppRoutes.cinemas), isFalse);
      expect(RouteGuards.requiresAuth(AppRoutes.cinemaDetail), isFalse);
      expect(RouteGuards.requiresAuth(AppRoutes.login), isFalse);
      expect(RouteGuards.requiresAuth(AppRoutes.register), isFalse);
    });

    test('4.2 getInitialRoute correctly segregates locked users and roles', () {
      // Guest
      expect(RouteGuards.getInitialRoute(null), AppRoutes.home);

      // Locked account (regardless of role)
      const lockedCustomer = AppUser(
        id: 'u1',
        fullName: 'Locked',
        email: 'locked@cinema.vn',
        role: UserRole.customer,
        isLocked: true,
      );
      expect(RouteGuards.getInitialRoute(lockedCustomer), AppRoutes.login);

      const lockedManager = AppUser(
        id: 'u2',
        fullName: 'Locked Mgr',
        email: 'lmgr@cinema.vn',
        role: UserRole.manager,
        isLocked: true,
      );
      expect(RouteGuards.getInitialRoute(lockedManager), AppRoutes.login);

      // Active customer
      const activeCustomer = AppUser(
        id: 'u3',
        fullName: 'Cust',
        email: 'cust@cinema.vn',
        role: UserRole.customer,
      );
      expect(RouteGuards.getInitialRoute(activeCustomer), AppRoutes.home);

      // Active staff
      const activeStaff = AppUser(
        id: 'u4',
        fullName: 'Staff',
        email: 'staff@cinema.vn',
        role: UserRole.staff,
      );
      expect(RouteGuards.getInitialRoute(activeStaff), AppRoutes.staffCheckin);

      // Active manager
      const activeManager = AppUser(
        id: 'u5',
        fullName: 'Manager',
        email: 'mgr@cinema.vn',
        role: UserRole.manager,
      );
      expect(RouteGuards.getInitialRoute(activeManager), AppRoutes.dashboard);

      // Active admin
      const activeAdmin = AppUser(
        id: 'u6',
        fullName: 'Admin',
        email: 'admin@cinema.vn',
        role: UserRole.admin,
      );
      expect(RouteGuards.getInitialRoute(activeAdmin), AppRoutes.dashboard);
    });
  });
}
