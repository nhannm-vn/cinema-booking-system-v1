import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/app_user.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/notification_badge.dart';
import '../../../../shared/widgets/qr_scanner_view.dart';
import '../../../../shared/widgets/result_sheet.dart';
import '../../../../shared/widgets/staff_bottom_nav.dart';
import '../../../auth/presentation/controllers/auth_provider.dart';
import '../controllers/checkin_provider.dart';

/// S18: Ticket Check-in Screen (/staff/checkin)
/// References: ROLE_FLOWS.md Section 3.1 & BUSINESS_RULES.md Section 8 & m4_plan.md Section 3.1
class TicketCheckinScreen extends StatefulWidget {
  final bool forceDesktopFallback;

  const TicketCheckinScreen({
    super.key,
    this.forceDesktopFallback = false,
  });

  @override
  State<TicketCheckinScreen> createState() => _TicketCheckinScreenState();
}

class _TicketCheckinScreenState extends State<TicketCheckinScreen> {
  final TextEditingController _manualInputController = TextEditingController();

  bool get _isDesktop =>
      widget.forceDesktopFallback ||
      (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.windows ||
              defaultTargetPlatform == TargetPlatform.linux ||
              defaultTargetPlatform == TargetPlatform.macOS));

  @override
  void dispose() {
    _manualInputController.dispose();
    super.dispose();
  }

  Future<void> _handleCode(BuildContext context, String code) async {
    final trimmed = code.trim().toUpperCase();
    if (trimmed.isEmpty) return;

    final provider = context.read<CheckinProvider>();
    final result = await provider.checkIn(trimmed);

    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return ResultSheet(
          isValid: result.isSuccess,
          errorMessage: result.message,
          movieTitle: result.movieTitle,
          roomName: result.roomName,
          showtime: result.showtimeStart,
          seats: result.seatsSummary,
          foods: result.foodsSummary,
          ageRating: result.ageRating,
          onConfirm: () {
            Navigator.pop(sheetContext);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.success,
                content: Text(
                  'ĐÃ XÁC NHẬN CHO KHÁCH VÀO RẠP',
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
            provider.resetScan();
          },
          onDismiss: () {
            Navigator.pop(sheetContext);
            provider.resetScan();
          },
        );
      },
    );
  }

  void _showManualInputDialog(BuildContext context) {
    _manualInputController.clear();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'NHẬP MÃ VÉ THỦ CÔNG',
                    style: AppTextStyles.titleSm.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Nhập mã đặt vé 8 ký tự được in trên vé hoặc ứng dụng khách hàng',
                    style: AppTextStyles.caption.copyWith(color: AppColors.body),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    key: const Key('manual_code_input'),
                    controller: _manualInputController,
                    label: 'MÃ ĐẶT VÉ',
                    hintText: 'VD: AB12CD34',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton.primary(
                    key: const Key('manual_code_submit'),
                    label: 'KIỂM TRA VÉ',
                    onPressed: () {
                      final input = _manualInputController.text.trim();
                      if (input.isNotEmpty) {
                        Navigator.pop(sheetContext);
                        _handleCode(context, input);
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cinemaName = auth.currentUser?.cinemaId?.toUpperCase() ?? 'RẠP CHIẾU';

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
              'SOÁT VÉ VÀO RẠP',
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
            key: const Key('ticket_checkin_manual_input_appbar_btn'),
            tooltip: 'Nhập mã tay',
            icon: const Icon(Icons.keyboard_outlined, color: AppColors.ink),
            onPressed: () => _showManualInputDialog(context),
          ),
          NotificationBadge(
            unreadCount: 0,
            onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
          ),
          const SizedBox(width: AppSpacing.xxs),
        ],
      ),
      body: _isDesktop ? _buildDesktopFallback(context) : _buildCameraScanner(context),
      bottomNavigationBar: auth.currentUser?.role == UserRole.manager || auth.currentUser?.role == UserRole.admin
          ? null
          : const StaffBottomNav(currentIndex: 0),
    );
  }

  Widget _buildCameraScanner(BuildContext context) {
    return QrScannerView(
      onScan: (code) => _handleCode(context, code),
      onManualInput: () => _showManualInputDialog(context),
    );
  }

  Widget _buildDesktopFallback(BuildContext context) {
    const double scanBoxSize = 260.0;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: scanBoxSize,
              height: scanBoxSize,
              decoration: BoxDecoration(
                color: AppColors.canvasElevated,
                border: Border.all(color: AppColors.primary, width: 2),
                borderRadius: BorderRadius.zero,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.qr_code_scanner,
                    size: 80,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                    child: Text(
                      'CAMERA KHÔNG KHẢ DỤNG TRÊN THIẾT BỊ NÀY',
                      style: AppTextStyles.captionUppercase,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Sử dụng chức năng nhập mã tay để kiểm tra vé',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.body),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: scanBoxSize,
              child: AppButton.primary(
                key: const Key('ticket_checkin_manual_input_btn'),
                label: 'NHẬP MÃ TAY',
                onPressed: () => _showManualInputDialog(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
