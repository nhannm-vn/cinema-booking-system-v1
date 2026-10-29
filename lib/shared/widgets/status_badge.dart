import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'app_badge.dart';

/// Status badge for bookings, showtimes and orders.
class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color textColor = AppColors.ink;
    String label = status.toUpperCase();

    switch (status.toLowerCase()) {
      case 'paid':
      case 'success':
      case 'active':
        bg = AppColors.success;
        label = 'ĐÃ THANH TOÁN';
        break;
      case 'upcoming':
        bg = AppColors.info;
        label = 'SẮP TỚI';
        break;
      case 'used':
        bg = AppColors.canvasElevated;
        label = 'ĐÃ SỬ DỤNG';
        break;
      case 'noshow':
        bg = AppColors.warning;
        label = 'KHÔNG SỬ DỤNG';
        break;
      case 'cancelled':
        bg = AppColors.warning;
        label = 'ĐÃ HỦY';
        break;
      case 'holding':
        bg = AppColors.muted;
        label = 'ĐANG GIỮ';
        break;
      case 'expired':
        bg = AppColors.muted;
        label = 'HẾT HẠN';
        break;
      case 'pending':
        bg = AppColors.info;
        label = 'CHỜ GIAO';
        break;
      case 'delivered':
        bg = AppColors.success;
        label = 'ĐÃ GIAO';
        break;
      default:
        bg = AppColors.canvasElevated;
        break;
    }

    return AppBadge(
      label: label,
      backgroundColor: bg,
      textColor: textColor,
    );
  }
}
