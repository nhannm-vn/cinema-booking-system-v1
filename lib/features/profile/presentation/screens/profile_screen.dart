import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/app_user.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/customer_bottom_nav.dart';
import '../../../../shared/widgets/manager_bottom_nav.dart';
import '../../../../shared/widgets/staff_bottom_nav.dart';
import '../../../auth/presentation/controllers/auth_provider.dart';

/// S11 Profile Screen.
/// References: ROLE_FLOWS.md Section 1, DESIGN_TOKENS.md, m3_plan.md Section 3.7
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.canvasElevated,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.zeroRadius),
        title: Text(
          'ĐĂNG XUẤT'.toUpperCase(),
          style: AppTextStyles.titleMd.copyWith(color: AppColors.ink),
        ),
        content: Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản?',
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.body),
        ),
        actions: [
          AppButton.outline(
            label: 'HỦY',
            onPressed: () => Navigator.pop(ctx),
          ),
          const SizedBox(height: AppSpacing.xxs),
          AppButton.primary(
            label: 'ĐĂNG XUẤT',
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthProvider>().signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.home);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    final String fullName = user?.fullName ?? 'Người Dùng';
    final String email = user?.email ?? '';
    final String? phone = user?.phone;
    final String initial = fullName.trim().isNotEmpty
        ? fullName.trim()[0].toUpperCase()
        : 'U';
    final String role = user?.role.name.toUpperCase() ?? 'CUSTOMER';

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        title: Text(
          'TÀI KHOẢN'.toUpperCase(),
          style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // User Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.canvasElevated,
              border: Border.all(color: AppColors.hairline, width: 1),
              borderRadius: AppRadius.zeroRadius,
            ),
            child: Row(
              children: [
                // Avatar with initial
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: AppTextStyles.displayLg.copyWith(color: AppColors.onPrimary),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),

                // Name, Email, Phone, Role
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              fullName,
                              style: AppTextStyles.titleMd.copyWith(color: AppColors.ink),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          AppBadge(
                            label: role,
                            backgroundColor: AppColors.canvasElevated,
                            textColor: AppColors.ink,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        email,
                        style: AppTextStyles.bodySm.copyWith(color: AppColors.body),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (phone != null && phone.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xxxs),
                        Text(
                          phone,
                          style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                        ),
                      ],
                      if (user?.cinemaId != null && user!.cinemaId!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xxxs),
                        Text(
                          'RẠP: ${user.cinemaId!.toUpperCase()}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Action Items
          Container(
            decoration: BoxDecoration(
              color: AppColors.canvasElevated,
              border: Border.all(color: AppColors.hairline, width: 1),
              borderRadius: AppRadius.zeroRadius,
            ),
            child: Column(
              children: [
                _buildMenuItem(
                  icon: Icons.edit_outlined,
                  title: 'SỬA HỒ SƠ',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.editProfile),
                ),
                const Divider(color: AppColors.hairline, height: 1),
                _buildMenuItem(
                  icon: Icons.headset_mic_outlined,
                  title: 'HỘP THƯ HỖ TRỢ',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.supportChat),
                ),
                const Divider(color: AppColors.hairline, height: 1),
                _buildMenuItem(
                  icon: Icons.logout,
                  title: 'ĐĂNG XUẤT',
                  textColor: AppColors.primary,
                  iconColor: AppColors.primary,
                  onTap: () => _confirmSignOut(context),
                  showTrailing: false,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(user),
    );
  }

  Widget _buildBottomNav(AppUser? user) {
    if (user?.role == UserRole.manager || user?.role == UserRole.admin) {
      return const ManagerBottomNav(currentIndex: 2);
    }
    if (user?.role == UserRole.staff) {
      return const StaffBottomNav(currentIndex: 3);
    }
    return const CustomerBottomNav(currentIndex: 3);
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
    bool showTrailing = true,
  }) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor ?? AppColors.ink),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: AppTextStyles.bodyMd.copyWith(
                  color: textColor ?? AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (showTrailing)
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.muted,
              ),
          ],
        ),
      ),
    );
  }
}
