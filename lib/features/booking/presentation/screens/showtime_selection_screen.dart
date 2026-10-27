import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/date_chip.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/showtime_row.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../auth/presentation/controllers/auth_provider.dart';
import '../../../movies/data/movie_model.dart';
import '../../data/models/showtime_model.dart';
import '../../data/repositories/showtime_repository.dart';
import '../controllers/booking_provider.dart';

/// S05 Showtime Selection Screen.
/// References: ROLE_FLOWS.md Section 1, DESIGN_TOKENS.md, m3_plan.md Section 3.1
class ShowtimeSelectionScreen extends StatefulWidget {
  final String? movieId;
  final String? movieTitle;
  final MovieModel? movie;
  final String? cinemaId;
  final String? cinemaName;

  const ShowtimeSelectionScreen({
    super.key,
    this.movieId,
    this.movieTitle,
    this.movie,
    this.cinemaId,
    this.cinemaName,
  });

  @override
  State<ShowtimeSelectionScreen> createState() => _ShowtimeSelectionScreenState();
}

class _ShowtimeSelectionScreenState extends State<ShowtimeSelectionScreen> {
  final ShowtimeRepository _repo = ShowtimeRepository();
  late final List<DateTime> _dates;
  late DateTime _selectedDate;

  bool _isLoading = false;
  String? _errorMessage;
  List<ShowtimeModel> _showtimes = [];

  String get _effectiveMovieId =>
      widget.movieId ?? widget.movie?.id ?? '';

  String get _displayTitle =>
      widget.movieTitle ?? widget.movie?.title ?? 'CHỌN SUẤT CHIẾU';

  String? get _effectiveAgeRating => widget.movie?.ageRating;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _dates = List.generate(
      7,
      (i) => DateTime(now.year, now.month, now.day).add(Duration(days: i)),
    );
    _fetchShowtimes();
  }

  Future<void> _fetchShowtimes() async {
    if (_effectiveMovieId.isEmpty) {
      setState(() {
        _errorMessage = 'Thiếu thông tin phim.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _repo.getShowtimes(
        movieId: _effectiveMovieId,
        date: _selectedDate,
        cinemaId: widget.cinemaId,
      );
      if (!mounted) return;
      setState(() {
        _showtimes = list;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Không thể tải danh sách suất chiếu. Vui lòng thử lại.';
        _isLoading = false;
      });
    }
  }

  void _onShowtimeSelected(ShowtimeModel showtime) {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      Navigator.pushNamed(
        context,
        AppRoutes.login,
        arguments: {'redirectRoute': AppRoutes.showtimes},
      );
      return;
    }

    final ageRating = _effectiveAgeRating;
    final isRestricted = ageRating == 'T16' || ageRating == 'T18';

    if (isRestricted) {
      final requiredAge = ageRating == 'T18' ? '18' : '16';
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.canvasElevated,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.zeroRadius),
          title: Text(
            'XÁC NHẬN ĐỘ TUỔI'.toUpperCase(),
            style: AppTextStyles.titleMd.copyWith(color: AppColors.ink),
          ),
          content: Text(
            'Phim dành cho khán giả từ $requiredAge tuổi trở lên. Quý khách vui lòng mang theo giấy tờ tùy thân để nhân viên kiểm tra tại rạp.',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.body),
          ),
          actions: [
            AppButton.outline(
              label: 'HỦY',
              onPressed: () => Navigator.pop(ctx),
            ),
            const SizedBox(height: AppSpacing.xxs),
            AppButton.primary(
              label: 'TÔI ĐÃ ĐỦ TUỔI',
              onPressed: () {
                Navigator.pop(ctx);
                _proceedToSeatSelection(showtime);
              },
            ),
          ],
        ),
      );
    } else {
      _proceedToSeatSelection(showtime);
    }
  }

  void _proceedToSeatSelection(ShowtimeModel showtime) {
    context.read<BookingProvider>().setShowtime(showtime);
    Navigator.pushNamed(context, AppRoutes.seatSelect);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.ink),
        title: Text(
          _displayTitle.toUpperCase(),
          style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 7-day Date Selector
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.hairline, width: 1),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _dates.map((date) {
                  final isSelected = date.year == _selectedDate.year &&
                      date.month == _selectedDate.month &&
                      date.day == _selectedDate.day;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: DateChip(
                      weekday: DateFormatter.formatWeekdayAbbr(date),
                      dayNumber: date.day.toString().padLeft(2, '0'),
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          _selectedDate = date;
                        });
                        _fetchShowtimes();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Showtimes Content with 3 UI States
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          children: List.generate(
            4,
            (index) => const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
              child: SkeletonBox(width: double.infinity, height: 60),
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: ErrorState(
          message: _errorMessage!,
          onRetry: _fetchShowtimes,
        ),
      );
    }

    if (_showtimes.isEmpty) {
      return const Center(
        child: EmptyState(
          title: 'CHƯA CÓ SUẤT CHIẾU',
          message: 'Vui lòng chọn ngày khác hoặc quay lại sau.',
          icon: Icons.calendar_today_outlined,
        ),
      );
    }

    // Group showtimes by cinema
    final Map<String, List<ShowtimeModel>> grouped = {};
    for (final st in _showtimes) {
      final key = st.cinemaName ?? 'Rạp Chiếu';
      grouped.putIfAbsent(key, () => []).add(st);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.sm),
      itemCount: grouped.keys.length,
      itemBuilder: (context, index) {
        final cinemaName = grouped.keys.elementAt(index);
        final list = grouped[cinemaName]!;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cinema header
              Row(
                children: [
                  const Icon(
                    Icons.place_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Expanded(
                    child: Text(
                      cinemaName.toUpperCase(),
                      style: AppTextStyles.titleMd.copyWith(color: AppColors.ink),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxs),

              // Showtimes in cinema
              ...list.map((st) {
                final isPast = st.isPast;
                final isSoldOut = st.isSoldOut || isPast;
                return ShowtimeRow(
                  startTime: DateFormatter.formatTime(st.startTime),
                  roomName: st.roomName ?? 'Phòng chiếu',
                  format: st.format,
                  minPrice: st.minPrice,
                  isSoldOut: isSoldOut,
                  onTap: () => _onShowtimeSelected(st),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
