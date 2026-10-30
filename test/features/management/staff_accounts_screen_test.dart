import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cinema_booking_v1/core/routes/app_router.dart';
import 'package:cinema_booking_v1/core/theme/app_theme.dart';
import 'package:cinema_booking_v1/features/auth/presentation/controllers/auth_provider.dart';
import 'package:cinema_booking_v1/features/management/data/repositories/management_repository.dart';
import 'package:cinema_booking_v1/features/management/presentation/controllers/management_provider.dart';
import 'package:cinema_booking_v1/features/management/presentation/screens/staff_accounts_screen.dart';
import 'package:cinema_booking_v1/features/cinemas/data/cinema_model.dart';
import 'package:cinema_booking_v1/shared/models/app_user.dart';

class MockManagementRepository extends ManagementRepository {
  List<AppUser> mockEmployees = [];
  List<CinemaModel> mockCinemas = [
    const CinemaModel(id: 'cn_q1', name: 'Rạp Quận 1', address: '123 Q1', phone: '0901', lat: 10.7, lng: 106.6),
    const CinemaModel(id: 'cn_tb', name: 'Rạp Tân Bình', address: '456 TB', phone: '0902', lat: 10.8, lng: 106.6),
  ];
  bool shouldThrowGetEmployees = false;
  bool shouldThrowCreateStaff = false;
  bool shouldThrowToggleLock = false;

  Map<String, dynamic>? lastCreatedStaff;
  Map<String, dynamic>? lastToggledUser;

  MockManagementRepository() : super(null);

  @override
  Future<List<CinemaModel>> getAllCinemas() async {
    return List.from(mockCinemas);
  }

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

class FakeAdminAuthProvider extends ChangeNotifier implements AuthProvider {
  final AppUser _user = const AppUser(
    id: 'admin_root',
    fullName: 'Tổng Quản Trị Hệ Thống',
    role: UserRole.admin,
    cinemaId: null,
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
  AuthProvider? authProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(
        value: authProvider ?? FakeManagerAuthProvider(),
      ),
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
          id: 'emp_staff_2',
          fullName: 'Trần Thị Staff 2',
          email: 'staff2@cinema.vn',
          phone: '0988777666',
          role: UserRole.staff,
          cinemaId: 'cn_q1',
          isLocked: true,
        ),
      ];

      await tester.pumpWidget(createManagementTestHarness(managementProvider: mgmtProvider));
      await tester.pumpAndSettle();

      expect(find.text('Lê Văn Staff'), findsOneWidget);
      expect(find.text('STAFF'), findsNWidgets(2));
      expect(find.text('KHÓA'), findsOneWidget);

      expect(find.text('Trần Thị Staff 2'), findsOneWidget);
      expect(find.text('MỞ KHÓA'), findsOneWidget);

      // Verify HR status badges instead of payment badges
      expect(find.text('ĐANG HOẠT ĐỘNG'), findsOneWidget);
      expect(find.text('ĐÃ KHÓA'), findsOneWidget);
      expect(find.text('ĐÃ THANH TOÁN'), findsNothing);
    });

    testWidgets('manager only manages staff: manager accounts are filtered out', (tester) async {
      mockRepo.mockEmployees = [
        const AppUser(
          id: 'emp_staff',
          fullName: 'Nhân Viên Soát Vé',
          email: 'staff@cinema.vn',
          role: UserRole.staff,
          cinemaId: 'cn_q1',
          isLocked: false,
        ),
        const AppUser(
          id: 'emp_manager_other',
          fullName: 'Quản Lý Đồng Nghiệp',
          email: 'manager2@cinema.vn',
          role: UserRole.manager,
          cinemaId: 'cn_q1',
          isLocked: false,
        ),
      ];

      await tester.pumpWidget(createManagementTestHarness(managementProvider: mgmtProvider));
      await tester.pumpAndSettle();

      // Only staff is displayed
      expect(find.text('Nhân Viên Soát Vé'), findsOneWidget);
      expect(find.text('Quản Lý Đồng Nghiệp'), findsNothing);
      expect(find.text('MANAGER'), findsNothing);
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

      // Submit with default STAFF role
      await tester.ensureVisible(find.byKey(const Key('add_staff_submit_btn')));
      await tester.tap(find.byKey(const Key('add_staff_submit_btn')));
      await tester.pumpAndSettle();

      expect(mockRepo.lastCreatedStaff?['email'], 'dvc@cinema.vn');
      expect(mockRepo.lastCreatedStaff?['fullName'], 'Đặng Văn C');
      expect(mockRepo.lastCreatedStaff?['phone'], '0933445566');
      expect(mockRepo.lastCreatedStaff?['password'], 'Secret123');
      expect(mockRepo.lastCreatedStaff?['role'], 'staff');
      expect(mockRepo.lastCreatedStaff?['cinemaId'], 'cn_q1');

      expect(find.text('TẠO TÀI KHOẢN NHÂN SỰ THÀNH CÔNG'), findsOneWidget);
    });

    testWidgets('admin role manages both managers and staff across cinemas and can filter', (tester) async {
      mockRepo.mockEmployees = [
        const AppUser(
          id: 'mgr_q1',
          fullName: 'Manager Quận 1',
          email: 'mgr.q1@cinema.vn',
          role: UserRole.manager,
          cinemaId: 'cn_q1',
          isLocked: false,
        ),
        const AppUser(
          id: 'staff_q1',
          fullName: 'Staff Quận 1',
          email: 'staff.q1@cinema.vn',
          role: UserRole.staff,
          cinemaId: 'cn_q1',
          isLocked: false,
        ),
        const AppUser(
          id: 'mgr_tb',
          fullName: 'Manager Tân Bình',
          email: 'mgr.tb@cinema.vn',
          role: UserRole.manager,
          cinemaId: 'cn_tb',
          isLocked: true,
        ),
      ];

      await tester.pumpWidget(createManagementTestHarness(
        managementProvider: mgmtProvider,
        authProvider: FakeAdminAuthProvider(),
      ));
      await tester.pumpAndSettle();

      // Verify Admin Appbar and cinema filter chips
      expect(find.text('QUẢN LÝ NHÂN SỰ'), findsOneWidget);
      expect(find.text('TẤT CẢ RẠP'), findsOneWidget);

      // Verify both Managers and Staff appear for Admin
      expect(find.text('Manager Quận 1'), findsOneWidget);
      expect(find.text('Staff Quận 1'), findsOneWidget);
      expect(find.text('Manager Tân Bình'), findsOneWidget);
      expect(find.text('MANAGER'), findsNWidgets(3)); // 1 filter ChoiceChip + 2 AppBadges
      expect(find.text('STAFF'), findsWidgets);

      // Verify filter by role: Tap MANAGER chip
      await tester.tap(find.widgetWithText(ChoiceChip, 'MANAGER').first);
      await tester.pumpAndSettle();

      expect(find.text('Manager Quận 1'), findsOneWidget);
      expect(find.text('Manager Tân Bình'), findsOneWidget);
      expect(find.text('Staff Quận 1'), findsNothing);

      // Tap STAFF chip
      await tester.tap(find.widgetWithText(ChoiceChip, 'STAFF').first);
      await tester.pumpAndSettle();

      expect(find.text('Staff Quận 1'), findsOneWidget);
      expect(find.text('Manager Quận 1'), findsNothing);
    });

    testWidgets('admin can create a MANAGER account and select cinema', (tester) async {
      mockRepo.mockEmployees = [];

      await tester.pumpWidget(createManagementTestHarness(
        managementProvider: mgmtProvider,
        authProvider: FakeAdminAuthProvider(),
      ));
      await tester.pumpAndSettle();

      // Open add employee modal
      await tester.tap(find.byKey(const Key('add_staff_appbar_btn')));
      await tester.pumpAndSettle();

      // Fill in details
      await tester.enterText(find.byKey(const Key('add_staff_name_field')), 'Quản Lý Mới');
      await tester.enterText(find.byKey(const Key('add_staff_email_field')), 'newmgr@cinema.vn');
      await tester.enterText(find.byKey(const Key('add_staff_password_field')), 'Pass1234');

      // Select MANAGER role in modal
      await tester.tap(find.widgetWithText(ChoiceChip, 'MANAGER').last);
      await tester.pumpAndSettle();

      // Submit
      await tester.ensureVisible(find.byKey(const Key('add_staff_submit_btn')));
      await tester.tap(find.byKey(const Key('add_staff_submit_btn')));
      await tester.pumpAndSettle();

      expect(mockRepo.lastCreatedStaff?['email'], 'newmgr@cinema.vn');
      expect(mockRepo.lastCreatedStaff?['role'], 'manager');
      expect(find.text('TẠO TÀI KHOẢN NHÂN SỰ THÀNH CÔNG'), findsOneWidget);
    });
  });
}
