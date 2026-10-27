import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import 'seat_widget.dart';

/// Seat Legend Component following DESIGN_TOKENS.md Section 7.13
class SeatLegend extends StatelessWidget {
  const SeatLegend({super.key});

  Widget _buildItem(Widget seat, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        seat,
        const SizedBox(width: AppSpacing.xxs),
        Text(
          label.toUpperCase(),
          style: AppTextStyles.captionUppercase.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xxs,
      alignment: WrapAlignment.center,
      children: [
        _buildItem(
          const SeatWidget(seatId: '', type: SeatType.standard, state: SeatState.available),
          'Thường',
        ),
        _buildItem(
          const SeatWidget(seatId: '', type: SeatType.vip, state: SeatState.available),
          'VIP',
        ),
        _buildItem(
          const SeatWidget(seatId: '', type: SeatType.couple, state: SeatState.available),
          'Đôi',
        ),
        _buildItem(
          const SeatWidget(seatId: '•', type: SeatType.standard, state: SeatState.selected),
          'Đang chọn',
        ),
        _buildItem(
          const SeatWidget(seatId: '', type: SeatType.standard, state: SeatState.sold),
          'Đã bán',
        ),
      ],
    );
  }
}
