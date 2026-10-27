import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_text_styles.dart';

/// Single dark theme for Cinema Booking App.
/// References: DESIGN_TOKENS.md & .cursorrules Section 2
abstract final class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.canvas,
      canvasColor: AppColors.canvas,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        surface: AppColors.canvas,
        onSurface: AppColors.ink,
        error: AppColors.warning,
        onError: AppColors.ink,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.ink),
        titleTextStyle: AppTextStyles.titleMd,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.hairline,
        thickness: 1,
        space: 1,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.canvasElevated,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.zeroRadius),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.canvasElevated,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sheetRadius),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.canvasElevated,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sheetRadius),
        titleTextStyle: TextStyle(
          color: AppColors.ink,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.canvas,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.muted),
        labelStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.body),
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
        errorStyle: AppTextStyles.caption.copyWith(color: AppColors.warning),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.canvasElevated,
          disabledForegroundColor: AppColors.muted,
          textStyle: AppTextStyles.button,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.zeroRadius),
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 32),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          foregroundColor: AppColors.ink,
          disabledForegroundColor: AppColors.muted,
          textStyle: AppTextStyles.button,
          side: const BorderSide(color: AppColors.ink, width: 1),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.zeroRadius),
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.ink,
          textStyle: AppTextStyles.button,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.zeroRadius),
        ),
      ),
    );
  }
}
