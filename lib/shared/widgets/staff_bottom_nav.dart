import 'package:flutter/material.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Reusable Staff Bottom Navigation Bar with 4 operational tabs.
/// References: ROLE_FLOWS.md Section 3, DESIGN_TOKENS.md Section 7.15, m4_plan.md Section 4.1
class StaffBottomNav extends StatelessWidget {
  final int currentIndex;

  const StaffBottomNav({
    super.key,
    required this.currentIndex,
  });

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, AppRoutes.staffCheckin);
        break;
      case 1:
        Navigator.pushReplacementNamed(context, AppRoutes.staffFood);
        break;
      case 2:
        Navigator.pushReplacementNamed(context, AppRoutes.staffCounterShowtimes);
        break;
      case 3:
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
            icon: Icons.qr_code_scanner,
            activeIcon: Icons.qr_code_scanner,
            label: 'SOÁT VÉ',
          ),
          _buildNavItem(
            context,
            index: 1,
            icon: Icons.fastfood_outlined,
            activeIcon: Icons.fastfood,
            label: 'ĐỒ ĂN',
          ),
          _buildNavItem(
            context,
            index: 2,
            icon: Icons.point_of_sale_outlined,
            activeIcon: Icons.point_of_sale,
            label: 'BÁN VÉ',
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
