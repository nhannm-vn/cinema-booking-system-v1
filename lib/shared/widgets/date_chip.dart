import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Date Chip component following DESIGN_TOKENS.md Section 7.5
class DateChip extends StatelessWidget {
  final String weekday;
  final String dayNumber;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback? onTap;

  const DateChip({
    super.key,
    required this.weekday,
    required this.dayNumber,
    this.isSelected = false,
    this.isEnabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Border? border;
    Color textColor;

    if (!isEnabled) {
      bg = Colors.transparent;
      border = Border.all(color: AppColors.muted, width: 1);
      textColor = AppColors.muted;
    } else if (isSelected) {
      bg = AppColors.primary;
      border = null;
      textColor = AppColors.onPrimary;
    } else {
      bg = Colors.transparent;
      border = Border.all(color: AppColors.ink, width: 1);
      textColor = AppColors.ink;
    }

    return InkWell(
      onTap: isEnabled ? onTap : null,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Container(
        width: 56,
        height: 64,
        decoration: BoxDecoration(
          color: bg,
          border: border,
          borderRadius: AppRadius.zeroRadius,
        ),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              weekday.toUpperCase(),
              style: AppTextStyles.captionUppercase.copyWith(color: textColor),
            ),
            const SizedBox(height: AppSpacing.xxxs),
            Text(
              dayNumber,
              style: AppTextStyles.titleMd.copyWith(color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}
