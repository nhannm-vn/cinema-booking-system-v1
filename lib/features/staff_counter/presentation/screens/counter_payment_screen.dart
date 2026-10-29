import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/hold_timer.dart';
import '../../../../shared/widgets/ticket_card.dart';
import '../controllers/staff_counter_provider.dart';

/// S21: Counter Payment & Change Calculator Screen (/staff/counter-payment)
/// References: ROLE_FLOWS.md Section 3.3 & BUSINESS_RULES.md Section 10 & m4_plan.md Section 3.4
class CounterPaymentScreen extends StatefulWidget {
  const CounterPaymentScreen({super.key});

  @override
  State<CounterPaymentScreen> createState() => _CounterPaymentScreenState();
}

class _CounterPaymentScreenState extends State<CounterPaymentScreen> {
  String _paymentMethod = 'cash'; // 'cash' hoặc 'card'
  final TextEditingController _cashInputController = TextEditingController();
  int _receivedCash = 0;
  bool _posConfirmed = false;

  @override
  void initState() {
    super.initState();
    _cashInputController.addListener(() {
      final clean = _cashInputController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final parsed = int.tryParse(clean) ?? 0;
      if (parsed != _receivedCash) {
        setState(() {
          _receivedCash = parsed;
        });
      }
    });
  }

  @override
  void dispose() {
    _cashInputController.dispose();
    super.dispose();
  }

  void _addCash(int delta, int total) {
    final next = _receivedCash + delta;
    setState(() {
      _receivedCash = next;
      _cashInputController.text = next.toString();
    });
  }

  void _setExactCash(int total) {
    setState(() {
      _receivedCash = total;
      _cashInputController.text = total.toString();
    });
  }

  Future<void> _handleCompleteSale(BuildContext context, StaffCounterProvider counter) async {
    final total = counter.calculateTotal();
    counter.calculateChange(_receivedCash);

    final success = await counter.completeSale(_paymentMethod);

    if (!context.mounted) return;

    if (success) {
      _showSuccessReceiptDialog(context, counter, total);
    } else if (counter.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.warning,
          content: Text(
            counter.errorMessage!,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.ink),
          ),
        ),
      );
    }
  }

  void _showSuccessReceiptDialog(
    BuildContext context,
    StaffCounterProvider counter,
    int total,
  ) {
    final showtime = counter.selectedShowtime;
    final bookingCode = counter.bookingCode ?? 'COUNTER';

    final movieTitle = showtime?.movieTitle ?? 'PHIM CHIẾU RẠP';
    final cinemaName = showtime?.cinemaName ?? 'Rạp Cinema';
    final roomName = showtime?.roomName ?? 'Phòng chiếu';
    final format = showtime?.format ?? '2D';
    final showtimeStr = showtime != null
        ? DateFormatter.formatDateTime(showtime.startTime)
        : 'Suất chiếu';
    final seatsStr = counter.selectedSeatIds.join(', ');
    final foodSummary = counter.selectedFoods
        .map((f) => '${f['qty']}x ${f['name']}')
        .join(', ');

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: AppColors.canvas,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.success,
                  size: 48,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'XUẤT VÉ THÀNH CÔNG',
                  style: AppTextStyles.titleMd.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'MÃ ĐẶT VÉ: #$bookingCode',
                  style: AppTextStyles.captionUppercase.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),

                // Electronic Ticket preview card
                TicketCard(
                  movieTitle: movieTitle,
                  cinemaName: cinemaName,
                  roomName: roomName,
                  format: format,
                  showtime: showtimeStr,
                  seatNames: seatsStr,
                  bookingCode: bookingCode,
                  foodSummary: foodSummary.isNotEmpty ? foodSummary : null,
                ),

                const SizedBox(height: AppSpacing.sm),

                // Action buttons
                AppButton.outline(
                  label: 'IN VÉ NHIỆT / HÓA ĐƠN',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppColors.info,
                        content: Text('Đang gửi lệnh in vé nhiệt tới máy in quầy...'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xs),
                AppButton.primary(
                  key: const Key('counter_new_sale_btn'),
                  label: 'BÁN ĐƠN MỚI',
                  onPressed: () {
                    counter.reset();
                    Navigator.pop(dialogContext);
                    Navigator.pop(context); // Trở về S20 Counter Showtimes
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onHoldExpired() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.canvasElevated,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          'HẾT THỜI GIAN GIỮ GHẾ',
          style: AppTextStyles.titleSm.copyWith(
            color: AppColors.warning,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Thời gian giữ ghế tại quầy (3 phút) đã kết thúc. Vui lòng chọn lại suất chiếu và ghế.',
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.body),
        ),
        actions: [
          AppButton.primary(
            label: 'ĐỒNG Ý',
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<StaffCounterProvider>().reset();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final counter = context.watch<StaffCounterProvider>();
    final showtime = counter.selectedShowtime;
    final totalAmount = counter.calculateTotal();
    final remainingDebt = totalAmount - _receivedCash;
    final change = _receivedCash >= totalAmount ? _receivedCash - totalAmount : 0;
    final canSubmit = _paymentMethod == 'cash'
        ? _receivedCash >= totalAmount
        : _posConfirmed;

    final holdUntil = counter.holdUntil ?? DateTime.now().add(const Duration(minutes: 3));

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        title: Text(
          'THANH TOÁN TẠI QUẦY',
          style: AppTextStyles.titleSm.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Center(
              child: HoldTimer(
                holdUntil: holdUntil,
                onExpired: _onHoldExpired,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Order summary card
            _buildOrderSummaryCard(counter, showtime, totalAmount),

            const SizedBox(height: AppSpacing.sm),

            // Payment method selector
            _buildPaymentMethodToggle(),

            const SizedBox(height: AppSpacing.sm),

            // Cash or POS mode body
            if (_paymentMethod == 'cash')
              _buildCashCalculator(totalAmount, remainingDebt, change)
            else
              _buildPosConfirmation(),

            const SizedBox(height: AppSpacing.lg),

            // Primary CTA
            AppButton.primary(
              key: const Key('counter_confirm_sale_btn'),
              label: 'XÁC NHẬN BÁN VÉ',
              onPressed: canSubmit && !counter.isLoading
                  ? () => _handleCompleteSale(context, counter)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCard(
    StaffCounterProvider counter,
    dynamic showtime,
    int totalAmount,
  ) {
    final movieTitle = showtime?.movieTitle ?? 'Suất chiếu';
    final roomName = showtime?.roomName ?? 'Phòng chiếu';
    final format = showtime?.format ?? '2D';
    final seatsStr = counter.selectedSeatIds.join(', ');
    final foodsStr = counter.selectedFoods
        .map((f) => '${f['qty']}x ${f['name']}')
        .join(', ');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.canvasElevated,
        border: Border.all(color: AppColors.hairline, width: 1),
        borderRadius: BorderRadius.zero,
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            movieTitle,
            style: AppTextStyles.titleSm.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xxxs),
          Text(
            '$roomName · $format',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.body),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Divider(color: AppColors.hairline, height: 1),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'GHẾ (${counter.selectedSeatIds.length})',
                style: AppTextStyles.captionUppercase.copyWith(color: AppColors.muted),
              ),
              Text(
                seatsStr,
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (foodsStr.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ĐỒ ĂN',
                  style: AppTextStyles.captionUppercase.copyWith(color: AppColors.muted),
                ),
                Text(
                  foodsStr,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.info,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          const Divider(color: AppColors.hairline, height: 1),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TỔNG TIỀN PHẢI THU',
                style: AppTextStyles.captionUppercase.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                CurrencyFormatter.format(totalAmount),
                style: AppTextStyles.displayMd.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.canvasElevated,
        border: Border.all(color: AppColors.hairline, width: 1),
        borderRadius: BorderRadius.zero,
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              key: const Key('payment_method_cash_tab'),
              onTap: () => setState(() => _paymentMethod = 'cash'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: _paymentMethod == 'cash'
                      ? AppColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.zero,
                ),
                alignment: Alignment.center,
                child: Text(
                  'TIỀN MẶT',
                  style: AppTextStyles.captionUppercase.copyWith(
                    color: _paymentMethod == 'cash' ? AppColors.ink : AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              key: const Key('payment_method_card_tab'),
              onTap: () => setState(() => _paymentMethod = 'card'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: _paymentMethod == 'card'
                      ? AppColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.zero,
                ),
                alignment: Alignment.center,
                child: Text(
                  'THẺ / POS / QR',
                  style: AppTextStyles.captionUppercase.copyWith(
                    color: _paymentMethod == 'card' ? AppColors.ink : AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashCalculator(int totalAmount, int remainingDebt, int change) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.canvasElevated,
        border: Border.all(color: AppColors.hairline, width: 1),
        borderRadius: BorderRadius.zero,
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Received cash text input
          AppTextField(
            key: const Key('cash_received_input'),
            controller: _cashInputController,
            label: 'TIỀN KHÁCH ĐƯA (VND)',
            hintText: 'Nhập số tiền khách đưa...',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.xs),

          // Quick cash buttons
          Wrap(
            spacing: AppSpacing.xxs,
            runSpacing: AppSpacing.xxs,
            children: [
              _buildQuickCashChip('ĐỦ TIỀN', () => _setExactCash(totalAmount), const Key('cash_exact_btn')),
              _buildQuickCashChip('+50K', () => _addCash(50000, totalAmount), const Key('cash_plus_50k_btn')),
              _buildQuickCashChip('+100K', () => _addCash(100000, totalAmount), const Key('cash_plus_100k_btn')),
              _buildQuickCashChip('+200K', () => _addCash(200000, totalAmount), const Key('cash_plus_200k_btn')),
              _buildQuickCashChip('+500K', () => _addCash(500000, totalAmount), const Key('cash_plus_500k_btn')),
            ],
          ),

          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.hairline, height: 1),
          const SizedBox(height: AppSpacing.md),

          // Live change calculation output
          if (_receivedCash < totalAmount) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.canvas,
                border: Border.all(color: AppColors.warning, width: 1),
                borderRadius: BorderRadius.zero,
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                  const SizedBox(width: AppSpacing.xxs),
                  Expanded(
                    child: Text(
                      'KHÁCH ĐƯA THIẾU: ${CurrencyFormatter.format(remainingDebt)}',
                      style: AppTextStyles.captionUppercase.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TIỀN THỪA TRẢ KHÁCH',
                  style: AppTextStyles.captionUppercase.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxs),
                Text(
                  CurrencyFormatter.format(change),
                  style: AppTextStyles.displayLg.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickCashChip(String label, VoidCallback onTap, Key key) {
    return InkWell(
      key: key,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: AppColors.canvas,
          border: Border.all(color: AppColors.hairline, width: 1),
          borderRadius: BorderRadius.zero,
        ),
        child: Text(
          label.toUpperCase(),
          style: AppTextStyles.captionUppercase.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildPosConfirmation() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.canvasElevated,
        border: Border.all(color: AppColors.hairline, width: 1),
        borderRadius: BorderRadius.zero,
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.credit_card, color: AppColors.primary, size: 28),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Quẹt thẻ ngân hàng hoặc quét mã QR thanh toán trên máy POS tại quầy',
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              border: Border.all(color: AppColors.hairline, width: 1),
              borderRadius: BorderRadius.zero,
            ),
            child: Row(
              children: [
                Checkbox(
                  key: const Key('pos_confirmed_checkbox'),
                  value: _posConfirmed,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _posConfirmed = val ?? false),
                ),
                Expanded(
                  child: Text(
                    'Đã xác nhận tiền vào tài khoản thành công qua máy POS / Chuyển khoản',
                    style: AppTextStyles.caption.copyWith(color: AppColors.ink),
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
