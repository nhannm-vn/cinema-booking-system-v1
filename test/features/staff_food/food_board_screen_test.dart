import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cinema_booking_v1/core/theme/app_theme.dart';
import 'package:cinema_booking_v1/features/auth/presentation/controllers/auth_provider.dart';
import 'package:cinema_booking_v1/features/booking/data/models/booking_model.dart';
import 'package:cinema_booking_v1/features/staff_food/data/staff_food_repository.dart';
import 'package:cinema_booking_v1/features/staff_food/presentation/controllers/staff_food_provider.dart';
import 'package:cinema_booking_v1/features/staff_food/presentation/screens/food_board_screen.dart';
import 'package:cinema_booking_v1/shared/models/app_user.dart';

class MockStaffFoodRepository implements StaffFoodRepository {
  List<BookingModel> mockPending = [];
  List<BookingModel> mockDelivered = [];
  String? lastDeliveredCode;
  bool shouldThrow = false;

  @override
  Future<List<BookingModel>> getPendingOrders(String cinemaId) async {
    if (shouldThrow) throw Exception('Lỗi kết nối cơ sở dữ liệu');
    return List.from(mockPending);
  }

  @override
  Future<List<BookingModel>> getDeliveredOrders(String cinemaId) async {
    if (shouldThrow) throw Exception('Lỗi kết nối cơ sở dữ liệu');
    return List.from(mockDelivered);
  }

  @override
  Future<void> deliverFood(String bookingCode) async {
    if (shouldThrow) throw Exception('Lỗi gọi RPC deliver_food');
    lastDeliveredCode = bookingCode;
    final idx = mockPending.indexWhere((b) => b.code == bookingCode);
    if (idx != -1) {
      final order = mockPending.removeAt(idx);
      mockDelivered.insert(0, order);
    }
  }
}

class FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  final AppUser _user = const AppUser(
    id: 'staff_1',
    fullName: 'Nhân viên Bếp',
    role: UserRole.staff,
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
  Future<bool> signUp({required String email, required String password, required String fullName, String? phone}) async => true;

  @override
  Future<bool> updateProfile({required String fullName, String? phone}) async => true;
}

BookingModel createTestBooking({
  required String code,
  required String movieTitle,
  required String roomName,
  required DateTime showtimeStart,
  required List<Map<String, dynamic>> foods,
  String foodStatus = 'pending',
}) {
  return BookingModel(
    code: code,
    cinemaId: 'cn_q1',
    cinemaName: 'Cinema Quận 1',
    movieTitle: movieTitle,
    roomName: roomName,
    format: '2D',
    showtimeId: 'st_1',
    showtimeStart: showtimeStart,
    status: 'paid',
    foodStatus: foodStatus,
    seats: const [
      {'id': 'A1', 'type': 'standard', 'price': 80000}
    ],
    foods: foods,
    priceSnapshot: const {'total': 150000},
    createdAt: DateTime.now(),
  );
}

Widget createFoodBoardTestHarness({
  required StaffFoodProvider foodProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: FakeAuthProvider()),
      ChangeNotifierProvider<StaffFoodProvider>.value(value: foodProvider),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      home: const FoodBoardScreen(),
    ),
  );
}

void main() {
  group('StaffFoodProvider Unit Tests', () {
    late MockStaffFoodRepository mockRepo;
    late StaffFoodProvider provider;

    setUp(() {
      mockRepo = MockStaffFoodRepository();
      provider = StaffFoodProvider(mockRepo);
    });

    test('initial state defaults are correct', () {
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
      expect(provider.currentTabIndex, 0);
      expect(provider.searchQuery, '');
      expect(provider.pendingOrders, isEmpty);
      expect(provider.deliveredOrders, isEmpty);
    });

    test('loadOrders loads and sorts pending orders ascending by showtimeStart', () async {
      final earlier = DateTime.now().add(const Duration(minutes: 30));
      final later = DateTime.now().add(const Duration(hours: 2));

      mockRepo.mockPending = [
        createTestBooking(
          code: 'ORDER_LATE',
          movieTitle: 'Kung Fu Panda 4',
          roomName: 'Phòng 2',
          showtimeStart: later,
          foods: [{'name': 'Coca-Cola', 'qty': 1}],
        ),
        createTestBooking(
          code: 'ORDER_EARLY',
          movieTitle: 'Dune 2',
          roomName: 'Phòng 1',
          showtimeStart: earlier,
          foods: [{'name': 'Bắp Rang Bơ', 'qty': 2}],
        ),
      ];

      await provider.loadOrders('cn_q1');

      expect(provider.pendingOrders.length, 2);
      expect(provider.pendingOrders[0].code, 'ORDER_EARLY');
      expect(provider.pendingOrders[1].code, 'ORDER_LATE');
    });

    test('setTab toggles current tab', () {
      provider.setTab(1);
      expect(provider.currentTabIndex, 1);
      provider.setTab(0);
      expect(provider.currentTabIndex, 0);
    });

    test('setSearchQuery filters orders by code or movie title', () async {
      mockRepo.mockPending = [
        createTestBooking(
          code: 'BC111111',
          movieTitle: 'Dune: Part Two',
          roomName: 'Phòng 1',
          showtimeStart: DateTime.now(),
          foods: [],
        ),
        createTestBooking(
          code: 'BC222222',
          movieTitle: 'Godzilla x Kong',
          roomName: 'Phòng 2',
          showtimeStart: DateTime.now(),
          foods: [],
        ),
      ];

      await provider.loadOrders('cn_q1');

      provider.setSearchQuery('DUNE');
      expect(provider.pendingOrders.length, 1);
      expect(provider.pendingOrders.first.code, 'BC111111');

      provider.setSearchQuery('222222');
      expect(provider.pendingOrders.length, 1);
      expect(provider.pendingOrders.first.code, 'BC222222');
    });

    test('deliverFood calls repository and updates pending/delivered lists', () async {
      mockRepo.mockPending = [
        createTestBooking(
          code: 'DELIVER_ME',
          movieTitle: 'Exhuma',
          roomName: 'Phòng 3',
          showtimeStart: DateTime.now(),
          foods: [{'name': 'Bắp Phô Mai', 'qty': 1}],
        ),
      ];

      final success = await provider.deliverFood('DELIVER_ME', 'cn_q1');

      expect(success, isTrue);
      expect(mockRepo.lastDeliveredCode, 'DELIVER_ME');
      expect(provider.pendingOrders, isEmpty);
      expect(provider.deliveredOrders.length, 1);
    });
  });

  group('S19 Food Board Screen Widget Tests', () {
    late MockStaffFoodRepository mockRepo;
    late StaffFoodProvider foodProvider;

    setUp(() {
      mockRepo = MockStaffFoodRepository();
      foodProvider = StaffFoodProvider(mockRepo);
    });

    testWidgets('renders screen headers, search field, tabs, and bottom nav', (tester) async {
      await tester.pumpWidget(createFoodBoardTestHarness(foodProvider: foodProvider));
      await tester.pumpAndSettle();

      expect(find.text('QUẦY ĐỒ ĂN'), findsOneWidget);
      expect(find.text('CN_Q1'), findsOneWidget);
      expect(find.byKey(const Key('food_search_field')), findsOneWidget);
      expect(find.byKey(const Key('food_tab_pending')), findsOneWidget);
      expect(find.byKey(const Key('food_tab_delivered')), findsOneWidget);

      // Verify StaffBottomNav
      expect(find.text('SOÁT VÉ'), findsOneWidget);
      expect(find.text('ĐỒ ĂN'), findsOneWidget);
      expect(find.text('BÁN VÉ'), findsOneWidget);
      expect(find.text('TÀI KHOẢN'), findsOneWidget);
    });

    testWidgets('shows EmptyState when pending orders list is empty', (tester) async {
      await tester.pumpWidget(createFoodBoardTestHarness(foodProvider: foodProvider));
      await tester.pumpAndSettle();

      expect(find.text('CHƯA CÓ ĐƠN CHỜ GIAO'), findsOneWidget);
      expect(find.text('Hiện tại không có đơn đồ ăn nào cần chuẩn bị.'), findsOneWidget);
    });

    testWidgets('renders pending order card and executes delivery flow', (tester) async {
      mockRepo.mockPending = [
        createTestBooking(
          code: 'FD998877',
          movieTitle: 'Avatar 3',
          roomName: 'Phòng VIP',
          showtimeStart: DateTime(2026, 10, 28, 19, 30),
          foods: [
            {'name': 'Combo Bắp Nước', 'qty': 2},
            {'name': 'Xúc Xích Nướng', 'qty': 1},
          ],
        ),
      ];

      await tester.pumpWidget(createFoodBoardTestHarness(foodProvider: foodProvider));
      await tester.pumpAndSettle();

      // Card rendered
      expect(find.text('#FD998877'), findsOneWidget);
      expect(find.text('Avatar 3'), findsOneWidget);
      expect(find.text('2x'), findsOneWidget);
      expect(find.text('Combo Bắp Nước'), findsOneWidget);
      expect(find.text('1x'), findsOneWidget);
      expect(find.text('Xúc Xích Nướng'), findsOneWidget);
      expect(find.byKey(const Key('deliver_btn_FD998877')), findsOneWidget);

      // Tap Deliver button
      await tester.tap(find.byKey(const Key('deliver_btn_FD998877')));
      await tester.pumpAndSettle();

      // Confirmation dialog opens
      expect(find.text('XÁC NHẬN GIAO ĐỒ ĂN'), findsOneWidget);
      expect(find.text('Xác nhận đã giao đủ đồ ăn cho đơn vé #FD998877?'), findsOneWidget);

      // Confirm delivery
      await tester.tap(find.text('XÁC NHẬN'));
      await tester.pumpAndSettle();

      // Success snackbar
      expect(find.text('ĐÃ GIAO ĐỒ ĂN CHO ĐƠN #FD998877 THÀNH CÔNG'), findsOneWidget);

      // Pending tab is now empty
      expect(find.text('CHƯA CÓ ĐƠN CHỜ GIAO'), findsOneWidget);

      // Switch to Delivered tab
      await tester.tap(find.byKey(const Key('food_tab_delivered')));
      await tester.pumpAndSettle();

      // Order appears under Delivered tab with status badge
      expect(find.text('#FD998877'), findsOneWidget);
      expect(find.text('ĐÃ GIAO'), findsAtLeastNWidgets(1));
    });

    testWidgets('search filters orders by code', (tester) async {
      mockRepo.mockPending = [
        createTestBooking(
          code: 'AAA11111',
          movieTitle: 'Phim A',
          roomName: 'Phòng 1',
          showtimeStart: DateTime.now(),
          foods: [{'name': 'Bắp Ngọt', 'qty': 1}],
        ),
        createTestBooking(
          code: 'BBB22222',
          movieTitle: 'Phim B',
          roomName: 'Phòng 2',
          showtimeStart: DateTime.now(),
          foods: [{'name': 'Nước Ngọt', 'qty': 1}],
        ),
      ];

      await tester.pumpWidget(createFoodBoardTestHarness(foodProvider: foodProvider));
      await tester.pumpAndSettle();

      expect(find.text('#AAA11111'), findsOneWidget);
      expect(find.text('#BBB22222'), findsOneWidget);

      // Enter search query
      await tester.enterText(find.byKey(const Key('food_search_field')), 'AAA');
      await tester.pumpAndSettle();

      expect(find.text('#AAA11111'), findsOneWidget);
      expect(find.text('#BBB22222'), findsNothing);
    });
  });
}
