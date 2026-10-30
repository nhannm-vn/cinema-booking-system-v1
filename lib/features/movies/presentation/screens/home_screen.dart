import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/customer_bottom_nav.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/movie_card.dart';
import '../../../../shared/widgets/notification_badge.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../auth/presentation/controllers/auth_provider.dart';
import '../../../notifications/presentation/controllers/notification_provider.dart';
import '../../data/movie_model.dart';
import '../controllers/movie_provider.dart';

/// S03 Home / Discovery Screen.
/// References: ROLE_FLOWS.md Section 1, DESIGN_TOKENS.md, m2_plan.md Section 2.3
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  final _pageController = PageController();
  int _currentCarouselPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final movieProvider = context.read<MovieProvider>();
      if (movieProvider.nowShowing.isEmpty && movieProvider.upcoming.isEmpty) {
        movieProvider.loadMovies();
      }
      final notifProvider = context.read<NotificationProvider>();
      notifProvider.loadNotifications();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onNotificationTap(BuildContext context) {
    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated) {
      Navigator.pushNamed(context, AppRoutes.notifications);
    } else {
      Navigator.pushNamed(
        context,
        AppRoutes.login,
        arguments: {'redirectRoute': AppRoutes.notifications},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final movieProvider = context.watch<MovieProvider>();
    final notifProvider = context.watch<NotificationProvider>();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CINEMA STAR',
              style: AppTextStyles.titleMd.copyWith(
                color: AppColors.primary,
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(
              height: 0,
              width: 0,
              child: Text(
                'CINEMA BOOKING APP',
                style: AppTextStyles.caption,
              ),
            ),
          ],
        ),
        actions: [
          NotificationBadge(
            unreadCount: notifProvider.unreadCount,
            onTap: () => _onNotificationTap(context),
          ),
        ],
      ),
      bottomNavigationBar: const CustomerBottomNav(currentIndex: 0),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.canvasElevated,
          onRefresh: () => movieProvider.loadMovies(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Search Field
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: AppTextField(
                    key: const Key('home_search_field'),
                    controller: _searchController,
                    hintText: 'Tìm phim theo tên...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.muted,
                      size: 20,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: AppColors.muted,
                              size: 18,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              movieProvider.clearSearch();
                            },
                          )
                        : null,
                    onChanged: (val) {
                      movieProvider.search(val);
                    },
                  ),
                ),

                // Content Area based on 3 States
                _buildContent(context, movieProvider),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, MovieProvider movieProvider) {
    if (movieProvider.isLoading) {
      return _buildLoadingSkeleton();
    }

    if (movieProvider.errorMessage != null) {
      return ErrorState(
        message: movieProvider.errorMessage!,
        onRetry: () => movieProvider.loadMovies(),
      );
    }

    // Search Mode
    if (movieProvider.searchQuery.trim().isNotEmpty) {
      final results = movieProvider.searchResults;
      if (results.isEmpty) {
        return const EmptyState(
          icon: Icons.search_off_outlined,
          title: 'Không tìm thấy phim phù hợp',
          message: 'Vui lòng thử tìm kiếm với tên phim khác.',
        );
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
              child: Text(
                'KẾT QUẢ TÌM KIẾM (${results.length})',
                style: AppTextStyles.captionUppercase.copyWith(
                  color: AppColors.muted,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final crossAxisCount = width > 1100
                    ? 5
                    : width > 800
                        ? 4
                        : width > 550
                            ? 3
                            : 2;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 0.58,
                    crossAxisSpacing: AppSpacing.xs,
                    mainAxisSpacing: AppSpacing.sm,
                  ),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final movie = results[index];
                    return MovieCard(
                      key: Key('movie_card_${movie.id}'),
                      title: movie.title,
                      posterUrl: movie.posterUrl,
                      ageRating: movie.ageRating,
                      genres: movie.genres.join(', '),
                      durationMin: movie.durationMin,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.movieDetail,
                          arguments: movie,
                        );
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      );
    }

    // Normal Discovery Mode
    final nowShowing = movieProvider.nowShowing;
    final upcoming = movieProvider.upcoming;

    if (nowShowing.isEmpty && upcoming.isEmpty) {
      return const EmptyState(
        icon: Icons.movie_outlined,
        title: 'Chưa có phim chiếu',
        message: 'Hiện tại hệ thống chưa cập nhật danh sách phim.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Hero Carousel (<= 5 movies)
        if (nowShowing.isNotEmpty) _buildHeroCarousel(context, nowShowing),

        const SizedBox(height: AppSpacing.md),

        // Now Showing Grid Section
        if (nowShowing.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Text(
              'ĐANG CHIẾU',
              style: AppTextStyles.captionUppercase.copyWith(
                color: AppColors.ink,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final crossAxisCount = width > 1100
                    ? 5
                    : width > 800
                        ? 4
                        : width > 550
                            ? 3
                            : 2;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 0.58,
                    crossAxisSpacing: AppSpacing.xs,
                    mainAxisSpacing: AppSpacing.sm,
                  ),
                  itemCount: nowShowing.length,
                  itemBuilder: (context, index) {
                    final movie = nowShowing[index];
                    return MovieCard(
                      key: Key('now_showing_card_${movie.id}'),
                      title: movie.title,
                      posterUrl: movie.posterUrl,
                      ageRating: movie.ageRating,
                      genres: movie.genres.join(', '),
                      durationMin: movie.durationMin,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.movieDetail,
                          arguments: movie,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.md),

        // Upcoming Horizontal List Section
        if (upcoming.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Text(
              'SẮP CHIẾU',
              style: AppTextStyles.captionUppercase.copyWith(
                color: AppColors.ink,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            height: 280,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              scrollDirection: Axis.horizontal,
              itemCount: upcoming.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
              itemBuilder: (context, index) {
                final movie = upcoming[index];
                return SizedBox(
                  width: 140,
                  child: MovieCard(
                    key: Key('upcoming_card_${movie.id}'),
                    title: movie.title,
                    posterUrl: movie.posterUrl,
                    ageRating: movie.ageRating,
                    genres: movie.genres.join(', '),
                    durationMin: movie.durationMin,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.movieDetail,
                        arguments: movie,
                      );
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ],
    );
  }

  Widget _buildHeroCarousel(BuildContext context, List<MovieModel> movies) {
    final heroList = movies.take(5).toList();

    return Column(
      children: [
        SizedBox(
          height: 380,
          child: PageView.builder(
            controller: _pageController,
            itemCount: heroList.length,
            onPageChanged: (page) {
              setState(() {
                _currentCarouselPage = page;
              });
            },
            itemBuilder: (context, index) {
              final movie = heroList[index];
              final imageUrl = movie.backdropUrl ?? movie.posterUrl;

              return Stack(
                fit: StackFit.expand,
                children: [
                  // Full-width Image
                  AppNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    fallbackIcon: Icons.movie_outlined,
                    iconSize: 48,
                  ),

                  // Bottom Gradient Fade to canvas
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppColors.canvas,
                          ],
                          stops: [0.3, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Overlay Content
                  Positioned(
                    bottom: AppSpacing.xs,
                    left: AppSpacing.xs,
                    right: AppSpacing.xs,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            AppBadge.age(movie.ageRating),
                            const SizedBox(width: AppSpacing.xxs),
                            Expanded(
                              child: Text(
                                '${movie.genresText} · ${movie.durationMin} phút',
                                style: AppTextStyles.bodySm.copyWith(
                                  color: AppColors.muted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xxxs),
                        Text(
                          movie.title,
                          style: AppTextStyles.displayLg.copyWith(
                            color: AppColors.ink,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        AppButton.primary(
                          key: Key('hero_book_button_${movie.id}'),
                          label: 'ĐẶT VÉ',
                          width: double.infinity,
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.movieDetail,
                              arguments: movie,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // Carousel Indicators
        if (heroList.length > 1) ...[
          const SizedBox(height: AppSpacing.xxs),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(heroList.length, (index) {
              final isSelected = index == _currentCarouselPage;
              return Container(
                width: isSelected ? 16 : 6,
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.hairline,
                  borderRadius: AppRadius.fullRadius,
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildLoadingSkeleton() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Carousel Shimmer
        SkeletonBox(
          width: double.infinity,
          height: 340,
        ),
        SizedBox(height: AppSpacing.md),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 120, height: 16),
              SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: SkeletonBox(height: 220),
                  ),
                  SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: SkeletonBox(height: 220),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
