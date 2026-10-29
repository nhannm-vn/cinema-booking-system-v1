import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/models/app_user.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../auth/presentation/controllers/auth_provider.dart';
import '../../../booking/data/models/booking_model.dart';
import '../controllers/management_provider.dart';

/// Screen S15: Bookings & Orders Inspection with status/channel filters and detail bottom sheet.
/// References: ROLE_FLOWS.md Section 4.4 & 5.4
class BookingsManagementScreen extends StatefulWidget {
  const BookingsManagementScreen({super.key});

  @override
  State<BookingsManagementScreen> createState() => _BookingsManagementScreenState();
}

class _BookingsManagementScreenState extends State<BookingsManagementScreen> {
  String _selectedStatus = 'ALL';
  String _selectedChannel = 'ALL';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String _activeCinemaId = 'cn_q1';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user?.cinemaId != null && user!.cinemaId!.isNotEmpty) {
        _activeCinemaId = user.cinemaId!;
      }
      _loadBookings();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadBookings() {
    context.read<ManagementProvider>().loadBookings(
      _activeCinemaId,
      status: _selectedStatus,
      channel: _selectedChannel,
      search: _searchQuery,
    );
  }

  void _openBookingDetailModal(BuildContext context, BookingModel booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.canvasElevated,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.zeroRadius),
      builder: (_) => _BookingDetailSheet(booking: booking),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final isAdmin = user?.role == UserRole.admin;
    final provider = context.watch<ManagementProvider>();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'KIỂM TRA ĐƠN VÉ & ĐẶT CHỖ'.toUpperCase(),
              style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
            ),
            const SizedBox(height: AppSpacing.xxxs),
            Text(
              isAdmin ? 'RẠP ${_activeCinemaId.toUpperCase()} (ADMIN)' : 'RẠP ${_activeCinemaId.toUpperCase()}',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: AppTextField(
              controller: _searchController,
              hintText: 'Tìm theo mã vé, tên phim, khách...',
              prefixIcon: const Icon(Icons.search, color: AppColors.muted),
              onChanged: (val) {
                _searchQuery = val.trim();
                _loadBookings();
              },
            ),
          ),

          // Status Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xxs,
            ),
            child: Row(
              children: [
                _buildStatusChip('TẤT CẢ', 'ALL'),
                const SizedBox(width: AppSpacing.xs),
                _buildStatusChip('PAID', 'paid'),
                const SizedBox(width: AppSpacing.xs),
                _buildStatusChip('USED', 'used'),
                const SizedBox(width: AppSpacing.xs),
                _buildStatusChip('CANCELLED', 'cancelled'),
                const SizedBox(width: AppSpacing.xs),
                _buildStatusChip('EXPIRED', 'expired'),
              ],
            ),
          ),

          // Channel Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xxs,
            ),
            child: Row(
              children: [
                Text(
                  'KÊNH: ',
                  style: AppTextStyles.captionUppercase.copyWith(color: AppColors.muted),
                ),
                _buildChannelChip('TẤT CẢ', 'ALL'),
                const SizedBox(width: AppSpacing.xs),
                _buildChannelChip('ONLINE', 'online'),
                const SizedBox(width: AppSpacing.xs),
                _buildChannelChip('QUẦY POS', 'counter'),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          // Bookings List
          Expanded(
            child: _buildBody(context, provider),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, String value) {
    final isSelected = _selectedStatus == value;
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
      onSelected: (_) {
        setState(() => _selectedStatus = value);
        _loadBookings();
      },
    );
  }

  Widget _buildChannelChip(String label, String value) {
    final isSelected = _selectedChannel == value;
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
      onSelected: (_) {
        setState(() => _selectedChannel = value);
        _loadBookings();
      },
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
          onRetry: () => _loadBookings(),
        ),
      );
    }

    if (provider.bookings.isEmpty) {
      return const Center(
        child: EmptyState(
          title: 'KHÔNG CÓ ĐƠN VÉ',
          message: 'Không tìm thấy đơn vé nào',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadBookings(),
      color: AppColors.primary,
      backgroundColor: AppColors.canvasElevated,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: provider.bookings.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final booking = provider.bookings[index];
          return _buildBookingCard(context, booking);
        },
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, BookingModel booking) {
    return InkWell(
      onTap: () => _openBookingDetailModal(context, booking),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.canvasElevated,
          borderRadius: AppRadius.zeroRadius,
          border: Border.all(color: AppColors.hairline, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '#${booking.code.toUpperCase()}',
                  style: AppTextStyles.titleSm.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                AppBadge(
                  label: booking.channel == 'counter' ? 'QUẦY' : 'ONLINE',
                  backgroundColor: booking.channel == 'counter' ? AppColors.warning : AppColors.info,
                ),
                const Spacer(),
                StatusBadge(status: booking.displayStatus),
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),

            Text(
              booking.movieTitle,
              style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xxxs),

            Text(
              '${booking.cinemaName} · ${booking.roomName} · ${booking.format}',
              style: AppTextStyles.caption.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.xxs),

            Row(
              children: [
                Expanded(
                  child: Text(
                    'Suất: ${DateFormatter.formatDateTime(booking.showtimeStart)}',
                    style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                  ),
                ),
                Text(
                  CurrencyFormatter.format(booking.totalAmount),
                  style: AppTextStyles.titleSm.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (booking.seatNamesSummary.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xxxs),
              Text(
                'Ghế: ${booking.seatNamesSummary}',
                style: AppTextStyles.caption.copyWith(color: AppColors.muted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BookingDetailSheet extends StatelessWidget {
  final BookingModel booking;

  const _BookingDetailSheet({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'ĐƠN VÉ #${booking.code.toUpperCase()}'.toUpperCase(),
                    style: AppTextStyles.titleSm.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                StatusBadge(status: booking.displayStatus),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            _buildSection(
              title: 'THÔNG TIN KHÁCH & KÊNH',
              items: [
                {'label': 'Kênh đặt vé', 'value': booking.channel == 'counter' ? 'Bán tại quầy' : 'Ứng dụng Online'},
                {'label': 'User ID', 'value': booking.userId ?? 'Khách vãng lai tại quầy'},
                if (booking.soldBy != null) {'label': 'Nhân viên bán', 'value': booking.soldBy!},
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            _buildSection(
              title: 'PHIM & SUẤT CHIẾU',
              items: [
                {'label': 'Phim', 'value': booking.movieTitle},
                {'label': 'Rạp chiếu', 'value': booking.cinemaName},
                {'label': 'Phòng / Định dạng', 'value': '${booking.roomName} · ${booking.format}'},
                {'label': 'Giờ chiếu', 'value': DateFormatter.formatDateTime(booking.showtimeStart)},
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            _buildSection(
              title: 'DANH SÁCH GHẾ (${booking.seats.length})',
              items: [
                {'label': 'Mã ghế', 'value': booking.seatNamesSummary.isNotEmpty ? booking.seatNamesSummary : 'Không có ghế'},
              ],
            ),

            if (booking.foods.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              _buildSection(
                title: 'BẮP NƯỚC & ĐỒ ĂN KÈM',
                items: [
                  {'label': 'Món ăn', 'value': booking.foodSummary},
                  {'label': 'Trạng thái giao', 'value': booking.foodStatus.toUpperCase()},
                ],
              ),
            ],

            const SizedBox(height: AppSpacing.sm),
            _buildSection(
              title: 'CHI TIẾT THANH TOÁN',
              items: [
                {'label': 'Tiền vé', 'value': CurrencyFormatter.format(booking.ticketTotal)},
                {'label': 'Tiền đồ ăn', 'value': CurrencyFormatter.format(booking.foodTotal)},
                {'label': 'Giảm giá', 'value': '- ${CurrencyFormatter.format(booking.discount)}'},
                {'label': 'Tổng thanh toán', 'value': CurrencyFormatter.format(booking.totalAmount)},
                {'label': 'Phương thức', 'value': booking.paymentMethod?.toUpperCase() ?? 'SEPAY'},
                if (booking.transactionNo != null) {'label': 'Mã SePay', 'value': booking.transactionNo!},
                if (booking.paidAt != null) {'label': 'Thời gian TT', 'value': DateFormatter.formatDateTime(booking.paidAt!)},
              ],
            ),

            if (booking.checkedInAt != null || booking.cancelReason != null) ...[
              const SizedBox(height: AppSpacing.sm),
              _buildSection(
                title: 'KIỂM TOÁN / SOÁT VÉ',
                items: [
                  if (booking.checkedInAt != null)
                    {'label': 'Soát vé lúc', 'value': DateFormatter.formatDateTime(booking.checkedInAt!)},
                  if (booking.checkedInBy != null)
                    {'label': 'Người soát vé', 'value': booking.checkedInBy!},
                  if (booking.cancelReason != null)
                    {'label': 'Lý do hủy', 'value': booking.cancelReason!},
                ],
              ),
            ],

            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.canvasElevated,
                shape: const RoundedRectangleBorder(borderRadius: AppRadius.zeroRadius),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(
                'ĐÓNG'.toUpperCase(),
                style: AppTextStyles.button.copyWith(color: AppColors.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required List<Map<String, String>> items}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTextStyles.captionUppercase.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          ...items.map((it) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    it['label']!,
                    style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                  ),
                ),
                Expanded(
                  child: Text(
                    it['value']!,
                    style: AppTextStyles.bodyMd.copyWith(color: AppColors.ink),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
