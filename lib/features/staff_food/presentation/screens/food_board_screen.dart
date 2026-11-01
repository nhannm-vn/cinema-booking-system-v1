import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/models/app_user.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/notification_badge.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../../shared/widgets/staff_bottom_nav.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../auth/presentation/controllers/auth_provider.dart';
import '../../../booking/data/models/booking_model.dart';
import '../controllers/staff_food_provider.dart';

/// S19: Food Delivery Board (/staff/food)
/// References: ROLE_FLOWS.md Section 3.2 & BUSINESS_RULES.md Section 9 & m4_plan.md Section 3.2
class FoodBoardScreen extends StatefulWidget {
  const FoodBoardScreen({super.key});

  @override
  State<FoodBoardScreen> createState() => _FoodBoardScreenState();
}

class _FoodBoardScreenState extends State<FoodBoardScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final auth = context.read<AuthProvider>();
          final cinemaId = auth.currentUser?.cinemaId ?? 'cn_q1';
          final provider = context.read<StaffFoodProvider>();
          provider.loadOrders(cinemaId);
          provider.subscribeRealtime(cinemaId);
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirmDeliver(BuildContext context, String bookingCode) async {
    final auth = context.read<AuthProvider>();
    final cinemaId = auth.currentUser?.cinemaId ?? 'cn_q1';
    final provider = context.read<StaffFoodProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.canvasElevated,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          'XÁC NHẬN GIAO ĐỒ ĂN',
          style: AppTextStyles.titleSm.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Xác nhận đã giao đủ đồ ăn cho đơn vé #$bookingCode?',
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.body),
        ),
        actions: [
          AppButton.text(
            label: 'HỦY',
            onPressed: () => Navigator.pop(dialogCtx, false),
          ),
          AppButton.primary(
            label: 'XÁC NHẬN',
            onPressed: () => Navigator.pop(dialogCtx, true),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await provider.deliverFood(bookingCode, cinemaId);
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.success,
              content: Text(
                'ĐÃ GIAO ĐỒ ĂN CHO ĐƠN #$bookingCode THÀNH CÔNG',
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        } else if (provider.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.warning,
              content: Text(
                provider.errorMessage!,
                style: AppTextStyles.bodySm.copyWith(color: AppColors.ink),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cinemaName = auth.currentUser?.cinemaId?.toUpperCase() ?? 'RẠP CHIẾU';
    final foodProvider = context.watch<StaffFoodProvider>();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'QUẦY ĐỒ ĂN',
              style: AppTextStyles.titleSm.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              cinemaName,
              style: AppTextStyles.caption.copyWith(color: AppColors.primary),
            ),
          ],
        ),
        actions: [
          NotificationBadge(
            unreadCount: 0,
            onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
          ),
          const SizedBox(width: AppSpacing.xxs),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: AppTextField(
              key: const Key('food_search_field'),
              controller: _searchController,
              hintText: 'TÌM THEO MÃ ĐẶT VÉ HOẶC TÊN PHIM...',
              prefixIcon: const Icon(Icons.search, color: AppColors.muted),
              onChanged: (val) => foodProvider.setSearchQuery(val),
            ),
          ),

          // Custom Tabs
          _buildTabs(foodProvider),

          // Content List with 3 UI States
          Expanded(
            child: _buildBody(context, foodProvider, auth.currentUser?.cinemaId ?? 'cn_q1'),
          ),
        ],
      ),
      bottomNavigationBar: auth.currentUser?.role == UserRole.manager || auth.currentUser?.role == UserRole.admin
          ? null
          : const StaffBottomNav(currentIndex: 1),
    );
  }

  Widget _buildTabs(StaffFoodProvider provider) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        border: Border(
          bottom: BorderSide(color: AppColors.hairline, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabItem(
              title: 'CHỜ GIAO (${provider.pendingOrders.length})',
              isSelected: provider.currentTabIndex == 0,
              onTap: () => provider.setTab(0),
              tabKey: const Key('food_tab_pending'),
            ),
          ),
          Expanded(
            child: _buildTabItem(
              title: 'ĐÃ GIAO (${provider.deliveredOrders.length})',
              isSelected: provider.currentTabIndex == 1,
              onTap: () => provider.setTab(1),
              tabKey: const Key('food_tab_delivered'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required Key tabKey,
  }) {
    return InkWell(
      key: tabKey,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title.toUpperCase(),
          textAlign: TextAlign.center,
          style: AppTextStyles.captionUppercase.copyWith(
            color: isSelected ? AppColors.primary : AppColors.muted,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, StaffFoodProvider provider, String cinemaId) {
    if (provider.isLoading) {
      return ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.xs),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
        itemBuilder: (_, __) => const SkeletonBox(
          width: double.infinity,
          height: 140,
        ),
      );
    }

    if (provider.errorMessage != null &&
        provider.pendingOrders.isEmpty &&
        provider.deliveredOrders.isEmpty) {
      return Center(
        child: ErrorState(
          message: provider.errorMessage!,
          onRetry: () => provider.loadOrders(cinemaId),
        ),
      );
    }

    final orders = provider.currentTabIndex == 0
        ? provider.pendingOrders
        : provider.deliveredOrders;

    if (orders.isEmpty) {
      return Center(
        child: EmptyState(
          title: provider.currentTabIndex == 0
              ? 'CHƯA CÓ ĐƠN CHỜ GIAO'
              : 'CHƯA CÓ ĐƠN ĐÃ GIAO',
          message: provider.currentTabIndex == 0
              ? 'Hiện tại không có đơn đồ ăn nào cần chuẩn bị.'
              : 'Chưa có đơn đồ ăn nào được giao hôm nay.',
          icon: Icons.fastfood_outlined,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.xs),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(context, order, provider.currentTabIndex == 0);
      },
    );
  }

  Widget _buildOrderCard(BuildContext context, BookingModel order, bool isPending) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.canvasElevated,
        border: Border.all(color: AppColors.hairline, width: 1),
        borderRadius: BorderRadius.zero,
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Code and Showtime
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#${order.code}',
                style: AppTextStyles.titleSm.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${order.roomName} · ${DateFormatter.formatTime(order.showtimeStart)}',
                style: AppTextStyles.caption.copyWith(color: AppColors.body),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxxs),

          // Movie Title
          Text(
            order.movieTitle,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Food items list
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.zero,
              border: Border.all(color: AppColors.hairline, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (order.foods.isNotEmpty)
                  ...order.foods.map((food) {
                    final qty = food['qty'] ?? 1;
                    final name = food['name'] ?? 'Món ăn';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xxxs,
                              vertical: 2,
                            ),
                            decoration: const BoxDecoration(
                              color: AppColors.canvasElevated,
                              borderRadius: BorderRadius.zero,
                            ),
                            child: Text(
                              '${qty}x',
                              style: AppTextStyles.captionUppercase.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xxs),
                          Expanded(
                            child: Text(
                              name,
                              style: AppTextStyles.bodySm.copyWith(
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  })
                else
                  Text(
                    order.foodSummary.isNotEmpty
                        ? order.foodSummary
                        : 'Không có thông tin món',
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.ink),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Bottom Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'GHẾ: ${order.seatNamesSummary.isNotEmpty ? order.seatNamesSummary : "TẠI QUẦY"}',
                  style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              if (isPending)
                AppButton.primary(
                  key: Key('deliver_btn_${order.code}'),
                  label: 'ĐÃ GIAO',
                  onPressed: () => _confirmDeliver(context, order.code),
                )
              else
                const StatusBadge(
                  status: 'delivered',
                ),
            ],
          ),
        ],
      ),
    );
  }
}
