import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/models/app_user.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/notification_badge.dart';
import '../../../../shared/widgets/quantity_stepper.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../../shared/widgets/staff_bottom_nav.dart';
import '../../../auth/presentation/controllers/auth_provider.dart';
import '../../../booking/data/models/showtime_model.dart';
import '../controllers/staff_counter_provider.dart';

/// S20: Counter Showtimes Screen (/staff/counter-showtimes)
/// References: ROLE_FLOWS.md Section 3.3 & BUSINESS_RULES.md Section 10 & m4_plan.md Section 3.3
class CounterShowtimesScreen extends StatefulWidget {
  const CounterShowtimesScreen({super.key});

  @override
  State<CounterShowtimesScreen> createState() => _CounterShowtimesScreenState();
}

class _CounterShowtimesScreenState extends State<CounterShowtimesScreen> {
  String _selectedRoom = 'TẤT CẢ';
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final auth = context.read<AuthProvider>();
          final cinemaId = auth.currentUser?.cinemaId ?? 'cn_q1';
          context.read<StaffCounterProvider>().loadShowtimes(cinemaId, DateTime.now());
        }
      });
    }
  }

  void _openSeatAndConcessionSheet(BuildContext context, ShowtimeModel showtime) {
    final provider = context.read<StaffCounterProvider>();
    provider.selectShowtime(showtime);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return ChangeNotifierProvider.value(
          value: provider,
          child: _SeatAndConcessionSheet(
            showtime: showtime,
            parentContext: context,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cinemaName = auth.currentUser?.cinemaId?.toUpperCase() ?? 'RẠP CHIẾU';
    final counterProvider = context.watch<StaffCounterProvider>();

    // Extract unique rooms for filtering
    final allRooms = <String>{'TẤT CẢ'};
    for (final st in counterProvider.showtimes) {
      if (st.roomName != null && st.roomName!.isNotEmpty) {
        allRooms.add(st.roomName!);
      }
    }

    final filteredShowtimes = _selectedRoom == 'TẤT CẢ'
        ? counterProvider.showtimes
        : counterProvider.showtimes.where((st) => st.roomName == _selectedRoom).toList();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BÁN VÉ TẠI QUẦY',
              style: AppTextStyles.titleSm.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'HÔM NAY · ${DateFormatter.formatDate(DateTime.now())} ($cinemaName)',
              style: AppTextStyles.caption.copyWith(color: AppColors.primary),
            ),
          ],
        ),
        actions: [
          NotificationBadge(
            unreadCount: 0,
            onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
          ),
          const SizedBox(width: AppSpacing.xxs),
        ],
      ),
      body: Column(
        children: [
          // Room filter chips
          Container(
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.canvas,
              border: Border(
                bottom: BorderSide(color: AppColors.hairline, width: 1),
              ),
            ),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.xxs,
              ),
              itemCount: allRooms.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xxs),
              itemBuilder: (context, index) {
                final room = allRooms.elementAt(index);
                final isSelected = room == _selectedRoom;

                return InkWell(
                  key: Key('room_filter_${room.replaceAll(" ", "_")}'),
                  onTap: () => setState(() => _selectedRoom = room),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.canvasElevated,
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.hairline,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.zero,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      room.toUpperCase(),
                      style: AppTextStyles.captionUppercase.copyWith(
                        color: isSelected ? AppColors.ink : AppColors.body,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Showtimes list with 3 UI States
          Expanded(
            child: _buildBody(context, counterProvider, filteredShowtimes, auth.currentUser?.cinemaId ?? 'cn_q1'),
          ),
        ],
      ),
      bottomNavigationBar: auth.currentUser?.role == UserRole.manager || auth.currentUser?.role == UserRole.admin
          ? null
          : const StaffBottomNav(currentIndex: 2),
    );
  }

  Widget _buildBody(
    BuildContext context,
    StaffCounterProvider provider,
    List<ShowtimeModel> showtimes,
    String cinemaId,
  ) {
    if (provider.isLoading) {
      return ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.xs),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
        itemBuilder: (_, __) => const SkeletonBox(
          width: double.infinity,
          height: 120,
        ),
      );
    }

    if (provider.errorMessage != null && provider.showtimes.isEmpty) {
      return Center(
        child: ErrorState(
          message: provider.errorMessage!,
          onRetry: () => provider.loadShowtimes(cinemaId, DateTime.now()),
        ),
      );
    }

    if (showtimes.isEmpty) {
      return const Center(
        child: EmptyState(
          title: 'KHÔNG CÓ SUẤT CHIẾU',
          message: 'Hôm nay không có suất chiếu nào tại rạp.',
          icon: Icons.movie_outlined,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.xs),
      itemCount: showtimes.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (context, index) {
        final showtime = showtimes[index];
        return _buildShowtimeCard(context, showtime);
      },
    );
  }

  Widget _buildShowtimeCard(BuildContext context, ShowtimeModel showtime) {
    final availableSeats = showtime.totalSeats - showtime.soldSeats;
    final isSoldOut = availableSeats <= 0;

    return InkWell(
      key: Key('counter_showtime_${showtime.id}'),
      onTap: isSoldOut ? null : () => _openSeatAndConcessionSheet(context, showtime),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.canvasElevated,
          border: Border.all(color: AppColors.hairline, width: 1),
          borderRadius: BorderRadius.zero,
        ),
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Movie Title & Format
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    showtime.movieTitle ?? 'Suất chiếu',
                    style: AppTextStyles.titleSm.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.xxs),
                AppBadge(label: showtime.format),
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),

            // Time & Room
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: AppColors.primary),
                const SizedBox(width: AppSpacing.xxxs),
                Text(
                  '${DateFormatter.formatTime(showtime.startTime)} - ${DateFormatter.formatTime(showtime.endTime)}',
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Icon(Icons.meeting_room_outlined, size: 16, color: AppColors.muted),
                const SizedBox(width: AppSpacing.xxxs),
                Text(
                  showtime.roomName ?? 'Phòng chiếu',
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.body),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),

            // Pricing & Availability Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TỪ ${CurrencyFormatter.format(showtime.minPrice)}',
                  style: AppTextStyles.captionUppercase.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  isSoldOut ? 'HẾT GHẾ' : 'CÒN $availableSeats/${showtime.totalSeats} GHẾ',
                  style: AppTextStyles.captionUppercase.copyWith(
                    color: isSoldOut ? AppColors.warning : AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SeatAndConcessionSheet extends StatefulWidget {
  final ShowtimeModel showtime;
  final BuildContext parentContext;

  const _SeatAndConcessionSheet({
    required this.showtime,
    required this.parentContext,
  });

  @override
  State<_SeatAndConcessionSheet> createState() => _SeatAndConcessionSheetState();
}

class _SeatAndConcessionSheetState extends State<_SeatAndConcessionSheet> {
  bool _isLoading = true;
  Set<String> _takenSeatIds = {};
  List<String> _layoutRows = [];
  List<Map<String, dynamic>> _dbFoods = [];

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    final counter = context.read<StaffCounterProvider>();
    try {
      final seatsFuture = counter.repo.getShowtimeSeats(widget.showtime.id);
      final layoutFuture = counter.repo.getRoomLayout(widget.showtime.roomId);
      final foodsFuture = counter.repo.getAvailableFoods(widget.showtime.cinemaId);

      final results = await Future.wait([seatsFuture, layoutFuture, foodsFuture]);
      final seats = results[0] as List<Map<String, dynamic>>;
      final layout = results[1] as List<String>;
      final foods = results[2] as List<Map<String, dynamic>>;

      final taken = <String>{};
      final now = DateTime.now();
      for (final s in seats) {
        final status = s['status'] as String?;
        final holdUntilStr = s['hold_until'] as String?;
        if (status == 'sold') {
          taken.add(s['seat_id'] as String);
        } else if (status == 'holding' && holdUntilStr != null) {
          final holdUntil = DateTime.tryParse(holdUntilStr);
          if (holdUntil != null && holdUntil.isAfter(now)) {
            taken.add(s['seat_id'] as String);
          }
        }
      }

      if (mounted) {
        setState(() {
          _takenSeatIds = taken;
          _layoutRows = layout;
          _dbFoods = foods;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final counter = context.watch<StaffCounterProvider>();
    final totalAmount = counter.calculateTotal();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.canvasElevated,
        borderRadius: AppRadius.sheetRadius,
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.showtime.movieTitle ?? 'CHỌN SUẤT CHIẾU',
                        style: AppTextStyles.titleSm.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${widget.showtime.roomName ?? "Phòng chiếu"} · ${DateFormatter.formatTime(widget.showtime.startTime)} (${widget.showtime.format})',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.muted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(color: AppColors.hairline, height: AppSpacing.sm),

            // Scrollable content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Seat Selection Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'CHỌN GHẾ TẠI QUẦY',
                                style: AppTextStyles.captionUppercase.copyWith(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${counter.selectedSeatIds.length}/8 GHẾ',
                                style: AppTextStyles.caption.copyWith(
                                  color: counter.selectedSeatIds.length >= 8
                                      ? AppColors.warning
                                      : AppColors.body,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),

                          // Screen indicator
                          Center(
                            child: Container(
                              width: 200,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: AppColors.muted,
                                borderRadius: BorderRadius.zero,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxxs),
                          Center(
                            child: Text(
                              'MÀN HÌNH',
                              style: AppTextStyles.captionUppercase.copyWith(
                                color: AppColors.muted,
                                fontSize: 9,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          // Quick Seat Grid
                          _buildSeatMatrix(counter),

                          const SizedBox(height: AppSpacing.md),
                          const Divider(color: AppColors.hairline, height: 1),
                          const SizedBox(height: AppSpacing.sm),

                          // Concessions Selection
                          Text(
                            'BẮP NƯỚC KÈM THEO',
                            style: AppTextStyles.captionUppercase.copyWith(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),

                          ..._buildConcessionList(counter),
                        ],
                      ),
                    ),
            ),

            const Divider(color: AppColors.hairline, height: AppSpacing.sm),

            // Total amount & Submit
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TỔNG TIỀN TẠM TÍNH',
                      style: AppTextStyles.captionUppercase.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(totalAmount),
                      style: AppTextStyles.displayMd.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                AppButton.primary(
                  key: const Key('counter_continue_booking_btn'),
                  label: 'TIẾP TỤC',
                  onPressed: counter.selectedSeatIds.isEmpty
                      ? null
                      : () async {
                          final ok = await counter.holdSeatsForCounter();
                          if (ok && context.mounted) {
                            Navigator.pop(context);
                            Navigator.pushNamed(
                              widget.parentContext,
                              AppRoutes.staffCounterPayment,
                            );
                          } else if (counter.errorMessage != null && context.mounted) {
                            ScaffoldMessenger.of(widget.parentContext).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.warning,
                                content: Text(
                                  counter.errorMessage!,
                                  style: AppTextStyles.bodySm.copyWith(
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeatMatrix(StaffCounterProvider counter) {
    if (_layoutRows.isNotEmpty) {
      return Column(
        children: _layoutRows.asMap().entries.map((entry) {
          final rowIndex = entry.key;
          final rowCode = String.fromCharCode(65 + rowIndex);
          final seatTokens = entry.value.split(',').map((s) => s.trim()).toList();

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  child: Text(
                    rowCode,
                    style: AppTextStyles.captionUppercase.copyWith(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: AppSpacing.xxs),
                ...seatTokens.asMap().entries.map((colEntry) {
                  final colNumber = colEntry.key + 1;
                  final seatId = '$rowCode$colNumber';
                  final isTaken = _takenSeatIds.contains(seatId);
                  final isSelected = counter.selectedSeatIds.contains(seatId);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.5),
                    child: InkWell(
                      key: Key('counter_seat_$seatId'),
                      onTap: isTaken
                          ? () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppColors.canvasElevated,
                                  content: Text(
                                    'GHẾ $seatId ĐÃ CÓ NGƯỜI ĐẶT'.toUpperCase(),
                                    style: AppTextStyles.bodySm.copyWith(color: AppColors.ink),
                                  ),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            }
                          : () {
                              counter.toggleSeat(seatId);
                            },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isTaken
                              ? AppColors.canvasElevated
                              : (isSelected ? AppColors.primary : AppColors.canvas),
                          border: Border.all(
                            color: isTaken
                                ? AppColors.hairline
                                : (isSelected ? AppColors.primary : AppColors.hairline),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.zero,
                        ),
                        child: Center(
                          child: Text(
                            '$colNumber',
                            style: AppTextStyles.caption.copyWith(
                              color: isTaken
                                  ? AppColors.muted
                                  : (isSelected ? AppColors.ink : AppColors.body),
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              decoration: isTaken ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        }).toList(),
      );
    }

    // Fallback standard layout A..D x 1..8
    const rows = ['A', 'B', 'C', 'D'];
    const cols = [1, 2, 3, 4, 5, 6, 7, 8];

    return Column(
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                child: Text(
                  row,
                  style: AppTextStyles.captionUppercase.copyWith(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: AppSpacing.xxs),
              ...cols.map((col) {
                final seatId = '$row$col';
                final isTaken = _takenSeatIds.contains(seatId);
                final isSelected = counter.selectedSeatIds.contains(seatId);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                  child: InkWell(
                    key: Key('counter_seat_$seatId'),
                    onTap: isTaken
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.canvasElevated,
                                content: Text(
                                  'GHẾ $seatId ĐÃ CÓ NGƯỜI ĐẶT'.toUpperCase(),
                                  style: AppTextStyles.bodySm.copyWith(color: AppColors.ink),
                                ),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        : () {
                            counter.toggleSeat(seatId);
                          },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isTaken
                            ? AppColors.canvasElevated
                            : (isSelected ? AppColors.primary : AppColors.canvas),
                        border: Border.all(
                          color: isTaken
                              ? AppColors.hairline
                              : (isSelected ? AppColors.primary : AppColors.hairline),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Center(
                        child: Text(
                          '$col',
                          style: AppTextStyles.caption.copyWith(
                            color: isTaken
                                ? AppColors.muted
                                : (isSelected ? AppColors.ink : AppColors.body),
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            decoration: isTaken ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }

  List<Widget> _buildConcessionList(StaffCounterProvider counter) {
    if (_dbFoods.isNotEmpty) {
      return _dbFoods.map((f) {
        final id = f['id'] as String;
        final name = f['name'] as String? ?? 'Bắp nước';
        final price = (f['price'] as num?)?.toInt() ?? 50000;
        return _buildConcessionItem(
          counter: counter,
          foodId: id,
          name: name,
          price: price,
        );
      }).toList();
    }

    return [
      _buildConcessionItem(
        counter: counter,
        foodId: 'food_combo1',
        name: 'Combo Bắp Nước',
        price: 75000,
      ),
      _buildConcessionItem(
        counter: counter,
        foodId: 'food_popcorn',
        name: 'Bắp Ngọt Vừa',
        price: 50000,
      ),
      _buildConcessionItem(
        counter: counter,
        foodId: 'food_drink',
        name: 'Coca-Cola Vừa',
        price: 30000,
      ),
    ];
  }

  Widget _buildConcessionItem({
    required StaffCounterProvider counter,
    required String foodId,
    required String name,
    required int price,
  }) {
    final existing = counter.selectedFoods.firstWhere(
      (item) => item['food_id'] == foodId,
      orElse: () => {'qty': 0},
    );
    final currentQty = (existing['qty'] as int?) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        border: Border.all(color: AppColors.hairline, width: 1),
        borderRadius: BorderRadius.zero,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  CurrencyFormatter.format(price),
                  style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
          QuantityStepper(
            value: currentQty,
            onChanged: (newQty) {
              counter.setFoodQuantity(foodId, name, price, newQty);
            },
          ),
        ],
      ),
    );
  }
}
