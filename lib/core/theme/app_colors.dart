import 'package:flutter/material.dart';

/// Design tokens for Colors.
/// References: DESIGN_TOKENS.md Section 2
abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFFDA291C); // Rosso Corsa
  static const Color primaryActive = Color(0xFFB01E0A); // Pressed
  static const Color primaryHover = Color(0xFF9D2211); // Hover

  // Background and Surfaces
  static const Color canvas = Color(0xFF181818); // Nền toàn app
  static const Color canvasElevated = Color(0xFF303030); // Card, bottom sheet, summary bar, ghế trống
  static const Color canvasLight = Color(0xFFFFFFFF); // Chỉ cho TicketCard và bảng giá
  static const Color surfaceSoftLight = Color(0xFFF7F7F7); // Dải sáng xen kẽ trên vé
  static const Color surfaceStrongLight = Color(0xFFEBEBEB); // Đường chia và badge trên nền sáng

  // Hairline
  static const Color hairline = Color(0xFF303030); // Viền 1px, đường chia nền tối
  static const Color hairlineOnLight = Color(0xFFD2D2D2); // Viền răng cưa và đường đứt trên vé
  static const Color hairlineSoft = Color(0xFFEBEBEB); // Đường chia nhạt

  // Text / Ink
  static const Color ink = Color(0xFFFFFFFF); // Tiêu đề, số lớn trên nền tối
  static const Color body = Color(0xFF969696); // Văn bản thường trên nền tối
  static const Color bodyOnLight = Color(0xFF181818); // Chữ trên vé và nền sáng
  static const Color muted = Color(0xFF666666); // Caption, nhãn phụ, icon chưa chọn
  static const Color mutedSoft = Color(0xFF8F8F8F); // Chữ vô hiệu
  static const Color onPrimary = Color(0xFFFFFFFF); // Chữ trên nền đỏ

  // Semantic
  static const Color success = Color(0xFF03904A); // Đặt vé thành công, soát vé hợp lệ
  static const Color info = Color(0xFF4C98B9); // Thông báo trung tính, tin nhắn
  static const Color warning = Color(0xFFF13A2C); // Lỗi form, sắp hết giờ giữ ghế, từ chối
  static const Color focusRing = Color(0xFFF6E500); // Chỉ viền focus của ô nhập
  static const Color shimmerHighlight = Color(0xFF3C3C3C); // Điểm sáng skeleton

  // Seat tokens
  static const Color seatAvailable = canvasElevated;
  static const Color seatSelected = primary;
  static const Color seatSold = canvas;
  static const Color seatHeld = muted;
}
