import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../data/notification_repository.dart';
import '../controllers/notification_provider.dart';

/// S30 Notification Center Screen.
/// References: ROLE_FLOWS.md Section 1, BUSINESS_RULES.md Section 14, m2_plan.md Section 2.7
class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadNotifications();
    });
  }

  IconData _getIconForType(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('paid') || lower.contains('booking_paid')) {
      return Icons.check_circle_outline;
    } else if (lower.contains('reminder') || lower.contains('show_reminder')) {
      return Icons.alarm_outlined;
    } else if (lower.contains('cancelled') || lower.contains('cancel')) {
      return Icons.cancel_outlined;
    } else if (lower.contains('refund')) {
      return Icons.currency_exchange_outlined;
    } else if (lower.contains('food')) {
      return Icons.fastfood_outlined;
    }
    return Icons.notifications_outlined;
  }

  Color _getColorForType(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('paid') || lower.contains('food')) {
      return AppColors.success;
    } else if (lower.contains('reminder')) {
      return AppColors.info;
    } else if (lower.contains('cancel') || lower.contains('refund')) {
      return AppColors.warning;
    }
    return AppColors.primary;
  }

  void _onNotificationTap(NotificationModel notification) {
    if (notification.bookingCode != null && notification.bookingCode!.isNotEmpty) {
      Navigator.pushNamed(context, AppRoutes.myTickets);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'THÔNG BÁO',
          style: AppTextStyles.titleSm.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          if (provider.unreadCount > 0)
            AppButton.text(
              key: const Key('mark_all_read_button'),
              label: 'ĐÃ ĐỌC TẤT CẢ',
              onPressed: () => provider.markAllAsRead(),
            ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.canvasElevated,
          onRefresh: () => provider.loadNotifications(),
          child: _buildContent(context, provider),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, NotificationProvider provider) {
    if (provider.isLoading) {
      return ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.xs),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
        itemBuilder: (_, __) => const SkeletonBox(
          width: double.infinity,
          height: 80,
        ),
      );
    }

    if (provider.errorMessage != null) {
      return ErrorState(
        message: provider.errorMessage!,
        onRetry: () => provider.loadNotifications(),
      );
    }

    final notifications = provider.notifications;
    if (notifications.isEmpty) {
      return const EmptyState(
        icon: Icons.notifications_off_outlined,
        title: 'Bạn không có thông báo nào',
        message: 'Khi có cập nhật về vé hoặc suất chiếu, thông báo sẽ hiển thị tại đây.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      itemCount: notifications.length,
      separatorBuilder: (_, __) => const Divider(
        color: AppColors.hairline,
        height: 1,
      ),
      itemBuilder: (context, index) {
        final notif = notifications[index];
        final icon = _getIconForType(notif.type);
        final iconColor = _getColorForType(notif.type);

        return InkWell(
          key: Key('notification_item_${notif.id}'),
          onTap: () => _onNotificationTap(notif),
          child: Container(
            color: notif.isRead ? AppColors.canvas : AppColors.canvasElevated,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.canvas,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              notif.title,
                              style: AppTextStyles.titleSm.copyWith(
                                color: AppColors.ink,
                                fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!notif.isRead) ...[
                            const SizedBox(width: AppSpacing.xxs),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: AppRadius.fullRadius,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxxs),
                      Text(
                        notif.body,
                        style: AppTextStyles.bodySm.copyWith(
                          color: notif.isRead ? AppColors.muted : AppColors.body,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        DateFormatter.formatDateTime(notif.createdAt),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
