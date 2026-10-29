import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cinema_booking_v1/core/routes/app_router.dart';
import 'package:cinema_booking_v1/core/theme/app_theme.dart';
import 'package:cinema_booking_v1/features/auth/presentation/controllers/auth_provider.dart';
import 'package:cinema_booking_v1/features/management/data/repositories/management_repository.dart';
import 'package:cinema_booking_v1/features/management/presentation/controllers/management_provider.dart';
import 'package:cinema_booking_v1/features/management/presentation/screens/staff_accounts_screen.dart';
import 'package:cinema_booking_v1/shared/models/app_user.dart';

class MockManagementRepository extends ManagementRepository {
  List<AppUser> mockEmployees = [];
  bool shouldThrowGetEmployees = false;
  bool shouldThrowCreateStaff = false;
  bool shouldThrowToggleLock = false;

  Map<String, dynamic>? lastCreatedStaff;
  Map<String, dynamic>? lastToggledUser;

  MockManagementRepository() : super(null);

  @override
  Future<List<AppUser>> getEmployees(String cinemaId) async {
    if (shouldThrowGetEmployees) {
      throw Exception('DB_FETCH_EMPLOYEES_ERROR');
    }
    return List.from(mockEmployees);
  }

  @override
  Future<Map<String, dynamic>> createStaff({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
    required String cinemaId,
  }) async {
    if (shouldThrowCreateStaff) {
      throw Exception('EMAIL_ALREADY_EXISTS');
    }
    lastCreatedStaff = {
      'email': email,
      'password': password,
      'fullName': fullName,
      'phone': phone,
      'role': role,
      'cinemaId': cinemaId,
    };
    return {'success': true, 'email': email};
  }

  @override
  Future<void> toggleUserLock(String userId, bool isLocked) async {
    if (shouldThrowToggleLock) {
      throw Exception('LOCK_TOGGLE_FAILED');
    }
    lastToggledUser = {
      'userId': userId,
      'isLocked': isLocked,
    };
    final index = mockEmployees.indexWhere((u) => u.id == userId);
    if (index != -1) {
      mockEmployees[index] = mockEmployees[index].copyWith(isLocked: isLocked);
    }
  }
}

class FakeManagerAuthProvider extends ChangeNotifier implements AuthProvider {
  final AppUser _user = const AppUser(
    id: 'manager_1',
    fullName: 'Quản Lý Rạp',
    role: UserRole.manager,
    cinemaId: 'cn_q1',
  );

  @override
  AppUser? get currentUser => _user;

  @override
  bool get isAuthenticated => true;

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
  Future<void> signOut() async {}

  @override
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async =>
      true;

  @override
  Future<bool> updateProfile({required String fullName, String? phone}) async => true;
}

Widget createManagementTestHarness({
  required ManagementProvider managementProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: FakeManagerAuthProvider()),
      ChangeNotifierProvider<ManagementProvider>.value(value: managementProvider),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.manageEmployees || settings.name == '/') {
          return MaterialPageRoute(builder: (_) => const StaffAccountsScreen());
        }
        return MaterialPageRoute(
          builder: (_) => Scaffold(body: Text('ROUTE: ${settings.name}')),
        );
      },
      home: const StaffAccountsScreen(),
    ),
  );
}

void main() {
  group('S23 Staff Accounts Screen Widget Tests', () {
    late MockManagementRepository mockRepo;
    late ManagementProvider mgmtProvider;

    setUp(() {
      mockRepo = MockManagementRepository();
      mgmtProvider = ManagementProvider(mockRepo);
    });

    testWidgets('renders empty state when no employees exist', (tester) async {
      mockRepo.mockEmployees = [];

      await tester.pumpWidget(createManagementTestHarness(managementProvider: mgmtProvider));
      await tester.pumpAndSettle();

      expect(find.text('QUẢN LÝ NHÂN VIÊN'), findsOneWidget);
      expect(find.text('CN_Q1'), findsOneWidget);
      expect(find.text('CHƯA CÓ NHÂN VIÊN'), findsOneWidget);
      expect(find.text('THÊM NHÂN VIÊN'), findsOneWidget);
      expect(find.byKey(const Key('add_staff_fab')), findsOneWidget);
    });

    testWidgets('renders error state when loading fails and retries successfully', (tester) async {
      mockRepo.shouldThrowGetEmployees = true;

      await tester.pumpWidget(createManagementTestHarness(managementProvider: mgmtProvider));
      await tester.pumpAndSettle();

      expect(find.textContaining('Không thể tải danh sách nhân viên'), findsOneWidget);
      expect(find.text('THỬ LẠI'), findsOneWidget);

      // Now fix repo and retry
      mockRepo.shouldThrowGetEmployees = false;
      mockRepo.mockEmployees = [
        const AppUser(
          id: 'emp_1',
          fullName: 'Nguyễn Văn A',
          email: 'nva@cinema.vn',
          phone: '0901234567',
          role: UserRole.staff,
          cinemaId: 'cn_q1',
        ),
      ];

      await tester.tap(find.text('THỬ LẠI'));
      await tester.pumpAndSettle();

      expect(find.text('Nguyễn Văn A'), findsOneWidget);
      expect(find.text('nva@cinema.vn'), findsOneWidget);
    });

    testWidgets('renders employee list with role badges, contact info, and status', (tester) async {
      mockRepo.mockEmployees = [
        const AppUser(
          id: 'emp_staff',
          fullName: 'Lê Văn Staff',
          email: 'staff@cinema.vn',
          phone: '0911222333',
          role: UserRole.staff,
          cinemaId: 'cn_q1',
          isLocked: false,
        ),
        const AppUser(
          id: 'emp_manager',
          fullName: 'Trần Thị Manager',
          email: 'manager@cinema.vn',
          phone: '0988777666',
          role: UserRole.manager,
          cinemaId: 'cn_q1',
          isLocked: true,
        ),
      ];

      await tester.pumpWidget(createManagementTestHarness(managementProvider: mgmtProvider));
      await tester.pumpAndSettle();

      expect(find.text('Lê Văn Staff'), findsOneWidget);
      expect(find.text('STAFF'), findsOneWidget);
      expect(find.text('KHÓA'), findsOneWidget);

      expect(find.text('Trần Thị Manager'), findsOneWidget);
      expect(find.text('MANAGER'), findsOneWidget);
      expect(find.text('MỞ KHÓA'), findsOneWidget);
    });

    testWidgets('toggle lock shows confirmation modal and invokes toggleUserLock', (tester) async {
      mockRepo.mockEmployees = [
        const AppUser(
          id: 'emp_staff',
          fullName: 'Lê Văn Staff',
          email: 'staff@cinema.vn',
          role: UserRole.staff,
          cinemaId: 'cn_q1',
          isLocked: false,
        ),
      ];

      await tester.pumpWidget(createManagementTestHarness(managementProvider: mgmtProvider));
      await tester.pumpAndSettle();

      // Tap KHÓA
      await tester.tap(find.byKey(const Key('toggle_lock_emp_staff')));
      await tester.pumpAndSettle();

      // Modal dialog appears
      expect(find.text('KHÓA TÀI KHOẢN'), findsOneWidget);
      expect(find.textContaining('Bạn có chắc chắn muốn KHÓA tài khoản "Lê Văn Staff"'), findsOneWidget);

      // Confirm
      await tester.tap(find.text('XÁC NHẬN'));
      await tester.pumpAndSettle();

      expect(mockRepo.lastToggledUser?['userId'], 'emp_staff');
      expect(mockRepo.lastToggledUser?['isLocked'], true);
      expect(find.text('ĐÃ KHÓA TÀI KHOẢN THÀNH CÔNG'), findsOneWidget);
    });

    testWidgets('add staff modal validation error when required fields are missing', (tester) async {
      mockRepo.mockEmployees = [];

      await tester.pumpWidget(createManagementTestHarness(managementProvider: mgmtProvider));
      await tester.pumpAndSettle();

      // Tap FAB to open modal
      await tester.tap(find.byKey(const Key('add_staff_fab')));
      await tester.pumpAndSettle();

      expect(find.text('THÊM TÀI KHOẢN NHÂN SỰ'), findsOneWidget);

      // Submit immediately without filling
      await tester.ensureVisible(find.byKey(const Key('add_staff_submit_btn')));
      await tester.tap(find.byKey(const Key('add_staff_submit_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng điền đủ thông tin (Mật khẩu >= 6 ký tự)'), findsOneWidget);
    });

    testWidgets('add staff modal submits successfully via Edge Function create-staff', (tester) async {
      mockRepo.mockEmployees = [];

      await tester.pumpWidget(createManagementTestHarness(managementProvider: mgmtProvider));
      await tester.pumpAndSettle();

      // Tap appbar action icon to open modal
      await tester.tap(find.byKey(const Key('add_staff_appbar_btn')));
      await tester.pumpAndSettle();

      // Enter details
      await tester.enterText(find.byKey(const Key('add_staff_name_field')), 'Đặng Văn C');
      await tester.enterText(find.byKey(const Key('add_staff_email_field')), 'dvc@cinema.vn');
      await tester.enterText(find.byKey(const Key('add_staff_phone_field')), '0933445566');
      await tester.enterText(find.byKey(const Key('add_staff_password_field')), 'Secret123');

      // Select MANAGER role chip
      await tester.tap(find.text('MANAGER'));
      await tester.pumpAndSettle();

      // Submit
      await tester.ensureVisible(find.byKey(const Key('add_staff_submit_btn')));
      await tester.tap(find.byKey(const Key('add_staff_submit_btn')));
      await tester.pumpAndSettle();

      expect(mockRepo.lastCreatedStaff?['email'], 'dvc@cinema.vn');
      expect(mockRepo.lastCreatedStaff?['fullName'], 'Đặng Văn C');
      expect(mockRepo.lastCreatedStaff?['phone'], '0933445566');
      expect(mockRepo.lastCreatedStaff?['password'], 'Secret123');
      expect(mockRepo.lastCreatedStaff?['role'], 'manager');
      expect(mockRepo.lastCreatedStaff?['cinemaId'], 'cn_q1');

      expect(find.text('TẠO TÀI KHOẢN NHÂN SỰ THÀNH CÔNG'), findsOneWidget);
    });
  });
}
