import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/customer_bottom_nav.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../data/cinema_model.dart';
import '../../data/location_service.dart';
import '../controllers/cinema_provider.dart';
import '../widgets/maps_web_guard.dart';

/// S17 Cinema Locator Screen.
/// References: ROLE_FLOWS.md Section 1, DESIGN_TOKENS.md, m2_plan.md Section 2.5
class CinemaMapScreen extends StatefulWidget {
  const CinemaMapScreen({super.key});

  @override
  State<CinemaMapScreen> createState() => _CinemaMapScreenState();
}

class _CinemaMapScreenState extends State<CinemaMapScreen> {
  GoogleMapController? _mapController;
  static const LatLng _defaultCenter = LatLng(10.7769, 106.7009); // TP. Hồ Chí Minh

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CinemaProvider>();
      if (provider.cinemas.isEmpty) {
        provider.loadCinemas();
      }
    });
  }

  Future<void> _centerUserLocation() async {
    final position = await LocationService.getCurrentPosition();
    if (position != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          14,
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể lấy vị trí hiện tại. Vui lòng cấp quyền vị trí.'),
          backgroundColor: AppColors.canvasElevated,
        ),
      );
    }
  }

  void _centerCinema(CinemaModel cinema) {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(cinema.lat, cinema.lng),
          15,
        ),
      );
    }
  }

  void _findNearestCinema(List<CinemaModel> cinemas) {
    if (cinemas.isEmpty) return;
    CinemaModel? nearest;
    for (final c in cinemas) {
      if (c.distanceKm != null) {
        if (nearest == null || (nearest.distanceKm ?? 999999) > c.distanceKm!) {
          nearest = c;
        }
      }
    }
    final target = nearest ?? cinemas.first;
    context.read<CinemaProvider>().selectCinema(target);
    _centerCinema(target);
  }

  Future<void> _openDirections(CinemaModel cinema) async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=${cinema.lat},${cinema.lng}';
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

  @override
  Widget build(BuildContext context) {
    final cinemaProvider = context.watch<CinemaProvider>();
    final cinemas = cinemaProvider.cinemas;

    final markers = cinemas.map((cinema) {
      return Marker(
        markerId: MarkerId(cinema.id),
        position: LatLng(cinema.lat, cinema.lng),
        infoWindow: InfoWindow(
          title: cinema.name,
          snippet: '${cinema.address} • Nhấn để chỉ đường',
          onTap: () => _openDirections(cinema),
        ),
        onTap: () {
          cinemaProvider.selectCinema(cinema);
          _centerCinema(cinema);
        },
      );
    }).toSet();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        title: Text(
          'CỤM RẠP',
          style: AppTextStyles.titleSm.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            key: const Key('cinema_my_location_button'),
            icon: const Icon(Icons.my_location, color: AppColors.ink),
            onPressed: _centerUserLocation,
          ),
        ],
      ),
      bottomNavigationBar: const CustomerBottomNav(currentIndex: 1),
      body: Stack(
        children: [
          // Google Map Background or Fallback Interactive Canvas
          if (isGoogleMapsReady())
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: cinemaProvider.selectedCinema != null
                    ? LatLng(
                        cinemaProvider.selectedCinema!.lat,
                        cinemaProvider.selectedCinema!.lng,
                      )
                    : _defaultCenter,
                zoom: 12,
              ),
              markers: markers,
              onMapCreated: (controller) => _mapController = controller,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
            )
          else
            _buildInteractiveMapCanvas(cinemas, cinemaProvider),

          // Draggable Bottom Sheet with Cinema List
          DraggableScrollableSheet(
            initialChildSize: 0.35,
            minChildSize: 0.15,
            maxChildSize: 0.85,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: AppColors.canvasElevated,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Column(
                  children: [
                    // Drag Handle Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: AppColors.muted,
                          borderRadius: AppRadius.fullRadius,
                        ),
                      ),
                    ),

                    // Sheet Header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: AppSpacing.xxs,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'DANH SÁCH RẠP (${cinemas.length})',
                            style: AppTextStyles.titleSm.copyWith(
                              color: AppColors.ink,
                            ),
                          ),
                          AppButton.outline(
                            key: const Key('find_nearest_cinema_button'),
                            label: 'RẠP GẦN NHẤT',
                            onPressed: () => _findNearestCinema(cinemas),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: AppColors.hairline, height: 1),

                    // Sheet Body
                    Expanded(
                      child: _buildSheetContent(
                        context,
                        cinemaProvider,
                        scrollController,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSheetContent(
    BuildContext context,
    CinemaProvider cinemaProvider,
    ScrollController scrollController,
  ) {
    if (cinemaProvider.isLoading) {
      return ListView.separated(
        controller: scrollController,
        padding: const EdgeInsets.all(AppSpacing.xs),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
        itemBuilder: (_, __) => const SkeletonBox(
          width: double.infinity,
          height: 72,
        ),
      );
    }

    if (cinemaProvider.errorMessage != null) {
      return SingleChildScrollView(
        controller: scrollController,
        child: ErrorState(
          message: cinemaProvider.errorMessage!,
          onRetry: () => cinemaProvider.loadCinemas(),
        ),
      );
    }

    final cinemas = cinemaProvider.cinemas;
    if (cinemas.isEmpty) {
      return SingleChildScrollView(
        controller: scrollController,
        child: const EmptyState(
          icon: Icons.place_outlined,
          title: 'Không tìm thấy rạp chiếu',
          message: 'Hiện tại chưa có cụm rạp nào hoạt động trong khu vực.',
        ),
      );
    }

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      itemCount: cinemas.length,
      separatorBuilder: (_, __) => const Divider(
        color: AppColors.hairline,
        height: 1,
      ),
      itemBuilder: (context, index) {
        final cinema = cinemas[index];
        final isSelected = cinemaProvider.selectedCinema?.id == cinema.id;

        return InkWell(
          key: Key('cinema_list_tile_${cinema.id}'),
          onTap: () {
            cinemaProvider.selectCinema(cinema);
            _centerCinema(cinema);
            Navigator.pushNamed(
              context,
              AppRoutes.cinemaDetail,
              arguments: cinema,
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            color: isSelected ? AppColors.canvas : Colors.transparent,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.movie_filter_outlined,
                  color: isSelected ? AppColors.primary : AppColors.muted,
                  size: 28,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              cinema.name,
                              style: AppTextStyles.titleSm.copyWith(
                                color: isSelected ? AppColors.primary : AppColors.ink,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (cinema.distanceKm != null)
                            AppBadge(
                              label: '${cinema.distanceKm} KM',
                              backgroundColor: AppColors.canvas,
                              textColor: AppColors.muted,
                            ),
                          IconButton(
                            icon: const Icon(
                              Icons.directions_outlined,
                              color: AppColors.primary,
                              size: 22,
                            ),
                            tooltip: 'Chỉ đường',
                            onPressed: () => _openDirections(cinema),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxxs),
                      Text(
                        cinema.address,
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.muted,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInteractiveMapCanvas(
    List<CinemaModel> cinemas,
    CinemaProvider cinemaProvider,
  ) {
    final selected = cinemaProvider.selectedCinema;

    return Container(
      color: AppColors.canvas,
      child: Stack(
        children: [
          // Background stylized map grid
          Positioned.fill(
            child: CustomPaint(
              painter: _MapGridPainter(),
            ),
          ),

          // Header badge
          Positioned(
            top: AppSpacing.sm,
            left: AppSpacing.xs,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxs,
                vertical: AppSpacing.xxxs,
              ),
              decoration: const BoxDecoration(
                color: AppColors.canvasElevated,
                borderRadius: AppRadius.fullRadius,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, size: 14, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.xxxs),
                  Text(
                    'TP. HỒ CHÍ MINH · ${cinemas.length} CỤM RẠP',
                    style: AppTextStyles.captionUppercase.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Interactive pins for cinemas
          ...cinemas.asMap().entries.map((entry) {
            final idx = entry.key;
            final cinema = entry.value;
            final isSelected = selected?.id == cinema.id;

            final double topFraction = idx == 0 ? 0.22 : 0.38;
            final double leftFraction = idx == 0 ? 0.32 : 0.62;

            return Positioned(
              top: MediaQuery.of(context).size.height * topFraction,
              left: MediaQuery.of(context).size.width * leftFraction - 60,
              child: GestureDetector(
                onTap: () {
                  cinemaProvider.selectCinema(cinema);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xxs,
                        vertical: AppSpacing.xxxs,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.canvasElevated,
                        borderRadius: AppRadius.xsRadius,
                        border: Border.all(
                          color: isSelected ? AppColors.ink : AppColors.hairline,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        cinema.name.toUpperCase(),
                        style: AppTextStyles.captionUppercase.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Icon(
                      Icons.location_on,
                      size: isSelected ? 36 : 28,
                      color: isSelected ? AppColors.primary : AppColors.muted,
                    ),
                    if (isSelected) ...[
                      const SizedBox(height: AppSpacing.xxxs),
                      InkWell(
                        onTap: () => _openDirections(cinema),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xxs,
                            vertical: AppSpacing.xxxs,
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.canvasElevated,
                            borderRadius: AppRadius.xsRadius,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.directions_outlined,
                                size: 14,
                                color: AppColors.ink,
                              ),
                              const SizedBox(width: AppSpacing.xxxs),
                              Text(
                                'CHỈ ĐƯỜNG',
                                style: AppTextStyles.captionUppercase.copyWith(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );

          }),
        ],
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.hairline
      ..strokeWidth = 1.0;

    const double step = 64.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final roadPaint = Paint()
      ..color = AppColors.canvasElevated
      ..strokeWidth = 16.0
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, size.height * 0.35)
      ..cubicTo(
        size.width * 0.3,
        size.height * 0.45,
        size.width * 0.6,
        size.height * 0.25,
        size.width,
        size.height * 0.5,
      );
    canvas.drawPath(path, roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

