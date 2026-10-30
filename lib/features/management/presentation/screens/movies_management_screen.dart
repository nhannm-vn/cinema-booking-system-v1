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
import '../../../../shared/widgets/app_network_image.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../auth/presentation/controllers/auth_provider.dart';
import '../../../movies/data/movie_model.dart';
import '../controllers/management_provider.dart';

/// Screen S13: Movies CRUD Management with future showtimes deletion protection.
/// References: ROLE_FLOWS.md Section 4.6 & Section 5.2, BUSINESS_RULES.md Section 2
class MoviesManagementScreen extends StatefulWidget {
  const MoviesManagementScreen({super.key});

  @override
  State<MoviesManagementScreen> createState() => _MoviesManagementScreenState();
}

class _MoviesManagementScreenState extends State<MoviesManagementScreen> {
  String _selectedStatus = 'ALL';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ManagementProvider>().loadMovies();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddEditModal(BuildContext context, {MovieModel? movie}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.canvasElevated,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.zeroRadius),
      builder: (_) => _MovieFormSheet(movie: movie),
    );
  }

  void _confirmDeleteMovie(BuildContext context, MovieModel movie) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.canvasElevated,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.zeroRadius),
        title: Text(
          'XÁC NHẬN XÓA PHIM'.toUpperCase(),
          style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa vĩnh viễn phim "${movie.title}"? Thao tác này không thể hoàn tác.',
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.ink),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'HỦY'.toUpperCase(),
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
              Navigator.pop(dialogCtx);
              final messenger = ScaffoldMessenger.of(context);
              final provider = context.read<ManagementProvider>();
              final success = await provider.deleteMovie(movie.id);
              if (!mounted) return;
              if (success) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Xóa phim thành công'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } else {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(provider.errorMessage ?? 'Xóa phim thất bại'),
                    backgroundColor: AppColors.warning,
                  ),
                );
              }
            },
            child: Text(
              'XÁC NHẬN XÓA'.toUpperCase(),
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

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        title: Text(
          'QUẢN LÝ DANH MỤC PHIM'.toUpperCase(),
          style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
        ),
        actions: [
          if (isAdmin)
            TextButton.icon(
              onPressed: () => _openAddEditModal(context),
              icon: const Icon(Icons.add, color: AppColors.primary, size: 20),
              label: Text(
                'THÊM PHIM'.toUpperCase(),
                style: AppTextStyles.button.copyWith(color: AppColors.primary),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: AppTextField(
              controller: _searchController,
              hintText: 'Tìm kiếm theo tên phim...',
              prefixIcon: const Icon(Icons.search, color: AppColors.muted),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
            ),
          ),

          // Status Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                _buildFilterChip('TẤT CẢ', 'ALL'),
                const SizedBox(width: AppSpacing.xs),
                _buildFilterChip('ĐANG CHIẾU', 'NOW_SHOWING'),
                const SizedBox(width: AppSpacing.xs),
                _buildFilterChip('SẮP CHIẾU', 'UPCOMING'),
                const SizedBox(width: AppSpacing.xs),
                _buildFilterChip('NGỪNG CHIẾU', 'INACTIVE'),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          // Movie List
          Expanded(
            child: _buildBody(context, provider, isAdmin),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
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
        setState(() {
          _selectedStatus = value;
        });
      },
    );
  }

  Widget _buildBody(BuildContext context, ManagementProvider provider, bool isAdmin) {
    if (provider.isLoading) {
      return ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, __) => const SkeletonBox(
          width: double.infinity,
          height: 100,
        ),
      );
    }

    if (provider.errorMessage != null) {
      return Center(
        child: ErrorState(
          message: provider.errorMessage!,
          onRetry: () => provider.loadMovies(),
        ),
      );
    }

    final now = DateTime.now();
    var filtered = provider.movies.where((movie) {
      // Status filter
      if (_selectedStatus == 'NOW_SHOWING') {
        if (!movie.isActive || movie.releaseDate.isAfter(now)) return false;
      } else if (_selectedStatus == 'UPCOMING') {
        if (!movie.isActive || !movie.releaseDate.isAfter(now)) return false;
      } else if (_selectedStatus == 'INACTIVE') {
        if (movie.isActive) return false;
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        if (!movie.title.toLowerCase().contains(_searchQuery)) return false;
      }
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return const Center(
        child: EmptyState(
          title: 'KHÔNG TÌM THẤY PHIM',
          message: 'Không tìm thấy phim phù hợp',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadMovies(),
      color: AppColors.primary,
      backgroundColor: AppColors.canvasElevated,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final movie = filtered[index];
          return _buildMovieCard(context, movie, provider, isAdmin);
        },
      ),
    );
  }

  Widget _buildMovieCard(
    BuildContext context,
    MovieModel movie,
    ManagementProvider provider,
    bool isAdmin,
  ) {
    final now = DateTime.now();
    String statusText;
    Color statusColor;

    if (!movie.isActive) {
      statusText = 'NGỪNG CHIẾU';
      statusColor = AppColors.muted;
    } else if (movie.releaseDate.isAfter(now)) {
      statusText = 'SẮP CHIẾU';
      statusColor = AppColors.info;
    } else {
      statusText = 'ĐANG CHIẾU';
      statusColor = AppColors.success;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.canvasElevated,
        borderRadius: AppRadius.zeroRadius,
        border: Border.all(color: AppColors.hairline, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster
          AppNetworkImage(
            imageUrl: movie.posterUrl,
            width: 64,
            height: 96,
            fit: BoxFit.cover,
            fallbackIcon: Icons.movie,
            iconSize: 24,
          ),
          const SizedBox(width: AppSpacing.sm),

          // Movie Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        movie.title,
                        style: AppTextStyles.titleSm.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    AppBadge(label: statusText, backgroundColor: statusColor),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),

                Row(
                  children: [
                    AppBadge.age(movie.ageRating),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${movie.durationMin} phút',
                      style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '· ${DateFormatter.formatDate(movie.releaseDate)}',
                      style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),

                Text(
                  'Đạo diễn: ${(movie.director != null && movie.director!.isNotEmpty) ? movie.director! : '---'}',
                  style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xxs),

                // Admin Controls
                if (isAdmin)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Switch(
                        value: movie.isActive,
                        activeThumbColor: AppColors.primary,
                        onChanged: (_) => provider.toggleMovieActive(movie),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.ink),
                        onPressed: () => _openAddEditModal(context, movie: movie),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.warning),
                        onPressed: () => _confirmDeleteMovie(context, movie),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MovieFormSheet extends StatefulWidget {
  final MovieModel? movie;

  const _MovieFormSheet({this.movie});

  @override
  State<_MovieFormSheet> createState() => _MovieFormSheetState();
}

class _MovieFormSheetState extends State<_MovieFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _directorController;
  late TextEditingController _durationController;
  late TextEditingController _releaseDateController;
  late TextEditingController _posterUrlController;
  late TextEditingController _backdropUrlController;
  late TextEditingController _trailerUrlController;
  late TextEditingController _synopsisController;
  late TextEditingController _genresController;
  String _ageRating = 'P';
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    final m = widget.movie;
    _titleController = TextEditingController(text: m?.title ?? '');
    _directorController = TextEditingController(text: m?.director ?? '');
    _durationController = TextEditingController(text: m != null ? '${m.durationMin}' : '120');
    _releaseDateController = TextEditingController(
      text: m != null ? m.releaseDate.toIso8601String().split('T').first : '2026-10-30',
    );
    _posterUrlController = TextEditingController(text: m?.posterUrl ?? '');
    _backdropUrlController = TextEditingController(text: m?.backdropUrl ?? '');
    _trailerUrlController = TextEditingController(text: m?.trailerUrl ?? '');
    _synopsisController = TextEditingController(text: m?.description ?? '');
    _genresController = TextEditingController(text: m != null ? m.genres.join(', ') : 'Hành động');
    _ageRating = m?.ageRating ?? 'P';
    _isActive = m?.isActive ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _directorController.dispose();
    _durationController.dispose();
    _releaseDateController.dispose();
    _posterUrlController.dispose();
    _backdropUrlController.dispose();
    _trailerUrlController.dispose();
    _synopsisController.dispose();
    _genresController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final isEditing = widget.movie != null;
    final id = widget.movie?.id ?? '';
    final duration = int.tryParse(_durationController.text.trim()) ?? 120;
    final releaseDate = DateTime.tryParse(_releaseDateController.text.trim()) ?? DateTime.now();
    final genres = _genresController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final movie = MovieModel(
      id: id,
      title: _titleController.text.trim(),
      director: _directorController.text.trim(),
      castMembers: widget.movie?.castMembers ?? const [],
      genres: genres,
      durationMin: duration,
      releaseDate: releaseDate,
      ageRating: _ageRating,
      posterUrl: _posterUrlController.text.trim(),
      backdropUrl: _backdropUrlController.text.trim(),
      trailerUrl: _trailerUrlController.text.trim(),
      description: _synopsisController.text.trim(),
      isActive: _isActive,
    );

    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<ManagementProvider>();
    final success = await provider.saveMovie(movie, isEditing: isEditing);
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Cập nhật phim thành công' : 'Thêm phim mới thành công'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Lưu phim thất bại'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.movie != null;

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
                (isEditing ? 'CHỈNH SỬA PHIM' : 'THÊM PHIM MỚI').toUpperCase(),
                style: AppTextStyles.titleSm.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              AppTextField(
                controller: _titleController,
                label: 'TÊN PHIM *',
                hintText: 'Nhập tên phim...',
                validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập tên phim' : null,
              ),
              const SizedBox(height: AppSpacing.sm),

              AppTextField(
                controller: _directorController,
                label: 'ĐẠO DIỄN',
                hintText: 'Nhập tên đạo diễn...',
              ),
              const SizedBox(height: AppSpacing.sm),

              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _durationController,
                      label: 'THỜI LƯỢNG (PHÚT) *',
                      hintText: '120',
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Bắt buộc';
                        if (int.tryParse(val.trim()) == null) return 'Phải là số';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppTextField(
                      controller: _releaseDateController,
                      label: 'KHỞI CHIẾU (YYYY-MM-DD) *',
                      hintText: '2026-10-30',
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Bắt buộc';
                        if (DateTime.tryParse(val.trim()) == null) return 'Sai định dạng ngày';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Age Rating Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: AppRadius.zeroRadius,
                  border: Border.all(color: AppColors.hairline),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _ageRating,
                    dropdownColor: AppColors.canvasElevated,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'P', child: Text('P - Mọi lứa tuổi', style: TextStyle(color: AppColors.ink))),
                      DropdownMenuItem(value: 'K', child: Text('K - Dưới 13 tuổi có bảo hộ', style: TextStyle(color: AppColors.ink))),
                      DropdownMenuItem(value: 'T13', child: Text('T13 - Từ 13 tuổi trở lên', style: TextStyle(color: AppColors.ink))),
                      DropdownMenuItem(value: 'T16', child: Text('T16 - Từ 16 tuổi trở lên', style: TextStyle(color: AppColors.ink))),
                      DropdownMenuItem(value: 'T18', child: Text('T18 - Từ 18 tuổi trở lên', style: TextStyle(color: AppColors.ink))),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _ageRating = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              AppTextField(
                controller: _genresController,
                label: 'THỂ LOẠI (CÁCH NHAU BẰNG DẤU PHẨY)',
                hintText: 'Hành động, Viễn tưởng, Phiêu lưu',
              ),
              const SizedBox(height: AppSpacing.sm),

              AppTextField(
                controller: _posterUrlController,
                label: 'LINK POSTER (URL)',
                hintText: 'https://...',
              ),
              const SizedBox(height: AppSpacing.sm),

              AppTextField(
                controller: _backdropUrlController,
                label: 'LINK BACKDROP (URL)',
                hintText: 'https://...',
              ),
              const SizedBox(height: AppSpacing.sm),

              AppTextField(
                controller: _trailerUrlController,
                label: 'LINK TRAILER (YOUTUBE URL)',
                hintText: 'https://youtube.com/...',
              ),
              const SizedBox(height: AppSpacing.sm),

              AppTextField(
                controller: _synopsisController,
                label: 'TÓM TẮT NỘI DUNG',
                hintText: 'Mô tả nội dung phim...',
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.sm),

              SwitchListTile(
                title: Text(
                  'Đang phát hành / Hoạt động',
                  style: AppTextStyles.bodyMd.copyWith(color: AppColors.ink),
                ),
                value: _isActive,
                activeThumbColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) => setState(() => _isActive = val),
              ),
              const SizedBox(height: AppSpacing.md),

              AppButton.primary(
                label: 'LƯU THÔNG TIN',
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
