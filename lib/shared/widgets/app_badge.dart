import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Badge pill component following DESIGN_TOKENS.md Section 7.2
class AppBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final BorderSide? border;

  const AppBadge({
    super.key,
    required this.label,
    this.backgroundColor = AppColors.canvasElevated,
    this.textColor = AppColors.ink,
    this.border,
  });

  /// Factory for Age rating badges: P, T13, T16, T18
  factory AppBadge.age(String rating) {
    Color bg = AppColors.canvasElevated;
    Color text = AppColors.ink;
    switch (rating.toUpperCase()) {
      case 'T18':
      case 'T16':
        bg = AppColors.warning;
        text = AppColors.ink;
        break;
      case 'T13':
        bg = AppColors.info;
        text = AppColors.ink;
        break;
      case 'P':
      default:
        bg = AppColors.success;
        text = AppColors.ink;
        break;
    }
    return AppBadge(
      label: rating.toUpperCase(),
      backgroundColor: bg,
      textColor: text,
    );
  }

  /// Factory for Format badges: 2D, 3D, IMAX
  factory AppBadge.format(String format) {
    return AppBadge(
      label: format.toUpperCase(),
      backgroundColor: AppColors.canvasElevated,
      textColor: AppColors.ink,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: AppSpacing.xxxs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadius.fullRadius,
        border: border != null ? Border.fromBorderSide(border!) : null,
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.captionUppercase.copyWith(color: textColor),
      ),
    );
  }
}
