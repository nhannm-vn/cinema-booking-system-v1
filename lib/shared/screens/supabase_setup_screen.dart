import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Screen displayed when Supabase credentials are not configured.
/// Adheres 100% to DESIGN_TOKENS.md.
class SupabaseSetupScreen extends StatelessWidget {
  const SupabaseSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        title: Text(
          'HƯỚNG DẪN CẤU HÌNH HỆ THỐNG',
          style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.cloud_off_outlined,
                  size: 64,
                  color: AppColors.primary,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'CHƯA KẾT NỐI SUPABASE',
                  style: AppTextStyles.displayLg.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Ứng dụng cần SUPABASE_URL và SUPABASE_ANON_KEY để kết nối cơ sở dữ liệu và hoạt động.',
                  style: AppTextStyles.bodyMd.copyWith(color: AppColors.body),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Step 1 Card
                _buildStepCard(
                  step: 'BƯỚC 1',
                  title: 'CHẠY SCRIPT TẠO DATABASE (1 FILE DUY NHẤT)',
                  content:
                      'Mở Supabase Dashboard (supabase.com) > SQL Editor.\nCopy toàn bộ nội dung file SUPABASE_ALL_IN_ONE.sql ở thư mục gốc dự án và bấm RUN để tạo toàn bộ bảng, RLS, triggers và dữ liệu mẫu.',
                ),
                const SizedBox(height: AppSpacing.sm),

                // Step 2 Card
                _buildStepCard(
                  step: 'BƯỚC 2',
                  title: 'LẤY API KEYS TRÊN SUPABASE DASHBOARD',
                  content:
                      'Vào Project Settings > API:\n• Project URL: https://xyz.supabase.co\n• Project API Keys: anon (public)',
                ),
                const SizedBox(height: AppSpacing.sm),

                // Step 3 Card
                _buildStepCard(
                  step: 'BƯỚC 3',
                  title: 'ĐIỀN VÀO DỰ ÁN ĐỂ CHẠY',
                  content:
                      'Cách 1 (Nhanh nhất): Mở file lib/core/config/supabase_config.dart và điền vào _directUrl và _directAnonKey.\n\nCách 2: Chạy lệnh terminal:\nflutter run --dart-define=SUPABASE_URL=YOUR_URL --dart-define=SUPABASE_ANON_KEY=YOUR_KEY',
                ),
                const SizedBox(height: AppSpacing.lg),

                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.canvasElevated,
                    borderRadius: AppRadius.zeroRadius,
                    border: Border.all(color: AppColors.hairline, width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.info, size: 20),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          'Sau khi điền key, hãy khởi động lại ứng dụng (Hot Restart / R) để vào giao diện chính.',
                          style: AppTextStyles.caption.copyWith(color: AppColors.body),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepCard({
    required String step,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxs,
                  vertical: AppSpacing.xxxs,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: AppRadius.zeroRadius,
                ),
                child: Text(
                  step,
                  style: AppTextStyles.captionUppercase.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.titleSm.copyWith(
                    color: AppColors.ink,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            content,
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.body,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
