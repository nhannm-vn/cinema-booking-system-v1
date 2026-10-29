import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cinema_booking_v1/core/routes/app_router.dart';
import 'package:cinema_booking_v1/core/theme/app_theme.dart';
import 'package:cinema_booking_v1/features/notifications/data/notification_repository.dart';
import 'package:cinema_booking_v1/features/notifications/presentation/controllers/notification_provider.dart';
import 'package:cinema_booking_v1/features/notifications/presentation/screens/notification_center_screen.dart';
import 'package:cinema_booking_v1/shared/widgets/empty_state.dart';
import 'package:cinema_booking_v1/shared/widgets/error_state.dart';
import 'package:cinema_booking_v1/shared/widgets/skeleton_box.dart';

class FakeFullNotificationProvider extends ChangeNotifier implements NotificationProvider {
  bool _isLoading = false;
  String? _errorMessage;
  List<NotificationModel> _notifications = [];
  bool markAllAsReadCalled = false;

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
  List<NotificationModel> get notifications => _notifications;
  void setNotifications(List<NotificationModel> list) {
    _notifications = list;
    notifyListeners();
  }

  @override
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  @override
  Future<void> loadNotifications() async {}

  @override
  Future<void> markAllAsRead() async {
    markAllAsReadCalled = true;
    _notifications = _notifications
        .map((n) => NotificationModel(
              id: n.id,
              userId: n.userId,
              type: n.type,
              title: n.title,
              body: n.body,
              bookingCode: n.bookingCode,
              isRead: true,
              createdAt: n.createdAt,
            ))
        .toList();
    notifyListeners();
  }
}

Widget createNotificationTestHarness({
  required FakeFullNotificationProvider notifProvider,
}) {
  return ChangeNotifierProvider<NotificationProvider>.value(
    value: notifProvider,
    child: MaterialApp(
      theme: AppTheme.dark,
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.myTickets) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('MY TICKETS SCREEN')),
          );
        }
        return MaterialPageRoute(
          builder: (_) => Scaffold(body: Text('ROUTE: ${settings.name}')),
        );
      },
      home: const NotificationCenterScreen(),
    ),
  );
}

void main() {
  group('S30 Notification Center Screen Widget Tests', () {
    late FakeFullNotificationProvider fakeNotifs;

    final unreadNotif = NotificationModel(
      id: 'notif_01',
      userId: 'usr_01',
      type: 'bookingPaid',
      title: 'Đặt vé thành công',
      body: 'Bạn đã thanh toán thành công vé xem phim Mai.',
      bookingCode: 'K7M2QX9P',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    );

    final readNotif = NotificationModel(
      id: 'notif_02',
      userId: 'usr_01',
      type: 'showReminder',
      title: 'Nhắc nhở suất chiếu',
      body: 'Suất chiếu phim sẽ bắt đầu sau 30 phút.',
      bookingCode: 'K7M2QX9P',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    );

    setUp(() {
      fakeNotifs = FakeFullNotificationProvider();
    });

    testWidgets('renders screen title and notifications list', (tester) async {
      fakeNotifs.setNotifications([unreadNotif, readNotif]);

      await tester.pumpWidget(createNotificationTestHarness(notifProvider: fakeNotifs));

      expect(find.text('THÔNG BÁO'), findsOneWidget);
      expect(find.text('Đặt vé thành công'), findsOneWidget);
      expect(find.text('Nhắc nhở suất chiếu'), findsOneWidget);
      expect(find.byKey(const Key('mark_all_read_button')), findsOneWidget);
    });

    testWidgets('renders SkeletonBox when loading', (tester) async {
      fakeNotifs.isLoading = true;

      await tester.pumpWidget(createNotificationTestHarness(notifProvider: fakeNotifs));

      expect(find.byType(SkeletonBox), findsAtLeastNWidgets(1));
    });

    testWidgets('renders ErrorState with retry when error occurs', (tester) async {
      fakeNotifs.errorMessage = 'Không thể tải thông báo.';

      await tester.pumpWidget(createNotificationTestHarness(notifProvider: fakeNotifs));

      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.text('Không thể tải thông báo.'), findsOneWidget);
    });

    testWidgets('renders EmptyState when notifications list is empty', (tester) async {
      fakeNotifs.setNotifications([]);

      await tester.pumpWidget(createNotificationTestHarness(notifProvider: fakeNotifs));

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('Bạn không có thông báo nào'), findsOneWidget);
    });

    testWidgets('tapping ĐÃ ĐỌC TẤT CẢ marks all as read', (tester) async {
      fakeNotifs.setNotifications([unreadNotif, readNotif]);

      await tester.pumpWidget(createNotificationTestHarness(notifProvider: fakeNotifs));

      expect(fakeNotifs.unreadCount, 1);
      await tester.tap(find.byKey(const Key('mark_all_read_button')));
      await tester.pumpAndSettle();

      expect(fakeNotifs.markAllAsReadCalled, isTrue);
      expect(fakeNotifs.unreadCount, 0);
    });

    testWidgets('tapping notification with bookingCode navigates to myTickets', (tester) async {
      fakeNotifs.setNotifications([unreadNotif]);

      await tester.pumpWidget(createNotificationTestHarness(notifProvider: fakeNotifs));

      await tester.tap(find.byKey(const Key('notification_item_notif_01')));
      await tester.pumpAndSettle();

      expect(find.text('MY TICKETS SCREEN'), findsOneWidget);
    });
  });
}
