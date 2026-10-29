import 'package:flutter/material.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Reusable Manager & Admin Bottom Navigation Bar with 3 tabs.
/// References: ROLE_FLOWS.md Section 0, 4 & 5, DESIGN_TOKENS.md Section 7.15
class ManagerBottomNav extends StatelessWidget {
  final int currentIndex;

  const ManagerBottomNav({
    super.key,
    required this.currentIndex,
  });

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
        break;
      case 1:
        Navigator.pushReplacementNamed(context, AppRoutes.managementHome);
        break;
      case 2:
        Navigator.pushReplacementNamed(context, AppRoutes.profile);
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
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
            label: 'TỔNG QUAN',
          ),
          _buildNavItem(
            context,
            index: 1,
            icon: Icons.menu_outlined,
            activeIcon: Icons.menu,
            label: 'QUẢN LÝ',
          ),
          _buildNavItem(
            context,
            index: 2,
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
