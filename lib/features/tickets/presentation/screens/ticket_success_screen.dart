import 'package:flutter/material.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../../shared/widgets/ticket_card.dart';
import '../../../booking/data/models/booking_model.dart';
import '../../data/ticket_repository.dart';

/// S09 Electronic Ticket Success Screen.
/// References: ROLE_FLOWS.md Section 1, DESIGN_TOKENS.md, m3_plan.md Section 3.6
class TicketSuccessScreen extends StatefulWidget {
  final String bookingCode;

  const TicketSuccessScreen({
    super.key,
    required this.bookingCode,
  });

  @override
  State<TicketSuccessScreen> createState() => _TicketSuccessScreenState();
}

class _TicketSuccessScreenState extends State<TicketSuccessScreen> {
  final TicketRepository _ticketRepo = TicketRepository();
  bool _isLoading = true;
  BookingModel? _booking;

  @override
  void initState() {
    super.initState();
    _fetchTicket();
  }

  Future<void> _fetchTicket() async {
    setState(() => _isLoading = true);
    try {
      final ticket = await _ticketRepo.getTicketByCode(widget.bookingCode);
      if (!mounted) return;
      setState(() {
        _booking = ticket;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToHome() {
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
  }

  void _navigateToMyTickets() {
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.myTickets, (route) => route.settings.name == AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _navigateToHome();
      },
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(
          backgroundColor: AppColors.canvas,
          elevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.ink),
              onPressed: _navigateToHome,
              tooltip: 'ĐÓNG',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Success Icon & Header
              const Icon(
                Icons.check_circle_outline,
                color: AppColors.success,
                size: 56,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'ĐẶT VÉ THÀNH CÔNG'.toUpperCase(),
                style: AppTextStyles.displayLg.copyWith(color: AppColors.ink),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'Vé điện tử của bạn đã sẵn sàng. Vui lòng xuất trình mã QR tại quầy soát vé.',
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),

              // Electronic Ticket Card
              if (_isLoading)
                const SkeletonBox(width: double.infinity, height: 380)
              else
                _buildTicketCard(),

              const SizedBox(height: AppSpacing.lg),

              // Action Buttons: 1 primary CTA, 1 outline button
              AppButton.primary(
                label: 'XEM VÉ CỦA TÔI',
                width: double.infinity,
                onPressed: _navigateToMyTickets,
              ),
              const SizedBox(height: AppSpacing.xs),
              AppButton.outline(
                label: 'VỀ TRANG CHỦ',
                width: double.infinity,
                onPressed: _navigateToHome,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketCard() {
    final b = _booking;
    final movieTitle = b?.movieTitle ?? 'VÉ XEM PHIM';
    final cinemaName = b?.cinemaName ?? 'Rạp Star Cinema';
    final roomName = b?.roomName ?? 'Phòng chiếu';
    final format = b?.format ?? '2D';
    final showtime = b != null
        ? DateFormatter.formatDateTime(b.showtimeStart)
        : 'Suất chiếu';

    final seatNames = (b?.seats ?? [])
        .map((s) => s['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .join(', ');

    final foodSummary = (b?.foods ?? [])
        .map((f) => '${f['qty']}x ${f['name']}')
        .join(', ');

    return TicketCard(
      movieTitle: movieTitle,
      cinemaName: cinemaName,
      roomName: roomName,
      format: format,
      showtime: showtime,
      seatNames: seatNames.isNotEmpty ? seatNames : 'Chưa cập nhật',
      bookingCode: widget.bookingCode,
      foodSummary: foodSummary.isNotEmpty ? foodSummary : null,
    );
  }
}
