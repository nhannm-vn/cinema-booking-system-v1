import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
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
          snippet: cinema.address,
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
          // Google Map Background
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
          ),

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
}
