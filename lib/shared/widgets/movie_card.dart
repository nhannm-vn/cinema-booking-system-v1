import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import 'app_badge.dart';
import 'skeleton_box.dart';

/// Movie Card component following DESIGN_TOKENS.md Section 7.3
/// - Poster ratio: 2:3, Corner radius: 0
/// - Age badge at top-left
/// - Title (titleSm), Genre · Duration (bodySm)
/// - No shadow, no card background
class MovieCard extends StatelessWidget {
  final String title;
  final String? posterUrl;
  final String ageRating;
  final String genres;
  final int durationMin;
  final VoidCallback? onTap;

  const MovieCard({
    super.key,
    required this.title,
    this.posterUrl,
    required this.ageRating,
    required this.genres,
    required this.durationMin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Poster 2:3 with Age Badge
          AspectRatio(
            aspectRatio: 2 / 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (posterUrl != null && posterUrl!.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: posterUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const SkeletonBox(),
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.canvasElevated,
                      child: const Center(
                        child: Icon(Icons.movie_outlined, color: AppColors.muted, size: 36),
                      ),
                    ),
                  )
                else
                  Container(
                    color: AppColors.canvasElevated,
                    child: const Center(
                      child: Icon(Icons.movie_outlined, color: AppColors.muted, size: 36),
                    ),
                  ),

                // Top-left Age Rating Badge
                Positioned(
                  top: AppSpacing.xxs,
                  left: AppSpacing.xxs,
                  child: AppBadge.age(ageRating),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),

          // Title
          Text(
            title,
            style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xxxs),

          // Genre · Duration
          Text(
            '$genres · $durationMin phút',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
