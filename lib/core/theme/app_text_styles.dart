import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Design tokens for Typography (Inter).
/// References: DESIGN_TOKENS.md Section 3
abstract final class AppTextStyles {
  /// Size 32, weight 500, line h 1.1, letter sp -0.64
  /// Dùng cho: Tên phim trên hero/backdrop
  static TextStyle get displayMega => GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w500,
        height: 1.1,
        letterSpacing: -0.64,
        color: AppColors.ink,
      );

  /// Size 28, weight 500, line h 1.1, letter sp -0.56
  /// Dùng cho: Tiêu đề trang (ĐĂNG NHẬP, TẠO TÀI KHOẢN)
  static TextStyle get displayXl => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w500,
        height: 1.1,
        letterSpacing: -0.56,
        color: AppColors.ink,
      );

  /// Size 24, weight 500, line h 1.2, letter sp -0.24
  /// Dùng cho: Tiêu đề section, "ĐẶT VÉ THÀNH CÔNG", tiền thừa, tổng tiền
  static TextStyle get displayLg => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        height: 1.2,
        letterSpacing: -0.24,
        color: AppColors.ink,
      );

  /// Size 20, weight 500, line h 1.4, letter sp 0.15
  /// Dùng cho: Tiêu đề phụ, tên phim trong vé
  static TextStyle get displayMd => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.15,
        color: AppColors.ink,
      );

  /// Size 18, weight 700, line h 1.2, letter sp 0
  /// Dùng cho: Tiêu đề component, giờ chiếu trong ShowtimeRow
  static TextStyle get titleMd => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: 0,
        color: AppColors.ink,
      );

  /// Size 16, weight 500, line h 1.4, letter sp 0.08
  /// Dùng cho: Tên phim trong card, nhãn danh sách
  static TextStyle get titleSm => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.08,
        color: AppColors.ink,
      );

  /// Size 14, weight 400, line h 1.5, letter sp 0
  /// Dùng cho: Văn bản mặc định
  static TextStyle get bodyMd => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: 0,
        color: AppColors.body,
      );

  /// Size 13, weight 400, line h 1.5, letter sp 0
  /// Dùng cho: Văn bản phụ, địa chỉ rạp
  static TextStyle get bodySm => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: 0,
        color: AppColors.body,
      );

  /// Size 12, weight 400, line h 1.4, letter sp 0
  /// Dùng cho: Chú thích, thông báo lỗi trường
  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        letterSpacing: 0,
        color: AppColors.muted,
      );

  /// Size 11, weight 600, line h 1.4, letter sp 1.1
  /// Dùng cho: Nhãn section, badge, nhãn bottom nav, hàng ghế, đồng hồ giữ ghế
  static TextStyle get captionUppercase => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 1.1,
        color: AppColors.ink,
      );

  /// Size 14, weight 700, line h 1.0, letter sp 1.4
  /// Dùng cho: Nhãn nút, UPPERCASE
  static TextStyle get button => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 1.0,
        letterSpacing: 1.4,
        color: AppColors.onPrimary,
      );

  /// Size 13, weight 600, line h 1.4, letter sp 0.65
  /// Dùng cho: Nhãn điều hướng, UPPERCASE
  static TextStyle get navLink => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0.65,
        color: AppColors.ink,
      );

  /// Size 48, weight 700, line h 1.0, letter sp -0.96
  /// Dùng cho: Thời lượng, tổng tiền lớn, số trong SpecCell
  static TextStyle get numberDisplay => GoogleFonts.inter(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        height: 1.0,
        letterSpacing: -0.96,
        color: AppColors.ink,
      );
}
