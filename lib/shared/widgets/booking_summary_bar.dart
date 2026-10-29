import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import 'app_button.dart';

/// Pinned bottom summary bar following DESIGN_TOKENS.md Section 7.9
class BookingSummaryBar extends StatelessWidget {
  final String seatSummary;
  final int totalPrice;
  final String buttonLabel;
  final VoidCallback? onButtonPressed;
  final bool isLoading;

  const BookingSummaryBar({
    super.key,
    required this.seatSummary,
    required this.totalPrice,
    this.buttonLabel = 'TIẾP TỤC',
    required this.onButtonPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.canvasElevated,
        border: Border(
          top: BorderSide(color: AppColors.hairline, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xxs,
          ),
          child: Row(
            children: [
              // Left: Info & Total
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (seatSummary.isNotEmpty)
                      Text(
                        seatSummary.toUpperCase(),
                        style: AppTextStyles.bodySm.copyWith(color: AppColors.body),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(
                      CurrencyFormatter.format(totalPrice),
                      style: AppTextStyles.displayLg.copyWith(color: AppColors.ink),
                    ),
                  ],
                ),
              ),

              // Right: Action Button
              AppButton.primary(
                label: buttonLabel,
                isLoading: isLoading,
                onPressed: onButtonPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
