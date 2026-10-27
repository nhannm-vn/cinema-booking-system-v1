import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Spec Cell component following DESIGN_TOKENS.md Section 7.7
class SpecCell extends StatelessWidget {
  final String value;
  final String label;
  final bool isLarge;

  const SpecCell({
    super.key,
    required this.value,
    required this.label,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: isLarge
              ? AppTextStyles.numberDisplay
              : AppTextStyles.displayLg.copyWith(color: AppColors.ink),
        ),
        const SizedBox(height: AppSpacing.xxxs),
        Text(
          label.toUpperCase(),
          style: AppTextStyles.captionUppercase.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }
}
