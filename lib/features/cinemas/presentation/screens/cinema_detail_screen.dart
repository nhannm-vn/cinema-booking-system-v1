import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../data/cinema_model.dart';
import '../../data/cinema_repository.dart';

/// S17B Cinema Detail Screen.
/// References: ROLE_FLOWS.md Section 1, DESIGN_TOKENS.md, m2_plan.md Section 2.6
class CinemaDetailScreen extends StatefulWidget {
  final CinemaModel? cinema;
  final String? cinemaId;

  const CinemaDetailScreen({
    super.key,
    this.cinema,
    this.cinemaId,
  });

  @override
  State<CinemaDetailScreen> createState() => _CinemaDetailScreenState();
}

class _CinemaDetailScreenState extends State<CinemaDetailScreen> {
  late CinemaModel? _cinema;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cinema = widget.cinema;
    if (_cinema == null && widget.cinemaId != null) {
      _fetchCinema(widget.cinemaId!);
    }
  }

  Future<void> _fetchCinema(String id) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = CinemaRepository();
      final fetched = await repo.getCinemaById(id);
      if (!mounted) return;

      if (fetched != null) {
        setState(() {
          _cinema = fetched;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Không tìm thấy thông tin rạp.';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Không thể tải thông tin rạp. Vui lòng thử lại.';
        _isLoading = false;
      });
    }
  }

  Future<void> _openMapDirections(CinemaModel cinema) async {
    final destination = Uri.encodeComponent('${cinema.name}, ${cinema.address}');
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=$destination';
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể mở bản đồ chỉ đường.'),
          backgroundColor: AppColors.canvasElevated,
        ),
      );
    }
  }

  void _viewShowtimes(CinemaModel cinema) {
    Navigator.pushNamed(
      context,
      AppRoutes.showtimes,
      arguments: {
        'cinemaId': cinema.id,
        'cinemaName': cinema.name,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SkeletonBox(width: double.infinity, height: 180),
                SizedBox(height: AppSpacing.sm),
                SkeletonBox(width: 200, height: 28),
                SizedBox(height: AppSpacing.xs),
                SkeletonBox(width: double.infinity, height: 60),
                SizedBox(height: AppSpacing.xs),
                SkeletonBox(width: double.infinity, height: 60),
              ],
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null || _cinema == null) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(
          backgroundColor: AppColors.canvas,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.ink),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: ErrorState(
          message: _errorMessage ?? 'Không tìm thấy thông tin rạp.',
          onRetry: widget.cinemaId != null ? () => _fetchCinema(widget.cinemaId!) : null,
        ),
      );
    }

    final cinema = _cinema!;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          cinema.name,
          style: AppTextStyles.titleSm.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cinema Banner
              SizedBox(
                height: 180,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const AppNetworkImage(
                      imageUrl: 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=1200',
                      fit: BoxFit.cover,
                      fallbackIcon: Icons.theater_comedy_outlined,
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.3),
                            AppColors.canvas.withValues(alpha: 0.85),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: AppSpacing.xs,
                      left: AppSpacing.xs,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                              vertical: AppSpacing.xxxs,
                            ),
                            color: AppColors.primary,
                            child: Text(
                              'CINEMA',
                              style: AppTextStyles.captionUppercase.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xxs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                              vertical: AppSpacing.xxxs,
                            ),
                            color: AppColors.canvasElevated,
                            child: Text(
                              cinema.isActive ? 'ĐANG HOẠT ĐỘNG' : 'TẠM NGHỈ',
                              style: AppTextStyles.captionUppercase.copyWith(
                                color: cinema.isActive ? AppColors.success : AppColors.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Cinema Name
              Text(
                cinema.name,
                style: AppTextStyles.displayLg.copyWith(
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),

              // Distance Pill
              if (cinema.distanceKm != null) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppBadge(
                    label: '${cinema.distanceKm} KM TỪ VỊ TRÍ CỦA BẠN',
                    backgroundColor: AppColors.canvasElevated,
                    textColor: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],

              // Address Tile
              _buildDetailTile(
                icon: Icons.location_on_outlined,
                label: 'ĐỊA CHỈ',
                value: cinema.address,
              ),
              const SizedBox(height: AppSpacing.xs),

              // Hotline Tile
              _buildDetailTile(
                icon: Icons.phone_outlined,
                label: 'HOTLINE',
                value: cinema.phone ?? '1900 6017',
              ),
              const SizedBox(height: AppSpacing.xs),

              // Opening Hours Tile
              _buildDetailTile(
                icon: Icons.access_time_outlined,
                label: 'GIỜ MỞ CỬA',
                value: cinema.openingHours ?? '08:00 - 24:00 (Hàng ngày)',
              ),
              const SizedBox(height: AppSpacing.md),

              // Directions Action (Outline Button)
              AppButton.outline(
                key: const Key('cinema_directions_button'),
                label: 'CHỈ ĐƯỜNG',
                icon: const Icon(
                  Icons.directions_outlined,
                  color: AppColors.ink,
                  size: 20,
                ),
                width: double.infinity,
                onPressed: () => _openMapDirections(cinema),
              ),
              const SizedBox(height: AppSpacing.xs),

              // View Showtimes CTA (Max 1 primary CTA per screen)
              AppButton.primary(
                key: const Key('cinema_view_showtimes_cta'),
                label: 'XEM SUẤT CHIẾU HÔM NAY',
                width: double.infinity,
                onPressed: () => _viewShowtimes(cinema),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: const BoxDecoration(
        color: AppColors.canvasElevated,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.muted, size: 22),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: AppTextStyles.captionUppercase.copyWith(
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxs),
                Text(
                  value,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
