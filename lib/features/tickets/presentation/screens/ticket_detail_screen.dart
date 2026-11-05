import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../shared/widgets/ticket_card.dart';
import '../../../booking/data/models/booking_model.dart';
import '../../data/ticket_repository.dart';
import '../controllers/ticket_provider.dart';

/// Screen S10B: Electronic Ticket Detail with full QR code and 2-hour refund cancellation.
/// References: BUSINESS_RULES.md Section 10.1 & ROLE_FLOWS.md Section 1.10
class TicketDetailScreen extends StatefulWidget {
  final BookingModel? initialTicket;
  final String? bookingCode;

  const TicketDetailScreen({
    super.key,
    this.initialTicket,
    this.bookingCode,
  });

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  BookingModel? _ticket;
  bool _isLoading = false;
  String? _errorMessage;
  RealtimeChannel? _realtimeSubscription;
  Timer? _pollingTimer;

  BuildContext? _activeCancelDialogContext;

  @override
  void initState() {
    super.initState();
    _ticket = widget.initialTicket;
    final code = _ticket?.code ?? widget.bookingCode;
    if (code != null) {
      _setupRealtimeSubscription(code);
    }
    if (_ticket == null && widget.bookingCode != null) {
      _loadTicketByCode(widget.bookingCode!);
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _realtimeSubscription?.unsubscribe();
    super.dispose();
  }

  void _setupRealtimeSubscription(String code) {
    _realtimeSubscription?.unsubscribe();
    _pollingTimer?.cancel();
    try {
      final client = Supabase.instance.client;

      // 1. Realtime listener via Postgres changes
      _realtimeSubscription = client
          .channel('public:bookings:$code')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'bookings',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'code',
              value: code,
            ),
            callback: (payload) {
              final newStatus = payload.newRecord['status'];
              final txnId = payload.newRecord['sepay_transaction_id'] as String?;
              if (newStatus == 'cancelled' && _ticket?.status != 'cancelled') {
                _pollingTimer?.cancel();
                if (_activeCancelDialogContext != null && _activeCancelDialogContext!.mounted) {
                  Navigator.of(_activeCancelDialogContext!).pop();
                  _activeCancelDialogContext = null;
                }
                if (mounted) {
                  setState(() {
                    _ticket = _ticket?.copyWith(
                      status: 'cancelled',
                      sepayTransactionId: txnId ?? _ticket?.sepayTransactionId,
                    );
                  });
                  if (_ticket != null) {
                    _showRefundSuccessDialog(context, _ticket!);
                  }
                }
                _loadTicketByCode(code);
              }
            },
          )
          .subscribe();

      // 2. Fallback polling every 3 seconds (identical to SepayPaymentScreen)
      _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
        if (!mounted || _ticket?.status == 'cancelled') {
          _pollingTimer?.cancel();
          return;
        }
        try {
          final res = await client
              .from('bookings')
              .select('status, sepay_transaction_id')
              .eq('code', code)
              .maybeSingle();

          if (res != null && res['status'] == 'cancelled' && _ticket?.status != 'cancelled') {
            _pollingTimer?.cancel();
            final txnId = res['sepay_transaction_id'] as String?;
            if (_activeCancelDialogContext != null && _activeCancelDialogContext!.mounted) {
              Navigator.of(_activeCancelDialogContext!).pop();
              _activeCancelDialogContext = null;
            }
            if (mounted) {
              setState(() {
                _ticket = _ticket?.copyWith(
                  status: 'cancelled',
                  sepayTransactionId: txnId ?? _ticket?.sepayTransactionId,
                );
              });
              if (_ticket != null) {
                _showRefundSuccessDialog(context, _ticket!);
              }
            }
            _loadTicketByCode(code);
          }
        } catch (_) {}
      });
    } catch (_) {
      // Offline fallback
    }
  }

  Future<void> _loadTicketByCode(String code) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = TicketRepository();
      final fetched = await repo.getTicketByCode(code);
      if (mounted) {
        setState(() {
          _ticket = fetched;
          _isLoading = false;
          if (fetched == null) {
            _errorMessage = 'Không tìm thấy thông tin vé $code';
          }
        });
        if (fetched != null && _realtimeSubscription == null) {
          _setupRealtimeSubscription(fetched.code);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Lỗi nạp chi tiết vé: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  void _showCancelDialog(BuildContext context, BookingModel ticket) {
    final sepayTxnController = TextEditingController();
    bool isCancelling = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        _activeCancelDialogContext = dialogCtx;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.canvasElevated,
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.zeroRadius),
              title: Text(
                'XÁC NHẬN HỦY VÉ'.toUpperCase(),
                style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bạn có chắc chắn muốn hủy vé #${ticket.code.toUpperCase()}? Theo chính sách của rạp, bạn sẽ được hoàn tiền 100% (${CurrencyFormatter.format(ticket.totalAmount)}) về phương thức thanh toán ban đầu.',
                      style: AppTextStyles.bodyMd.copyWith(color: AppColors.ink),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // SePay Sandbox Test Guide Card
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.canvas,
                        border: Border.all(color: AppColors.hairline),
                        borderRadius: AppRadius.zeroRadius,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.swap_vert_circle_outlined, color: AppColors.primary, size: 20),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  'DEMO HOÀN TIỀN SEPAY SANDBOX'.toUpperCase(),
                                  style: AppTextStyles.captionUppercase.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Mở SePay Sandbox và tạo giao dịch "Tiền ra" với thông tin:',
                            style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          _buildCopyableRow(
                            'Tài khoản SePay:',
                            '0000000001',
                            '0000000001',
                          ),
                          _buildCopyableRow(
                            'Loại giao dịch:',
                            'Tiền ra (Chi tiền)',
                            null,
                          ),
                          _buildCopyableRow(
                            'Số tiền:',
                            CurrencyFormatter.format(ticket.totalAmount),
                            ticket.totalAmount.toString(),
                          ),
                          _buildCopyableRow(
                            'Nội dung CK:',
                            ticket.code.toUpperCase(),
                            ticket.code.toUpperCase(),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          const Row(
                            children: [
                              Icon(Icons.sync, color: AppColors.primary, size: 16),
                              SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  'Đang lắng nghe SePay Realtime...',
                                  style: TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Optional SePay Transaction ID
                    TextField(
                      controller: sepayTxnController,
                      style: AppTextStyles.bodySm.copyWith(color: AppColors.ink),
                      decoration: InputDecoration(
                        labelText: 'MÃ GIAO DỊCH SEPAY (TÙY CHỌN)',
                        labelStyle: AppTextStyles.captionUppercase.copyWith(color: AppColors.muted),
                        hintText: 'Nhập ID SePay (ví dụ: 123456)',
                        hintStyle: AppTextStyles.caption.copyWith(color: AppColors.muted),
                        filled: true,
                        fillColor: AppColors.canvas,
                        border: const OutlineInputBorder(borderRadius: AppRadius.zeroRadius),
                        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _activeCancelDialogContext = null;
                    Navigator.pop(dialogCtx);
                  },
                  child: Text(
                    'QUAY LẠI'.toUpperCase(),
                    style: AppTextStyles.button.copyWith(color: AppColors.muted),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    elevation: 0,
                    shape: const RoundedRectangleBorder(borderRadius: AppRadius.zeroRadius),
                  ),
                  onPressed: isCancelling
                      ? null
                      : () async {
                          setDialogState(() => isCancelling = true);
                          final scaffoldMessenger = ScaffoldMessenger.of(context);
                          final provider = context.read<TicketProvider>();
                          final txnId = sepayTxnController.text.trim().isNotEmpty
                              ? sepayTxnController.text.trim()
                              : null;
                          final reason = txnId != null
                              ? 'Khách hủy vé trực tuyến (Mã GD SePay: $txnId)'
                              : 'Khách hủy vé trực tuyến';
                          final success = await provider.cancelBooking(ticket.code, reason: reason);
                          if (success && txnId != null) {
                            try {
                              await Supabase.instance.client
                                  .from('bookings')
                                  .update({'sepay_transaction_id': txnId})
                                  .eq('code', ticket.code);
                            } catch (_) {}
                          }
                          _activeCancelDialogContext = null;
                          if (dialogCtx.mounted) {
                            Navigator.pop(dialogCtx);
                          }
                          if (success) {
                            if (context.mounted) {
                              setState(() {
                                _ticket = _ticket?.copyWith(
                                  status: 'cancelled',
                                  sepayTransactionId: txnId ?? _ticket?.sepayTransactionId,
                                );
                              });
                              _showRefundSuccessDialog(context, _ticket ?? ticket);
                            }
                          } else {
                            final err = provider.errorMessage ?? 'Hủy vé thất bại';
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text(err),
                                backgroundColor: AppColors.warning,
                              ),
                            );
                          }
                        },
                  child: Text(
                    'XÁC NHẬN HỦY'.toUpperCase(),
                    style: AppTextStyles.button.copyWith(color: AppColors.ink),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCopyableRow(String label, String displayValue, String? copyValue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.muted)),
          Row(
            children: [
              Text(
                displayValue,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (copyValue != null) ...[
                const SizedBox(width: 4),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: copyValue));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.canvasElevated,
                        content: Text(
                          'ĐÃ SAO CHÉP $copyValue'.toUpperCase(),
                          style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(Icons.copy, size: 14, color: AppColors.primary),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showRefundSuccessDialog(BuildContext context, BookingModel ticket) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppColors.canvasElevated,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.zeroRadius),
          title: Column(
            children: [
              const Icon(Icons.check_circle_outline, color: AppColors.success, size: 54),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'HOÀN TIỀN THÀNH CÔNG'.toUpperCase(),
                style: AppTextStyles.titleSm.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxxs),
              Text(
                'Đã chuyển tiền hoàn 100% về tài khoản khách hàng',
                style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.canvas,
                border: Border.all(color: AppColors.hairline),
                borderRadius: AppRadius.zeroRadius,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      '+ ${CurrencyFormatter.format(ticket.totalAmount)}',
                      style: AppTextStyles.displayLg.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Divider(color: AppColors.hairline, height: 1),
                  const SizedBox(height: AppSpacing.sm),
                  _buildReceiptRow('Tài khoản chuyển (Rạp)', '0000000001\nCINEMA BOOKING SYSTEM'),
                  const SizedBox(height: AppSpacing.xs),
                  _buildReceiptRow('Tài khoản nhận (Khách)', '0000000002\nNGUYEN VAN KHACH 1'),
                  const SizedBox(height: AppSpacing.xs),
                  _buildReceiptRow(
                    'Mã giao dịch SePay',
                    ticket.sepayTransactionId != null && ticket.sepayTransactionId!.isNotEmpty
                        ? ticket.sepayTransactionId!
                        : 'SEPAY-${ticket.code.toUpperCase()}',
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _buildReceiptRow('Nội dung chuyển khoản', 'HOAN TIEN VE ${ticket.code.toUpperCase()}'),
                  const SizedBox(height: AppSpacing.xs),
                  _buildReceiptRow('Trạng thái giao dịch', 'ĐÃ HOÀN TẤT (100%)'),
                ],
              ),
            ),
          ),
          actions: [
            AppButton.primary(
              label: 'ĐÃ HIỂU & ĐÓNG',
              onPressed: () {
                Navigator.pop(dialogCtx);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.muted),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        title: Text(
          'CHI TIẾT VÉ'.toUpperCase(),
          style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            SkeletonBox(width: double.infinity, height: 320),
            SizedBox(height: AppSpacing.md),
            SkeletonBox(width: double.infinity, height: 160),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: ErrorState(
          message: _errorMessage!,
          onRetry: () {
            if (widget.bookingCode != null) {
              _loadTicketByCode(widget.bookingCode!);
            }
          },
        ),
      );
    }

    if (_ticket == null) {
      return const Center(
        child: EmptyState(
          title: 'CHI TIẾT VÉ',
          message: 'Không tìm thấy thông tin vé.',
        ),
      );
    }

    final ticket = _ticket!;
    final canCancel = ticket.canCancel;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Electronic Ticket Container with QR
          TicketCard(
            movieTitle: ticket.movieTitle,
            cinemaName: ticket.cinemaName,
            roomName: ticket.roomName,
            format: ticket.format,
            showtime: DateFormatter.formatDateTime(ticket.showtimeStart),
            seatNames: ticket.seatNamesSummary,
            bookingCode: ticket.code,
            foodSummary: ticket.foodSummary.isNotEmpty ? ticket.foodSummary : null,
          ),
          const SizedBox(height: AppSpacing.md),

          // 2. Status & Cinema Channel Badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.canvasElevated,
              borderRadius: AppRadius.zeroRadius,
              border: Border.all(color: AppColors.hairline, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TRẠNG THÁI VÉ',
                  style: AppTextStyles.captionUppercase.copyWith(color: AppColors.muted),
                ),
                StatusBadge(status: ticket.displayStatus),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 3. Concession Items (if any)
          if (ticket.foods.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.canvasElevated,
                borderRadius: AppRadius.zeroRadius,
                border: Border.all(color: AppColors.hairline, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BẮP NƯỚC KÈM THEO'.toUpperCase(),
                    style: AppTextStyles.captionUppercase.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...ticket.foods.map((food) {
                    final qty = food['qty'] ?? 1;
                    final name = food['name'] ?? '';
                    final price = (food['price'] as num?)?.toInt() ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$qty x $name',
                            style: AppTextStyles.bodyMd.copyWith(color: AppColors.ink),
                          ),
                          Text(
                            CurrencyFormatter.format(price * (qty as int)),
                            style: AppTextStyles.bodyMd.copyWith(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(color: AppColors.hairline, height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TRẠNG THÁI GIAO ĐỒ ĂN',
                        style: AppTextStyles.captionUppercase.copyWith(color: AppColors.muted),
                      ),
                      Text(
                        ticket.foodStatus.toUpperCase(),
                        style: AppTextStyles.captionUppercase.copyWith(
                          color: ticket.foodStatus == 'delivered'
                              ? AppColors.success
                              : (ticket.foodStatus == 'cancelled' ? AppColors.warning : AppColors.info),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // 4. Payment Snapshot Breakdown
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.canvasElevated,
              borderRadius: AppRadius.zeroRadius,
              border: Border.all(color: AppColors.hairline, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CHI TIẾT THANH TOÁN'.toUpperCase(),
                  style: AppTextStyles.captionUppercase.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildPriceRow('Tiền vé', CurrencyFormatter.format(ticket.ticketTotal)),
                const SizedBox(height: AppSpacing.xxs),
                _buildPriceRow('Tiền đồ ăn', CurrencyFormatter.format(ticket.foodTotal)),
                const SizedBox(height: AppSpacing.xxs),
                _buildPriceRow('Giảm giá', '- ${CurrencyFormatter.format(ticket.discount)}'),
                const Divider(color: AppColors.hairline, height: AppSpacing.md),
                _buildPriceRow(
                  'Tổng thanh toán',
                  CurrencyFormatter.format(ticket.totalAmount),
                  isBold: true,
                  highlightColor: AppColors.primary,
                ),
                const SizedBox(height: AppSpacing.xs),
                _buildPriceRow(
                  'Phương thức',
                  ticket.paymentMethod?.toUpperCase() ?? 'SEPAY VIETQR',
                ),
                const SizedBox(height: AppSpacing.xxs),
                _buildPriceRow(
                  'Thời gian thanh toán',
                  ticket.paidAt != null
                      ? DateFormatter.formatDateTime(ticket.paidAt!)
                      : '---',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 5. Cancellation & Refund Section
          if (ticket.status == 'cancelled') ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.canvasElevated,
                border: Border.all(color: AppColors.success),
                borderRadius: AppRadius.zeroRadius,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: AppColors.success, size: 22),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          'ĐÃ HOÀN TIỀN 100% THÀNH CÔNG'.toUpperCase(),
                          style: AppTextStyles.titleSm.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Đã chuyển tiền hoàn 100% về tài khoản khách hàng qua SePay VietQR.',
                    style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Divider(color: AppColors.hairline, height: 1),
                  const SizedBox(height: AppSpacing.sm),
                  _buildPriceRow(
                    'Số tiền hoàn trả',
                    '+ ${CurrencyFormatter.format(ticket.totalAmount)}',
                    isBold: true,
                    highlightColor: AppColors.success,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _buildReceiptRow('Tài khoản chuyển (Rạp)', '0000000001 · CINEMA BOOKING SYSTEM'),
                  const SizedBox(height: AppSpacing.xs),
                  _buildReceiptRow('Tài khoản nhận (Khách)', '0000000002 · NGUYEN VAN KHACH 1'),
                  const SizedBox(height: AppSpacing.xs),
                  _buildReceiptRow(
                    'Mã giao dịch SePay',
                    ticket.sepayTransactionId != null && ticket.sepayTransactionId!.isNotEmpty
                        ? ticket.sepayTransactionId!
                        : 'SEPAY-${ticket.code.toUpperCase()}',
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _buildReceiptRow('Nội dung chuyển khoản', 'HOAN TIEN VE ${ticket.code.toUpperCase()}'),
                  const SizedBox(height: AppSpacing.md),
                  AppButton.outline(
                    label: 'XEM BIÊN NHẬN HOÀN TIỀN',
                    onPressed: () => _showRefundSuccessDialog(context, ticket),
                  ),
                ],
              ),
            ),
          ] else if (canCancel) ...[
            AppButton.outline(
              label: 'HỦY VÉ VÀ HOÀN TIỀN',
              onPressed: () => _showCancelDialog(context, ticket),
            ),
          ] else if (ticket.status == 'paid') ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.canvasElevated,
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
                borderRadius: AppRadius.zeroRadius,
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Không thể hủy vé vì suất chiếu bắt đầu trong vòng chưa đầy 2 giờ nữa theo chính sách của rạp.',
                      style: AppTextStyles.caption.copyWith(color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    String value, {
    bool isBold = false,
    Color? highlightColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMd.copyWith(
            color: AppColors.muted,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMd.copyWith(
            color: highlightColor ?? AppColors.ink,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
