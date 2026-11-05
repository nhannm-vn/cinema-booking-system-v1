import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cinema_booking_v1/core/routes/app_router.dart';
import 'package:cinema_booking_v1/core/routes/route_guards.dart';
import 'package:cinema_booking_v1/core/theme/app_theme.dart';
import 'package:cinema_booking_v1/features/auth/presentation/controllers/auth_provider.dart';
import 'package:cinema_booking_v1/features/management/presentation/controllers/management_provider.dart';
import 'package:cinema_booking_v1/features/management/presentation/screens/management_menu_screen.dart';
import 'package:cinema_booking_v1/features/management/presentation/screens/operational_dashboard_screen.dart';
import 'package:cinema_booking_v1/features/staff_checkin/presentation/screens/ticket_checkin_screen.dart';
import 'package:cinema_booking_v1/features/staff_food/presentation/screens/food_board_screen.dart';
import 'package:cinema_booking_v1/features/staff_counter/presentation/screens/counter_showtimes_screen.dart';
import 'package:cinema_booking_v1/shared/models/app_user.dart';

class FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  AppUser? _user;

  FakeAuthProvider([AppUser? user]) : _user = user;

  void setUser(AppUser? user) {
    _user = user;
    notifyListeners();
  }

  @override
  AppUser? get currentUser => _user;

  @override
  bool get isAuthenticated => _user != null;

  @override
  bool get isLoading => false;

  @override
  AuthStatus get status => _user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const staffUser = AppUser(
    id: 'staff_01',
    email: 'staff@cinema.vn',
    fullName: 'Nhân Viên Quầy',
    role: UserRole.staff,
    cinemaId: 'cn_q1',
  );

  const managerUser = AppUser(
    id: 'mgr_01',
    email: 'manager@cinema.vn',
    fullName: 'Quản Lý Rạp',
    role: UserRole.manager,
    cinemaId: 'cn_q1',
  );

  const adminUser = AppUser(
    id: 'admin_01',
    email: 'admin@cinema.vn',
    fullName: 'Quản Trị Viên',
    role: UserRole.admin,
  );

  group('Strict Role Separation - RouteGuards Tests', () {
    test('Staff has access only to staff operational routes and account', () {
      expect(RouteGuards.canAccessRoute(staffUser, AppRoutes.staffCheckin), isTrue);
      expect(RouteGuards.canAccessRoute(staffUser, AppRoutes.staffFood), isTrue);
      expect(RouteGuards.canAccessRoute(staffUser, AppRoutes.staffCounterShowtimes), isTrue);
      expect(RouteGuards.canAccessRoute(staffUser, AppRoutes.staffCounterPayment), isTrue);

      // Staff cannot access management routes
      expect(RouteGuards.canAccessRoute(staffUser, AppRoutes.dashboard), isFalse);
      expect(RouteGuards.canAccessRoute(staffUser, AppRoutes.managementHome), isFalse);
      expect(RouteGuards.canAccessRoute(staffUser, AppRoutes.manageShowtimes), isFalse);
      expect(RouteGuards.canAccessRoute(staffUser, AppRoutes.manageBookings), isFalse);
      expect(RouteGuards.canAccessRoute(staffUser, AppRoutes.manageEmployees), isFalse);
      expect(RouteGuards.canAccessRoute(staffUser, AppRoutes.manageFoods), isFalse);
    });

    test('Manager and Admin CANNOT access staff operational routes', () {
      expect(RouteGuards.canAccessRoute(managerUser, AppRoutes.staffCheckin), isFalse);
      expect(RouteGuards.canAccessRoute(managerUser, AppRoutes.staffFood), isFalse);
      expect(RouteGuards.canAccessRoute(managerUser, AppRoutes.staffCounterShowtimes), isFalse);
      expect(RouteGuards.canAccessRoute(managerUser, AppRoutes.staffCounterPayment), isFalse);

      expect(RouteGuards.canAccessRoute(adminUser, AppRoutes.staffCheckin), isFalse);
      expect(RouteGuards.canAccessRoute(adminUser, AppRoutes.staffFood), isFalse);
      expect(RouteGuards.canAccessRoute(adminUser, AppRoutes.staffCounterShowtimes), isFalse);
      expect(RouteGuards.canAccessRoute(adminUser, AppRoutes.staffCounterPayment), isFalse);
    });

    test('Manager can access management routes but not admin-only routes', () {
      expect(RouteGuards.canAccessRoute(managerUser, AppRoutes.dashboard), isTrue);
      expect(RouteGuards.canAccessRoute(managerUser, AppRoutes.managementHome), isTrue);
      expect(RouteGuards.canAccessRoute(managerUser, AppRoutes.manageShowtimes), isTrue);
      expect(RouteGuards.canAccessRoute(managerUser, AppRoutes.manageBookings), isTrue);
      expect(RouteGuards.canAccessRoute(managerUser, AppRoutes.manageEmployees), isTrue);
      expect(RouteGuards.canAccessRoute(managerUser, AppRoutes.manageFoods), isTrue);

      // Admin only
      expect(RouteGuards.canAccessRoute(managerUser, AppRoutes.manageRooms), isFalse);
      expect(RouteGuards.canAccessRoute(managerUser, AppRoutes.configSeatMap), isFalse);
      expect(RouteGuards.canAccessRoute(managerUser, AppRoutes.manageVouchers), isFalse);
      expect(RouteGuards.canAccessRoute(managerUser, AppRoutes.manageManagers), isFalse);
      expect(RouteGuards.canAccessRoute(managerUser, AppRoutes.auditLogs), isFalse);
    });

    test('Admin has full access to all management and admin routes', () {
      expect(RouteGuards.canAccessRoute(adminUser, AppRoutes.dashboard), isTrue);
      expect(RouteGuards.canAccessRoute(adminUser, AppRoutes.managementHome), isTrue);
      expect(RouteGuards.canAccessRoute(adminUser, AppRoutes.manageRooms), isTrue);
      expect(RouteGuards.canAccessRoute(adminUser, AppRoutes.configSeatMap), isTrue);
      expect(RouteGuards.canAccessRoute(adminUser, AppRoutes.manageVouchers), isTrue);
      expect(RouteGuards.canAccessRoute(adminUser, AppRoutes.manageManagers), isTrue);
      expect(RouteGuards.canAccessRoute(adminUser, AppRoutes.auditLogs), isTrue);
    });
  });

  group('Strict Role Separation - UI Screens Verification', () {
    testWidgets('S12 ManagementMenuScreen does NOT show any staff shortcuts', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(create: (_) => FakeAuthProvider(managerUser)),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const ManagementMenuScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure staff shortcuts are completely absent
      expect(find.textContaining('Soát vé tại cửa'), findsNothing);
      expect(find.textContaining('Quầy giao đồ ăn'), findsNothing);
      expect(find.textContaining('Bán vé tại quầy'), findsNothing);

      // Ensure proper management items exist
      expect(find.text('Bàn làm việc / Dashboard (S22)'), findsOneWidget);
      expect(find.text('Quản lý đơn vé & Bookings (S15)'), findsOneWidget);
      expect(find.text('Quản lý nhân viên (S23)'), findsOneWidget);
      expect(find.text('Hộp thư hỗ trợ khách (S31)'), findsOneWidget);
    });

    testWidgets('S22 OperationalDashboardScreen quick actions have NO staff actions', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(create: (_) => FakeAuthProvider(managerUser)),
            ChangeNotifierProvider<ManagementProvider>(create: (_) => ManagementProvider()),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const OperationalDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure staff buttons are removed
      expect(find.text('BÁN QUẦY'), findsNothing);
      expect(find.text('SOÁT VÉ'), findsNothing);

      // Ensure management buttons exist
      expect(find.text('LẬP SUẤT'), findsOneWidget);
      expect(find.text('ĐƠN VÉ'), findsOneWidget);
      expect(find.text('NHÂN SỰ'), findsOneWidget);
      expect(find.text('MENU BẮP'), findsOneWidget);
    });

    testWidgets('S18 TicketCheckinScreen blocks Manager with Unauthorized State', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(create: (_) => FakeAuthProvider(managerUser)),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const TicketCheckinScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('KHÔNG CÓ QUYỀN TRUY CẬP'), findsOneWidget);
      expect(find.text('VỀ BÀN LÀM VIỆC'), findsOneWidget);
    });

    testWidgets('S19 FoodBoardScreen blocks Admin with Unauthorized State', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(create: (_) => FakeAuthProvider(adminUser)),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const FoodBoardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('KHÔNG CÓ QUYỀN TRUY CẬP'), findsOneWidget);
      expect(find.text('VỀ BÀN LÀM VIỆC'), findsOneWidget);
    });

    testWidgets('S20 CounterShowtimesScreen blocks Manager with Unauthorized State', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(create: (_) => FakeAuthProvider(managerUser)),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const CounterShowtimesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('KHÔNG CÓ QUYỀN TRUY CẬP'), findsOneWidget);
      expect(find.text('VỀ BÀN LÀM VIỆC'), findsOneWidget);
    });
  });
}
