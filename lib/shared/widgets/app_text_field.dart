import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Text field component following DESIGN_TOKENS.md Section 7.6
class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? errorText;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final int maxLines;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.errorText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!.toUpperCase(),
            style: AppTextStyles.captionUppercase.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.xxs),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          enabled: enabled,
          maxLines: maxLines,
          onChanged: onChanged,
          validator: validator,
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.ink),
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.muted),
            errorText: errorText,
            errorStyle: AppTextStyles.caption.copyWith(color: AppColors.warning),
            filled: true,
            fillColor: AppColors.canvas,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: 14,
            ),
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            border: const OutlineInputBorder(
              borderRadius: AppRadius.smRadius,
              borderSide: BorderSide(color: AppColors.hairline, width: 1),
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: AppRadius.smRadius,
              borderSide: BorderSide(color: AppColors.hairline, width: 1),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: AppRadius.smRadius,
              borderSide: BorderSide(color: AppColors.focusRing, width: 1),
            ),
            errorBorder: const OutlineInputBorder(
              borderRadius: AppRadius.smRadius,
              borderSide: BorderSide(color: AppColors.warning, width: 1),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderRadius: AppRadius.smRadius,
              borderSide: BorderSide(color: AppColors.warning, width: 1),
            ),
          ),
        ),
      ],
    );
  }
}
