import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  @override
  void initState() {
    super.initState();
    _ticket = widget.initialTicket;
    if (_ticket == null && widget.bookingCode != null) {
      _loadTicketByCode(widget.bookingCode!);
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
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppColors.canvasElevated,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.zeroRadius),
          title: Text(
            'XÁC NHẬN HỦY VÉ'.toUpperCase(),
            style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
          ),
          content: Text(
            'Bạn có chắc chắn muốn hủy vé #${ticket.code.toUpperCase()}? Theo chính sách của rạp, bạn sẽ được hoàn tiền 100% (${CurrencyFormatter.format(ticket.totalAmount)}) về phương thức thanh toán ban đầu.',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.ink),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
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
              onPressed: () async {
                Navigator.pop(dialogCtx);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);
                final provider = context.read<TicketProvider>();
                final success = await provider.cancelBooking(ticket.code);
                if (success) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Hủy vé thành công và hoàn tiền 100%'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  navigator.pop();
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

          // 5. Cancellation Section (2-hour rule)
          if (canCancel) ...[
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
