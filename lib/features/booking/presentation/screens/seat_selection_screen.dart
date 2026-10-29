import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/booking_summary_bar.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/seat_legend.dart';
import '../../../../shared/widgets/seat_widget.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../data/models/seat_model.dart';
import '../../data/repositories/seat_repository.dart';
import '../../data/repositories/showtime_repository.dart';
import '../controllers/booking_provider.dart';

/// S06 Seat Map Selection Screen.
/// References: ROLE_FLOWS.md Section 1, DESIGN_TOKENS.md, m3_plan.md Section 3.2
class SeatSelectionScreen extends StatefulWidget {
  const SeatSelectionScreen({super.key});

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  final SeatRepository _seatRepo = SeatRepository();
  final ShowtimeRepository _showtimeRepo = ShowtimeRepository();

  bool _isLoading = true;
  String? _errorMessage;
  List<String> _layoutRows = [];
  StreamSubscription<List<SeatModel>>? _seatSub;
  final Map<String, SeatModel> _liveSeatMap = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSeatMap();
    });
  }

  @override
  void dispose() {
    _seatSub?.cancel();
    super.dispose();
  }

  Future<void> _initSeatMap() async {
    final booking = context.read<BookingProvider>();
    final showtime = booking.selectedShowtime;

    if (showtime == null) {
      setState(() {
        _errorMessage = 'Chưa chọn suất chiếu.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final details = await _showtimeRepo.getShowtimeWithRoom(showtime.id);
      final room = details?['rooms'] as Map<String, dynamic>?;
      final layoutRaw = room?['seat_layout'];

      if (layoutRaw is List) {
        _layoutRows = layoutRaw.map((e) => e.toString()).toList();
      } else {
        // Fallback standard layout (A to H)
        _layoutRows = [
          'S,S,S,S,S,S,S,S,S,S',
          'S,S,S,S,S,S,S,S,S,S',
          'S,S,S,S,S,S,S,S,S,S',
          'V,V,V,V,V,V,V,V,V,V',
          'V,V,V,V,V,V,V,V,V,V',
          'V,V,V,V,V,V,V,V,V,V',
          'V,V,V,V,V,V,V,V,V,V',
          'C,C,C,C,C',
        ];
      }

      // Start Realtime stream
      _seatSub?.cancel();
      _seatSub = _seatRepo.streamSeats(showtime.id).listen((seats) {
        if (!mounted) return;
        setState(() {
          _liveSeatMap.clear();
          for (final seat in seats) {
            _liveSeatMap[seat.seatId] = seat;
          }
        });
      });

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        // Still load fallback layout if room query encounters issue
        _layoutRows = [
          'S,S,S,S,S,S,S,S,S,S',
          'S,S,S,S,S,S,S,S,S,S',
          'S,S,S,S,S,S,S,S,S,S',
          'V,V,V,V,V,V,V,V,V,V',
          'V,V,V,V,V,V,V,V,V,V',
          'V,V,V,V,V,V,V,V,V,V',
          'V,V,V,V,V,V,V,V,V,V',
          'C,C,C,C,C',
        ];
        _isLoading = false;
      });
    }
  }

  SeatState _getSeatState(String seatId, BookingProvider booking) {
    if (booking.selectedSeatIds.contains(seatId)) {
      return SeatState.selected;
    }
    final live = _liveSeatMap[seatId];
    if (live != null) {
      if (live.isSold) return SeatState.sold;
      if (live.isHolding && live.bookingCode != booking.currentBookingCode) {
        return SeatState.held;
      }
    }
    return SeatState.available;
  }

  void _onSeatTap(String seatId, SeatType type, BookingProvider booking) {
    final live = _liveSeatMap[seatId];
    if (live != null && (live.isSold || (live.isHolding && live.bookingCode != booking.currentBookingCode))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.canvasElevated,
          content: Text(
            'Ghế này không còn trống.'.toUpperCase(),
            style: AppTextStyles.bodySm.copyWith(color: AppColors.ink),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final wasSelected = booking.selectedSeatIds.contains(seatId);
    if (!wasSelected && booking.selectedSeatIds.length >= 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.warning,
          content: Text(
            'BẠN CHỈ ĐƯỢC CHỌN TỐI ĐA 8 GHẾ MỖI LẦN'.toUpperCase(),
            style: AppTextStyles.bodySm.copyWith(color: AppColors.ink),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    booking.toggleSeat(seatId, type);
  }

  Future<void> _handleContinue(BookingProvider booking) async {
    final success = await booking.holdSelectedSeats();
    if (!mounted) return;

    if (success) {
      Navigator.pushNamed(context, AppRoutes.foodSelect);
    } else {
      final err = booking.errorMessage ?? 'Không thể giữ ghế. Vui lòng thử lại.';
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.canvasElevated,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.zeroRadius),
          title: Text(
            'THÔNG BÁO'.toUpperCase(),
            style: AppTextStyles.titleMd.copyWith(color: AppColors.ink),
          ),
          content: Text(
            err,
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.body),
          ),
          actions: [
            AppButton.primary(
              label: 'ĐỒNG Ý',
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );
    }
  }

  Future<bool> _handlePop(BookingProvider booking) async {
    if (booking.holdUntil != null) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.canvasElevated,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.zeroRadius),
          title: Text(
            'RỜI KHỎI VÀ NHẢ GHẾ?'.toUpperCase(),
            style: AppTextStyles.titleMd.copyWith(color: AppColors.ink),
          ),
          content: Text(
            'Ghế bạn đang giữ sẽ được nhả cho người khác nếu bạn rời đi.',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.body),
          ),
          actions: [
            AppButton.outline(
              label: 'Ở LẠI',
              onPressed: () => Navigator.pop(ctx, false),
            ),
            const SizedBox(height: AppSpacing.xxs),
            AppButton.primary(
              label: 'RỜI ĐI',
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await booking.releaseCurrentHold();
        return true;
      }
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingProvider>();
    final showtime = booking.selectedShowtime;

    final String title = showtime?.movieTitle ?? 'CHỌN GHẾ';
    final String subtitle = showtime != null
        ? '${showtime.cinemaName ?? ""} · ${showtime.roomName ?? ""} · ${DateFormatter.formatTime(showtime.startTime)}'
        : '';

    final selectedCount = booking.selectedSeatIds.length;
    final summaryText = selectedCount > 0
        ? '$selectedCount GHẾ · ${booking.selectedSeatIds.join(", ")}'
        : '';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _handlePop(booking);
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(
          backgroundColor: AppColors.canvas,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.ink),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle.toUpperCase(),
                  style: AppTextStyles.captionUppercase.copyWith(color: AppColors.muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: SkeletonBox(width: 320, height: 360))
            : _errorMessage != null
                ? Center(
                    child: ErrorState(
                      message: _errorMessage!,
                      onRetry: _initSeatMap,
                    ),
                  )
                : Column(
                    children: [
                      // Curved Screen display
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        child: Column(
                          children: [
                            CustomPaint(
                              size: const Size(double.infinity, 14),
                              painter: _ScreenArcPainter(),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              'MÀN HÌNH',
                              style: AppTextStyles.captionUppercase.copyWith(
                                color: AppColors.muted,
                                letterSpacing: 3.0,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Interactive Seat Map Grid
                      Expanded(
                        child: InteractiveViewer(
                          minScale: 0.8,
                          maxScale: 2.5,
                          boundaryMargin: const EdgeInsets.all(AppSpacing.md),
                          child: Center(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  for (int r = 0; r < _layoutRows.length; r++)
                                    _buildSeatRow(r, _layoutRows[r], booking),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Seat Legend
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        child: SeatLegend(),
                      ),

                      // Sticky Bottom Summary Bar
                      BookingSummaryBar(
                        seatSummary: summaryText,
                        totalPrice: booking.calculateTicketTotal(),
                        buttonLabel: 'TIẾP TỤC',
                        isLoading: booking.isLoading,
                        onButtonPressed: selectedCount > 0
                            ? () => _handleContinue(booking)
                            : null,
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildSeatRow(int rowIndex, String rowPattern, BookingProvider booking) {
    final rowLetter = String.fromCharCode(65 + rowIndex); // A, B, C...
    final tokens = rowPattern.split(',');

    int seatNum = 1;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row label left
          SizedBox(
            width: 20,
            child: Text(
              rowLetter,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: AppSpacing.xxs),

          // Seats in row
          for (final token in tokens) ...[
            if (token == '_')
              const SizedBox(width: 28.0)
            else ...[
              _buildSeatItem(rowLetter, seatNum++, token, booking),
              const SizedBox(width: 4.0),
            ],
          ],

          const SizedBox(width: AppSpacing.xxs),
          // Row label right
          SizedBox(
            width: 20,
            child: Text(
              rowLetter,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatItem(String rowLetter, int seatNumber, String typeToken, BookingProvider booking) {
    final seatId = '$rowLetter$seatNumber';
    SeatType type = SeatType.standard;
    if (typeToken == 'V') type = SeatType.vip;
    if (typeToken == 'C') type = SeatType.couple;

    final state = _getSeatState(seatId, booking);

    return SeatWidget(
      seatId: seatId,
      type: type,
      state: state,
      onTap: () => _onSeatTap(seatId, type, booking),
    );
  }
}

class _ScreenArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.hairline
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height);
    path.quadraticBezierTo(
      size.width / 2,
      0,
      size.width,
      size.height,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
