import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cinema_booking_v1/core/routes/app_router.dart';
import 'package:cinema_booking_v1/core/theme/app_theme.dart';
import 'package:cinema_booking_v1/features/auth/presentation/controllers/auth_provider.dart';
import 'package:cinema_booking_v1/features/auth/presentation/screens/login_screen.dart';
import 'package:cinema_booking_v1/shared/models/app_user.dart';

class FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  AppUser? _currentUser;
  AuthStatus _status = AuthStatus.unauthenticated;
  String? _errorMessage;
  bool signInResult = true;
  bool signOutCalled = false;
  String? lastEmail;
  String? lastPassword;

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
    lastEmail = email;
    lastPassword = password;
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
    return true;
  }

  @override
  Future<void> signOut() async {
    signOutCalled = true;
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

Widget createLoginTestHarness({
  required FakeAuthProvider authProvider,
  String? redirectRoute,
  Map<String, WidgetBuilder>? customRoutes,
}) {
  return ChangeNotifierProvider<AuthProvider>.value(
    value: authProvider,
    child: MaterialApp(
      theme: AppTheme.dark,
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.login || settings.name == '/') {
          return MaterialPageRoute(
            builder: (_) => LoginScreen(redirectRoute: redirectRoute),
          );
        }
        if (customRoutes != null && customRoutes.containsKey(settings.name)) {
          return MaterialPageRoute(builder: customRoutes[settings.name]!);
        }
        return MaterialPageRoute(
          builder: (_) => Scaffold(body: Text('ROUTE: ${settings.name}')),
        );
      },
      home: LoginScreen(redirectRoute: redirectRoute),
    ),
  );
}

void main() {
  group('S01 Login Screen Widget Tests', () {
    late FakeAuthProvider fakeAuth;

    setUp(() {
      fakeAuth = FakeAuthProvider();
    });

    testWidgets('renders all essential login elements', (tester) async {
      await tester.pumpWidget(createLoginTestHarness(authProvider: fakeAuth));

      expect(find.text('CINEMA STAR'), findsOneWidget);
      expect(find.text('ĐĂNG NHẬP'), findsAtLeastNWidgets(1));
      expect(find.byKey(const Key('login_email_field')), findsOneWidget);
      expect(find.byKey(const Key('login_password_field')), findsOneWidget);
      expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
      expect(find.byKey(const Key('login_to_register_button')), findsOneWidget);
      expect(find.byKey(const Key('login_guest_button')), findsOneWidget);
    });

    testWidgets('shows validation errors when fields are empty', (tester) async {
      await tester.pumpWidget(createLoginTestHarness(authProvider: fakeAuth));

      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập email'), findsOneWidget);
      expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
    });

    testWidgets('validates invalid email format', (tester) async {
      await tester.pumpWidget(createLoginTestHarness(authProvider: fakeAuth));

      await tester.enterText(
        find.byKey(const Key('login_email_field')),
        'invalid-email',
      );
      await tester.enterText(
        find.byKey(const Key('login_password_field')),
        '123456',
      );
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Email không hợp lệ'), findsOneWidget);
    });

    testWidgets('validates password length >= 6', (tester) async {
      await tester.pumpWidget(createLoginTestHarness(authProvider: fakeAuth));

      await tester.enterText(
        find.byKey(const Key('login_email_field')),
        'user@cinema.vn',
      );
      await tester.enterText(
        find.byKey(const Key('login_password_field')),
        '123',
      );
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Mật khẩu phải từ 6 ký tự trở lên'), findsOneWidget);
    });

    testWidgets('routes Customer to S03 Home upon login', (tester) async {
      fakeAuth.currentUser = const AppUser(
        id: 'usr_c1',
        fullName: 'Khách Hàng',
        role: UserRole.customer,
      );

      await tester.pumpWidget(createLoginTestHarness(authProvider: fakeAuth));

      await tester.enterText(
        find.byKey(const Key('login_email_field')),
        'khach1@cinema.vn',
      );
      await tester.enterText(
        find.byKey(const Key('login_password_field')),
        '123456',
      );
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('ROUTE: ${AppRoutes.home}'), findsOneWidget);
    });

    testWidgets('routes Staff to S18 Checkin upon login', (tester) async {
      fakeAuth.currentUser = const AppUser(
        id: 'usr_s1',
        fullName: 'Nhân Viên',
        role: UserRole.staff,
        cinemaId: 'cn_q1',
      );

      await tester.pumpWidget(createLoginTestHarness(authProvider: fakeAuth));

      await tester.enterText(
        find.byKey(const Key('login_email_field')),
        'staff1@cinema.vn',
      );
      await tester.enterText(
        find.byKey(const Key('login_password_field')),
        '123456',
      );
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('ROUTE: ${AppRoutes.staffCheckin}'), findsOneWidget);
    });

    testWidgets('routes Manager to S22 Dashboard upon login', (tester) async {
      fakeAuth.currentUser = const AppUser(
        id: 'usr_m1',
        fullName: 'Quản Lý',
        role: UserRole.manager,
        cinemaId: 'cn_q1',
      );

      await tester.pumpWidget(createLoginTestHarness(authProvider: fakeAuth));

      await tester.enterText(
        find.byKey(const Key('login_email_field')),
        'manager1@cinema.vn',
      );
      await tester.enterText(
        find.byKey(const Key('login_password_field')),
        '123456',
      );
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('ROUTE: ${AppRoutes.dashboard}'), findsOneWidget);
    });

    testWidgets('routes Admin to S12 Management Menu upon login', (tester) async {
      fakeAuth.currentUser = const AppUser(
        id: 'usr_a1',
        fullName: 'Quản Trị Viên',
        role: UserRole.admin,
      );

      await tester.pumpWidget(createLoginTestHarness(authProvider: fakeAuth));

      await tester.enterText(
        find.byKey(const Key('login_email_field')),
        'admin1@cinema.vn',
      );
      await tester.enterText(
        find.byKey(const Key('login_password_field')),
        '123456',
      );
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('ROUTE: ${AppRoutes.managementHome}'), findsOneWidget);
    });

    testWidgets('locked account shows warning and triggers signOut', (tester) async {
      fakeAuth.currentUser = const AppUser(
        id: 'usr_locked',
        fullName: 'Tài Khoản Bị Khóa',
        role: UserRole.customer,
        isLocked: true,
      );

      await tester.pumpWidget(createLoginTestHarness(authProvider: fakeAuth));

      await tester.enterText(
        find.byKey(const Key('login_email_field')),
        'locked@cinema.vn',
      );
      await tester.enterText(
        find.byKey(const Key('login_password_field')),
        '123456',
      );
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      expect(
        find.text('Tài khoản của bạn đã bị khóa. Vui lòng liên hệ ban quản lý.'),
        findsOneWidget,
      );
      expect(fakeAuth.signOutCalled, isTrue);
    });

    testWidgets('guest button routes directly to S03 Home', (tester) async {
      await tester.pumpWidget(createLoginTestHarness(authProvider: fakeAuth));

      await tester.tap(find.byKey(const Key('login_guest_button')));
      await tester.pumpAndSettle();

      expect(find.text('ROUTE: ${AppRoutes.home}'), findsOneWidget);
    });
  });
}
