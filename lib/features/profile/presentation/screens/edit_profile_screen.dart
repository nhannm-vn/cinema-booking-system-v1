import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../auth/presentation/controllers/auth_provider.dart';

/// S11B Edit Profile Screen.
/// References: ROLE_FLOWS.md Section 1, DESIGN_TOKENS.md, m3_plan.md Section 3.7
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _roleController;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _roleController = TextEditingController(text: user?.role.name.toUpperCase() ?? 'CUSTOMER');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.updateProfile(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.canvasElevated,
          content: Text(
            'Cập nhật hồ sơ thành công.'.toUpperCase(),
            style: AppTextStyles.bodySm.copyWith(color: AppColors.success),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.warning,
          content: Text(
            (auth.errorMessage ?? 'Không thể cập nhật hồ sơ.').toUpperCase(),
            style: AppTextStyles.bodySm.copyWith(color: AppColors.ink),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.ink),
        title: Text(
          'CHỈNH SỬA HỒ SƠ'.toUpperCase(),
          style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            AppTextField(
              controller: _nameController,
              label: 'Họ và tên',
              hintText: 'Nhập họ và tên',
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Vui lòng nhập họ và tên';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.sm),

            AppTextField(
              controller: _phoneController,
              label: 'Số điện thoại',
              hintText: 'Nhập số điện thoại (ví dụ: 0901234567)',
              keyboardType: TextInputType.phone,
              validator: (v) {
                if (v != null && v.trim().isNotEmpty) {
                  final regex = RegExp(r'^[0-9]{10}$');
                  if (!regex.hasMatch(v.trim())) {
                    return 'Số điện thoại phải có đúng 10 chữ số';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.sm),

            AppTextField(
              controller: _emailController,
              label: 'Email',
              enabled: false,
            ),
            const SizedBox(height: AppSpacing.xxxs),
            Text(
              'Email đăng nhập không thể thay đổi.',
              style: AppTextStyles.caption.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.sm),

            AppTextField(
              controller: _roleController,
              label: 'Vai trò tài khoản',
              enabled: false,
            ),
            const SizedBox(height: AppSpacing.lg),

            AppButton.primary(
              label: 'LƯU THAY ĐỔI',
              width: double.infinity,
              isLoading: auth.isLoading,
              onPressed: _saveProfile,
            ),
          ],
        ),
      ),
    );
  }
}
