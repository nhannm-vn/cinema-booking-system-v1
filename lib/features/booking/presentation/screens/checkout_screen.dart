import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/hold_timer.dart';
import '../../../payment/data/payment_repository.dart';
import '../controllers/booking_provider.dart';

/// S08 Checkout & Voucher Screen.
/// References: ROLE_FLOWS.md Section 1, DESIGN_TOKENS.md, m3_plan.md Section 3.4
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final PaymentRepository _paymentRepo = PaymentRepository();
  final TextEditingController _voucherController = TextEditingController();

  bool _isProcessingPayment = false;
  String? _paymentError;

  @override
  void dispose() {
    _voucherController.dispose();
    super.dispose();
  }

  void _handleHoldExpired() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.canvasElevated,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.zeroRadius),
        title: Text(
          'HẾT THỜI GIAN GIỮ GHẾ'.toUpperCase(),
          style: AppTextStyles.titleMd.copyWith(color: AppColors.ink),
        ),
        content: Text(
          'Thời gian giữ ghế 5 phút đã kết thúc. Ghế đã được nhả cho người khác.',
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.body),
        ),
        actions: [
          AppButton.primary(
            label: 'CHỌN LẠI GHẾ',
            onPressed: () {
              Navigator.pop(ctx);
              context.read<BookingProvider>().reset();
              Navigator.popUntil(context, ModalRoute.withName(AppRoutes.seatSelect));
            },
          ),
        ],
      ),
    );
  }

  Future<void> _applyVoucher(BookingProvider booking) async {
    final code = _voucherController.text.trim();
    if (code.isEmpty) return;

    final success = await booking.applyVoucher(code);
    if (success) {
      await booking.syncBookingDetails();
    }
  }

  Future<void> _removeVoucher(BookingProvider booking) async {
    booking.removeVoucher();
    _voucherController.clear();
    await booking.syncBookingDetails();
  }

  Future<void> _handleVNPayCheckout(BookingProvider booking) async {
    if (booking.currentBookingCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.warning,
          content: Text(
            'THÔNG TIN ĐẶT VÉ KHÔNG HỢP LỆ.'.toUpperCase(),
            style: AppTextStyles.bodySm.copyWith(color: AppColors.ink),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isProcessingPayment = true;
      _paymentError = null;
    });

    try {
      final txnRef = '${booking.currentBookingCode}-${DateTime.now().millisecondsSinceEpoch}';
      final url = await _paymentRepo.createVNPayUrl(
        bookingCode: booking.currentBookingCode!,
        txnRef: txnRef,
      );

      if (!mounted) return;
      setState(() {
        _isProcessingPayment = false;
      });

      Navigator.pushNamed(
        context,
        AppRoutes.vnpayWebview,
        arguments: {
          'paymentUrl': url,
          'bookingCode': booking.currentBookingCode!,
          'txnRef': txnRef,
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessingPayment = false;
        _paymentError = e.toString().replaceFirst('Exception: ', '');
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.warning,
          content: Text(
            (_paymentError ?? 'Lỗi khởi tạo cổng thanh toán.').toUpperCase(),
            style: AppTextStyles.bodySm.copyWith(color: AppColors.ink),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingProvider>();
    final showtime = booking.selectedShowtime;
    final holdUntil = booking.holdUntil;

    final ticketTotal = booking.calculateTicketTotal();
    final foodTotal = booking.calculateFoodTotal();
    final discount = booking.discount;
    final grandTotal = booking.calculateGrandTotal();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.ink),
        title: Text(
          'THANH TOÁN'.toUpperCase(),
          style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
        ),
      ),
      body: Column(
        children: [
          // HoldTimer banner
          if (holdUntil != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              decoration: const BoxDecoration(
                color: AppColors.canvasElevated,
                border: Border(
                  bottom: BorderSide(color: AppColors.hairline, width: 1),
                ),
              ),
              child: Center(
                child: HoldTimer(
                  holdUntil: holdUntil,
                  onExpired: _handleHoldExpired,
                ),
              ),
            ),

          // Order details & payment content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.sm),
              children: [
                // 1. Movie & Showtime Block
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.canvasElevated,
                    border: Border.all(color: AppColors.hairline, width: 1),
                    borderRadius: AppRadius.zeroRadius,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (showtime?.movieTitle ?? 'PHIM').toUpperCase(),
                        style: AppTextStyles.titleMd.copyWith(color: AppColors.ink),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        '${showtime?.cinemaName ?? ""} · ${showtime?.roomName ?? ""} · ${showtime?.format ?? "2D"}',
                        style: AppTextStyles.bodyMd.copyWith(color: AppColors.body),
                      ),
                      if (showtime != null) ...[
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          DateFormatter.formatDateTime(showtime.startTime),
                          style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // 2. Seats and Foods Breakdown Block
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.canvasElevated,
                    border: Border.all(color: AppColors.hairline, width: 1),
                    borderRadius: AppRadius.zeroRadius,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${booking.selectedSeatIds.length} GHẾ (${booking.selectedSeatIds.join(", ")})',
                              style: AppTextStyles.bodyMd.copyWith(color: AppColors.ink),
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(ticketTotal),
                            style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
                          ),
                        ],
                      ),
                      if (booking.selectedFoods.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        const Divider(color: AppColors.hairline, height: 1),
                        const SizedBox(height: AppSpacing.xs),
                        ...booking.selectedFoods.map((f) => Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${f.quantity}x ${f.name}',
                                      style: AppTextStyles.bodyMd.copyWith(color: AppColors.body),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(
                                    CurrencyFormatter.format(f.price * f.quantity),
                                    style: AppTextStyles.bodyMd.copyWith(color: AppColors.ink),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // 3. Voucher Section
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.canvasElevated,
                    border: Border.all(color: AppColors.hairline, width: 1),
                    borderRadius: AppRadius.zeroRadius,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MÃ GIẢM GIÁ'.toUpperCase(),
                        style: AppTextStyles.captionUppercase.copyWith(color: AppColors.muted),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      if (booking.appliedVoucherCode != null) ...[
                        Row(
                          children: [
                            const AppBadge(
                              label: 'ĐÃ ÁP DỤNG',
                              backgroundColor: AppColors.success,
                              textColor: AppColors.ink,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                '${booking.appliedVoucherCode} (-${CurrencyFormatter.format(discount)})',
                                style: AppTextStyles.titleSm.copyWith(color: AppColors.success),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: AppColors.muted),
                              onPressed: () => _removeVoucher(booking),
                              tooltip: 'HỦY MÃ',
                            ),
                          ],
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                controller: _voucherController,
                                hintText: 'NHẬP MÃ (VÍ DỤ: CINEMA20)',
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            AppButton.outline(
                              label: 'ÁP DỤNG',
                              isLoading: booking.isLoading,
                              onPressed: () => _applyVoucher(booking),
                            ),
                          ],
                        ),
                        if (booking.voucherError != null) ...[
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            booking.voucherError!,
                            style: AppTextStyles.bodySm.copyWith(color: AppColors.warning),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // 4. Payment Method Selection (VNPay Sandbox)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.canvasElevated,
                    border: Border.all(color: AppColors.primary, width: 1.5),
                    borderRadius: AppRadius.zeroRadius,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: AppRadius.zeroRadius,
                        ),
                        child: const Center(
                          child: Icon(Icons.payment, color: AppColors.onPrimary, size: 20),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'VNPAY SANDBOX (TEST CỔNG THANH TOÁN)',
                              style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
                            ),
                            const SizedBox(height: AppSpacing.xxxs),
                            Text(
                              'Thẻ ATM nội địa / QR Pay / Thẻ quốc tế',
                              style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.check_circle, color: AppColors.primary, size: 22),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // 5. Total Price Breakdown
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.canvasElevated,
                    border: Border.all(color: AppColors.hairline, width: 1),
                    borderRadius: AppRadius.zeroRadius,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Tiền vé', style: AppTextStyles.bodyMd.copyWith(color: AppColors.body)),
                          Text(CurrencyFormatter.format(ticketTotal), style: AppTextStyles.bodyMd.copyWith(color: AppColors.ink)),
                        ],
                      ),
                      if (foodTotal > 0) ...[
                        const SizedBox(height: AppSpacing.xxs),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Tiền bắp nước', style: AppTextStyles.bodyMd.copyWith(color: AppColors.body)),
                            Text(CurrencyFormatter.format(foodTotal), style: AppTextStyles.bodyMd.copyWith(color: AppColors.ink)),
                          ],
                        ),
                      ],
                      if (discount > 0) ...[
                        const SizedBox(height: AppSpacing.xxs),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Giảm giá', style: AppTextStyles.bodyMd.copyWith(color: AppColors.success)),
                            Text('- ${CurrencyFormatter.format(discount)}', style: AppTextStyles.bodyMd.copyWith(color: AppColors.success)),
                          ],
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xs),
                      const Divider(color: AppColors.hairline, height: 1),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('TỔNG CỘNG', style: AppTextStyles.titleMd.copyWith(color: AppColors.ink)),
                          Text(
                            CurrencyFormatter.format(grandTotal),
                            style: AppTextStyles.displayLg.copyWith(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Pinned bottom CTA (1 primary button)
          Container(
            decoration: const BoxDecoration(
              color: AppColors.canvasElevated,
              border: Border(
                top: BorderSide(color: AppColors.hairline, width: 1),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TỔNG THANH TOÁN',
                            style: AppTextStyles.captionUppercase.copyWith(color: AppColors.muted),
                          ),
                          Text(
                            CurrencyFormatter.format(grandTotal),
                            style: AppTextStyles.displayLg.copyWith(color: AppColors.ink),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    AppButton.primary(
                      label: 'THANH TOÁN VNPAY',
                      isLoading: _isProcessingPayment,
                      onPressed: () => _handleVNPayCheckout(booking),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
