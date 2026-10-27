import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../../../shared/widgets/customer_bottom_nav.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/notification_badge.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../booking/data/models/booking_model.dart';
import '../controllers/ticket_provider.dart';

/// Screen S10: My Tickets (Tabbed: SẮP TỚI, ĐÃ XEM, ĐÃ HỦY).
/// References: ROLE_FLOWS.md Section 1.10, DESIGN_TOKENS.md Section 7.12
class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TicketProvider>().loadMyTickets();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ticketProvider = context.watch<TicketProvider>();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        title: Text(
          'VÉ CỦA TÔI'.toUpperCase(),
          style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
        ),
        actions: [
          NotificationBadge(
            unreadCount: 0,
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.notifications);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2.0,
          labelColor: AppColors.ink,
          unselectedLabelColor: AppColors.muted,
          labelStyle: AppTextStyles.button.copyWith(fontSize: 12),
          unselectedLabelStyle: AppTextStyles.button.copyWith(fontSize: 12),
          tabs: const [
            Tab(text: 'SẮP TỚI'),
            Tab(text: 'ĐÃ XEM'),
            Tab(text: 'ĐÃ HỦY'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTicketList(
            context,
            ticketProvider: ticketProvider,
            tickets: ticketProvider.upcomingTickets,
            emptyMessage: 'Bạn chưa có vé sắp chiếu nào',
          ),
          _buildTicketList(
            context,
            ticketProvider: ticketProvider,
            tickets: ticketProvider.historyTickets,
            emptyMessage: 'Chưa có lịch sử vé đã xem',
          ),
          _buildTicketList(
            context,
            ticketProvider: ticketProvider,
            tickets: ticketProvider.cancelledTickets,
            emptyMessage: 'Chưa có vé nào bị hủy',
          ),
        ],
      ),
      bottomNavigationBar: const CustomerBottomNav(currentIndex: 2),
    );
  }

  Widget _buildTicketList(
    BuildContext context, {
    required TicketProvider ticketProvider,
    required List<BookingModel> tickets,
    required String emptyMessage,
  }) {
    if (ticketProvider.isLoading) {
      return ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, __) => const SkeletonBox(
          width: double.infinity,
          height: 120,
        ),
      );
    }

    if (ticketProvider.errorMessage != null) {
      return Center(
        child: ErrorState(
          message: ticketProvider.errorMessage!,
          onRetry: () => ticketProvider.loadMyTickets(),
        ),
      );
    }

    if (tickets.isEmpty) {
      return Center(
        child: EmptyState(
          title: 'VÉ CỦA TÔI',
          message: emptyMessage,
          actionLabel: 'ĐẶT VÉ NGAY',
          onAction: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.home,
              (route) => false,
            );
          },
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ticketProvider.loadMyTickets(),
      color: AppColors.primary,
      backgroundColor: AppColors.canvasElevated,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: tickets.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final ticket = tickets[index];
          return _buildTicketCard(context, ticket);
        },
      ),
    );
  }

  Widget _buildTicketCard(BuildContext context, BookingModel ticket) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.ticketDetail,
          arguments: ticket,
        );
      },
      borderRadius: AppRadius.zeroRadius,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.canvasElevated,
          borderRadius: AppRadius.zeroRadius,
          border: Border.all(color: AppColors.hairline, width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Movie Poster Thumbnail
            ClipRRect(
              borderRadius: AppRadius.zeroRadius,
              child: Container(
                width: 72,
                height: 104,
                color: AppColors.canvasElevated,
                child: ticket.posterUrl != null && ticket.posterUrl!.isNotEmpty
                    ? Image.network(
                        ticket.posterUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.movie, color: AppColors.muted, size: 28),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.movie, color: AppColors.muted, size: 28),
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Ticket Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ticket.movieTitle,
                          style: AppTextStyles.titleSm.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      StatusBadge(status: ticket.displayStatus),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),

                  // Badges
                  Row(
                    children: [
                      AppBadge.age(ticket.ageRating ?? 'P'),
                      const SizedBox(width: AppSpacing.xxs),
                      AppBadge.format(ticket.format),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '#${ticket.code.toUpperCase()}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),

                  // Cinema & Room
                  Text(
                    '${ticket.cinemaName} · ${ticket.roomName}',
                    style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xxxs),

                  // Showtime
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 12, color: AppColors.muted),
                      const SizedBox(width: AppSpacing.xxs),
                      Text(
                        DateFormatter.formatDateTime(ticket.showtimeStart),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxxs),

                  // Seat summary
                  Row(
                    children: [
                      const Icon(Icons.event_seat, size: 12, color: AppColors.muted),
                      const SizedBox(width: AppSpacing.xxs),
                      Expanded(
                        child: Text(
                          'Ghế: ${ticket.seatNamesSummary}',
                          style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
