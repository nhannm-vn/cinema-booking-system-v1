import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

enum _AppButtonVariant { primary, outline, text }

/// Reusable Button Component following DESIGN_TOKENS.md Section 7.1
/// - Height: 48px, Radius: 0px (AppRadius.none)
/// - Label is always UPPERCASE
/// - Elevation: 0, no BoxShadow
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final _AppButtonVariant _variant;
  final bool isLoading;
  final Widget? icon;
  final double? width;

  const AppButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
  }) : _variant = _AppButtonVariant.primary;

  const AppButton.outline({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
  }) : _variant = _AppButtonVariant.outline;

  const AppButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
  }) : _variant = _AppButtonVariant.text;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null && !isLoading;
    final uppercaseLabel = label.toUpperCase();

    Widget content = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.ink),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(width: AppSpacing.xxs),
              ],
              Text(
                uppercaseLabel,
                style: _variant == _AppButtonVariant.primary
                    ? AppTextStyles.button.copyWith(
                        color: isEnabled ? AppColors.onPrimary : AppColors.muted,
                      )
                    : AppTextStyles.button.copyWith(
                        color: isEnabled ? AppColors.ink : AppColors.muted,
                      ),
              ),
            ],
          );

    Widget buttonWidget;
    switch (_variant) {
      case _AppButtonVariant.primary:
        buttonWidget = ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.canvasElevated,
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.zeroRadius),
            minimumSize: Size(width ?? 0, 48),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          ),
          child: content,
        );
        break;

      case _AppButtonVariant.outline:
        buttonWidget = OutlinedButton(
          onPressed: isEnabled ? onPressed : null,
          style: OutlinedButton.styleFrom(
            elevation: 0,
            backgroundColor: Colors.transparent,
            side: BorderSide(
              color: isEnabled ? AppColors.ink : AppColors.muted,
              width: 1,
            ),
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.zeroRadius),
            minimumSize: Size(width ?? 0, 48),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          ),
          child: content,
        );
        break;

      case _AppButtonVariant.text:
        buttonWidget = TextButton(
          onPressed: isEnabled ? onPressed : null,
          style: TextButton.styleFrom(
            elevation: 0,
            backgroundColor: Colors.transparent,
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.zeroRadius),
            minimumSize: Size(width ?? 0, 48),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          ),
          child: content,
        );
        break;
    }

    if (width != null) {
      return SizedBox(width: width, child: buttonWidget);
    }
    return buttonWidget;
  }
}
