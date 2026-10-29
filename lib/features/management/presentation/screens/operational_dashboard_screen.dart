import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/manager_bottom_nav.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../auth/presentation/controllers/auth_provider.dart';
import '../controllers/management_provider.dart';

/// Screen S22: Operational Dashboard with real-time revenue, tickets, and occupancy metrics.
/// References: ROLE_FLOWS.md Section 4.1 & 5.1, BUSINESS_RULES.md Section 4
class OperationalDashboardScreen extends StatefulWidget {
  const OperationalDashboardScreen({super.key});

  @override
  State<OperationalDashboardScreen> createState() => _OperationalDashboardScreenState();
}

class _OperationalDashboardScreenState extends State<OperationalDashboardScreen> {
  String _selectedPeriod = 'today';
  String _activeCinemaId = 'cn_q1';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user?.cinemaId != null && user!.cinemaId!.isNotEmpty) {
        _activeCinemaId = user.cinemaId!;
      }
      _loadMetrics();
    });
  }

  void _loadMetrics() {
    context.read<ManagementProvider>().loadDashboardMetrics(
      _activeCinemaId,
      period: _selectedPeriod,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ManagementProvider>();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BÀN LÀM VIỆC VẬN HÀNH'.toUpperCase(),
              style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
            ),
            const SizedBox(height: AppSpacing.xxxs),
            Text(
              'RẠP ${_activeCinemaId.toUpperCase()}',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadMetrics(),
        color: AppColors.primary,
        backgroundColor: AppColors.canvasElevated,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Period Filter Selector
              _buildPeriodSelector(),
              const SizedBox(height: AppSpacing.md),

              // KPI 4-cell Grid
              _buildMetricsGrid(provider),
              const SizedBox(height: AppSpacing.lg),

              // Quick Action Shortcuts
              Text(
                'LỐI TẮT THAO TÁC NHANH'.toUpperCase(),
                style: AppTextStyles.captionUppercase.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildQuickActions(context),
              const SizedBox(height: AppSpacing.lg),

              // Upcoming Showtimes Section
              Text(
                'SUẤT CHIẾU SẮP DIỄN RA'.toUpperCase(),
                style: AppTextStyles.captionUppercase.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildUpcomingShowtimes(provider),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const ManagerBottomNav(currentIndex: 0),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxs),
      decoration: BoxDecoration(
        color: AppColors.canvasElevated,
        borderRadius: AppRadius.zeroRadius,
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: [
          _buildPeriodTab('HÔM NAY', 'today'),
          _buildPeriodTab('7 NGÀY', 'week'),
          _buildPeriodTab('THÁNG NÀY', 'month'),
        ],
      ),
    );
  }

  Widget _buildPeriodTab(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return Expanded(
      child: InkWell(
        onTap: () {
          if (_selectedPeriod != value) {
            setState(() => _selectedPeriod = value);
            _loadMetrics();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: AppRadius.zeroRadius,
          ),
          alignment: Alignment.center,
          child: Text(
            label.toUpperCase(),
            style: AppTextStyles.button.copyWith(
              color: isSelected ? AppColors.ink : AppColors.muted,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(ManagementProvider provider) {
    if (provider.isLoading) {
      return const Column(
        children: [
          Row(
            children: [
              Expanded(child: SkeletonBox(width: double.infinity, height: 90)),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: SkeletonBox(width: double.infinity, height: 90)),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: SkeletonBox(width: double.infinity, height: 90)),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: SkeletonBox(width: double.infinity, height: 90)),
            ],
          ),
        ],
      );
    }

    if (provider.errorMessage != null) {
      return ErrorState(
        message: provider.errorMessage!,
        onRetry: () => _loadMetrics(),
      );
    }

    final metrics = provider.metrics;
    if (metrics == null) {
      return const EmptyState(
        title: 'KHÔNG CÓ DỮ LIỆU',
        message: 'Không có dữ liệu vận hành',
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                label: 'DOANH THU THỰC',
                value: CurrencyFormatter.format(metrics.todayRevenue),
                highlightColor: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildMetricCard(
                label: 'SỐ VÉ ĐÃ BÁN',
                value: '${metrics.todayTickets} vé',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                label: 'TỈ LỆ LẤP ĐẦY',
                value: '${metrics.occupancyRate.toStringAsFixed(1)}%',
                highlightColor: metrics.occupancyRate >= 70
                    ? AppColors.success
                    : (metrics.occupancyRate < 30 ? AppColors.warning : AppColors.ink),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildMetricCard(
                label: 'CÔNG SUẤT PHÒNG',
                value: '${metrics.soldCapacity}/${metrics.totalCapacity} ghế',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    Color? highlightColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.canvasElevated,
        borderRadius: AppRadius.zeroRadius,
        border: Border.all(color: AppColors.hairline, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTextStyles.captionUppercase.copyWith(
              color: AppColors.muted,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTextStyles.titleSm.copyWith(
              color: highlightColor ?? AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        _buildActionTile(
          context,
          icon: Icons.schedule,
          label: 'LẬP SUẤT',
          route: AppRoutes.manageShowtimes,
        ),
        const SizedBox(width: AppSpacing.xs),
        _buildActionTile(
          context,
          icon: Icons.point_of_sale,
          label: 'BÁN QUẦY',
          route: AppRoutes.staffCounterShowtimes,
        ),
        const SizedBox(width: AppSpacing.xs),
        _buildActionTile(
          context,
          icon: Icons.qr_code_scanner,
          label: 'SOÁT VÉ',
          route: AppRoutes.staffCheckin,
        ),
        const SizedBox(width: AppSpacing.xs),
        _buildActionTile(
          context,
          icon: Icons.receipt_long,
          label: 'ĐƠN VÉ',
          route: AppRoutes.manageBookings,
        ),
      ],
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.canvasElevated,
            borderRadius: AppRadius.zeroRadius,
            border: Border.all(color: AppColors.hairline),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                label.toUpperCase(),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.ink,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingShowtimes(ManagementProvider provider) {
    if (provider.isLoading) {
      return const Column(
        children: [
          SkeletonBox(width: double.infinity, height: 72),
          SizedBox(height: AppSpacing.sm),
          SkeletonBox(width: double.infinity, height: 72),
        ],
      );
    }

    final upcoming = provider.metrics?.upcomingShowtimes ?? [];
    if (upcoming.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.canvasElevated,
          borderRadius: AppRadius.zeroRadius,
          border: Border.all(color: AppColors.hairline),
        ),
        child: Center(
          child: Text(
            'Không có suất chiếu nào sắp diễn ra trong ngày',
            style: AppTextStyles.caption.copyWith(color: AppColors.muted),
          ),
        ),
      );
    }

    return Column(
      children: upcoming.map((showtime) {
        final progress = showtime.totalSeats > 0 ? (showtime.soldSeats / showtime.totalSeats) : 0.0;
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.xs),
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.canvasElevated,
            borderRadius: AppRadius.zeroRadius,
            border: Border.all(color: AppColors.hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    DateFormatter.formatTime(showtime.startTime),
                    style: AppTextStyles.titleSm.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      showtime.movieTitle,
                      style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AppBadge.format(showtime.format),
                ],
              ),
              const SizedBox(height: AppSpacing.xxs),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    showtime.roomName,
                    style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                  ),
                  Text(
                    '${showtime.soldSeats}/${showtime.totalSeats} ghế (${(progress * 100).toInt()}%)',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxs),
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: AppColors.canvas,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 3,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
