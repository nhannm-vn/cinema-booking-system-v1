import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Electronic Ticket Card component following DESIGN_TOKENS.md Section 7.12
class TicketCard extends StatelessWidget {
  final String movieTitle;
  final String cinemaName;
  final String roomName;
  final String format;
  final String showtime;
  final String seatNames;
  final String bookingCode;
  final String? foodSummary;

  const TicketCard({
    super.key,
    required this.movieTitle,
    required this.cinemaName,
    required this.roomName,
    required this.format,
    required this.showtime,
    required this.seatNames,
    required this.bookingCode,
    this.foodSummary,
  });

  Widget _buildField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.captionUppercase.copyWith(
            color: AppColors.muted,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: AppSpacing.xxxs),
        Text(
          value,
          style: AppTextStyles.titleSm.copyWith(
            color: AppColors.bodyOnLight,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.canvasLight,
        borderRadius: AppRadius.zeroRadius,
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Movie Title
          Text(
            movieTitle,
            style: AppTextStyles.displayMd.copyWith(
              color: AppColors.bodyOnLight,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Grid Info (Cinema, Room, Showtime, Seats)
          Row(
            children: [
              Expanded(child: _buildField('Rạp', cinemaName)),
              Expanded(child: _buildField('Phòng / Định dạng', '$roomName · $format')),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          Row(
            children: [
              Expanded(child: _buildField('Suất chiếu', showtime)),
              Expanded(child: _buildField('Ghế', seatNames)),
            ],
          ),

          if (foodSummary != null && foodSummary!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            _buildField('Đồ ăn kèm (Nhận tại quầy)', foodSummary!),
          ],

          const SizedBox(height: AppSpacing.sm),

          // Dashed Divider Line
          Row(
            children: List.generate(
              30,
              (index) => Expanded(
                child: Container(
                  height: 1.5,
                  color: index.isEven ? AppColors.hairlineOnLight : Colors.transparent,
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Center QR Code
          Center(
            child: Column(
              children: [
                QrImageView(
                  data: bookingCode,
                  version: QrVersions.auto,
                  size: 160.0,
                  backgroundColor: AppColors.canvasLight,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: AppColors.bodyOnLight,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: AppColors.bodyOnLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  bookingCode.toUpperCase(),
                  style: AppTextStyles.titleMd.copyWith(
                    color: AppColors.bodyOnLight,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxs),
                Text(
                  'MÃ ĐẶT VÉ',
                  style: AppTextStyles.captionUppercase.copyWith(
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
