import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import 'app_button.dart';

/// Error State component following DESIGN_TOKENS.md Section 7.16
class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel = 'THỬ LẠI',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.warning),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'ĐÃ XẢY RA LỖI',
              style: AppTextStyles.titleSm.copyWith(color: AppColors.warning),
            ),
            const SizedBox(height: AppSpacing.xxxs),
            Text(
              message,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.body),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.sm),
              AppButton.outline(
                label: retryLabel,
                onPressed: onRetry!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
