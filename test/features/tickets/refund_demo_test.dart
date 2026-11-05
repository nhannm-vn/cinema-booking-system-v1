import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cinema_booking_v1/core/theme/app_theme.dart';
import 'package:cinema_booking_v1/features/booking/data/models/booking_model.dart';
import 'package:cinema_booking_v1/features/tickets/presentation/controllers/ticket_provider.dart';
import 'package:cinema_booking_v1/features/tickets/presentation/screens/ticket_detail_screen.dart';

class FakeRefundTicketProvider extends ChangeNotifier implements TicketProvider {
  final Map<String, BookingModel> _tickets = {};

  void addTicket(BookingModel ticket) {
    _tickets[ticket.code] = ticket;
  }

  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => null;

  @override
  List<BookingModel> get upcomingTickets =>
      _tickets.values.where((b) => b.status == 'paid').toList();

  @override
  List<BookingModel> get historyTickets => [];

  @override
  List<BookingModel> get cancelledTickets =>
      _tickets.values.where((b) => b.status == 'cancelled').toList();

  @override
  Future<void> loadMyTickets() async {}

  @override
  Future<bool> cancelBooking(String code, {String reason = 'Khách hủy vé trực tuyến'}) async {
    final t = _tickets[code];
    if (t != null) {
      _tickets[code] = t.copyWith(status: 'cancelled');
      notifyListeners();
      return true;
    }
    return false;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeRefundTicketProvider fakeTicketProvider;

  setUp(() {
    fakeTicketProvider = FakeRefundTicketProvider();
  });

  Widget createWidgetUnderTest(BookingModel ticket) {
    fakeTicketProvider.addTicket(ticket);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<TicketProvider>.value(value: fakeTicketProvider),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: TicketDetailScreen(initialTicket: ticket),
      ),
    );
  }

  group('SePay Refund Demo UI & Receipt Verification', () {
    testWidgets('Renders permanent refund card when ticket status is cancelled', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final cancelledTicket = BookingModel(
        code: 'TESTREF1',
        status: 'cancelled',
        showtimeId: 'st-1',
        cinemaId: 'cin-1',
        movieTitle: 'MAI',
        cinemaName: 'CGV Landmark 81',
        roomName: 'Cinema 01',
        format: '2D Phụ đề',
        showtimeStart: DateTime.now().add(const Duration(hours: 5)),
        priceSnapshot: const {'total': 180000},
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      await tester.pumpWidget(createWidgetUnderTest(cancelledTicket));
      await tester.pumpAndSettle();

      // Verify refund information card is rendered
      expect(find.text('ĐÃ HOÀN TIỀN 100% THÀNH CÔNG'), findsOneWidget);
      expect(find.textContaining('0000000001 · CINEMA BOOKING SYSTEM'), findsOneWidget);
      expect(find.textContaining('0000000002 · NGUYEN VAN KHACH 1'), findsOneWidget);
      expect(find.textContaining('SEPAY-TESTREF1'), findsOneWidget);
      expect(find.text('XEM BIÊN NHẬN HOÀN TIỀN'), findsOneWidget);

      // Tap button to view full modal receipt
      await tester.scrollUntilVisible(find.text('XEM BIÊN NHẬN HOÀN TIỀN'), 300);
      await tester.tap(find.text('XEM BIÊN NHẬN HOÀN TIỀN'));
      await tester.pumpAndSettle();

      expect(find.text('HOÀN TIỀN THÀNH CÔNG'), findsOneWidget);
      expect(find.text('ĐÃ HIỂU & ĐÓNG'), findsOneWidget);

      await tester.tap(find.text('ĐÃ HIỂU & ĐÓNG'));
      await tester.pumpAndSettle();

      expect(find.text('HOÀN TIỀN THÀNH CÔNG'), findsNothing);
    });

    testWidgets('Cancelling paid ticket triggers refund dialog with 0000000001 details', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final paidTicket = BookingModel(
        code: 'PAIDDEMO',
        status: 'paid',
        showtimeId: 'st-1',
        cinemaId: 'cin-1',
        movieTitle: 'MAI',
        cinemaName: 'CGV Landmark 81',
        roomName: 'Cinema 01',
        format: '2D Phụ đề',
        showtimeStart: DateTime.now().add(const Duration(hours: 5)),
        priceSnapshot: const {'total': 90000},
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      await tester.pumpWidget(createWidgetUnderTest(paidTicket));
      await tester.pumpAndSettle();

      // Must find cancel button
      expect(find.text('HỦY VÉ VÀ HOÀN TIỀN'), findsOneWidget);

      // Tap cancel button
      await tester.scrollUntilVisible(find.text('HỦY VÉ VÀ HOÀN TIỀN'), 300);
      await tester.tap(find.text('HỦY VÉ VÀ HOÀN TIỀN'));
      await tester.pumpAndSettle();

      expect(find.text('XÁC NHẬN HỦY VÉ'), findsOneWidget);

      // Confirm cancel
      await tester.tap(find.text('XÁC NHẬN HỦY'));
      await tester.pumpAndSettle();

      // Verifies refund dialog is displayed
      expect(find.text('HOÀN TIỀN THÀNH CÔNG'), findsOneWidget);
      expect(find.textContaining('0000000001'), findsAtLeastNWidgets(1));
      expect(find.textContaining('0000000002'), findsAtLeastNWidgets(1));

      // Close dialog
      await tester.tap(find.text('ĐÃ HIỂU & ĐÓNG'));
      await tester.pumpAndSettle();

      // Screen is now updated to cancelled state with permanent refund card
      expect(find.text('ĐÃ HOÀN TIỀN 100% THÀNH CÔNG'), findsOneWidget);
      expect(find.textContaining('0000000001 · CINEMA BOOKING SYSTEM'), findsOneWidget);
    });
  });
}
