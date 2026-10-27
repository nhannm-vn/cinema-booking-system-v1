import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../controllers/auth_provider.dart';

/// S02 Register Screen.
/// References: ROLE_FLOWS.md Section 0, DESIGN_TOKENS.md, m2_plan.md Section 2.2
class RegisterScreen extends StatefulWidget {
  final String? redirectRoute;

  const RegisterScreen({
    super.key,
    this.redirectRoute,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      final destination = (widget.redirectRoute != null && widget.redirectRoute!.isNotEmpty)
          ? widget.redirectRoute!
          : AppRoutes.home;
      Navigator.pushNamedAndRemoveUntil(context, destination, (route) => false);
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ĐĂNG KÝ',
          style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'TẠO TÀI KHOẢN',
                  style: AppTextStyles.displayXl.copyWith(color: AppColors.ink),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Đăng ký để nhận ưu đãi và quản lý vé tiện lợi',
                  style: AppTextStyles.bodyMd.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: AppSpacing.md),

                // Error Banner
                if (auth.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: AppColors.canvasElevated,
                      borderRadius: AppRadius.smRadius,
                      border: Border.all(
                        color: AppColors.warning,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.warning,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Expanded(
                          child: Text(
                            auth.errorMessage!,
                            style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],

                // Full Name
                AppTextField(
                  key: const Key('register_name_field'),
                  label: 'HỌ VÀ TÊN',
                  hintText: 'Nguyễn Văn A',
                  controller: _nameController,
                  prefixIcon: const Icon(Icons.person_outline, color: AppColors.muted, size: 20),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập họ và tên';
                    }
                    if (value.trim().length < 2) {
                      return 'Họ và tên phải từ 2 ký tự trở lên';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xs),

                // Email
                AppTextField(
                  key: const Key('register_email_field'),
                  label: 'EMAIL',
                  hintText: 'example@cinema.vn',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined, color: AppColors.muted, size: 20),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập email';
                    }
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Email không hợp lệ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xs),

                // Phone Number
                AppTextField(
                  key: const Key('register_phone_field'),
                  label: 'SỐ ĐIỆN THOẠI',
                  hintText: '0901234567',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.muted, size: 20),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập số điện thoại';
                    }
                    final phoneRegex = RegExp(r'^0[0-9]{9}$');
                    if (!phoneRegex.hasMatch(value.trim())) {
                      return 'Số điện thoại phải gồm 10 chữ số bắt đầu bằng số 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xs),

                // Password
                AppTextField(
                  key: const Key('register_password_field'),
                  label: 'MẬT KHẨU',
                  hintText: 'Tối thiểu 6 ký tự',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.muted, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppColors.muted,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mật khẩu';
                    }
                    if (value.length < 6) {
                      return 'Mật khẩu phải từ 6 ký tự trở lên';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xs),

                // Confirm Password
                AppTextField(
                  key: const Key('register_confirm_password_field'),
                  label: 'NHẬP LẠI MẬT KHẨU',
                  hintText: 'Xác nhận lại mật khẩu',
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.muted, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppColors.muted,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirm = !_obscureConfirm;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng xác nhận mật khẩu';
                    }
                    if (value != _passwordController.text) {
                      return 'Mật khẩu xác nhận không khớp';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Primary CTA (Max 1 primary CTA per screen)
                AppButton.primary(
                  key: const Key('register_submit_button'),
                  label: 'TẠO TÀI KHOẢN',
                  width: double.infinity,
                  isLoading: auth.isLoading,
                  onPressed: _handleRegister,
                ),
                const SizedBox(height: AppSpacing.xs),

                // Already have account
                AppButton.text(
                  key: const Key('register_to_login_button'),
                  label: 'ĐÃ CÓ TÀI KHOẢN? ĐĂNG NHẬP',
                  width: double.infinity,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
