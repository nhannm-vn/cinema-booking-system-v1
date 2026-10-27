import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Promotional Band component following DESIGN_TOKENS.md Section 7.8
/// - Full-width band with primary red background (#DA291C)
/// - displayLg white text
/// - Maximum 1 promo band per screen
class PromoBand extends StatelessWidget {
  final String text;
  final String? subtitle;
  final VoidCallback? onTap;

  const PromoBand({
    super.key,
    required this.text,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        color: AppColors.primary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              text.toUpperCase(),
              style: AppTextStyles.displayLg.copyWith(color: AppColors.onPrimary),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(
                subtitle!,
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.onPrimary),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
