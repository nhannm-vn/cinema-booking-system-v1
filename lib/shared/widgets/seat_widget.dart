import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_text_styles.dart';

enum SeatType { standard, vip, couple }
enum SeatState { available, selected, sold, held }

/// Single seat widget following DESIGN_TOKENS.md Section 7.13 & Section 2.6
class SeatWidget extends StatelessWidget {
  final String seatId;
  final SeatType type;
  final SeatState state;
  final VoidCallback? onTap;

  const SeatWidget({
    super.key,
    required this.seatId,
    this.type = SeatType.standard,
    this.state = SeatState.available,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCouple = type == SeatType.couple;
    final double width = isCouple ? 62.0 : 28.0;
    const double height = 28.0;

    Color bg;
    Border? border;
    Widget? content;

    switch (state) {
      case SeatState.available:
        bg = AppColors.canvasElevated;
        if (type == SeatType.vip) {
          border = Border.all(color: AppColors.ink, width: 1);
        }
        break;

      case SeatState.selected:
        bg = AppColors.primary;
        content = Center(
          child: Text(
            seatId,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.onPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
        break;

      case SeatState.sold:
        bg = AppColors.canvas;
        border = Border.all(color: AppColors.muted, width: 1);
        content = const Center(
          child: Icon(Icons.close, size: 14, color: AppColors.muted),
        );
        break;

      case SeatState.held:
        bg = AppColors.muted;
        break;
    }

    return InkWell(
      onTap: (state == SeatState.available || state == SeatState.selected)
          ? () {
              HapticFeedback.selectionClick();
              onTap?.call();
            }
          : null,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: bg,
          border: border,
          borderRadius: AppRadius.xsRadius,
        ),
        child: content,
      ),
    );
  }
}
