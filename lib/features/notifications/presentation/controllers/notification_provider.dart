import 'package:flutter/material.dart';
import '../../data/notification_repository.dart';

/// Provider quản lý thông báo người dùng (S30).
class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _repo;

  NotificationProvider([NotificationRepository? repo])
      : _repo = repo ?? NotificationRepository();

  bool _isLoading = false;
  String? _errorMessage;
  List<NotificationModel> _notifications = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<NotificationModel> get notifications => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Tải danh sách thông báo.
  Future<void> loadNotifications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _notifications = await _repo.getNotifications();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách thông báo: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Đánh dấu tất cả thông báo là đã đọc.
  Future<void> markAllAsRead() async {
    try {
      await _repo.markAllAsRead();
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
    } catch (_) {}
  }
}
