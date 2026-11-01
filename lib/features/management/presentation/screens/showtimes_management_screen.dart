import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/models/app_user.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/date_chip.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../auth/presentation/controllers/auth_provider.dart';
import '../../../booking/data/models/room_model.dart';
import '../../../booking/data/models/showtime_model.dart';
import '../../../movies/data/movie_model.dart';
import '../controllers/management_provider.dart';

/// Screen S14: Showtimes Management with 15-minute gap conflict prevention & cancellation.
/// References: BUSINESS_RULES.md Section 3.3, ROLE_FLOWS.md Section 4.3 & 5.3
class ShowtimesManagementScreen extends StatefulWidget {
  const ShowtimesManagementScreen({super.key});

  @override
  State<ShowtimesManagementScreen> createState() => _ShowtimesManagementScreenState();
}

class _ShowtimesManagementScreenState extends State<ShowtimesManagementScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedRoomId = 'ALL';
  String _selectedFormat = 'ALL';
  String _activeCinemaId = 'cn_q1';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      final isAdmin = user?.role == UserRole.admin;
      if (user?.cinemaId != null && user!.cinemaId!.isNotEmpty) {
        _activeCinemaId = user.cinemaId!;
      }
      final provider = context.read<ManagementProvider>();
      if (isAdmin) {
        provider.loadCinemas();
      }
      _loadData();
    });
  }

  void _loadData() {
    final provider = context.read<ManagementProvider>();
    provider.loadRooms(_activeCinemaId);
    provider.loadMovies();
    provider.loadShowtimes(
      _activeCinemaId,
      date: _selectedDate,
      roomId: _selectedRoomId,
      format: _selectedFormat,
    );
  }

  void _openAddShowtimeModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.canvasElevated,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.zeroRadius),
      builder: (_) => _AddShowtimeSheet(
        cinemaId: _activeCinemaId,
        selectedDate: _selectedDate,
        onCreated: () => _loadData(),
      ),
    );
  }

  void _confirmCancelShowtime(BuildContext context, ShowtimeModel showtime) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.canvasElevated,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.zeroRadius),
        title: Text(
          'XÁC NHẬN HỦY SUẤT CHIẾU'.toUpperCase(),
          style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cảnh báo: Hủy suất chiếu "${showtime.movieTitle ?? 'Phim'}" lúc ${DateFormatter.formatTime(showtime.startTime)} (${DateFormatter.formatDate(showtime.startTime)}) sẽ tự động hoàn tiền 100% cho tất cả khách hàng đã mua vé và gửi thông báo huỷ.',
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.ink),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: reasonController,
              label: 'LÝ DO HỦY *',
              hintText: 'Nhập lý do hủy suất chiếu...',
            ),
          ],
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
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng nhập lý do hủy suất chiếu'),
                    backgroundColor: AppColors.warning,
                  ),
                );
                return;
              }

              Navigator.pop(dialogCtx);
              final messenger = ScaffoldMessenger.of(context);
              final provider = context.read<ManagementProvider>();
              final success = await provider.cancelShowtime(
                showtime.id,
                reason,
                cinemaId: _activeCinemaId,
                date: _selectedDate,
              );
              if (!mounted) return;
              if (success) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Hủy suất chiếu thành công và tự động hoàn tiền'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } else {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(provider.errorMessage ?? 'Hủy suất thất bại'),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final isAdmin = user?.role == UserRole.admin;
    final provider = context.watch<ManagementProvider>();
    final selectedCinema = provider.cinemas.where((c) => c.id == _activeCinemaId).firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LỊCH SUẤT CHIẾU'.toUpperCase(),
              style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
            ),
            const SizedBox(height: AppSpacing.xxxs),
            Text(
              selectedCinema != null ? selectedCinema.name.toUpperCase() : 'RẠP ${_activeCinemaId.toUpperCase()}',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _openAddShowtimeModal(context),
            icon: const Icon(Icons.add, color: AppColors.primary, size: 20),
            label: Text(
              'THÊM SUẤT'.toUpperCase(),
              style: AppTextStyles.button.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Cinema Selector Bar (if Admin)
          if (isAdmin && provider.cinemas.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: provider.cinemas.map((cinema) {
                  final isSelected = _activeCinemaId == cinema.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: ChoiceChip(
                      label: Text(
                        cinema.name.toUpperCase(),
                        style: AppTextStyles.caption.copyWith(
                          color: isSelected ? AppColors.ink : AppColors.muted,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.canvasElevated,
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.zeroRadius,
                        side: BorderSide(color: AppColors.hairline),
                      ),
                      elevation: 0,
                      pressElevation: 0,
                      onSelected: (_) {
                        setState(() {
                          _activeCinemaId = cinema.id;
                          _selectedRoomId = 'ALL';
                        });
                        _loadData();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

          // 7-day Date Selector
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(7, (index) {
                  final date = DateTime.now().add(Duration(days: index));
                  final isSelected = DateUtils.isSameDay(date, _selectedDate);
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
                        _loadData();
                      },
                    ),
                  );
                }),
              ),
            ),
          ),

          // Filters: Rooms and Formats
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xxs,
            ),
            child: Row(
              children: [
                _buildChip(
                  label: 'TẤT CẢ PHÒNG',
                  isSelected: _selectedRoomId == 'ALL',
                  onSelected: () {
                    setState(() => _selectedRoomId = 'ALL');
                    _loadData();
                  },
                ),
                ...provider.rooms.map((room) => Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.xs),
                  child: _buildChip(
                    label: room.name,
                    isSelected: _selectedRoomId == room.id,
                    onSelected: () {
                      setState(() => _selectedRoomId = room.id);
                      _loadData();
                    },
                  ),
                )),
                const SizedBox(width: AppSpacing.md),
                _buildChip(
                  label: 'TẤT CẢ ĐỊNH DẠNG',
                  isSelected: _selectedFormat == 'ALL',
                  onSelected: () {
                    setState(() => _selectedFormat = 'ALL');
                    _loadData();
                  },
                ),
                ...['2D', '3D', 'IMAX'].map((fmt) => Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.xs),
                  child: _buildChip(
                    label: fmt,
                    isSelected: _selectedFormat == fmt,
                    onSelected: () {
                      setState(() => _selectedFormat = fmt);
                      _loadData();
                    },
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Showtimes List
          Expanded(
            child: _buildBody(context, provider),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(
        label.toUpperCase(),
        style: AppTextStyles.caption.copyWith(
          color: isSelected ? AppColors.ink : AppColors.muted,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.canvasElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.zeroRadius,
        side: BorderSide(color: AppColors.hairline),
      ),
      elevation: 0,
      pressElevation: 0,
      onSelected: (_) => onSelected(),
    );
  }

  Widget _buildBody(BuildContext context, ManagementProvider provider) {
    if (provider.isLoading) {
      return ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, __) => const SkeletonBox(
          width: double.infinity,
          height: 110,
        ),
      );
    }

    if (provider.errorMessage != null) {
      return Center(
        child: ErrorState(
          message: provider.errorMessage!,
          onRetry: () => _loadData(),
        ),
      );
    }

    if (provider.showtimes.isEmpty) {
      return Center(
        child: EmptyState(
          title: 'KHÔNG CÓ SUẤT CHIẾU',
          message: 'Không có suất chiếu nào trong ngày đã chọn',
          actionLabel: 'THÊM SUẤT CHIẾU',
          onAction: () => _openAddShowtimeModal(context),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      color: AppColors.primary,
      backgroundColor: AppColors.canvasElevated,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: provider.showtimes.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final showtime = provider.showtimes[index];
          return _buildShowtimeCard(context, showtime);
        },
      ),
    );
  }

  Widget _buildShowtimeCard(BuildContext context, ShowtimeModel showtime) {
    final isCancelled = showtime.isCancelled;
    final progress = showtime.totalSeats > 0 ? (showtime.soldSeats / showtime.totalSeats) : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.canvasElevated,
        borderRadius: AppRadius.zeroRadius,
        border: Border.all(
          color: isCancelled ? AppColors.muted.withValues(alpha: 0.3) : AppColors.hairline,
          width: 1,
        ),
      ),
      child: Opacity(
        opacity: isCancelled ? 0.6 : 1.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${DateFormatter.formatTime(showtime.startTime)} — ${DateFormatter.formatTime(showtime.endTime)}',
                  style: AppTextStyles.titleSm.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (isCancelled)
                  const AppBadge(label: 'ĐÃ HỦY', backgroundColor: AppColors.muted)
                else
                  const AppBadge(label: 'HOẠT ĐỘNG', backgroundColor: AppColors.success),
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),

            Row(
              children: [
                Expanded(
                  child: Text(
                    showtime.movieTitle ?? 'Tên phim',
                    style: AppTextStyles.titleSm.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                AppBadge.format(showtime.format),
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),

            Text(
              '${showtime.roomName ?? 'Phòng'} · Rạp ${showtime.cinemaName ?? _activeCinemaId.toUpperCase()}',
              style: AppTextStyles.caption.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.xs),

            // Capacity progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Đã bán: ${showtime.soldSeats}/${showtime.totalSeats} ghế (${(progress * 100).toInt()}%)',
                  style: AppTextStyles.caption.copyWith(
                    color: showtime.isSoldOut ? AppColors.warning : AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!isCancelled)
                  InkWell(
                    onTap: () => _confirmCancelShowtime(context, showtime),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
                      child: Text(
                        'HỦY SUẤT',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxxs),
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: AppColors.canvas,
              valueColor: AlwaysStoppedAnimation<Color>(
                showtime.isSoldOut ? AppColors.warning : AppColors.primary,
              ),
              minHeight: 4,
            ),

            if (isCancelled && showtime.cancelReason != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Lý do hủy: ${showtime.cancelReason}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.warning,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddShowtimeSheet extends StatefulWidget {
  final String cinemaId;
  final DateTime selectedDate;
  final VoidCallback onCreated;

  const _AddShowtimeSheet({
    required this.cinemaId,
    required this.selectedDate,
    required this.onCreated,
  });

  @override
  State<_AddShowtimeSheet> createState() => _AddShowtimeSheetState();
}

class _AddShowtimeSheetState extends State<_AddShowtimeSheet> {
  final _formKey = GlobalKey<FormState>();
  MovieModel? _selectedMovie;
  RoomModel? _selectedRoom;
  String _selectedFormat = '2D';
  TimeOfDay _startTime = const TimeOfDay(hour: 19, minute: 0);

  DateTime get _startDateTime {
    return DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );
  }

  DateTime get _endDateTime {
    final duration = _selectedMovie?.durationMin ?? 120;
    return _startDateTime.add(Duration(minutes: duration));
  }

  bool _hasConflictWith(List<ShowtimeModel> existingList) {
    final candidateStart = _startDateTime;
    final candidateEnd = _endDateTime;

    for (final s in existingList) {
      if (s.isCancelled || s.roomId != _selectedRoom?.id) continue;
      // 15-minute gap conflict condition:
      // (candidateStart < (s.endTime + 15m)) && (candidateEnd > (s.startTime - 15m))
      final existingStart = s.startTime;
      final existingEnd = s.endTime;
      final limitStart = existingStart.subtract(const Duration(minutes: 15));
      final limitEnd = existingEnd.add(const Duration(minutes: 15));

      if (candidateStart.isBefore(limitEnd) && candidateEnd.isAfter(limitStart)) {
        return true;
      }
    }
    return false;
  }

  Future<void> _submit() async {
    if (_selectedMovie == null || _selectedRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn phim và phòng chiếu'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final provider = context.read<ManagementProvider>();

    // Client-side 15-minute gap pre-check
    if (_hasConflictWith(provider.showtimes)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Xung đột lịch chiếu: Phòng ${_selectedRoom!.name} đã có suất chiếu trong khung giờ này (khoảng nghỉ vệ sinh tối thiểu 15 phút).',
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final success = await provider.createShowtime(
      movieId: _selectedMovie!.id,
      cinemaId: widget.cinemaId,
      roomId: _selectedRoom!.id,
      format: _selectedFormat,
      startTime: _startDateTime,
      endTime: _endDateTime,
      totalSeats: _selectedRoom!.seatCount,
    );

    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
      widget.onCreated();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Tạo suất chiếu thành công'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Tạo suất chiếu thất bại'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ManagementProvider>();
    final activeMovies = provider.movies.where((m) => m.isActive).toList();
    final rooms = provider.rooms;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'LẬP LỊCH SUẤT CHIẾU MỚI'.toUpperCase(),
                style: AppTextStyles.titleSm.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Movie Dropdown
              Text('CHỌN PHIM *', style: AppTextStyles.captionUppercase.copyWith(color: AppColors.muted)),
              const SizedBox(height: AppSpacing.xxs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: AppRadius.zeroRadius,
                  border: Border.all(color: AppColors.hairline),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<MovieModel>(
                    value: _selectedMovie,
                    hint: const Text('Chọn phim...', style: TextStyle(color: AppColors.muted)),
                    dropdownColor: AppColors.canvasElevated,
                    isExpanded: true,
                    items: activeMovies.map((m) {
                      return DropdownMenuItem(
                        value: m,
                        child: Text(
                          '${m.title} (${m.durationMin}p)',
                          style: const TextStyle(color: AppColors.ink),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedMovie = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Room Dropdown
              Text('CHỌN PHÒNG CHIẾU *', style: AppTextStyles.captionUppercase.copyWith(color: AppColors.muted)),
              const SizedBox(height: AppSpacing.xxs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: AppRadius.zeroRadius,
                  border: Border.all(color: AppColors.hairline),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<RoomModel>(
                    value: _selectedRoom,
                    hint: const Text('Chọn phòng chiếu...', style: TextStyle(color: AppColors.muted)),
                    dropdownColor: AppColors.canvasElevated,
                    isExpanded: true,
                    items: rooms.map((r) {
                      return DropdownMenuItem(
                        value: r,
                        child: Text(
                          '${r.name} (${r.seatCount} ghế)',
                          style: const TextStyle(color: AppColors.ink),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedRoom = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Format
              Text('ĐỊNH DẠNG CHIẾU', style: AppTextStyles.captionUppercase.copyWith(color: AppColors.muted)),
              const SizedBox(height: AppSpacing.xxs),
              Row(
                children: ['2D', '3D', 'IMAX'].map((fmt) {
                  final isSelected = _selectedFormat == fmt;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: ChoiceChip(
                      label: Text(fmt),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.canvas,
                      onSelected: (_) => setState(() => _selectedFormat = fmt),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Time picker
              Text('GIỜ BẮT ĐẦU CHIẾU *', style: AppTextStyles.captionUppercase.copyWith(color: AppColors.muted)),
              const SizedBox(height: AppSpacing.xxs),
              InkWell(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _startTime,
                  );
                  if (picked != null) {
                    setState(() => _startTime = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    border: Border.all(color: AppColors.hairline),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormatter.formatTime(_startDateTime),
                        style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
                      ),
                      const Icon(Icons.access_time, color: AppColors.primary, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Auto-calculated End Time Box
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  border: Border.all(color: AppColors.hairline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GIỜ KẾT THÚC DỰ KIẾN (TỰ ĐỘNG TÍNH):',
                      style: AppTextStyles.captionUppercase.copyWith(color: AppColors.muted),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${DateFormatter.formatTime(_endDateTime)} (Thời lượng: ${_selectedMovie?.durationMin ?? 120} phút)',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              AppButton.primary(
                label: 'LẬP SUẤT CHIẾU',
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
