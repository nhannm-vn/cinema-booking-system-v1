import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/hold_timer.dart';
import '../../../../shared/widgets/quantity_stepper.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../data/models/food_model.dart';
import '../../data/repositories/food_repository.dart';
import '../controllers/booking_provider.dart';

/// S07 Food & Concession Selection Screen.
/// References: ROLE_FLOWS.md Section 1, DESIGN_TOKENS.md, m3_plan.md Section 3.3
class FoodSelectionScreen extends StatefulWidget {
  const FoodSelectionScreen({super.key});

  @override
  State<FoodSelectionScreen> createState() => _FoodSelectionScreenState();
}

class _FoodSelectionScreenState extends State<FoodSelectionScreen> {
  final FoodRepository _foodRepo = FoodRepository();
  bool _isLoading = true;
  String? _errorMessage;
  List<FoodModel> _allFoods = [];
  String _selectedCategory = 'ALL';

  final List<Map<String, String>> _categories = const [
    {'key': 'ALL', 'label': 'TẤT CẢ'},
    {'key': 'combo', 'label': 'COMBO'},
    {'key': 'popcorn', 'label': 'BẮP'},
    {'key': 'drink', 'label': 'NƯỚC'},
    {'key': 'snack', 'label': 'SNACK'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchFoods();
  }

  Future<void> _fetchFoods() async {
    final booking = context.read<BookingProvider>();
    final cinemaId = booking.selectedShowtime?.cinemaId ?? '';

    if (cinemaId.isEmpty) {
      setState(() {
        _errorMessage = 'Thiếu thông tin rạp chiếu.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _foodRepo.getFoodsByCinema(cinemaId);
      if (!mounted) return;
      setState(() {
        _allFoods = list;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Không thể tải danh mục bắp nước. Vui lòng thử lại.';
        _isLoading = false;
      });
    }
  }

  void _handleHoldExpired() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.canvasElevated,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.zeroRadius),
        title: Text(
          'HẾT THỜI GIAN GIỮ GHẾ'.toUpperCase(),
          style: AppTextStyles.titleMd.copyWith(color: AppColors.ink),
        ),
        content: Text(
          'Thời gian giữ ghế 5 phút đã kết thúc. Ghế đã được nhả cho người khác.',
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.body),
        ),
        actions: [
          AppButton.primary(
            label: 'CHỌN LẠI GHẾ',
            onPressed: () {
              Navigator.pop(ctx);
              context.read<BookingProvider>().reset();
              Navigator.popUntil(context, ModalRoute.withName(AppRoutes.seatSelect));
            },
          ),
        ],
      ),
    );
  }

  Future<void> _proceedToCheckout({bool skipFood = false}) async {
    final booking = context.read<BookingProvider>();
    if (skipFood) {
      // Clear food selections
      for (final f in List<FoodModel>.from(booking.selectedFoods)) {
        booking.updateFoodQuantity(f, 0);
      }
    }

    final success = await booking.syncBookingDetails();
    if (!mounted) return;

    if (success) {
      Navigator.pushNamed(context, AppRoutes.checkout);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.warning,
          content: Text(
            (booking.errorMessage ?? 'Không thể đồng bộ thông tin vé.').toUpperCase(),
            style: AppTextStyles.bodySm.copyWith(color: AppColors.ink),
          ),
        ),
      );
    }
  }

  int _getFoodQuantity(FoodModel food, BookingProvider booking) {
    final item = booking.selectedFoods.firstWhere(
      (f) => f.id == food.id,
      orElse: () => food.copyWith(quantity: 0),
    );
    return item.quantity;
  }

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingProvider>();
    final holdUntil = booking.holdUntil;

    final filteredFoods = _selectedCategory == 'ALL'
        ? _allFoods
        : _allFoods.where((f) => f.category == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.ink),
        title: Text(
          'CHỌN BẮP NƯỚC'.toUpperCase(),
          style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
        ),
      ),
      body: Column(
        children: [
          // HoldTimer banner
          if (holdUntil != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              decoration: const BoxDecoration(
                color: AppColors.canvasElevated,
                border: Border(
                  bottom: BorderSide(color: AppColors.hairline, width: 1),
                ),
              ),
              child: Center(
                child: HoldTimer(
                  holdUntil: holdUntil,
                  onExpired: _handleHoldExpired,
                ),
              ),
            ),

          // Categories horizontal bar
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.hairline, width: 1),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat['key'];
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedCategory = cat['key']!;
                        });
                      },
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.hairline,
                            width: 1,
                          ),
                          borderRadius: AppRadius.zeroRadius,
                        ),
                        child: Text(
                          cat['label']!,
                          style: AppTextStyles.captionUppercase.copyWith(
                            color: isSelected ? AppColors.onPrimary : AppColors.body,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Food items list with 3 UI States
          Expanded(
            child: _buildFoodList(filteredFoods, booking),
          ),

          // Pinned bottom action bar
          _buildBottomBar(booking),
        ],
      ),
    );
  }

  Widget _buildFoodList(List<FoodModel> foods, BookingProvider booking) {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.sm),
        itemCount: 4,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.sm),
          child: SkeletonBox(width: double.infinity, height: 80),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: ErrorState(
          message: _errorMessage!,
          onRetry: _fetchFoods,
        ),
      );
    }

    if (foods.isEmpty) {
      return const Center(
        child: EmptyState(
          title: 'CHƯA CÓ MÓN ĂN',
          message: 'Không tìm thấy bắp nước trong danh mục này.',
          icon: Icons.fastfood_outlined,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.sm),
      itemCount: foods.length,
      itemBuilder: (context, index) {
        final food = foods[index];
        final qty = _getFoodQuantity(food, booking);

        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: AppColors.canvasElevated,
            border: Border.all(color: AppColors.hairline, width: 1),
            borderRadius: AppRadius.zeroRadius,
          ),
          child: Row(
            children: [
              // Food image or fallback
              Container(
                width: 72,
                height: 72,
                color: AppColors.canvas,
                child: food.imageUrl != null && food.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: food.imageUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const Icon(
                          Icons.fastfood,
                          color: AppColors.muted,
                          size: 32,
                        ),
                      )
                    : const Icon(
                        Icons.fastfood,
                        color: AppColors.muted,
                        size: 32,
                      ),
              ),
              const SizedBox(width: AppSpacing.xs),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.name,
                      style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (food.description != null && food.description!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxxs),
                      Text(
                        food.description!,
                        style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      CurrencyFormatter.format(food.price),
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),

              // QuantityStepper or Hết hàng
              if (!food.isAvailable)
                Text(
                  'HẾT HÀNG',
                  style: AppTextStyles.captionUppercase.copyWith(color: AppColors.muted),
                )
              else
                QuantityStepper(
                  value: qty,
                  isAvailable: food.isAvailable,
                  onChanged: (newQty) {
                    booking.updateFoodQuantity(food, newQty);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(BookingProvider booking) {
    final foodTotal = booking.calculateFoodTotal();
    final grandTotal = booking.calculateGrandTotal();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.canvasElevated,
        border: Border(
          top: BorderSide(color: AppColors.hairline, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              // Left: Grand Total
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (foodTotal > 0)
                      Text(
                        'ĐỒ ĂN: ${CurrencyFormatter.format(foodTotal)}',
                        style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
                      ),
                    Text(
                      CurrencyFormatter.format(grandTotal),
                      style: AppTextStyles.displayLg.copyWith(color: AppColors.ink),
                    ),
                  ],
                ),
              ),

              // Outline button: BỎ QUA
              AppButton.outline(
                label: 'BỎ QUA',
                isLoading: booking.isLoading,
                onPressed: () => _proceedToCheckout(skipFood: true),
              ),
              const SizedBox(width: AppSpacing.xs),

              // Primary button: TIẾP TỤC
              AppButton.primary(
                label: 'TIẾP TỤC',
                isLoading: booking.isLoading,
                onPressed: () => _proceedToCheckout(skipFood: false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
