import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/routes/route_guards.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/app_user.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../controllers/auth_provider.dart';

/// S01 Login Screen.
/// References: ROLE_FLOWS.md Section 0, DESIGN_TOKENS.md, m2_plan.md Section 2.1
class LoginScreen extends StatefulWidget {
  final String? redirectRoute;

  const LoginScreen({
    super.key,
    this.redirectRoute,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _lockedError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _lockedError = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.signIn(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      final user = auth.currentUser;
      if (user != null && user.isLocked) {
        setState(() {
          _lockedError = 'Tài khoản của bạn đã bị khóa. Vui lòng liên hệ ban quản lý.';
        });
        await auth.signOut();
        return;
      }

      final destination = _resolveDestination(user);
      Navigator.pushReplacementNamed(context, destination);
    }
  }

  String _resolveDestination(AppUser? user) {
    if (widget.redirectRoute != null &&
        widget.redirectRoute!.isNotEmpty &&
        (user == null || user.role == UserRole.customer)) {
      return widget.redirectRoute!;
    }
    if (user != null && user.role == UserRole.admin) {
      return AppRoutes.managementHome;
    }
    return RouteGuards.getInitialRoute(user);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final errorMessage = _lockedError ?? auth.errorMessage;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Branding Header
                  Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.movie_outlined,
                          color: AppColors.primary,
                          size: 48,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'CINEMA STAR',
                          style: AppTextStyles.captionUppercase.copyWith(
                            color: AppColors.muted,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          'ĐĂNG NHẬP',
                          style: AppTextStyles.displayXl.copyWith(
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Error Banner
                  if (errorMessage != null) ...[
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
                              errorMessage,
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

                  // Email Input
                  AppTextField(
                    key: const Key('login_email_field'),
                    label: 'EMAIL',
                    hintText: 'example@cinema.vn',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: AppColors.muted,
                      size: 20,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập email';
                      }
                      final emailRegex = RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      );
                      if (!emailRegex.hasMatch(value.trim())) {
                        return 'Email không hợp lệ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Password Input
                  AppTextField(
                    key: const Key('login_password_field'),
                    label: 'MẬT KHẨU',
                    hintText: 'Nhập mật khẩu',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: AppColors.muted,
                      size: 20,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
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
                  const SizedBox(height: AppSpacing.md),

                  // Primary Submit Button (Max 1 primary CTA)
                  AppButton.primary(
                    key: const Key('login_submit_button'),
                    label: 'ĐĂNG NHẬP',
                    width: double.infinity,
                    isLoading: auth.isLoading,
                    onPressed: _handleLogin,
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Outline Register Link
                  AppButton.outline(
                    key: const Key('login_to_register_button'),
                    label: 'CHƯA CÓ TÀI KHOẢN? ĐĂNG KÝ',
                    width: double.infinity,
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.register);
                    },
                  ),
                  const SizedBox(height: AppSpacing.xxs),

                  // Continue as Guest Text Button
                  AppButton.text(
                    key: const Key('login_guest_button'),
                    label: 'TIẾP TỤC VỚI TƯ CÁCH KHÁCH',
                    width: double.infinity,
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, AppRoutes.home);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
