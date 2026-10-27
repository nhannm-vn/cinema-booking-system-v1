import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../data/models/voucher_model.dart';
import '../controllers/management_provider.dart';

/// Screen S27: Voucher & Promotion Management with lifecycle status badges and CRUD.
/// References: ROLE_FLOWS.md Section 5.6, BUSINESS_RULES.md Section 8
class VouchersManagementScreen extends StatefulWidget {
  const VouchersManagementScreen({super.key});

  @override
  State<VouchersManagementScreen> createState() => _VouchersManagementScreenState();
}

class _VouchersManagementScreenState extends State<VouchersManagementScreen> {
  String _selectedFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ManagementProvider>().loadVouchers();
    });
  }

  void _openAddEditVoucherModal(BuildContext context, {VoucherModel? voucher}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.canvasElevated,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.zeroRadius),
      builder: (_) => _VoucherFormSheet(voucher: voucher),
    );
  }

  void _confirmDeleteVoucher(BuildContext context, VoucherModel voucher) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.canvasElevated,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.zeroRadius),
        title: Text(
          'XÁC NHẬN XÓA VOUCHER'.toUpperCase(),
          style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa mã voucher "${voucher.code}" khỏi hệ thống?',
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
              final success = await provider.deleteVoucher(voucher.code);
              if (!mounted) return;
              if (success) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Xóa voucher thành công'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } else {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(provider.errorMessage ?? 'Xóa voucher thất bại'),
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
        title: Text(
          'QUẢN LÝ VOUCHER & KHUYẾN MÃI'.toUpperCase(),
          style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _openAddEditVoucherModal(context),
            icon: const Icon(Icons.add, color: AppColors.primary, size: 20),
            label: Text(
              'THÊM VOUCHER'.toUpperCase(),
              style: AppTextStyles.button.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips Bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                _buildFilterChip('TẤT CẢ', 'ALL'),
                _buildFilterChip('CÒN HẠN', 'VALID'),
                _buildFilterChip('HẾT LƯỢT', 'EXHAUSTED'),
                _buildFilterChip('HẾT HẠN', 'EXPIRED'),
                _buildFilterChip('TẠM KHÓA', 'LOCKED'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Vouchers List
          Expanded(
            child: _buildBody(context, provider),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
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
      onSelected: (_) => setState(() => _selectedFilter = value),
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
          height: 120,
        ),
      );
    }

    if (provider.errorMessage != null) {
      return Center(
        child: ErrorState(
          message: provider.errorMessage!,
          onRetry: () => provider.loadVouchers(),
        ),
      );
    }

    final filtered = provider.vouchers.where((v) {
      if (_selectedFilter == 'VALID') return v.isUsable;
      if (_selectedFilter == 'EXHAUSTED') return v.isExhausted;
      if (_selectedFilter == 'EXPIRED') return v.isExpired;
      if (_selectedFilter == 'LOCKED') return !v.isActive;
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: EmptyState(
          title: 'KHÔNG CÓ VOUCHER',
          message: 'Không tìm thấy voucher nào',
          actionLabel: 'TẠO VOUCHER',
          onAction: () => _openAddEditVoucherModal(context),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => provider.loadVouchers(),
      color: AppColors.primary,
      backgroundColor: AppColors.canvasElevated,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final voucher = filtered[index];
          return _buildVoucherCard(context, voucher, provider);
        },
      ),
    );
  }

  Widget _buildVoucherCard(BuildContext context, VoucherModel voucher, ManagementProvider provider) {
    Color badgeColor;
    if (!voucher.isActive) {
      badgeColor = AppColors.muted;
    } else if (voucher.isExpired) {
      badgeColor = AppColors.warning;
    } else if (voucher.isExhausted) {
      badgeColor = AppColors.warning;
    } else {
      badgeColor = AppColors.success;
    }

    final discountText = voucher.type == 'percent'
        ? 'Giảm ${voucher.value}% cho tiền vé'
        : 'Giảm ${CurrencyFormatter.format(voucher.value)} cho tiền vé';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
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
                voucher.code,
                style: AppTextStyles.titleSm.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              AppBadge(label: voucher.statusBadgeText, backgroundColor: badgeColor),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          Text(
            discountText,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),

          Text(
            'Đơn tối thiểu: ${CurrencyFormatter.format(voucher.minBookingAmount)}${voucher.maxDiscount != null ? ' · Giảm tối đa: ${CurrencyFormatter.format(voucher.maxDiscount!)}' : ''}',
            style: AppTextStyles.caption.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.xxs),

          Text(
            'Đã dùng: ${voucher.usedCount}/${voucher.maxUses} lượt · Hết hạn: ${DateFormatter.formatDate(voucher.expiresAt)}',
            style: AppTextStyles.caption.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.sm),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'KÍCH HOẠT:',
                    style: AppTextStyles.captionUppercase.copyWith(
                      color: AppColors.muted,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Switch(
                    value: voucher.isActive,
                    activeColor: AppColors.primary,
                    onChanged: (val) => provider.toggleVoucher(voucher.code, val),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.ink),
                    onPressed: () => _openAddEditVoucherModal(context, voucher: voucher),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.warning),
                    onPressed: () => _confirmDeleteVoucher(context, voucher),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VoucherFormSheet extends StatefulWidget {
  final VoucherModel? voucher;

  const _VoucherFormSheet({this.voucher});

  @override
  State<_VoucherFormSheet> createState() => _VoucherFormSheetState();
}

class _VoucherFormSheetState extends State<_VoucherFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeController;
  late TextEditingController _valueController;
  late TextEditingController _minAmountController;
  late TextEditingController _maxDiscountController;
  late TextEditingController _maxUsesController;
  late TextEditingController _expiresAtController;
  String _type = 'percent';
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    final v = widget.voucher;
    _codeController = TextEditingController(text: v?.code ?? '');
    _valueController = TextEditingController(text: v != null ? '${v.value}' : '20');
    _minAmountController = TextEditingController(text: v != null ? '${v.minBookingAmount}' : '0');
    _maxDiscountController = TextEditingController(text: v?.maxDiscount != null ? '${v!.maxDiscount}' : '');
    _maxUsesController = TextEditingController(text: v != null ? '${v.maxUses}' : '100');
    _expiresAtController = TextEditingController(
      text: v != null ? v.expiresAt.toIso8601String().split('T').first : '2026-12-31',
    );
    _type = v?.type ?? 'percent';
    _isActive = v?.isActive ?? true;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _valueController.dispose();
    _minAmountController.dispose();
    _maxDiscountController.dispose();
    _maxUsesController.dispose();
    _expiresAtController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final isEditing = widget.voucher != null;
    final code = _codeController.text.trim().toUpperCase();
    final value = int.tryParse(_valueController.text.trim()) ?? 0;
    final minAmount = int.tryParse(_minAmountController.text.trim()) ?? 0;
    final maxDiscount = int.tryParse(_maxDiscountController.text.trim());
    final maxUses = int.tryParse(_maxUsesController.text.trim()) ?? 100;
    final expiresAt = DateTime.tryParse(_expiresAtController.text.trim()) ?? DateTime.now().add(const Duration(days: 30));

    final voucher = VoucherModel(
      code: code,
      type: _type,
      value: value,
      minBookingAmount: minAmount,
      maxDiscount: maxDiscount,
      startDate: widget.voucher?.startDate ?? DateTime.now(),
      expiresAt: expiresAt,
      maxUses: maxUses,
      usedCount: widget.voucher?.usedCount ?? 0,
      isActive: _isActive,
      createdAt: widget.voucher?.createdAt ?? DateTime.now(),
    );

    final provider = context.read<ManagementProvider>();
    final success = await provider.saveVoucher(voucher, isEditing: isEditing);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Cập nhật voucher thành công' : 'Tạo voucher thành công'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Lưu voucher thất bại'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.voucher != null;

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
                (isEditing ? 'CHỈNH SỬA VOUCHER' : 'TẠO VOUCHER MỚI').toUpperCase(),
                style: AppTextStyles.titleSm.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              AppTextField(
                controller: _codeController,
                label: 'MÃ VOUCHER *',
                hintText: 'CINEMA20',
                enabled: !isEditing,
                validator: (val) => val == null || val.trim().isEmpty ? 'Bắt buộc' : null,
              ),
              const SizedBox(height: AppSpacing.sm),

              // Type Selector
              Text('LOẠI GIẢM GIÁ *', style: AppTextStyles.captionUppercase.copyWith(color: AppColors.muted)),
              const SizedBox(height: AppSpacing.xxs),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  ChoiceChip(
                    label: const Text('Phần trăm (%)'),
                    selected: _type == 'percent',
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.canvas,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.zeroRadius,
                      side: BorderSide(color: AppColors.hairline),
                    ),
                    elevation: 0,
                    pressElevation: 0,
                    onSelected: (_) => setState(() => _type = 'percent'),
                  ),
                  ChoiceChip(
                    label: const Text('Số tiền cố định (VND)'),
                    selected: _type == 'amount',
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.canvas,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.zeroRadius,
                      side: BorderSide(color: AppColors.hairline),
                    ),
                    elevation: 0,
                    pressElevation: 0,
                    onSelected: (_) => setState(() => _type = 'amount'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _valueController,
                      label: _type == 'percent' ? 'GIÁ TRỊ (%) *' : 'SỐ TIỀN GIẢM (VND) *',
                      hintText: _type == 'percent' ? '20' : '50000',
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Bắt buộc';
                        final n = int.tryParse(val.trim());
                        if (n == null || n <= 0) return 'Phải > 0';
                        if (_type == 'percent' && n > 100) return 'Tối đa 100%';
                        return null;
                      },
                    ),
                  ),
                  if (_type == 'percent') ...[
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppTextField(
                        controller: _maxDiscountController,
                        label: 'GIẢM TỐI ĐA (VND)',
                        hintText: '50000',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _minAmountController,
                      label: 'ĐƠN TỐI THIỂU (VND)',
                      hintText: '100000',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppTextField(
                      controller: _maxUsesController,
                      label: 'TỔNG LƯỢT DÙNG *',
                      hintText: '100',
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Bắt buộc';
                        final n = int.tryParse(val.trim());
                        if (n == null || n <= 0) return 'Phải > 0';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              AppTextField(
                controller: _expiresAtController,
                label: 'NGÀY HẾT HẠN (YYYY-MM-DD) *',
                hintText: '2026-12-31',
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Bắt buộc';
                  if (DateTime.tryParse(val.trim()) == null) return 'Sai định dạng ngày';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.sm),

              SwitchListTile(
                title: Text(
                  'Kích hoạt voucher ngay',
                  style: AppTextStyles.bodyMd.copyWith(color: AppColors.ink),
                ),
                value: _isActive,
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) => setState(() => _isActive = val),
              ),
              const SizedBox(height: AppSpacing.md),

              AppButton.primary(
                label: 'LƯU VOUCHER',
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
