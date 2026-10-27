import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/auth/presentation/controllers/auth_provider.dart';

/// Reusable Customer Bottom Navigation Bar.
/// References: ROLE_FLOWS.md Section 1, DESIGN_TOKENS.md Section 7.15, m2_plan.md Section 3
class CustomerBottomNav extends StatelessWidget {
  final int currentIndex;

  const CustomerBottomNav({
    super.key,
    required this.currentIndex,
  });

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return;

    final auth = context.read<AuthProvider>();

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, AppRoutes.home);
        break;
      case 1:
        Navigator.pushReplacementNamed(context, AppRoutes.cinemas);
        break;
      case 2:
        if (auth.isAuthenticated) {
          Navigator.pushReplacementNamed(context, AppRoutes.myTickets);
        } else {
          Navigator.pushNamed(
            context,
            AppRoutes.login,
            arguments: {'redirectRoute': AppRoutes.myTickets},
          );
        }
        break;
      case 3:
        if (auth.isAuthenticated) {
          Navigator.pushReplacementNamed(context, AppRoutes.profile);
        } else {
          Navigator.pushNamed(
            context,
            AppRoutes.login,
            arguments: {'redirectRoute': AppRoutes.profile},
          );
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        border: Border(
          top: BorderSide(
            color: AppColors.hairline,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            context,
            index: 0,
            icon: Icons.movie_outlined,
            activeIcon: Icons.movie,
            label: 'PHIM',
          ),
          _buildNavItem(
            context,
            index: 1,
            icon: Icons.place_outlined,
            activeIcon: Icons.place,
            label: 'RẠP',
          ),
          _buildNavItem(
            context,
            index: 2,
            icon: Icons.confirmation_number_outlined,
            activeIcon: Icons.confirmation_number,
            label: 'VÉ CỦA TÔI',
          ),
          _buildNavItem(
            context,
            index: 3,
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'TÀI KHOẢN',
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final bool isSelected = index == currentIndex;
    final color = isSelected ? AppColors.primary : AppColors.muted;
    final textColor = isSelected ? AppColors.ink : AppColors.muted;

    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(context, index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: color,
              size: 22,
            ),
            const SizedBox(height: AppSpacing.xxxs),
            Text(
              label.toUpperCase(),
              style: AppTextStyles.captionUppercase.copyWith(
                color: textColor,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
