import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cinema_booking_v1/core/routes/app_router.dart';
import 'package:cinema_booking_v1/core/theme/app_theme.dart';
import 'package:cinema_booking_v1/features/auth/presentation/controllers/auth_provider.dart';
import 'package:cinema_booking_v1/features/booking/presentation/controllers/booking_provider.dart';
import 'package:cinema_booking_v1/features/booking/presentation/screens/checkout_screen.dart';
import 'package:cinema_booking_v1/features/booking/presentation/screens/food_selection_screen.dart';
import 'package:cinema_booking_v1/features/booking/presentation/screens/seat_selection_screen.dart';
import 'package:cinema_booking_v1/features/booking/presentation/screens/showtime_selection_screen.dart';
import 'package:cinema_booking_v1/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:cinema_booking_v1/features/profile/presentation/screens/profile_screen.dart';
import 'package:cinema_booking_v1/features/tickets/presentation/screens/ticket_success_screen.dart';
import 'package:cinema_booking_v1/shared/widgets/app_button.dart';
import 'package:cinema_booking_v1/shared/widgets/booking_summary_bar.dart';
import 'package:cinema_booking_v1/shared/widgets/customer_bottom_nav.dart';
import 'package:cinema_booking_v1/shared/widgets/date_chip.dart';
import 'package:cinema_booking_v1/shared/widgets/hold_timer.dart';
import 'package:cinema_booking_v1/shared/widgets/seat_legend.dart';
import 'package:cinema_booking_v1/shared/widgets/ticket_card.dart';
import '../e2e/test_fixtures.dart';

// =============================================================================
// TEST HARNESS & DOUBLES FOR EMPIRICAL CHALLENGER M3_2
// =============================================================================

class MockChallengerAuthProvider extends ChangeNotifier implements AuthProvider {
  AppUser? _user = const AppUser(
    id: 'usr_challenger_01',
    fullName: 'Hoàng Minh Tuấn',
    email: 'tuan.hoang@cinema.vn',
    phone: '0987654321',
    role: UserRole.customer,
  );

  @override
  AppUser? get currentUser => _user;

  @override
  AuthStatus get status => AuthStatus.authenticated;

  @override
  bool get isAuthenticated => _user != null;

  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => null;

  @override
  Future<bool> signIn(String email, String password) async => true;

  @override
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async => true;

  @override
  Future<bool> updateProfile({required String fullName, String? phone}) async {
    if (_user != null) {
      _user = AppUser(
        id: _user!.id,
        fullName: fullName,
        email: _user!.email,
        phone: phone,
        role: _user!.role,
      );
      notifyListeners();
    }
    return true;
  }

  @override
  Future<void> signOut() async {
    _user = null;
    notifyListeners();
  }

  @override
  void clearError() {}
}

class MockChallengerBookingProvider extends BookingProvider {
  DateTime? _customHoldUntil;
  String? _customBookingCode;

  void setMockHoldUntil(DateTime? time) {
    _customHoldUntil = time;
    notifyListeners();
  }

  void setMockBookingCode(String? code) {
    _customBookingCode = code;
    notifyListeners();
  }

  @override
  DateTime? get holdUntil => _customHoldUntil ?? super.holdUntil;

  @override
  String? get currentBookingCode => _customBookingCode ?? super.currentBookingCode;
}

Widget createTestHarness({
  required Widget child,
  BookingProvider? bookingProvider,
  AuthProvider? authProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(
        value: authProvider ?? MockChallengerAuthProvider(),
      ),
      ChangeNotifierProvider<BookingProvider>.value(
        value: bookingProvider ?? MockChallengerBookingProvider(),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.home) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const Scaffold(body: Text('HOME_SCREEN_TARGET')),
          );
        }
        if (settings.name == AppRoutes.myTickets) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const Scaffold(body: Text('MY_TICKETS_TARGET')),
          );
        }
        return AppRouter.onGenerateRoute(settings);
      },
      home: child,
    ),
  );
}

void setTestScreenSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

// =============================================================================
// ASSERTION HELPERS FOR STRICT COMPLIANCE
// =============================================================================

void verifyAllButtonLabelsUppercase(WidgetTester tester) {
  // Check AppButton labels
  final appButtons = tester.widgetList<AppButton>(find.byType(AppButton));
  for (final btn in appButtons) {
    expect(btn.label, equals(btn.label.toUpperCase()),
        reason: 'AppButton label "${btn.label}" must be strictly UPPERCASE');
  }

  // Check ElevatedButton child Text widgets
  final elevatedButtons = find.byType(ElevatedButton);
  for (final eb in tester.widgetList<ElevatedButton>(elevatedButtons)) {
    final textWidgets = tester.widgetList<Text>(
      find.descendant(of: find.byWidget(eb), matching: find.byType(Text)),
    );
    for (final tw in textWidgets) {
      if (tw.data != null && tw.data!.isNotEmpty) {
        expect(tw.data, equals(tw.data!.toUpperCase()),
            reason: 'ElevatedButton child text "${tw.data}" must be strictly UPPERCASE');
      }
    }
  }

  // Check OutlinedButton child Text widgets
  final outlinedButtons = find.byType(OutlinedButton);
  for (final ob in tester.widgetList<OutlinedButton>(outlinedButtons)) {
    final textWidgets = tester.widgetList<Text>(
      find.descendant(of: find.byWidget(ob), matching: find.byType(Text)),
    );
    for (final tw in textWidgets) {
      if (tw.data != null && tw.data!.isNotEmpty) {
        expect(tw.data, equals(tw.data!.toUpperCase()),
            reason: 'OutlinedButton child text "${tw.data}" must be strictly UPPERCASE');
      }
    }
  }

  // Check TextButton child Text widgets
  final textButtons = find.byType(TextButton);
  for (final tb in tester.widgetList<TextButton>(textButtons)) {
    final textWidgets = tester.widgetList<Text>(
      find.descendant(of: find.byWidget(tb), matching: find.byType(Text)),
    );
    for (final tw in textWidgets) {
      if (tw.data != null && tw.data!.isNotEmpty) {
        expect(tw.data, equals(tw.data!.toUpperCase()),
            reason: 'TextButton child text "${tw.data}" must be strictly UPPERCASE');
      }
    }
  }
}

void verifyMaxOnePrimaryButton(WidgetTester tester) {
  // In our design system, AppButton.primary renders an ElevatedButton with AppColors.primary
  final elevatedButtons = find.byType(ElevatedButton);
  final count = tester.widgetList(elevatedButtons).length;
  expect(count, lessThanOrEqualTo(1),
      reason: 'DESIGN_TOKENS.md rule violation: At most 1 primary button on a screen. Found $count');
}

void verifyZeroElevationAndZeroBoxShadow(WidgetTester tester) {
  // 1. Verify AppBars have 0 elevation
  final appBars = tester.widgetList<AppBar>(find.byType(AppBar));
  for (final ab in appBars) {
    expect(ab.elevation ?? 0, equals(0),
        reason: 'AppBar elevation must be 0');
    expect(ab.scrolledUnderElevation ?? 0, equals(0),
        reason: 'AppBar scrolledUnderElevation must be 0');
  }

  // 2. Verify ElevatedButtons have 0 elevation
  final elevatedButtons = tester.widgetList<ElevatedButton>(find.byType(ElevatedButton));
  for (final eb in elevatedButtons) {
    final elev = eb.style?.elevation?.resolve({});
    expect(elev ?? 0, equals(0),
        reason: 'ElevatedButton elevation must be 0');
  }

  // 3. Verify OutlinedButtons have 0 elevation
  final outlinedButtons = tester.widgetList<OutlinedButton>(find.byType(OutlinedButton));
  for (final ob in outlinedButtons) {
    final elev = ob.style?.elevation?.resolve({});
    expect(elev ?? 0, equals(0),
        reason: 'OutlinedButton elevation must be 0');
  }

  // 4. Verify all DecoratedBox widgets have zero BoxShadow
  final decoratedBoxes = tester.widgetList<DecoratedBox>(find.byType(DecoratedBox));
  for (final db in decoratedBoxes) {
    if (db.decoration is BoxDecoration) {
      final boxDec = db.decoration as BoxDecoration;
      expect(boxDec.boxShadow == null || boxDec.boxShadow!.isEmpty, isTrue,
          reason: 'BoxDecoration must have zero BoxShadow (flat design token rule)');
    }
  }

  // 5. Verify all Container widgets with BoxDecoration have zero BoxShadow
  final containers = tester.widgetList<Container>(find.byType(Container));
  for (final c in containers) {
    if (c.decoration is BoxDecoration) {
      final boxDec = c.decoration as BoxDecoration;
      expect(boxDec.boxShadow == null || boxDec.boxShadow!.isEmpty, isTrue,
          reason: 'Container BoxDecoration must have zero BoxShadow');
    }
  }

  // 6. Verify all Material widgets on screen have 0 elevation
  final materials = tester.widgetList<Material>(find.byType(Material));
  for (final m in materials) {
    expect(m.elevation, equals(0),
        reason: 'Material widget on screen must have 0 elevation');
  }
}

// =============================================================================
// MAIN EMPIRICAL VERIFICATION SUITE
// =============================================================================

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initTestSupabase();
  });

  final testMovie = MovieModel(
    id: 'mov_mai_01',
    title: 'Mai',
    genres: const ['Tâm lý', 'Tình cảm'],
    durationMin: 131,
    ageRating: 'T18',
    releaseDate: DateTime.now().subtract(const Duration(days: 2)),
  );

  final testShowtime = ShowtimeModel(
    id: 'st_m3_test',
    movieId: 'mov_mai_01',
    cinemaId: 'cn_q1',
    roomId: 'rm_01',
    format: '2D',
    startTime: DateTime.now().add(const Duration(hours: 3)),
    endTime: DateTime.now().add(const Duration(hours: 5, minutes: 11)),
    totalSeats: 80,
    soldSeats: 12,
    minPrice: 85000,
    movieTitle: 'Mai',
    roomName: 'Phòng 1 (IMAX)',
    cinemaName: 'Star Cinema Quận 1',
  );

  const testFood = FoodModel(
    id: 'f_combo_01',
    cinemaId: 'cn_q1',
    name: 'Combo Solo Bắp Nước',
    category: 'combo',
    price: 75000,
    isAvailable: true,
  );

  // ===========================================================================
  // REQUIREMENT 1: WIDGET RENDERING (S05, S06, S07, S08, S09, S11, S11B)
  // ===========================================================================
  group('Requirement 1: Widget Rendering of Milestone 3 Screens', () {
    testWidgets('1.1 S05: ShowtimeSelectionScreen renders uppercase title and 7 DateChips', (tester) async {
      setTestScreenSize(tester);

      await tester.pumpWidget(
        createTestHarness(
          child: ShowtimeSelectionScreen(
            movie: testMovie,
            movieId: testMovie.id,
            movieTitle: testMovie.title,
            cinemaId: 'cn_q1',
            cinemaName: 'Star Cinema Quận 1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Title should render in uppercase
      expect(find.text('MAI'), findsOneWidget);

      // Verify exactly 7 DateChip widgets for the 7-day selector
      expect(find.byType(DateChip), findsNWidgets(7));
    });

    testWidgets('1.2 S06: SeatSelectionScreen renders Curved Screen, SeatWidget matrix, and SeatLegend', (tester) async {
      setTestScreenSize(tester);
      final booking = MockChallengerBookingProvider();
      booking.setShowtime(testShowtime);

      await tester.pumpWidget(
        createTestHarness(
          child: const SeatSelectionScreen(),
          bookingProvider: booking,
        ),
      );
      await tester.pumpAndSettle();

      // Curved Screen label
      expect(find.text('MÀN HÌNH'), findsOneWidget);

      // InteractiveViewer seat map & SeatLegend
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.byType(SeatWidget), findsWidgets);
      expect(find.byType(SeatLegend), findsOneWidget);

      // Pinned bottom summary bar
      expect(find.byType(BookingSummaryBar), findsOneWidget);
    });

    testWidgets('1.3 S07: FoodSelectionScreen renders HoldTimer, concession categories, and stepper', (tester) async {
      setTestScreenSize(tester);
      final booking = MockChallengerBookingProvider();
      booking.setShowtime(testShowtime);
      booking.toggleSeat('A1', SeatType.standard);
      booking.setMockHoldUntil(DateTime.now().add(const Duration(minutes: 5)));

      await tester.pumpWidget(
        createTestHarness(
          child: const FoodSelectionScreen(),
          bookingProvider: booking,
        ),
      );
      await tester.pumpAndSettle();

      // HoldTimer
      expect(find.byType(HoldTimer), findsOneWidget);

      // Category labels
      expect(find.text('TẤT CẢ'), findsOneWidget);
      expect(find.text('COMBO'), findsOneWidget);
      expect(find.text('BẮP'), findsOneWidget);
      expect(find.text('NƯỚC'), findsOneWidget);
      expect(find.text('SNACK'), findsOneWidget);

      // Bottom bar action buttons
      expect(find.text('BỎ QUA'), findsOneWidget);
      expect(find.text('TIẾP TỤC'), findsOneWidget);
    });

    testWidgets('1.4 S08: CheckoutScreen renders HoldTimer, order summary, voucher input, and VNPay Sandbox', (tester) async {
      setTestScreenSize(tester);
      final booking = MockChallengerBookingProvider();
      booking.setShowtime(testShowtime);
      booking.toggleSeat('A1', SeatType.standard);
      booking.setMockHoldUntil(DateTime.now().add(const Duration(minutes: 5)));
      booking.setMockBookingCode('M3CHAL04');
      booking.updateFoodQuantity(testFood, 1);

      await tester.pumpWidget(
        createTestHarness(
          child: const CheckoutScreen(),
          bookingProvider: booking,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HoldTimer), findsOneWidget);
      expect(find.text('THANH TOÁN'), findsOneWidget);
      expect(find.text('1 GHẾ (A1)'), findsOneWidget);
      expect(find.text('1x Combo Solo Bắp Nước'), findsOneWidget);
      expect(find.textContaining('VNPAY SANDBOX'), findsOneWidget);
      expect(find.text('THANH TOÁN VNPAY'), findsOneWidget);
    });

    testWidgets('1.5 S09: TicketSuccessScreen renders success icon, header, TicketCard, and actions', (tester) async {
      setTestScreenSize(tester);

      await tester.pumpWidget(
        createTestHarness(
          child: const TicketSuccessScreen(bookingCode: 'M3CHAL01'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.text('ĐẶT VÉ THÀNH CÔNG'), findsOneWidget);
      expect(find.byType(TicketCard), findsOneWidget);
      expect(find.text('XEM VÉ CỦA TÔI'), findsOneWidget);
      expect(find.text('VỀ TRANG CHỦ'), findsOneWidget);
    });

    testWidgets('1.6 S11: ProfileScreen renders user details, initial avatar, role badge, and menu', (tester) async {
      setTestScreenSize(tester);

      await tester.pumpWidget(
        createTestHarness(
          child: const ProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TÀI KHOẢN'), findsWidgets);
      expect(find.text('Hoàng Minh Tuấn'), findsOneWidget);
      expect(find.text('tuan.hoang@cinema.vn'), findsOneWidget);
      expect(find.text('CUSTOMER'), findsOneWidget);
      expect(find.text('H'), findsOneWidget); // Initial avatar
      expect(find.text('SỬA HỒ SƠ'), findsOneWidget);
      expect(find.text('HỘP THƯ HỖ TRỢ'), findsOneWidget);
      expect(find.text('ĐĂNG XUẤT'), findsOneWidget);
      expect(find.byType(CustomerBottomNav), findsOneWidget);
    });

    testWidgets('1.7 S11B: EditProfileScreen renders form fields and save CTA button', (tester) async {
      setTestScreenSize(tester);

      await tester.pumpWidget(
        createTestHarness(
          child: const EditProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CHỈNH SỬA HỒ SƠ'), findsOneWidget);
      expect(find.text('Hoàng Minh Tuấn'), findsOneWidget);
      expect(find.text('0987654321'), findsOneWidget);
      expect(find.text('tuan.hoang@cinema.vn'), findsOneWidget);
      expect(find.text('LƯU THAY ĐỔI'), findsOneWidget);
    });
  });

  // ===========================================================================
  // REQUIREMENT 2: BUTTON TEXT CASE VERIFICATION (.toUpperCase())
  // ===========================================================================
  group('Requirement 2: Button Text Case Verification (.toUpperCase())', () {
    testWidgets('2.1 S05: All buttons render uppercase labels', (tester) async {
      setTestScreenSize(tester);
      await tester.pumpWidget(
        createTestHarness(
          child: ShowtimeSelectionScreen(
            movie: testMovie,
            movieId: testMovie.id,
            movieTitle: testMovie.title,
            cinemaId: 'cn_q1',
            cinemaName: 'Star Cinema Quận 1',
          ),
        ),
      );
      await tester.pumpAndSettle();
      verifyAllButtonLabelsUppercase(tester);
    });

    testWidgets('2.2 S06: All buttons render uppercase labels', (tester) async {
      setTestScreenSize(tester);
      final booking = MockChallengerBookingProvider();
      booking.setShowtime(testShowtime);

      await tester.pumpWidget(
        createTestHarness(
          child: const SeatSelectionScreen(),
          bookingProvider: booking,
        ),
      );
      await tester.pumpAndSettle();
      verifyAllButtonLabelsUppercase(tester);
    });

    testWidgets('2.3 S07: All buttons render uppercase labels', (tester) async {
      setTestScreenSize(tester);
      final booking = MockChallengerBookingProvider();
      booking.setShowtime(testShowtime);
      booking.toggleSeat('A1', SeatType.standard);
      booking.setMockHoldUntil(DateTime.now().add(const Duration(minutes: 5)));

      await tester.pumpWidget(
        createTestHarness(
          child: const FoodSelectionScreen(),
          bookingProvider: booking,
        ),
      );
      await tester.pumpAndSettle();
      verifyAllButtonLabelsUppercase(tester);
    });

    testWidgets('2.4 S08: All buttons render uppercase labels', (tester) async {
      setTestScreenSize(tester);
      final booking = MockChallengerBookingProvider();
      booking.setShowtime(testShowtime);
      booking.toggleSeat('A1', SeatType.standard);
      booking.setMockHoldUntil(DateTime.now().add(const Duration(minutes: 5)));

      await tester.pumpWidget(
        createTestHarness(
          child: const CheckoutScreen(),
          bookingProvider: booking,
        ),
      );
      await tester.pumpAndSettle();
      verifyAllButtonLabelsUppercase(tester);
    });

    testWidgets('2.5 S09: All buttons render uppercase labels', (tester) async {
      setTestScreenSize(tester);
      await tester.pumpWidget(
        createTestHarness(
          child: const TicketSuccessScreen(bookingCode: 'M3CHAL02'),
        ),
      );
      await tester.pumpAndSettle();
      verifyAllButtonLabelsUppercase(tester);
    });

    testWidgets('2.6 S11: All buttons render uppercase labels', (tester) async {
      setTestScreenSize(tester);
      await tester.pumpWidget(
        createTestHarness(
          child: const ProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();
      verifyAllButtonLabelsUppercase(tester);
    });

    testWidgets('2.7 S11B: All buttons render uppercase labels', (tester) async {
      setTestScreenSize(tester);
      await tester.pumpWidget(
        createTestHarness(
          child: const EditProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();
      verifyAllButtonLabelsUppercase(tester);
    });
  });

  // ===========================================================================
  // REQUIREMENT 3: PRIMARY BUTTON RULE (MAX 1 PRIMARY BUTTON PER SCREEN)
  // ===========================================================================
  group('Requirement 3: Primary Button Rule Verification (Max 1 Primary Button)', () {
    testWidgets('3.1 S05 has <= 1 primary button', (tester) async {
      setTestScreenSize(tester);
      await tester.pumpWidget(
        createTestHarness(
          child: ShowtimeSelectionScreen(
            movie: testMovie,
            movieId: testMovie.id,
            movieTitle: testMovie.title,
            cinemaId: 'cn_q1',
            cinemaName: 'Star Cinema Quận 1',
          ),
        ),
      );
      await tester.pumpAndSettle();
      verifyMaxOnePrimaryButton(tester);
    });

    testWidgets('3.2 S06 has exactly 1 primary button in summary bar', (tester) async {
      setTestScreenSize(tester);
      final booking = MockChallengerBookingProvider();
      booking.setShowtime(testShowtime);

      await tester.pumpWidget(
        createTestHarness(
          child: const SeatSelectionScreen(),
          bookingProvider: booking,
        ),
      );
      await tester.pumpAndSettle();
      verifyMaxOnePrimaryButton(tester);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('3.3 S07 has exactly 1 primary button in bottom bar', (tester) async {
      setTestScreenSize(tester);
      final booking = MockChallengerBookingProvider();
      booking.setShowtime(testShowtime);
      booking.toggleSeat('A1', SeatType.standard);
      booking.setMockHoldUntil(DateTime.now().add(const Duration(minutes: 5)));

      await tester.pumpWidget(
        createTestHarness(
          child: const FoodSelectionScreen(),
          bookingProvider: booking,
        ),
      );
      await tester.pumpAndSettle();
      verifyMaxOnePrimaryButton(tester);
      expect(find.widgetWithText(ElevatedButton, 'TIẾP TỤC'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'BỎ QUA'), findsOneWidget);
    });

    testWidgets('3.4 S08 has exactly 1 primary button in checkout bar', (tester) async {
      setTestScreenSize(tester);
      final booking = MockChallengerBookingProvider();
      booking.setShowtime(testShowtime);
      booking.toggleSeat('A1', SeatType.standard);
      booking.setMockHoldUntil(DateTime.now().add(const Duration(minutes: 5)));

      await tester.pumpWidget(
        createTestHarness(
          child: const CheckoutScreen(),
          bookingProvider: booking,
        ),
      );
      await tester.pumpAndSettle();
      verifyMaxOnePrimaryButton(tester);
      expect(find.widgetWithText(ElevatedButton, 'THANH TOÁN VNPAY'), findsOneWidget);
    });

    testWidgets('3.5 S09 has exactly 1 primary button', (tester) async {
      setTestScreenSize(tester);
      await tester.pumpWidget(
        createTestHarness(
          child: const TicketSuccessScreen(bookingCode: 'M3CHAL03'),
        ),
      );
      await tester.pumpAndSettle();
      verifyMaxOnePrimaryButton(tester);
      expect(find.widgetWithText(ElevatedButton, 'XEM VÉ CỦA TÔI'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'VỀ TRANG CHỦ'), findsOneWidget);
    });

    testWidgets('3.6 S11 has 0 primary buttons on main screen', (tester) async {
      setTestScreenSize(tester);
      await tester.pumpWidget(
        createTestHarness(
          child: const ProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();
      verifyMaxOnePrimaryButton(tester);
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('3.7 S11B has exactly 1 primary button', (tester) async {
      setTestScreenSize(tester);
      await tester.pumpWidget(
        createTestHarness(
          child: const EditProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();
      verifyMaxOnePrimaryButton(tester);
      expect(find.widgetWithText(ElevatedButton, 'LƯU THAY ĐỔI'), findsOneWidget);
    });
  });

  // ===========================================================================
  // REQUIREMENT 4: ELEVATION AND ZERO BOXSHADOW VERIFICATION
  // ===========================================================================
  group('Requirement 4: Elevation Verification (0 Elevation & Zero BoxShadow)', () {
    testWidgets('4.1 S05 has 0 elevation and zero BoxShadow', (tester) async {
      setTestScreenSize(tester);
      await tester.pumpWidget(
        createTestHarness(
          child: ShowtimeSelectionScreen(
            movie: testMovie,
            movieId: testMovie.id,
            movieTitle: testMovie.title,
            cinemaId: 'cn_q1',
            cinemaName: 'Star Cinema Quận 1',
          ),
        ),
      );
      await tester.pumpAndSettle();
      verifyZeroElevationAndZeroBoxShadow(tester);
    });

    testWidgets('4.2 S06 has 0 elevation and zero BoxShadow', (tester) async {
      setTestScreenSize(tester);
      final booking = MockChallengerBookingProvider();
      booking.setShowtime(testShowtime);

      await tester.pumpWidget(
        createTestHarness(
          child: const SeatSelectionScreen(),
          bookingProvider: booking,
        ),
      );
      await tester.pumpAndSettle();
      verifyZeroElevationAndZeroBoxShadow(tester);
    });

    testWidgets('4.3 S07 has 0 elevation and zero BoxShadow', (tester) async {
      setTestScreenSize(tester);
      final booking = MockChallengerBookingProvider();
      booking.setShowtime(testShowtime);
      booking.toggleSeat('A1', SeatType.standard);
      booking.setMockHoldUntil(DateTime.now().add(const Duration(minutes: 5)));

      await tester.pumpWidget(
        createTestHarness(
          child: const FoodSelectionScreen(),
          bookingProvider: booking,
        ),
      );
      await tester.pumpAndSettle();
      verifyZeroElevationAndZeroBoxShadow(tester);
    });

    testWidgets('4.4 S08 has 0 elevation and zero BoxShadow', (tester) async {
      setTestScreenSize(tester);
      final booking = MockChallengerBookingProvider();
      booking.setShowtime(testShowtime);
      booking.toggleSeat('A1', SeatType.standard);
      booking.setMockHoldUntil(DateTime.now().add(const Duration(minutes: 5)));

      await tester.pumpWidget(
        createTestHarness(
          child: const CheckoutScreen(),
          bookingProvider: booking,
        ),
      );
      await tester.pumpAndSettle();
      verifyZeroElevationAndZeroBoxShadow(tester);
    });

    testWidgets('4.5 S09 has 0 elevation and zero BoxShadow', (tester) async {
      setTestScreenSize(tester);
      await tester.pumpWidget(
        createTestHarness(
          child: const TicketSuccessScreen(bookingCode: 'M3CHAL04'),
        ),
      );
      await tester.pumpAndSettle();
      verifyZeroElevationAndZeroBoxShadow(tester);
    });

    testWidgets('4.6 S11 has 0 elevation and zero BoxShadow', (tester) async {
      setTestScreenSize(tester);
      await tester.pumpWidget(
        createTestHarness(
          child: const ProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();
      verifyZeroElevationAndZeroBoxShadow(tester);
    });

    testWidgets('4.7 S11B has 0 elevation and zero BoxShadow', (tester) async {
      setTestScreenSize(tester);
      await tester.pumpWidget(
        createTestHarness(
          child: const EditProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();
      verifyZeroElevationAndZeroBoxShadow(tester);
    });
  });

  // ===========================================================================
  // REQUIREMENT 5: POPSCOPE ON S09 PREVENTING ACCIDENTAL BACKWARD POP
  // ===========================================================================
  group('Requirement 5: PopScope on S09 Preventing Accidental Backward Pop', () {
    testWidgets('5.1 S09 PopScope enforces canPop: false', (tester) async {
      setTestScreenSize(tester);
      await tester.pumpWidget(
        createTestHarness(
          child: const TicketSuccessScreen(bookingCode: 'M3CHAL05'),
        ),
      );
      await tester.pumpAndSettle();

      final popScopeFinder = find.byWidgetPredicate((w) => w is PopScope);
      expect(popScopeFinder, findsOneWidget);

      final popScope = tester.widget(popScopeFinder) as PopScope;
      expect(popScope.canPop, isFalse,
          reason: 'S09 PopScope must enforce canPop: false to prevent popping backward into checkout/payment');
    });

    testWidgets('5.2 S09 PopScope onPopInvokedWithResult routes to Home when backward navigation is triggered', (tester) async {
      setTestScreenSize(tester);

      await tester.pumpWidget(
        createTestHarness(
          child: const TicketSuccessScreen(bookingCode: 'M3CHAL05'),
        ),
      );
      await tester.pumpAndSettle();

      final popScopeFinder = find.byWidgetPredicate((w) => w is PopScope);
      final popScope = tester.widget(popScopeFinder) as PopScope;

      // Trigger pop invocation directly
      popScope.onPopInvokedWithResult!(false, null);
      await tester.pumpAndSettle();

      // Home route was triggered (Navigator.pushNamedAndRemoveUntil home)
      expect(find.text('HOME_SCREEN_TARGET'), findsOneWidget);
    });

    testWidgets('5.3 S06 PopScope protects held seats by enforcing canPop: false', (tester) async {
      setTestScreenSize(tester);
      final booking = MockChallengerBookingProvider();
      booking.setShowtime(testShowtime);
      booking.setMockHoldUntil(DateTime.now().add(const Duration(minutes: 5)));

      await tester.pumpWidget(
        createTestHarness(
          child: const SeatSelectionScreen(),
          bookingProvider: booking,
        ),
      );
      await tester.pumpAndSettle();

      final popScopeFinder = find.byWidgetPredicate((w) => w is PopScope);
      expect(popScopeFinder, findsOneWidget);

      final popScope = tester.widget(popScopeFinder) as PopScope;
      expect(popScope.canPop, isFalse,
          reason: 'S06 PopScope must have canPop: false so that holding seats are not abandoned without confirmation');
    });
  });
}
