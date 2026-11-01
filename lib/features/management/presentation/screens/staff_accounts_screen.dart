import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/routes/app_router.dart';
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
import '../../../../shared/widgets/notification_badge.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../auth/presentation/controllers/auth_provider.dart';
import '../controllers/management_provider.dart';

/// S23: Staff Account Management Screen (/management/employees)
/// References: ROLE_FLOWS.md Section 4 & 5, BUSINESS_RULES.md Section 2, m4_plan.md Section 3.5
class StaffAccountsScreen extends StatefulWidget {
  const StaffAccountsScreen({super.key});

  @override
  State<StaffAccountsScreen> createState() => _StaffAccountsScreenState();
}

class _StaffAccountsScreenState extends State<StaffAccountsScreen> {
  bool _initialized = false;
  String _activeCinemaId = 'cn_q1';
  String _selectedRoleFilter = 'all';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final auth = context.read<AuthProvider>();
          final user = auth.currentUser;
          final isAdmin = user?.role == UserRole.admin;
          if (user?.cinemaId != null && user!.cinemaId!.isNotEmpty) {
            _activeCinemaId = user.cinemaId!;
          } else if (isAdmin) {
            _activeCinemaId = 'all';
          }
          final mgmt = context.read<ManagementProvider>();
          if (isAdmin) {
            mgmt.loadCinemas();
          }
          mgmt.loadEmployees(_activeCinemaId);
        }
      });
    }
  }

  void _showAddStaffModal(BuildContext context, String initialCinemaId) {
    final mgmtInstance = context.read<ManagementProvider>();
    final initialCinema = (initialCinemaId == 'all' || initialCinemaId.isEmpty)
        ? (mgmtInstance.cinemas.firstOrNull?.id ?? 'cn_q1')
        : initialCinemaId;
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String selectedRole = 'staff';
    String selectedCinemaId = initialCinema;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final mgmt = modalCtx.watch<ManagementProvider>();
            final auth = modalCtx.watch<AuthProvider>();
            final isAdmin = auth.currentUser?.role == UserRole.admin;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.canvasElevated,
                  borderRadius: AppRadius.sheetRadius,
                ),
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: SafeArea(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'THÊM TÀI KHOẢN NHÂN SỰ',
                          style: AppTextStyles.titleSm.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          'Tài khoản sẽ được tạo tự động qua Edge Function và phân quyền theo rạp',
                          style: AppTextStyles.caption.copyWith(color: AppColors.body),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        if (isAdmin && mgmt.cinemas.isNotEmpty) ...[
                          Text(
                            'CHỌN RẠP CÔNG TÁC',
                            style: AppTextStyles.captionUppercase.copyWith(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: mgmt.cinemas.map((c) {
                                final isSel = selectedCinemaId == c.id;
                                return Padding(
                                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                                  child: ChoiceChip(
                                    label: Text(c.name.toUpperCase()),
                                    selected: isSel,
                                    selectedColor: AppColors.primary,
                                    backgroundColor: AppColors.canvas,
                                    onSelected: (val) {
                                      if (val) setModalState(() => selectedCinemaId = c.id);
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                        ],

                        AppTextField(
                          key: const Key('add_staff_name_field'),
                          controller: nameCtrl,
                          label: 'HỌ VÀ TÊN',
                          hintText: 'VD: Nguyễn Văn A',
                        ),
                        const SizedBox(height: AppSpacing.xs),

                        AppTextField(
                          key: const Key('add_staff_email_field'),
                          controller: emailCtrl,
                          label: 'EMAIL ĐĂNG NHẬP',
                          hintText: 'staff@cinema.vn',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: AppSpacing.xs),

                        AppTextField(
                          key: const Key('add_staff_phone_field'),
                          controller: phoneCtrl,
                          label: 'SỐ ĐIỆN THOẠI',
                          hintText: '0901234567',
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: AppSpacing.xs),

                        AppTextField(
                          key: const Key('add_staff_password_field'),
                          controller: passCtrl,
                          label: 'MẬT KHẨU TẠM',
                          hintText: 'Tối thiểu 6 ký tự',
                          obscureText: true,
                        ),
                        const SizedBox(height: AppSpacing.xs),

                        // Role selection: Manager chỉ có quyền tạo nhân viên (STAFF)
                        if (isAdmin) ...[
                          Row(
                            children: [
                              Text(
                                'VAI TRÒ: ',
                                style: AppTextStyles.captionUppercase.copyWith(
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              ChoiceChip(
                                label: Text('STAFF', style: AppTextStyles.captionUppercase),
                                selected: selectedRole == 'staff',
                                selectedColor: AppColors.primary,
                                backgroundColor: AppColors.canvas,
                                onSelected: (val) {
                                  if (val) setModalState(() => selectedRole = 'staff');
                                },
                              ),
                              const SizedBox(width: AppSpacing.xxs),
                              ChoiceChip(
                                label: Text('MANAGER', style: AppTextStyles.captionUppercase),
                                selected: selectedRole == 'manager',
                                selectedColor: AppColors.primary,
                                backgroundColor: AppColors.canvas,
                                onSelected: (val) {
                                  if (val) setModalState(() => selectedRole = 'manager');
                                },
                              ),
                            ],
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Text(
                                'VAI TRÒ: ',
                                style: AppTextStyles.captionUppercase.copyWith(
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              const AppBadge(
                                label: 'STAFF (NHÂN VIÊN)',
                                backgroundColor: AppColors.primary,
                                textColor: AppColors.ink,
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),

                        AppButton.primary(
                          key: const Key('add_staff_submit_btn'),
                          label: 'TẠO TÀI KHOẢN',
                          isLoading: mgmt.isLoading,
                          onPressed: () async {
                            final name = nameCtrl.text.trim();
                            final email = emailCtrl.text.trim();
                            final phone = phoneCtrl.text.trim();
                            final pass = passCtrl.text.trim();

                            if (name.isEmpty || email.isEmpty || pass.length < 6) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: AppColors.warning,
                                  content: Text('Vui lòng điền đủ thông tin (Mật khẩu >= 6 ký tự)'),
                                ),
                              );
                              return;
                            }

                            final ok = await mgmt.createStaffAccount(
                              email: email,
                              password: pass,
                              fullName: name,
                              phone: phone,
                              role: selectedRole,
                              cinemaId: selectedCinemaId,
                            );

                            if (ok && sheetContext.mounted) {
                              Navigator.pop(sheetContext);
                              await mgmt.loadEmployees(_activeCinemaId);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    backgroundColor: AppColors.success,
                                    content: Text('TẠO TÀI KHOẢN NHÂN SỰ THÀNH CÔNG'),
                                  ),
                                );
                              }
                            } else if (mgmt.errorMessage != null && sheetContext.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppColors.warning,
                                  content: Text(mgmt.errorMessage!),
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        AppButton.text(
                          label: 'HỦY',
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmToggleLock(
    BuildContext context,
    AppUser employee,
    String cinemaId,
  ) async {
    final auth = context.read<AuthProvider>();
    if (auth.currentUser?.id == employee.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.warning,
          content: Text('BẠN KHÔNG THỂ TỰ KHÓA TÀI KHOẢN CỦA CHÍNH MÌNH'),
        ),
      );
      return;
    }
    if (auth.currentUser?.role == UserRole.manager && employee.role == UserRole.manager) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.warning,
          content: Text('QUẢN LÝ KHÔNG CÓ QUYỀN KHÓA TÀI KHOẢN QUẢN LÝ KHÁC'),
        ),
      );
      return;
    }

    final mgmt = context.read<ManagementProvider>();
    final willLock = !employee.isLocked;
    final actionLabel = willLock ? 'KHÓA' : 'MỞ KHÓA';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.canvasElevated,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          '$actionLabel TÀI KHOẢN',
          style: AppTextStyles.titleSm.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Bạn có chắc chắn muốn $actionLabel tài khoản "${employee.fullName}" (${employee.email ?? employee.id})?',
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.body),
        ),
        actions: [
          AppButton.text(
            label: 'HỦY',
            onPressed: () => Navigator.pop(dialogCtx, false),
          ),
          AppButton.primary(
            label: 'XÁC NHẬN',
            onPressed: () => Navigator.pop(dialogCtx, true),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await mgmt.toggleUserLock(employee.id, willLock, cinemaId);
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.success,
              content: Text('ĐÃ $actionLabel TÀI KHOẢN THÀNH CÔNG'),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.warning,
              content: Text(mgmt.errorMessage ?? 'KHÔNG THỂ $actionLabel TÀI KHOẢN'),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.currentUser?.role == UserRole.admin;
    final mgmt = context.watch<ManagementProvider>();
    final selectedCinema = mgmt.cinemas.where((c) => c.id == _activeCinemaId).firstOrNull;
    final String cinemaSubtitle;
    if (isAdmin && _activeCinemaId == 'all') {
      cinemaSubtitle = 'TẤT CẢ RẠP (QUẬN 1 & TÂN BÌNH)';
    } else {
      cinemaSubtitle = selectedCinema != null ? selectedCinema.name.toUpperCase() : _activeCinemaId.toUpperCase();
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAdmin ? 'QUẢN LÝ NHÂN SỰ' : 'QUẢN LÝ NHÂN VIÊN',
              style: AppTextStyles.titleSm.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              cinemaSubtitle,
              style: AppTextStyles.caption.copyWith(color: AppColors.primary),
            ),
          ],
        ),
        actions: [
          IconButton(
            key: const Key('add_staff_appbar_btn'),
            tooltip: 'Thêm nhân viên',
            icon: const Icon(Icons.person_add_alt_1_outlined, color: AppColors.primary),
            onPressed: () => _showAddStaffModal(context, _activeCinemaId),
          ),
          NotificationBadge(
            unreadCount: 0,
            onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
          ),
          const SizedBox(width: AppSpacing.xxs),
        ],
      ),
      body: Column(
        children: [
          if (isAdmin && mgmt.cinemas.isNotEmpty) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: ChoiceChip(
                      label: Text(
                        'TẤT CẢ RẠP',
                        style: AppTextStyles.caption.copyWith(
                          color: _activeCinemaId == 'all' ? AppColors.ink : AppColors.muted,
                          fontWeight: _activeCinemaId == 'all' ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      selected: _activeCinemaId == 'all',
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.canvasElevated,
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.zeroRadius,
                        side: BorderSide(color: AppColors.hairline),
                      ),
                      elevation: 0,
                      pressElevation: 0,
                      onSelected: (_) {
                        setState(() => _activeCinemaId = 'all');
                        mgmt.loadEmployees('all');
                      },
                    ),
                  ),
                  ...mgmt.cinemas.map((cinema) {
                    final isSelected = _activeCinemaId == cinema.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: ChoiceChip(
                        label: Text(
                          cinema.name.toUpperCase(),
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
                          setState(() => _activeCinemaId = cinema.id);
                          mgmt.loadEmployees(cinema.id);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xxs,
              ),
              child: Row(
                children: [
                  Text(
                    'VAI TRÒ: ',
                    style: AppTextStyles.captionUppercase.copyWith(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  ChoiceChip(
                    label: Text('TẤT CẢ', style: AppTextStyles.captionUppercase),
                    selected: _selectedRoleFilter == 'all',
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.canvasElevated,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.zeroRadius,
                      side: BorderSide(color: AppColors.hairline),
                    ),
                    elevation: 0,
                    pressElevation: 0,
                    onSelected: (val) {
                      if (val) setState(() => _selectedRoleFilter = 'all');
                    },
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  ChoiceChip(
                    label: Text('MANAGER', style: AppTextStyles.captionUppercase),
                    selected: _selectedRoleFilter == 'manager',
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.canvasElevated,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.zeroRadius,
                      side: BorderSide(color: AppColors.hairline),
                    ),
                    elevation: 0,
                    pressElevation: 0,
                    onSelected: (val) {
                      if (val) setState(() => _selectedRoleFilter = 'manager');
                    },
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  ChoiceChip(
                    label: Text('STAFF', style: AppTextStyles.captionUppercase),
                    selected: _selectedRoleFilter == 'staff',
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.canvasElevated,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.zeroRadius,
                      side: BorderSide(color: AppColors.hairline),
                    ),
                    elevation: 0,
                    pressElevation: 0,
                    onSelected: (val) {
                      if (val) setState(() => _selectedRoleFilter = 'staff');
                    },
                  ),
                ],
              ),
            ),
          ],
          Expanded(child: _buildBody(context, mgmt, _activeCinemaId)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('add_staff_fab'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: const Icon(Icons.add, color: AppColors.ink),
        onPressed: () => _showAddStaffModal(context, _activeCinemaId),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ManagementProvider mgmt, String cinemaId) {
    final auth = context.watch<AuthProvider>();
    final isManager = auth.currentUser?.role == UserRole.manager;

    List<AppUser> displayEmployees;
    if (isManager) {
      // Manager chỉ quản lý nhân viên (staff) trong rạp của mình
      displayEmployees = mgmt.employees
          .where((e) => e.role == UserRole.staff && e.id != auth.currentUser?.id)
          .toList();
    } else {
      // Admin quản lý cả Manager và Staff của các rạp
      var list = mgmt.employees.where((e) => e.id != auth.currentUser?.id);
      if (_selectedRoleFilter == 'manager') {
        list = list.where((e) => e.role == UserRole.manager);
      } else if (_selectedRoleFilter == 'staff') {
        list = list.where((e) => e.role == UserRole.staff);
      }
      displayEmployees = list.toList();
    }

    if (mgmt.isLoading && displayEmployees.isEmpty) {
      return ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.xs),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
        itemBuilder: (_, __) => const SkeletonBox(
          width: double.infinity,
          height: 100,
        ),
      );
    }

    if (mgmt.errorMessage != null && displayEmployees.isEmpty) {
      return Center(
        child: ErrorState(
          message: mgmt.errorMessage!,
          onRetry: () => mgmt.loadEmployees(cinemaId),
        ),
      );
    }

    if (displayEmployees.isEmpty) {
      return Center(
        child: EmptyState(
          title: isManager ? 'CHƯA CÓ NHÂN VIÊN' : 'CHƯA CÓ NHÂN SỰ',
          message: isManager
              ? 'Rạp chưa có nhân viên nào. Nhấn THÊM NHÂN VIÊN để bắt đầu.'
              : 'Chưa có nhân sự nào phù hợp với bộ lọc. Nhấn THÊM để tạo mới.',
          icon: Icons.people_outline,
          actionLabel: isManager ? 'THÊM NHÂN VIÊN' : 'THÊM NHÂN SỰ',
          onAction: () => _showAddStaffModal(context, cinemaId),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.xs),
      itemCount: displayEmployees.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (context, index) {
        final employee = displayEmployees[index];
        return _buildEmployeeCard(context, employee, cinemaId);
      },
    );
  }

  String _getCinemaName(ManagementProvider mgmt, String? cinemaId) {
    if (cinemaId == null) return '';
    final cinema = mgmt.cinemas.where((c) => c.id == cinemaId).firstOrNull;
    return cinema != null ? cinema.name.toUpperCase() : cinemaId.toUpperCase();
  }

  Widget _buildEmployeeCard(BuildContext context, AppUser employee, String cinemaId) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.currentUser?.role == UserRole.admin;
    final mgmt = context.watch<ManagementProvider>();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.canvasElevated,
        border: Border.all(color: AppColors.hairline, width: 1),
        borderRadius: BorderRadius.zero,
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AppColors.canvas,
            radius: 20,
            child: Icon(
              employee.role == UserRole.manager ? Icons.manage_accounts : Icons.person,
              color: AppColors.primary,
            ),
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
                        employee.fullName.isNotEmpty ? employee.fullName : 'Nhân sự',
                        style: AppTextStyles.titleSm.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    AppBadge(
                      label: employee.role.name.toUpperCase(),
                      backgroundColor: employee.role == UserRole.manager ? AppColors.info : AppColors.hairline,
                      textColor: AppColors.ink,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxxs),
                Text(
                  employee.email ?? employee.phone ?? employee.id,
                  style: AppTextStyles.caption.copyWith(color: AppColors.body),
                ),
                if (employee.phone != null && employee.phone!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'SĐT: ${employee.phone}',
                    style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                  ),
                ],
                if (isAdmin && employee.cinemaId != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'RẠP: ${_getCinemaName(mgmt, employee.cinemaId)}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppBadge(
                      label: employee.isLocked ? 'ĐÃ KHÓA' : 'ĐANG HOẠT ĐỘNG',
                      backgroundColor: employee.isLocked ? AppColors.warning : AppColors.success,
                      textColor: AppColors.ink,
                    ),
                    SizedBox(
                      height: 32,
                      child: AppButton.outline(
                        key: Key('toggle_lock_${employee.id}'),
                        label: employee.isLocked ? 'MỞ KHÓA' : 'KHÓA',
                        onPressed: () => _confirmToggleLock(context, employee, cinemaId),
                      ),
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
