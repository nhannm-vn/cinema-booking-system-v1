import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import 'skeleton_box.dart';

/// Robust Network Image component for Cinema Booking.
/// Bypasses web CORS restrictions on Flutter Web via Image.network
/// and leverages local disk cache via CachedNetworkImage on mobile/desktop.
/// References: DESIGN_TOKENS.md Section 7 & TECH_STACK.md Section 11
class AppNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final IconData fallbackIcon;
  final double iconSize;
  final BorderRadius borderRadius;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.movie_outlined,
    this.iconSize = 32.0,
    this.borderRadius = AppRadius.zeroRadius,
  });

  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      color: AppColors.canvasElevated,
      child: Center(
        child: Icon(
          fallbackIcon,
          color: AppColors.muted,
          size: iconSize,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: _buildFallback(),
      );
    }

    final trimmedUrl = imageUrl!.trim();

    Widget imageWidget;
    if (kIsWeb) {
      imageWidget = Image.network(
        trimmedUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return SkeletonBox(width: width, height: height);
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildFallback();
        },
      );
    } else {
      imageWidget = CachedNetworkImage(
        imageUrl: trimmedUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (_, __) => SkeletonBox(width: width, height: height),
        errorWidget: (_, __, ___) => _buildFallback(),
      );
    }

    if (borderRadius != BorderRadius.zero) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}

