import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import 'app_button.dart';

/// Check-in Result Bottom Sheet following BUSINESS_RULES.md Section 8
class ResultSheet extends StatefulWidget {
  final bool isValid;
  final String? errorMessage;
  final String? movieTitle;
  final String? roomName;
  final String? showtime;
  final String? seats;
  final String? foods;
  final String? ageRating;
  final VoidCallback onConfirm;
  final VoidCallback onDismiss;

  const ResultSheet({
    super.key,
    required this.isValid,
    this.errorMessage,
    this.movieTitle,
    this.roomName,
    this.showtime,
    this.seats,
    this.foods,
    this.ageRating,
    required this.onConfirm,
    required this.onDismiss,
  });

  @override
  State<ResultSheet> createState() => _ResultSheetState();
}

class _ResultSheetState extends State<ResultSheet> {
  bool _idVerified = false;

  bool get _requiresIdCheck {
    final rating = widget.ageRating?.toUpperCase();
    return rating == 'T16' || rating == 'T18';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.canvasElevated,
        borderRadius: AppRadius.sheetRadius,
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Icon & Title
            Center(
              child: Icon(
                widget.isValid ? Icons.check_circle_outline : Icons.cancel_outlined,
                size: 56,
                color: widget.isValid ? AppColors.success : AppColors.warning,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              widget.isValid ? 'VÉ HỢP LỆ' : 'VÉ KHÔNG HỢP LỆ',
              style: AppTextStyles.titleMd.copyWith(
                color: widget.isValid ? AppColors.success : AppColors.warning,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),

            if (!widget.isValid) ...[
              // Error message
              Text(
                widget.errorMessage ?? 'Vé không hợp lệ.',
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.ink),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton.outline(
                label: 'QUÉT TIẾP',
                onPressed: widget.onDismiss,
              ),
            ] else ...[
              // Ticket details
              Text(
                widget.movieTitle ?? '',
                style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxxs),
              Text(
                '${widget.roomName ?? ''} · ${widget.showtime ?? ''}',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.body),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxxs),
              Text(
                'GHẾ: ${widget.seats ?? ''}',
                style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
                textAlign: TextAlign.center,
              ),
              if (widget.foods != null && widget.foods!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxxs),
                Text(
                  'ĐỒ ĂN: ${widget.foods!}',
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.info),
                  textAlign: TextAlign.center,
                ),
              ],

              // Age verification warning for T16/T18
              if (_requiresIdCheck) ...[
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    border: Border.all(color: AppColors.warning, width: 1),
                    borderRadius: AppRadius.smRadius,
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _idVerified,
                        activeColor: AppColors.warning,
                        onChanged: (val) => setState(() => _idVerified = val ?? false),
                      ),
                      Expanded(
                        child: Text(
                          'Khán giả phim ${widget.ageRating}. Đã kiểm tra giấy tờ tùy thân hợp lệ.',
                          style: AppTextStyles.caption.copyWith(color: AppColors.ink),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.sm),

              // Confirm button
              AppButton.primary(
                label: 'XÁC NHẬN CHO VÀO',
                onPressed: (!_requiresIdCheck || _idVerified) ? widget.onConfirm : null,
              ),
              const SizedBox(height: AppSpacing.xxs),
              AppButton.text(
                label: 'BỎ QUA',
                onPressed: widget.onDismiss,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
