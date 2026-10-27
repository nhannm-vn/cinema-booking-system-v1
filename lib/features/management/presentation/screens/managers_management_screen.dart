import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/app_user.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../controllers/management_provider.dart';

/// Screen S28: Manager Accounts Management (Admin-only) with cinema assignment & lock toggle.
/// References: ROLE_FLOWS.md Section 5.7, BUSINESS_RULES.md Section 1.3
class ManagersManagementScreen extends StatefulWidget {
  const ManagersManagementScreen({super.key});

  @override
  State<ManagersManagementScreen> createState() => _ManagersManagementScreenState();
}

class _ManagersManagementScreenState extends State<ManagersManagementScreen> {
  String _selectedCinemaFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ManagementProvider>();
      provider.loadCinemas();
      provider.loadManagers();
    });
  }

  void _openAddManagerModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.canvasElevated,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.zeroRadius),
      builder: (_) => const _AddManagerSheet(),
    );
  }

  void _confirmToggleLock(BuildContext context, AppUser manager) {
    final willLock = !manager.isLocked;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.canvasElevated,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.zeroRadius),
        title: Text(
          (willLock ? 'XÁC NHẬN KHÓA TÀI KHOẢN' : 'XÁC NHẬN MỞ KHÓA').toUpperCase(),
          style: AppTextStyles.titleSm.copyWith(
            color: willLock ? AppColors.warning : AppColors.success,
          ),
        ),
        content: Text(
          willLock
              ? 'Khóa tài khoản quản lý "${manager.fullName}"? Tài khoản này sẽ bị thu hồi phiên đăng nhập và không thể thao tác.'
              : 'Mở khóa tài khoản quản lý "${manager.fullName}"?',
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
              backgroundColor: willLock ? AppColors.warning : AppColors.success,
              elevation: 0,
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.zeroRadius),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final messenger = ScaffoldMessenger.of(context);
              await context.read<ManagementProvider>().toggleManagerLock(manager.id, willLock);
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text(willLock ? 'Đã khóa tài khoản quản lý' : 'Đã mở khóa tài khoản quản lý'),
                  backgroundColor: willLock ? AppColors.warning : AppColors.success,
                ),
              );
            },
            child: Text(
              (willLock ? 'KHÓA TÀI KHOẢN' : 'MỞ KHÓA').toUpperCase(),
              style: AppTextStyles.button.copyWith(color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }

  void _openReassignModal(BuildContext context, AppUser manager) {
    final cinemas = context.read<ManagementProvider>().cinemas;
    String newCinemaId = manager.cinemaId ?? (cinemas.isNotEmpty ? cinemas.first.id : 'cn_q1');

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: AppColors.canvasElevated,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.zeroRadius),
          title: Text(
            'CHUYỂN CÔNG TÁC QUẢN LÝ'.toUpperCase(),
            style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chọn rạp mới cho quản lý ${manager.fullName}:',
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.ink),
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                value: newCinemaId,
                dropdownColor: AppColors.canvasElevated,
                items: cinemas.map((c) => DropdownMenuItem(
                  value: c.id,
                  child: Text(c.name, style: const TextStyle(color: AppColors.ink)),
                )).toList(),
                onChanged: (val) {
                  if (val != null) setModalState(() => newCinemaId = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text('HỦY'.toUpperCase(), style: const TextStyle(color: AppColors.muted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                shape: const RoundedRectangleBorder(borderRadius: AppRadius.zeroRadius),
              ),
              onPressed: () async {
                Navigator.pop(dialogCtx);
                final messenger = ScaffoldMessenger.of(context);
                await context.read<ManagementProvider>().reassignManagerCinema(manager.id, newCinemaId);
                if (!mounted) return;
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Chuyển rạp công tác thành công'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              child: Text('XÁC NHẬN'.toUpperCase()),
            ),
          ],
        ),
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
          'QUẢN LÝ QUẢN LÝ RẠP'.toUpperCase(),
          style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _openAddManagerModal(context),
            icon: const Icon(Icons.add, color: AppColors.primary, size: 20),
            label: Text(
              'THÊM MANAGER'.toUpperCase(),
              style: AppTextStyles.button.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Cinema Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                _buildFilterChip('TẤT CẢ RẠP', 'ALL'),
                ...provider.cinemas.map((c) => Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.xs),
                  child: _buildFilterChip(c.name, c.id),
                )),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          // Managers List
          Expanded(
            child: _buildBody(context, provider),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedCinemaFilter == value;
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
      onSelected: (_) => setState(() => _selectedCinemaFilter = value),
    );
  }

  Widget _buildBody(BuildContext context, ManagementProvider provider) {
    if (provider.isLoading) {
      return ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, __) => const SkeletonBox(
          width: double.infinity,
          height: 110,
        ),
      );
    }

    if (provider.errorMessage != null) {
      return Center(
        child: ErrorState(
          message: provider.errorMessage!,
          onRetry: () => provider.loadManagers(),
        ),
      );
    }

    final filtered = provider.managers.where((m) {
      if (_selectedCinemaFilter != 'ALL') {
        return m.cinemaId == _selectedCinemaFilter;
      }
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: EmptyState(
          title: 'CHƯA CÓ QUẢN LÝ',
          message: 'Chưa có tài khoản quản lý rạp nào',
          actionLabel: 'THÊM QUẢN LÝ',
          onAction: () => _openAddManagerModal(context),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => provider.loadManagers(),
      color: AppColors.primary,
      backgroundColor: AppColors.canvasElevated,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final manager = filtered[index];
          return _buildManagerCard(context, manager);
        },
      ),
    );
  }

  Widget _buildManagerCard(BuildContext context, AppUser manager) {
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
              Expanded(
                child: Text(
                  manager.fullName.isNotEmpty ? manager.fullName : 'Quản lý rạp',
                  style: AppTextStyles.titleSm.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              AppBadge(
                label: manager.isLocked ? 'ĐÃ KHÓA' : 'HOẠT ĐỘNG',
                backgroundColor: manager.isLocked ? AppColors.warning : AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          Text(
            manager.email ?? '',
            style: AppTextStyles.caption.copyWith(color: AppColors.muted),
          ),
          if (manager.phone != null && manager.phone!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxxs),
            Text(
              'SĐT: ${manager.phone}',
              style: AppTextStyles.caption.copyWith(color: AppColors.muted),
            ),
          ],
          const SizedBox(height: AppSpacing.xxs),

          Row(
            children: [
              AppBadge(
                label: 'RẠP ${manager.cinemaId?.toUpperCase() ?? 'CHƯA GÁN'}',
                backgroundColor: AppColors.primary,
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _openReassignModal(context, manager),
                child: Text(
                  'CHUYỂN RẠP',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.info,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              TextButton(
                onPressed: () => _confirmToggleLock(context, manager),
                child: Text(
                  manager.isLocked ? 'MỞ KHÓA' : 'KHÓA',
                  style: AppTextStyles.caption.copyWith(
                    color: manager.isLocked ? AppColors.success : AppColors.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddManagerSheet extends StatefulWidget {
  const _AddManagerSheet();

  @override
  State<_AddManagerSheet> createState() => _AddManagerSheetState();
}

class _AddManagerSheetState extends State<_AddManagerSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _cinemaId = 'cn_q1';

  @override
  void initState() {
    super.initState();
    final cinemas = context.read<ManagementProvider>().cinemas;
    if (cinemas.isNotEmpty) {
      _cinemaId = cinemas.first.id;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<ManagementProvider>();
    final success = await provider.createManagerAccount(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      cinemaId: _cinemaId,
    );

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tạo tài khoản quản lý rạp thành công'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Tạo quản lý thất bại'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cinemas = context.watch<ManagementProvider>().cinemas;

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
                'TẠO TÀI KHOẢN QUẢN LÝ RẠP (MANAGER)'.toUpperCase(),
                style: AppTextStyles.titleSm.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              AppTextField(
                controller: _nameController,
                label: 'HỌ VÀ TÊN *',
                hintText: 'Nguyễn Văn Quản Lý',
                validator: (val) => val == null || val.trim().isEmpty ? 'Bắt buộc' : null,
              ),
              const SizedBox(height: AppSpacing.sm),

              AppTextField(
                controller: _emailController,
                label: 'EMAIL ĐĂNG NHẬP *',
                hintText: 'manager2@cinema.vn',
                keyboardType: TextInputType.emailAddress,
                validator: (val) => val == null || val.trim().isEmpty ? 'Bắt buộc' : null,
              ),
              const SizedBox(height: AppSpacing.sm),

              AppTextField(
                controller: _passwordController,
                label: 'MẬT KHẨU TẠM THỜI *',
                hintText: '******',
                obscureText: true,
                validator: (val) => val == null || val.length < 6 ? 'Tối thiểu 6 ký tự' : null,
              ),
              const SizedBox(height: AppSpacing.sm),

              AppTextField(
                controller: _phoneController,
                label: 'SỐ ĐIỆN THOẠI',
                hintText: '0901234567',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppSpacing.sm),

              // Cinema dropdown
              Text('RẠP PHỤ TRÁCH *', style: AppTextStyles.captionUppercase.copyWith(color: AppColors.muted)),
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
                    value: _cinemaId,
                    dropdownColor: AppColors.canvasElevated,
                    isExpanded: true,
                    items: cinemas.map((c) => DropdownMenuItem(
                      value: c.id,
                      child: Text(c.name, style: const TextStyle(color: AppColors.ink)),
                    )).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _cinemaId = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              AppButton.primary(
                label: 'TẠO TÀI KHOẢN QUẢN LÝ',
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
