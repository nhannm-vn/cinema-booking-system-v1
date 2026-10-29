import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';

/// Showtime Row component following DESIGN_TOKENS.md Section 7.4
class ShowtimeRow extends StatelessWidget {
  final String startTime;
  final String roomName;
  final String format;
  final int minPrice;
  final bool isSoldOut;
  final VoidCallback? onTap;

  const ShowtimeRow({
    super.key,
    required this.startTime,
    required this.roomName,
    required this.format,
    required this.minPrice,
    this.isSoldOut = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isSoldOut ? AppColors.muted : AppColors.ink;
    final subtextColor = isSoldOut ? AppColors.muted : AppColors.body;

    return InkWell(
      onTap: isSoldOut ? null : onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.hairline, width: 1)),
        ),
        child: Row(
          children: [
            // Left: Start time
            SizedBox(
              width: 72,
              child: Text(
                startTime,
                style: AppTextStyles.titleMd.copyWith(color: textColor),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),

            // Center: Room & Format
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    roomName,
                    style: AppTextStyles.bodyMd.copyWith(color: textColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xxxs),
                  Text(
                    format.toUpperCase(),
                    style: AppTextStyles.captionUppercase.copyWith(color: subtextColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),

            // Right: Price or "HẾT VÉ"
            if (isSoldOut)
              Text(
                'HẾT VÉ',
                style: AppTextStyles.captionUppercase.copyWith(color: AppColors.muted),
              )
            else
              Text(
                'từ ${CurrencyFormatter.format(minPrice)}',
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.ink),
              ),
          ],
        ),
      ),
    );
  }
}
