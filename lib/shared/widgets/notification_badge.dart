import 'package:flutter/material.dart';

/// Notification Bell Icon placeholder (no-op/shrink).
class NotificationBadge extends StatelessWidget {
  final int unreadCount;
  final VoidCallback? onTap;

  const NotificationBadge({
    super.key,
    required this.unreadCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
