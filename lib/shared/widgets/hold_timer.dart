import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/date_formatter.dart';

/// Hold Countdown Timer component following DESIGN_TOKENS.md Section 7.14
class HoldTimer extends StatefulWidget {
  final DateTime holdUntil;
  final VoidCallback? onExpired;

  const HoldTimer({
    super.key,
    required this.holdUntil,
    this.onExpired,
  });

  @override
  State<HoldTimer> createState() => _HoldTimerState();
}

class _HoldTimerState extends State<HoldTimer> {
  Timer? _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _calculateRemaining();
    _startTimer();
  }

  void _calculateRemaining() {
    final diff = widget.holdUntil.difference(DateTime.now());
    _remaining = diff.isNegative ? Duration.zero : diff;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _calculateRemaining();
        if (_remaining == Duration.zero) {
          timer.cancel();
          widget.onExpired?.call();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isWarning = _remaining.inSeconds < 60;
    final Color textColor = isWarning ? AppColors.warning : AppColors.ink;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.access_time_filled,
          size: 14,
          color: textColor,
        ),
        const SizedBox(width: AppSpacing.xxxs),
        Text(
          'GIỮ GHẾ CÒN ${DateFormatter.formatTimer(_remaining)}',
          style: AppTextStyles.captionUppercase.copyWith(
            color: textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
