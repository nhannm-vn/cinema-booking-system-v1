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
import '../../../../shared/widgets/status_badge.dart';
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final auth = context.read<AuthProvider>();
          final cinemaId = auth.currentUser?.cinemaId ?? 'cn_q1';
          context.read<ManagementProvider>().loadEmployees(cinemaId);
        }
      });
    }
  }

  void _showAddStaffModal(BuildContext context, String cinemaId) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String selectedRole = 'staff';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final mgmt = modalCtx.watch<ManagementProvider>();

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

                        // Role selection
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
                              cinemaId: cinemaId,
                            );

                            if (ok && sheetContext.mounted) {
                              Navigator.pop(sheetContext);
                              await mgmt.loadEmployees(cinemaId);
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
      await mgmt.toggleUserLock(employee.id, willLock, cinemaId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text('ĐÃ $actionLabel TÀI KHOẢN THÀNH CÔNG'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cinemaId = auth.currentUser?.cinemaId ?? 'cn_q1';
    final cinemaName = cinemaId.toUpperCase();
    final mgmt = context.watch<ManagementProvider>();

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
              'QUẢN LÝ NHÂN VIÊN',
              style: AppTextStyles.titleSm.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              cinemaName,
              style: AppTextStyles.caption.copyWith(color: AppColors.primary),
            ),
          ],
        ),
        actions: [
          IconButton(
            key: const Key('add_staff_appbar_btn'),
            tooltip: 'Thêm nhân viên',
            icon: const Icon(Icons.person_add_alt_1_outlined, color: AppColors.primary),
            onPressed: () => _showAddStaffModal(context, cinemaId),
          ),
          NotificationBadge(
            unreadCount: 0,
            onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
          ),
          const SizedBox(width: AppSpacing.xxs),
        ],
      ),
      body: _buildBody(context, mgmt, cinemaId),
      floatingActionButton: FloatingActionButton(
        key: const Key('add_staff_fab'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: const Icon(Icons.add, color: AppColors.ink),
        onPressed: () => _showAddStaffModal(context, cinemaId),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ManagementProvider mgmt, String cinemaId) {
    if (mgmt.isLoading && mgmt.employees.isEmpty) {
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

    if (mgmt.errorMessage != null && mgmt.employees.isEmpty) {
      return Center(
        child: ErrorState(
          message: mgmt.errorMessage!,
          onRetry: () => mgmt.loadEmployees(cinemaId),
        ),
      );
    }

    if (mgmt.employees.isEmpty) {
      return Center(
        child: EmptyState(
          title: 'CHƯA CÓ NHÂN VIÊN',
          message: 'Rạp chưa có nhân viên nào. Nhấn THÊM NHÂN VIÊN để bắt đầu.',
          icon: Icons.people_outline,
          actionLabel: 'THÊM NHÂN VIÊN',
          onAction: () => _showAddStaffModal(context, cinemaId),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.xs),
      itemCount: mgmt.employees.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (context, index) {
        final employee = mgmt.employees[index];
        return _buildEmployeeCard(context, employee, cinemaId);
      },
    );
  }

  Widget _buildEmployeeCard(BuildContext context, AppUser employee, String cinemaId) {
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
              employee.isManager ? Icons.manage_accounts : Icons.person,
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
                        employee.fullName.isNotEmpty ? employee.fullName : 'Nhân viên',
                        style: AppTextStyles.titleSm.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    AppBadge(label: employee.role.name.toUpperCase()),
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
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    StatusBadge(
                      status: employee.isLocked ? 'cancelled' : 'active',
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
