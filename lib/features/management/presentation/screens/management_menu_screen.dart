import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/app_user.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../../../shared/widgets/manager_bottom_nav.dart';
import '../../../auth/presentation/controllers/auth_provider.dart';

/// Screen S12: Management Menu with role-based grouped sections.
/// References: ROLE_FLOWS.md Section 4.2 & Section 5.1
class ManagementMenuScreen extends StatelessWidget {
  const ManagementMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final isAdmin = user?.role == UserRole.admin;
    final cinemaName = user?.cinemaId != null && user!.cinemaId!.isNotEmpty
        ? 'RẠP ${user.cinemaId!.toUpperCase()}'
        : 'TOÀN HỆ THỐNG';

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'QUẢN LÝ HỆ THỐNG'.toUpperCase(),
              style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
            ),
            const SizedBox(height: AppSpacing.xxxs),
            Text(
              cinemaName,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Section 1: Operations
          _buildSectionHeader('VẬN HÀNH'),
          _buildMenuItem(
            context,
            icon: Icons.dashboard_outlined,
            title: 'Bàn làm việc / Dashboard (S22)',
            subtitle: 'Số liệu doanh thu, vé bán & tỷ lệ lấp đầy',
            route: AppRoutes.dashboard,
          ),
          _buildMenuItem(
            context,
            icon: Icons.receipt_long_outlined,
            title: 'Quản lý đơn vé & Bookings (S15)',
            subtitle: 'Tra cứu danh sách booking, trạng thái thanh toán',
            route: AppRoutes.manageBookings,
          ),
          _buildMenuItem(
            context,
            icon: Icons.badge_outlined,
            title: 'Quản lý nhân viên (S23)',
            subtitle: 'Tạo tài khoản, khóa / mở khóa nhân sự',
            route: AppRoutes.manageEmployees,
          ),
          _buildMenuItem(
            context,
            icon: Icons.chat_outlined,
            title: 'Hộp thư hỗ trợ khách (S31)',
            subtitle: 'Tin nhắn trực tuyến hai chiều với khách hàng',
            route: AppRoutes.supportChat,
          ),
          _buildMenuItem(
            context,
            icon: Icons.qr_code_scanner,
            title: 'Lối tắt: Soát vé tại cửa (S18)',
            subtitle: 'Quét QR và nhập mã soát vé',
            route: AppRoutes.staffCheckin,
          ),
          _buildMenuItem(
            context,
            icon: Icons.fastfood_outlined,
            title: 'Lối tắt: Quầy giao đồ ăn (S19)',
            subtitle: 'Bảng theo dõi và giao bắp nước',
            route: AppRoutes.staffFood,
          ),
          _buildMenuItem(
            context,
            icon: Icons.point_of_sale_outlined,
            title: 'Lối tắt: Bán vé tại quầy (S20)',
            subtitle: 'Chọn suất, chọn ghế và xuất vé tại quầy POS',
            route: AppRoutes.staffCounterShowtimes,
          ),

          const SizedBox(height: AppSpacing.lg),

          // Section 2: Catalog & Scheduling
          _buildSectionHeader('DANH MỤC & LỊCH CHIẾU'),
          _buildMenuItem(
            context,
            icon: Icons.movie_outlined,
            title: 'Phim (S13)',
            subtitle: isAdmin ? 'Thêm, sửa, quản lý phim toàn hệ thống' : 'Xem danh mục phim đang & sắp chiếu',
            route: AppRoutes.manageMovies,
            badge: isAdmin
                ? const AppBadge(label: 'TOÀN QUYỀN', backgroundColor: AppColors.primary)
                : const AppBadge(label: 'CHỈ XEM', backgroundColor: AppColors.muted),
          ),
          _buildMenuItem(
            context,
            icon: Icons.schedule_outlined,
            title: 'Lịch suất chiếu (S14)',
            subtitle: 'Lập lịch suất chiếu mới, kiểm tra giãn cách 15 phút',
            route: AppRoutes.manageShowtimes,
          ),
          _buildMenuItem(
            context,
            icon: Icons.lunch_dining_outlined,
            title: 'Menu bắp nước (S16)',
            subtitle: 'Bật / tắt trạng thái còn hàng, quản lý món ăn',
            route: AppRoutes.manageFoods,
          ),

          const SizedBox(height: AppSpacing.lg),

          // Section 3: Configuration & Pricing
          _buildSectionHeader('CẤU HÌNH & GIÁ'),
          _buildMenuItem(
            context,
            icon: Icons.price_change_outlined,
            title: 'Bảng giá vé (S26)',
            subtitle: isAdmin ? 'Cấu hình giá cơ sở và phụ thu động' : 'Xem cấu hình giá vé và phụ thu',
            route: AppRoutes.configPricing,
            badge: isAdmin
                ? const AppBadge(label: 'CHỈNH SỬA', backgroundColor: AppColors.primary)
                : const AppBadge(label: 'CHỈ XEM', backgroundColor: AppColors.muted),
          ),
          if (isAdmin) ...[
            _buildMenuItem(
              context,
              icon: Icons.meeting_room_outlined,
              title: 'Rạp & Phòng chiếu (S25)',
              subtitle: 'Quản lý hệ thống cụm rạp và phòng chiếu',
              route: AppRoutes.manageRooms,
            ),
            _buildMenuItem(
              context,
              icon: Icons.event_seat_outlined,
              title: 'Sơ đồ ghế (S24)',
              subtitle: 'Thiết kế ma trận ghế thường, VIP, đôi',
              route: AppRoutes.configSeatMap,
            ),
            _buildMenuItem(
              context,
              icon: Icons.confirmation_number_outlined,
              title: 'Mã giảm giá / Voucher (S27)',
              subtitle: 'Tạo và kiểm soát voucher khuyến mãi',
              route: AppRoutes.manageVouchers,
            ),
          ],

          if (isAdmin) ...[
            const SizedBox(height: AppSpacing.lg),

            // Section 4: System Administration
            _buildSectionHeader('QUẢN TRỊ HỆ THỐNG'),
            _buildMenuItem(
              context,
              icon: Icons.admin_panel_settings_outlined,
              title: 'Quản lý Quản lý rạp (S28)',
              subtitle: 'Phân công và quản lý tài khoản Manager',
              route: AppRoutes.manageManagers,
            ),
            _buildMenuItem(
              context,
              icon: Icons.history_edu_outlined,
              title: 'Nhật ký thao tác / Audit Logs (S29)',
              subtitle: 'Lịch sử soát vé, hoàn tiền, đổi giá, sơ đồ ghế',
              route: AppRoutes.auditLogs,
            ),
          ],

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
      bottomNavigationBar: const ManagerBottomNav(currentIndex: 1),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, left: AppSpacing.xxs),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.captionUppercase.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
    Widget? badge,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.hairline, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          leading: Icon(icon, color: AppColors.primary, size: 24),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.titleSm.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: AppSpacing.xs),
                badge,
              ],
            ],
          ),
          subtitle: Text(
            subtitle,
            style: AppTextStyles.caption.copyWith(color: AppColors.muted),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: AppColors.muted,
          ),
          onTap: () {
            Navigator.pushNamed(context, route);
          },
        ),
      ),
    );
  }
}
