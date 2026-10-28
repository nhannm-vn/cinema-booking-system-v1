import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/app_button.dart';

/// S08B SePay Automated Bank Transfer & VietQR Payment Screen.
/// References: ROLE_FLOWS.md Section 1, TECH_STACK.md Section 8, BUSINESS_RULES.md Section 6.2
class SepayPaymentScreen extends StatefulWidget {
  final String paymentUrl;
  final String bookingCode;
  final String? txnRef;
  final String bank;
  final String accountNo;
  final String accountName;
  final int amount;

  const SepayPaymentScreen({
    super.key,
    required this.paymentUrl,
    required this.bookingCode,
    this.txnRef,
    this.bank = 'MBBank',
    this.accountNo = '0000123456789',
    this.accountName = 'CINEMA BOOKING SYSTEM',
    this.amount = 0,
  });

  @override
  State<SepayPaymentScreen> createState() => _SepayPaymentScreenState();
}

class _SepayPaymentScreenState extends State<SepayPaymentScreen> {
  Timer? _pollingTimer;
  RealtimeChannel? _realtimeSubscription;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _startListeningPaymentStatus();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _realtimeSubscription?.unsubscribe();
    super.dispose();
  }

  void _startListeningPaymentStatus() {
    try {
      final client = Supabase.instance.client;

      // 1. Listen via Realtime Postgres changes on bookings
      _realtimeSubscription = client
          .channel('public:bookings:${widget.bookingCode}')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'bookings',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'code',
              value: widget.bookingCode,
            ),
            callback: (payload) {
              final newStatus = payload.newRecord['status'];
              if (newStatus == 'paid') {
                _handlePaymentSuccess();
              }
            },
          )
          .subscribe();

      // 2. Fallback polling every 3 seconds
      _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
        if (_isSuccess || !mounted) return;
        try {
          final res = await client
              .from('bookings')
              .select('status')
              .eq('code', widget.bookingCode)
              .maybeSingle();

          if (res != null && res['status'] == 'paid') {
            _handlePaymentSuccess();
          }
        } catch (_) {}
      });
    } catch (_) {
      // In standalone tests or offline mode
    }
  }

  void _copyToClipboard(String label, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.canvasElevated,
        content: Text(
          'ĐÃ SAO CHÉP $label'.toUpperCase(),
          style: AppTextStyles.bodySm.copyWith(color: AppColors.primary),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handlePaymentSuccess() {
    if (_isSuccess || !mounted) return;
    _isSuccess = true;
    _pollingTimer?.cancel();

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.ticketSuccess,
      (route) => route.settings.name == AppRoutes.home,
      arguments: {'bookingCode': widget.bookingCode},
    );
  }

  void _handleCancelPayment() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.canvasElevated,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.zeroRadius),
        title: Text(
          'HỦY GIAO DỊCH'.toUpperCase(),
          style: AppTextStyles.titleMd.copyWith(color: AppColors.ink),
        ),
        content: Text(
          'Quý khách có chắc chắn muốn hủy thanh toán đơn hàng này? Ghế vẫn được giữ trong thời gian quy định.',
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.body),
        ),
        actions: [
          AppButton.outline(
            label: 'TIẾP TỤC THANH TOÁN',
            onPressed: () => Navigator.pop(ctx),
          ),
          AppButton.primary(
            label: 'XÁC NHẬN HỦY',
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transferContent = widget.bookingCode;
    final vietQrData =
        'https://qr.sepay.vn/img?bank=${widget.bank}&acc=${widget.accountNo}&template=compact&amount=${widget.amount}&des=${widget.bookingCode}';

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.ink),
        title: Text(
          'CỔNG THANH TOÁN SEPAY'.toUpperCase(),
          style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Banner instruction
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.canvasElevated,
              border: Border.all(color: AppColors.hairline, width: 1),
              borderRadius: AppRadius.zeroRadius,
            ),
            child: Row(
              children: [
                const Icon(Icons.qr_code_scanner, color: AppColors.primary, size: 28),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'QUÉT MÃ VIETQR BẰNG APP NGÂN HÀNG'.toUpperCase(),
                        style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
                      ),
                      const SizedBox(height: AppSpacing.xxxs),
                      Text(
                        'Mở App ngân hàng bất kỳ để quét mã hoặc chuyển khoản đúng nội dung bên dưới.',
                        style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // VietQR Display Card
          Center(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.canvasLight,
                borderRadius: AppRadius.smRadius,
                border: Border.all(color: AppColors.hairline, width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'VIETQR · SEPAY AUTOMATION',
                    style: AppTextStyles.captionUppercase.copyWith(
                      color: AppColors.bodyOnLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  QrImageView(
                    data: vietQrData,
                    version: QrVersions.auto,
                    size: 200.0,
                    backgroundColor: AppColors.canvasLight,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: AppColors.canvas,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: AppColors.canvas,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Quét mã để tự động nhập số tiền & nội dung',
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Transfer Details Table
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
                  'THÔNG TIN CHUYỂN KHOẢN'.toUpperCase(),
                  style: AppTextStyles.captionUppercase.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildInfoRow('Ngân hàng', widget.bank, false),
                const Divider(color: AppColors.hairline, height: 16),
                _buildInfoRow(
                  'Số tài khoản',
                  widget.accountNo,
                  true,
                  onCopy: () => _copyToClipboard('SỐ TÀI KHOẢN', widget.accountNo),
                ),
                const Divider(color: AppColors.hairline, height: 16),
                _buildInfoRow('Chủ tài khoản', widget.accountName, false),
                if (widget.amount > 0) ...[
                  const Divider(color: AppColors.hairline, height: 16),
                  _buildInfoRow(
                    'Số tiền',
                    CurrencyFormatter.format(widget.amount),
                    true,
                    onCopy: () => _copyToClipboard('SỐ TIỀN', widget.amount.toString()),
                  ),
                ],
                const Divider(color: AppColors.hairline, height: 16),
                _buildInfoRow(
                  'Nội dung CK',
                  transferContent,
                  true,
                  highlight: true,
                  onCopy: () => _copyToClipboard('NỘI DUNG', transferContent),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Note
          Text(
            '* Lưu ý: Vui lòng chuyển khoản chính xác nội dung "$transferContent" để hệ thống tự động xác nhận vé ngay lập tức.',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.warning),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Automated Waiting Indicator
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.md,
              horizontal: AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: AppColors.canvasElevated,
              border: Border.all(color: AppColors.hairline),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'ĐANG CHỜ HỆ THỐNG XÁC NHẬN THANH TOÁN TỰ ĐỘNG...'.toUpperCase(),
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton.outline(
            label: 'HỦY GIAO DỊCH',
            onPressed: _handleCancelPayment,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    bool showCopy, {
    bool highlight = false,
    VoidCallback? onCopy,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.muted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMd.copyWith(
              color: highlight ? AppColors.primary : AppColors.ink,
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        if (showCopy)
          IconButton(
            icon: const Icon(Icons.copy, size: 18, color: AppColors.primary),
            onPressed: onCopy,
            tooltip: 'Sao chép $label',
          ),
      ],
    );
  }
}
