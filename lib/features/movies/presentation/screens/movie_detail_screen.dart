import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../../shared/widgets/spec_cell.dart';
import '../../data/movie_model.dart';
import '../../data/movie_repository.dart';

/// S04 Movie Detail Screen.
/// References: ROLE_FLOWS.md Section 1, DESIGN_TOKENS.md, m2_plan.md Section 2.4
class MovieDetailScreen extends StatefulWidget {
  final MovieModel? movie;
  final String? movieId;

  const MovieDetailScreen({
    super.key,
    this.movie,
    this.movieId,
  });

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  late MovieModel? _movie;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _movie = widget.movie;
    if (_movie == null && widget.movieId != null) {
      _fetchMovie(widget.movieId!);
    }
  }

  Future<void> _fetchMovie(String id) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = MovieRepository();
      final fetched = await repo.getMovieById(id);
      if (!mounted) return;

      if (fetched != null) {
        setState(() {
          _movie = fetched;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Không tìm thấy thông tin phim.';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Không thể tải thông tin phim. Vui lòng thử lại.';
        _isLoading = false;
      });
    }
  }

  Future<void> _launchTrailer(String? trailerUrl) async {
    if (trailerUrl == null || trailerUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phim chưa có trailer.'),
          backgroundColor: AppColors.canvasElevated,
        ),
      );
      return;
    }

    final uri = Uri.tryParse(trailerUrl.trim());
    if (uri != null) {
      final canLaunch = await canLaunchUrl(uri);
      if (canLaunch) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Không thể mở trailer. Vui lòng kiểm tra lại liên kết.'),
        backgroundColor: AppColors.canvasElevated,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SkeletonBox(width: double.infinity, height: 260),
              SizedBox(height: AppSpacing.md),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Column(
                  children: [
                    SkeletonBox(width: double.infinity, height: 32),
                    SizedBox(height: AppSpacing.xs),
                    SkeletonBox(width: double.infinity, height: 72),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null || _movie == null) {
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
          message: _errorMessage ?? 'Không tìm thấy thông tin phim.',
          onRetry: widget.movieId != null ? () => _fetchMovie(widget.movieId!) : null,
        ),
      );
    }

    final movie = _movie!;
    final backdrop = movie.backdropUrl ?? movie.posterUrl;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Stack(
        children: [
          // Scrollable Content
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Full-bleed Backdrop
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppNetworkImage(
                        imageUrl: backdrop,
                        fit: BoxFit.cover,
                        fallbackIcon: Icons.movie_outlined,
                        iconSize: 48,
                      ),

                      // Gradient Bottom Fade to canvas
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
                              stops: [0.4, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Details
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Age Badge & Genres
                      Row(
                        children: [
                          AppBadge.age(movie.ageRating),
                          const SizedBox(width: AppSpacing.xxs),
                          Expanded(
                            child: Text(
                              movie.genresText,
                              style: AppTextStyles.bodySm.copyWith(
                                color: AppColors.muted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxs),

                      // Title
                      Text(
                        movie.title,
                        style: AppTextStyles.displayMega.copyWith(
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // SpecCell Container (Duration, Age rating, First Genre/Format)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                          horizontal: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.canvasElevated,
                          border: Border.all(
                            color: AppColors.hairline,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: SpecCell(
                                value: '${movie.durationMin}',
                                label: 'PHÚT',
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 36,
                              color: AppColors.hairline,
                            ),
                            Expanded(
                              child: SpecCell(
                                value: movie.ageRating,
                                label: 'ĐỘ TUỔI',
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 36,
                              color: AppColors.hairline,
                            ),
                            Expanded(
                              child: SpecCell(
                                value: movie.genres.isNotEmpty ? movie.genres.first : '2D',
                                label: 'THỂ LOẠI',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Trailer CTA (Outline Button)
                      AppButton.outline(
                        key: const Key('movie_detail_trailer_button'),
                        label: 'XEM TRAILER',
                        icon: const Icon(
                          Icons.play_arrow_outlined,
                          color: AppColors.ink,
                          size: 20,
                        ),
                        width: double.infinity,
                        onPressed: () => _launchTrailer(movie.trailerUrl),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Synopsis Section
                      Text(
                        'TÓM TẮT NỘI DUNG',
                        style: AppTextStyles.captionUppercase.copyWith(
                          color: AppColors.muted,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        movie.description ?? 'Nội dung đang được cập nhật.',
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.body,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Crew Metadata
                      Text(
                        'ĐẠO DIỄN',
                        style: AppTextStyles.captionUppercase.copyWith(
                          color: AppColors.muted,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxxs),
                      Text(
                        movie.director ?? 'Đang cập nhật',
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),

                      Text(
                        'DIỄN VIÊN',
                        style: AppTextStyles.captionUppercase.copyWith(
                          color: AppColors.muted,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxxs),
                      Text(
                        movie.castMembers.isNotEmpty
                            ? movie.castMembers.join(', ')
                            : 'Đang cập nhật',
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),

                      Text(
                        'NGÀY KHỞI CHIẾU',
                        style: AppTextStyles.captionUppercase.copyWith(
                          color: AppColors.muted,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxxs),
                      Text(
                        DateFormatter.formatDate(movie.releaseDate),
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.ink,
                        ),
                      ),

                      // Safe space for sticky bottom bar
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Custom Circular Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + AppSpacing.xxs,
            left: AppSpacing.xs,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.canvasElevated,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColors.ink,
                  size: 22,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Sticky Bottom Bar with CTA (Max 1 primary CTA)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: const BoxDecoration(
                color: AppColors.canvasElevated,
                border: Border(
                  top: BorderSide(
                    color: AppColors.hairline,
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: movie.isNowShowing
                    ? AppButton.primary(
                        key: const Key('movie_detail_book_cta'),
                        label: 'ĐẶT VÉ',
                        width: double.infinity,
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.showtimes,
                            arguments: {
                              'movieId': movie.id,
                              'movieTitle': movie.title,
                            },
                          );
                        },
                      )
                    : const AppButton.primary(
                        key: Key('movie_detail_book_cta'),
                        label: 'CHƯA MỞ BÁN',
                        width: double.infinity,
                        onPressed: null,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
