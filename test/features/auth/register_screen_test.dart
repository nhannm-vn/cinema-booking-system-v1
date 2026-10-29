import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cinema_booking_v1/core/routes/app_router.dart';
import 'package:cinema_booking_v1/core/theme/app_theme.dart';
import 'package:cinema_booking_v1/features/auth/presentation/controllers/auth_provider.dart';
import 'package:cinema_booking_v1/features/auth/presentation/screens/register_screen.dart';
import 'package:cinema_booking_v1/shared/models/app_user.dart';

class FakeRegisterAuthProvider extends ChangeNotifier implements AuthProvider {
  AppUser? _currentUser;
  AuthStatus _status = AuthStatus.unauthenticated;
  String? _errorMessage;
  bool signUpResult = true;
  String? lastRegisteredEmail;
  String? lastRegisteredName;
  String? lastRegisteredPhone;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  AuthStatus get status => _status;

  @override
  bool get isAuthenticated => _currentUser != null;

  @override
  bool get isLoading => _status == AuthStatus.loading;

  @override
  String? get errorMessage => _errorMessage;

  @override
  Future<bool> signIn(String email, String password) async => true;

  @override
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    lastRegisteredEmail = email;
    lastRegisteredName = fullName;
    lastRegisteredPhone = phone;

    if (signUpResult) {
      _currentUser = AppUser(
        id: 'usr_new',
        fullName: fullName,
        email: email,
        phone: phone,
        role: UserRole.customer,
      );
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } else {
      _errorMessage = 'Email đã tồn tại trong hệ thống.';
      notifyListeners();
      return false;
    }
  }

  @override
  Future<bool> updateProfile({required String fullName, String? phone}) async {
    return true;
  }

  @override
  Future<void> signOut() async {}

  @override
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

Widget createRegisterTestHarness({
  required FakeRegisterAuthProvider authProvider,
  String? redirectRoute,
}) {
  return ChangeNotifierProvider<AuthProvider>.value(
    value: authProvider,
    child: MaterialApp(
      theme: AppTheme.dark,
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) => Scaffold(body: Text('ROUTE: ${settings.name}')),
        );
      },
      home: RegisterScreen(redirectRoute: redirectRoute),
    ),
  );
}

void main() {
  group('S02 Register Screen Widget Tests', () {
    late FakeRegisterAuthProvider fakeAuth;

    void setMobileView(WidgetTester tester) {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    setUp(() {
      fakeAuth = FakeRegisterAuthProvider();
    });

    testWidgets('renders all register form fields and labels', (tester) async {
      setMobileView(tester);
      await tester.pumpWidget(createRegisterTestHarness(authProvider: fakeAuth));

      expect(find.text('TẠO TÀI KHOẢN'), findsNWidgets(2)); // Title and Button
      expect(find.byKey(const Key('register_name_field')), findsOneWidget);
      expect(find.byKey(const Key('register_email_field')), findsOneWidget);
      expect(find.byKey(const Key('register_phone_field')), findsOneWidget);
      expect(find.byKey(const Key('register_password_field')), findsOneWidget);
      expect(find.byKey(const Key('register_confirm_password_field')), findsOneWidget);
      expect(find.byKey(const Key('register_submit_button')), findsOneWidget);
    });

    testWidgets('validates full name minimum length', (tester) async {
      setMobileView(tester);
      await tester.pumpWidget(createRegisterTestHarness(authProvider: fakeAuth));

      await tester.enterText(find.byKey(const Key('register_name_field')), 'A');
      await tester.tap(find.byKey(const Key('register_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Họ và tên phải từ 2 ký tự trở lên'), findsOneWidget);
    });

    testWidgets('validates 10-digit phone starting with 0', (tester) async {
      setMobileView(tester);
      await tester.pumpWidget(createRegisterTestHarness(authProvider: fakeAuth));

      // Test with 9 digits
      await tester.enterText(find.byKey(const Key('register_phone_field')), '090123456');
      await tester.tap(find.byKey(const Key('register_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Số điện thoại phải gồm 10 chữ số bắt đầu bằng số 0'), findsOneWidget);

      // Test with letters
      await tester.enterText(find.byKey(const Key('register_phone_field')), '090123456A');
      await tester.tap(find.byKey(const Key('register_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Số điện thoại phải gồm 10 chữ số bắt đầu bằng số 0'), findsOneWidget);
    });

    testWidgets('validates password confirmation match', (tester) async {
      setMobileView(tester);
      await tester.pumpWidget(createRegisterTestHarness(authProvider: fakeAuth));

      await tester.enterText(find.byKey(const Key('register_password_field')), 'password123');
      await tester.enterText(find.byKey(const Key('register_confirm_password_field')), 'password999');
      await tester.tap(find.byKey(const Key('register_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Mật khẩu xác nhận không khớp'), findsOneWidget);
    });

    testWidgets('successful registration calls signUp and routes to Home', (tester) async {
      setMobileView(tester);
      await tester.pumpWidget(createRegisterTestHarness(authProvider: fakeAuth));

      await tester.enterText(find.byKey(const Key('register_name_field')), 'Nguyễn Văn A');
      await tester.enterText(find.byKey(const Key('register_email_field')), 'nguyenvana@cinema.vn');
      await tester.enterText(find.byKey(const Key('register_phone_field')), '0912345678');
      await tester.enterText(find.byKey(const Key('register_password_field')), 'secure123');
      await tester.enterText(find.byKey(const Key('register_confirm_password_field')), 'secure123');

      await tester.tap(find.byKey(const Key('register_submit_button')));
      await tester.pumpAndSettle();

      expect(fakeAuth.lastRegisteredName, 'Nguyễn Văn A');
      expect(fakeAuth.lastRegisteredEmail, 'nguyenvana@cinema.vn');
      expect(fakeAuth.lastRegisteredPhone, '0912345678');
      expect(find.text('ROUTE: ${AppRoutes.home}'), findsOneWidget);
    });

    testWidgets('shows error banner on registration failure', (tester) async {
      setMobileView(tester);
      fakeAuth.signUpResult = false;
      await tester.pumpWidget(createRegisterTestHarness(authProvider: fakeAuth));

      await tester.enterText(find.byKey(const Key('register_name_field')), 'Nguyễn Văn A');
      await tester.enterText(find.byKey(const Key('register_email_field')), 'existing@cinema.vn');
      await tester.enterText(find.byKey(const Key('register_phone_field')), '0912345678');
      await tester.enterText(find.byKey(const Key('register_password_field')), 'secure123');
      await tester.enterText(find.byKey(const Key('register_confirm_password_field')), 'secure123');

      await tester.tap(find.byKey(const Key('register_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Email đã tồn tại trong hệ thống.'), findsOneWidget);
    });
  });
}
