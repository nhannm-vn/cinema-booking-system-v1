import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';

/// Skeleton Box component following DESIGN_TOKENS.md Section 7.11
/// - Background: canvasElevated, Highlight: shimmerHighlight
/// - Corner radius: 0px
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.canvasElevated,
      highlightColor: AppColors.shimmerHighlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.canvasElevated,
          borderRadius: borderRadius ?? AppRadius.zeroRadius,
        ),
      ),
    );
  }
}
