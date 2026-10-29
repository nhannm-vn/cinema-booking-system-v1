import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cinema_booking_v1/core/theme/app_theme.dart';
import 'package:cinema_booking_v1/features/auth/presentation/controllers/auth_provider.dart';
import 'package:cinema_booking_v1/features/staff_checkin/data/checkin_repository.dart';
import 'package:cinema_booking_v1/features/staff_checkin/presentation/controllers/checkin_provider.dart';
import 'package:cinema_booking_v1/features/staff_checkin/presentation/screens/ticket_checkin_screen.dart';
import 'package:cinema_booking_v1/shared/models/app_user.dart';

class MockCheckinRepository implements CheckinRepository {
  CheckinResult? nextResult;

  @override
  Future<CheckinResult> checkIn(String bookingCode) async {
    if (nextResult != null) return nextResult!;

    if (bookingCode == 'VALID001') {
      return const CheckinResult(
        isSuccess: true,
        message: 'Soát vé thành công',
        code: 'VALID001',
        movieTitle: 'Dune: Hành Tinh Cát 2',
        roomName: 'Phòng 1',
        showtimeStart: '19:00',
        seatsSummary: 'A1, A2',
        foodsSummary: '1x Bắp Ngọt, 1x Coca-Cola',
        ageRating: 'P',
      );
    } else if (bookingCode == 'AGE18XYZ') {
      return const CheckinResult(
        isSuccess: true,
        message: 'Soát vé thành công',
        code: 'AGE18XYZ',
        movieTitle: 'Deadpool & Wolverine',
        roomName: 'Phòng IMAX',
        showtimeStart: '20:30',
        seatsSummary: 'C5, C6',
        foodsSummary: '',
        ageRating: 'T18',
      );
    } else if (bookingCode == 'WRONG_CN') {
      return const CheckinResult(
        isSuccess: false,
        errorCode: 'WRONG_CINEMA',
        message: 'Vé thuộc rạp khác (Cinema Thủ Đức)',
      );
    } else {
      return const CheckinResult(
        isSuccess: false,
        errorCode: 'NOT_FOUND',
        message: 'Mã vé không tồn tại trong hệ thống',
      );
    }
  }
}

class FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  AppUser? _user = const AppUser(
    id: 'staff_1',
    fullName: 'Nhân viên A',
    role: UserRole.staff,
    cinemaId: 'cn_q1',
  );

  @override
  AppUser? get currentUser => _user;

  @override
  bool get isAuthenticated => _user != null;

  @override
  bool get isLoading => false;

  @override
  AuthStatus get status => AuthStatus.authenticated;

  @override
  String? get errorMessage => null;

  @override
  void clearError() {}

  @override
  Future<bool> signIn(String email, String password) async => true;

  @override
  Future<void> signOut() async {
    _user = null;
    notifyListeners();
  }

  @override
  Future<bool> signUp({required String email, required String password, required String fullName, String? phone}) async => true;

  @override
  Future<bool> updateProfile({required String fullName, String? phone}) async => true;
}

Widget createCheckinTestHarness({
  required CheckinProvider checkinProvider,
  AuthProvider? authProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider ?? FakeAuthProvider()),
      ChangeNotifierProvider<CheckinProvider>.value(value: checkinProvider),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      home: const TicketCheckinScreen(forceDesktopFallback: true),
    ),
  );
}

void main() {
  group('CheckinProvider Unit Tests', () {
    late MockCheckinRepository mockRepo;
    late CheckinProvider provider;

    setUp(() {
      mockRepo = MockCheckinRepository();
      provider = CheckinProvider(mockRepo);
    });

    test('initial state is clean', () {
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
      expect(provider.lastResult, isNull);
      expect(provider.isIdVerified, isFalse);
      expect(provider.currentScannedCode, isNull);
    });

    test('checkIn normalizes input code and captures success result', () async {
      final res = await provider.checkIn(' valid001 ');

      expect(provider.currentScannedCode, 'VALID001');
      expect(res.isSuccess, isTrue);
      expect(res.movieTitle, 'Dune: Hành Tinh Cát 2');
      expect(provider.lastResult, res);
      expect(provider.isLoading, isFalse);
    });

    test('checkIn captures failure result on invalid code', () async {
      final res = await provider.checkIn('WRONG_CN');

      expect(res.isSuccess, isFalse);
      expect(res.message, contains('Cinema Thủ Đức'));
      expect(provider.lastResult?.isSuccess, isFalse);
    });

    test('setIdVerified updates verified flag', () {
      expect(provider.isIdVerified, isFalse);
      provider.setIdVerified(true);
      expect(provider.isIdVerified, isTrue);
      provider.setIdVerified(false);
      expect(provider.isIdVerified, isFalse);
    });

    test('resetScan clears state completely', () async {
      await provider.checkIn('VALID001');
      provider.setIdVerified(true);

      provider.resetScan();
      expect(provider.lastResult, isNull);
      expect(provider.currentScannedCode, isNull);
      expect(provider.isIdVerified, isFalse);
      expect(provider.errorMessage, isNull);
    });
  });

  group('S18 Ticket Check-in Screen Widget Tests', () {
    late MockCheckinRepository mockRepo;
    late CheckinProvider checkinProvider;
    late FakeAuthProvider fakeAuth;

    setUp(() {
      mockRepo = MockCheckinRepository();
      checkinProvider = CheckinProvider(mockRepo);
      fakeAuth = FakeAuthProvider();
    });

    testWidgets('renders screen headers, desktop scanner fallback, and bottom nav', (tester) async {
      await tester.pumpWidget(createCheckinTestHarness(
        checkinProvider: checkinProvider,
        authProvider: fakeAuth,
      ));

      expect(find.text('SOÁT VÉ VÀO RẠP'), findsOneWidget);
      expect(find.text('CN_Q1'), findsOneWidget);
      expect(find.text('CAMERA KHÔNG KHẢ DỤNG TRÊN THIẾT BỊ NÀY'), findsOneWidget);
      expect(find.byKey(const Key('ticket_checkin_manual_input_btn')), findsOneWidget);

      // Verify 4 Staff Bottom Nav tabs
      expect(find.text('SOÁT VÉ'), findsOneWidget);
      expect(find.text('ĐỒ ĂN'), findsOneWidget);
      expect(find.text('BÁN VÉ'), findsOneWidget);
      expect(find.text('TÀI KHOẢN'), findsOneWidget);
    });

    testWidgets('opens manual input dialog and validates non-existent ticket', (tester) async {
      await tester.pumpWidget(createCheckinTestHarness(
        checkinProvider: checkinProvider,
        authProvider: fakeAuth,
      ));

      // Tap manual input button
      await tester.tap(find.byKey(const Key('ticket_checkin_manual_input_btn')));
      await tester.pumpAndSettle();

      expect(find.text('NHẬP MÃ VÉ THỦ CÔNG'), findsOneWidget);
      expect(find.byKey(const Key('manual_code_input')), findsOneWidget);
      expect(find.byKey(const Key('manual_code_submit')), findsOneWidget);

      // Enter unknown code
      await tester.enterText(find.byKey(const Key('manual_code_input')), 'UNKNOWN1');
      await tester.tap(find.byKey(const Key('manual_code_submit')));
      await tester.pumpAndSettle();

      // Result sheet shows invalid ticket
      expect(find.text('VÉ KHÔNG HỢP LỆ'), findsOneWidget);
      expect(find.text('Mã vé không tồn tại trong hệ thống'), findsOneWidget);
      expect(find.text('QUÉT TIẾP'), findsOneWidget);

      // Dismiss
      await tester.tap(find.text('QUÉT TIẾP'));
      await tester.pumpAndSettle();
      expect(find.text('VÉ KHÔNG HỢP LỆ'), findsNothing);
    });

    testWidgets('verifies valid ticket and confirms entry', (tester) async {
      await tester.pumpWidget(createCheckinTestHarness(
        checkinProvider: checkinProvider,
        authProvider: fakeAuth,
      ));

      // Tap manual input
      await tester.tap(find.byKey(const Key('ticket_checkin_manual_input_btn')));
      await tester.pumpAndSettle();

      // Enter valid code
      await tester.enterText(find.byKey(const Key('manual_code_input')), 'VALID001');
      await tester.tap(find.byKey(const Key('manual_code_submit')));
      await tester.pumpAndSettle();

      // Valid result sheet
      expect(find.text('VÉ HỢP LỆ'), findsOneWidget);
      expect(find.text('Dune: Hành Tinh Cát 2'), findsOneWidget);
      expect(find.text('GHẾ: A1, A2'), findsOneWidget);
      expect(find.text('ĐỒ ĂN: 1x Bắp Ngọt, 1x Coca-Cola'), findsOneWidget);
      expect(find.text('XÁC NHẬN CHO VÀO'), findsOneWidget);

      // Confirm
      await tester.tap(find.text('XÁC NHẬN CHO VÀO'));
      await tester.pumpAndSettle();

      expect(find.text('ĐÃ XÁC NHẬN CHO KHÁCH VÀO RẠP'), findsOneWidget);
    });

    testWidgets('enforces age verification gating for T18 movie ticket', (tester) async {
      await tester.pumpWidget(createCheckinTestHarness(
        checkinProvider: checkinProvider,
        authProvider: fakeAuth,
      ));

      await tester.tap(find.byKey(const Key('ticket_checkin_manual_input_btn')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('manual_code_input')), 'AGE18XYZ');
      await tester.tap(find.byKey(const Key('manual_code_submit')));
      await tester.pumpAndSettle();

      expect(find.text('VÉ HỢP LỆ'), findsOneWidget);
      expect(find.text('Deadpool & Wolverine'), findsOneWidget);
      expect(find.text('Khán giả phim T18. Đã kiểm tra giấy tờ tùy thân hợp lệ.'), findsOneWidget);

      // Confirm button is initially disabled for T18 without checking ID
      final confirmBtn = tester.widget<ElevatedButton>(
        find.ancestor(of: find.text('XÁC NHẬN CHO VÀO'), matching: find.byType(ElevatedButton)),
      );
      expect(confirmBtn.onPressed, isNull);

      // Check ID checkbox
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      // Confirm button is now enabled
      final enabledBtn = tester.widget<ElevatedButton>(
        find.ancestor(of: find.text('XÁC NHẬN CHO VÀO'), matching: find.byType(ElevatedButton)),
      );
      expect(enabledBtn.onPressed, isNotNull);

      await tester.tap(find.text('XÁC NHẬN CHO VÀO'));
      await tester.pumpAndSettle();

      expect(find.text('ĐÃ XÁC NHẬN CHO KHÁCH VÀO RẠP'), findsOneWidget);
    });
  });
}
