import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../auth/presentation/controllers/auth_provider.dart';
import '../../../booking/data/models/food_model.dart';
import '../controllers/management_provider.dart';

/// Screen S16: Food & Concessions Catalog Management with availability toggle.
/// References: ROLE_FLOWS.md Section 4.5 & 5.2, BUSINESS_RULES.md Section 5
class FoodCatalogScreen extends StatefulWidget {
  const FoodCatalogScreen({super.key});

  @override
  State<FoodCatalogScreen> createState() => _FoodCatalogScreenState();
}

class _FoodCatalogScreenState extends State<FoodCatalogScreen> {
  String _selectedCategory = 'ALL';
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
      _loadFoods();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadFoods() {
    context.read<ManagementProvider>().loadFoods(
      _activeCinemaId,
      category: _selectedCategory,
    );
  }

  void _openAddEditFoodModal(BuildContext context, {FoodModel? food}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.canvasElevated,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.zeroRadius),
      builder: (_) => _FoodFormSheet(
        cinemaId: _activeCinemaId,
        food: food,
        onSaved: () => _loadFoods(),
      ),
    );
  }

  void _confirmDeleteFood(BuildContext context, FoodModel food) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.canvasElevated,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.zeroRadius),
        title: Text(
          'XÁC NHẬN XÓA MÓN ĂN'.toUpperCase(),
          style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
        ),
        content: Text(
          'Bạn có chắc muốn xóa món "${food.name}" khỏi thực đơn rạp?',
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
              final success = await provider.deleteFood(food.id, _activeCinemaId);
              if (!mounted) return;
              if (success) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Xóa món ăn thành công'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } else {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(provider.errorMessage ?? 'Xóa món ăn thất bại'),
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
              'MENU BẮP NƯỚC & ĐỒ ĂN'.toUpperCase(),
              style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
            ),
            const SizedBox(height: AppSpacing.xxxs),
            Text(
              'RẠP ${_activeCinemaId.toUpperCase()}',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _openAddEditFoodModal(context),
            icon: const Icon(Icons.add, color: AppColors.primary, size: 20),
            label: Text(
              'THÊM MÓN'.toUpperCase(),
              style: AppTextStyles.button.copyWith(color: AppColors.primary),
            ),
          ),
        ],
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
              hintText: 'Tìm kiếm tên món ăn...',
              prefixIcon: const Icon(Icons.search, color: AppColors.muted),
              onChanged: (val) {
                setState(() => _searchQuery = val.trim().toLowerCase());
              },
            ),
          ),

          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xxs,
            ),
            child: Row(
              children: [
                _buildCategoryChip('TẤT CẢ', 'ALL'),
                const SizedBox(width: AppSpacing.xs),
                _buildCategoryChip('COMBO', 'combo'),
                const SizedBox(width: AppSpacing.xs),
                _buildCategoryChip('BẮP RANG', 'popcorn'),
                const SizedBox(width: AppSpacing.xs),
                _buildCategoryChip('NƯỚC UỐNG', 'drink'),
                const SizedBox(width: AppSpacing.xs),
                _buildCategoryChip('ĐỒ ĂN NHẸ', 'snack'),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          // Foods List
          Expanded(
            child: _buildBody(context, provider),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, String value) {
    final isSelected = _selectedCategory == value;
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
        setState(() => _selectedCategory = value);
        _loadFoods();
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
          height: 90,
        ),
      );
    }

    if (provider.errorMessage != null) {
      return Center(
        child: ErrorState(
          message: provider.errorMessage!,
          onRetry: () => _loadFoods(),
        ),
      );
    }

    var list = provider.foods;
    if (_searchQuery.isNotEmpty) {
      list = list.where((f) => f.name.toLowerCase().contains(_searchQuery)).toList();
    }

    if (list.isEmpty) {
      return Center(
        child: EmptyState(
          title: 'KHÔNG CÓ MÓN ĂN',
          message: 'Không có món ăn nào trong danh mục',
          actionLabel: 'THÊM MÓN MỚI',
          onAction: () => _openAddEditFoodModal(context),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadFoods(),
      color: AppColors.primary,
      backgroundColor: AppColors.canvasElevated,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final food = list[index];
          return _buildFoodCard(context, food, provider);
        },
      ),
    );
  }

  Widget _buildFoodCard(BuildContext context, FoodModel food, ManagementProvider provider) {
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
          // Food Image
          AppNetworkImage(
            imageUrl: food.imageUrl,
            width: 64,
            height: 64,
            fit: BoxFit.cover,
            fallbackIcon: Icons.fastfood,
            iconSize: 24,
          ),
          const SizedBox(width: AppSpacing.sm),

          // Food Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        food.name,
                        style: AppTextStyles.titleSm.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    AppBadge(
                      label: food.category.toUpperCase(),
                      backgroundColor: AppColors.muted,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),

                Text(
                  CurrencyFormatter.format(food.price),
                  style: AppTextStyles.titleSm.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (food.description != null && food.description!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxxs),
                  Text(
                    food.description!,
                    style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: AppSpacing.xxs),

                Row(
                  children: [
                    Text(
                      food.isAvailable ? 'CÒN HÀNG' : 'HẾT HÀNG',
                      style: AppTextStyles.caption.copyWith(
                        color: food.isAvailable ? AppColors.success : AppColors.warning,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Switch(
                      value: food.isAvailable,
                      activeThumbColor: AppColors.success,
                      onChanged: (val) => provider.toggleFood(food.id, val),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.ink),
                      onPressed: () => _openAddEditFoodModal(context, food: food),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.warning),
                      onPressed: () => _confirmDeleteFood(context, food),
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

class _FoodFormSheet extends StatefulWidget {
  final String cinemaId;
  final FoodModel? food;
  final VoidCallback onSaved;

  const _FoodFormSheet({
    required this.cinemaId,
    this.food,
    required this.onSaved,
  });

  @override
  State<_FoodFormSheet> createState() => _FoodFormSheetState();
}

class _FoodFormSheetState extends State<_FoodFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _imageController;
  late TextEditingController _descController;
  String _category = 'combo';
  bool _isAvailable = true;

  @override
  void initState() {
    super.initState();
    final f = widget.food;
    _nameController = TextEditingController(text: f?.name ?? '');
    _priceController = TextEditingController(text: f != null ? '${f.price}' : '85000');
    _imageController = TextEditingController(text: f?.imageUrl ?? '');
    _descController = TextEditingController(text: f?.description ?? '');
    _category = f?.category ?? 'combo';
    _isAvailable = f?.isAvailable ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _imageController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final isEditing = widget.food != null;
    final price = int.tryParse(_priceController.text.trim()) ?? 0;

    final food = FoodModel(
      id: widget.food?.id ?? '',
      cinemaId: widget.cinemaId,
      name: _nameController.text.trim(),
      category: _category,
      price: price,
      isAvailable: _isAvailable,
      imageUrl: _imageController.text.trim().isNotEmpty ? _imageController.text.trim() : null,
      description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
    );

    final provider = context.read<ManagementProvider>();
    final success = await provider.saveFood(food, isEditing: isEditing, cinemaId: widget.cinemaId);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Cập nhật món ăn thành công' : 'Thêm món ăn thành công'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Lưu món ăn thất bại'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.food != null;

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
                (isEditing ? 'CHỈNH SỬA MÓN ĂN' : 'THÊM MÓN MỚI').toUpperCase(),
                style: AppTextStyles.titleSm.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              AppTextField(
                controller: _nameController,
                label: 'TÊN MÓN ĂN *',
                hintText: 'Nhập tên món...',
                validator: (val) => val == null || val.trim().isEmpty ? 'Bắt buộc' : null,
              ),
              const SizedBox(height: AppSpacing.sm),

              // Category dropdown
              Text('DANH MỤC *', style: AppTextStyles.captionUppercase.copyWith(color: AppColors.muted)),
              const SizedBox(height: AppSpacing.xxs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: AppRadius.zeroRadius,
                  border: Border.all(color: AppColors.hairline),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _category,
                    dropdownColor: AppColors.canvasElevated,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'combo', child: Text('Combo bắp nước', style: TextStyle(color: AppColors.ink))),
                      DropdownMenuItem(value: 'popcorn', child: Text('Bắp rang', style: TextStyle(color: AppColors.ink))),
                      DropdownMenuItem(value: 'drink', child: Text('Nước ngọt & nước suối', style: TextStyle(color: AppColors.ink))),
                      DropdownMenuItem(value: 'snack', child: Text('Đồ ăn nhẹ', style: TextStyle(color: AppColors.ink))),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _category = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              AppTextField(
                controller: _priceController,
                label: 'ĐƠN GIÁ (VND) *',
                hintText: '85000',
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Bắt buộc';
                  final p = int.tryParse(val.trim());
                  if (p == null || p < 0) return 'Giá phải là số nguyên >= 0';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.sm),

              AppTextField(
                controller: _imageController,
                label: 'LINK ẢNH (URL)',
                hintText: 'https://...',
              ),
              const SizedBox(height: AppSpacing.sm),

              AppTextField(
                controller: _descController,
                label: 'MÔ TẢ MÓN ĂN',
                hintText: '1 Bắp lớn + 2 Nước ngọt...',
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.sm),

              SwitchListTile(
                title: Text(
                  'Đang có sẵn để bán (Còn hàng)',
                  style: AppTextStyles.bodyMd.copyWith(color: AppColors.ink),
                ),
                value: _isAvailable,
                activeThumbColor: AppColors.success,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) => setState(() => _isAvailable = val),
              ),
              const SizedBox(height: AppSpacing.md),

              AppButton.primary(
                label: 'LƯU MÓN ĂN',
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
