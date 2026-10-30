import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/models/app_user.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../auth/presentation/controllers/auth_provider.dart';
import '../../data/models/pricing_settings_model.dart';
import '../controllers/management_provider.dart';

/// Screen S26: Dynamic Pricing Settings with Interactive Formula Simulator.
/// References: BUSINESS_RULES.md Section 4, ROLE_FLOWS.md Section 5.5
class PricingSettingsScreen extends StatefulWidget {
  const PricingSettingsScreen({super.key});

  @override
  State<PricingSettingsScreen> createState() => _PricingSettingsScreenState();
}

class _PricingSettingsScreenState extends State<PricingSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Base Prices Controllers
  late TextEditingController _base2dController;
  late TextEditingController _base3dController;
  late TextEditingController _baseImaxController;

  // Seat Surcharges Controllers
  late TextEditingController _surchargeVipController;
  late TextEditingController _surchargeCoupleController;

  // Time Surcharges Controllers
  late TextEditingController _surchargeWeekendController;
  late TextEditingController _surchargePrimeController;
  late TextEditingController _primeStartHourController;
  late TextEditingController _primeEndHourController;

  // Interactive Simulator State
  String _simFormat = '2D';
  String _simSeatType = 'standard';
  bool _simIsWeekend = false;
  bool _simIsPrime = false;

  @override
  void initState() {
    super.initState();
    _base2dController = TextEditingController(text: '80000');
    _base3dController = TextEditingController(text: '100000');
    _baseImaxController = TextEditingController(text: '120000');
    _surchargeVipController = TextEditingController(text: '20000');
    _surchargeCoupleController = TextEditingController(text: '20000');
    _surchargeWeekendController = TextEditingController(text: '10000');
    _surchargePrimeController = TextEditingController(text: '10000');
    _primeStartHourController = TextEditingController(text: '18');
    _primeEndHourController = TextEditingController(text: '22');

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<ManagementProvider>();
      await provider.loadPricingSettings();
      final s = provider.pricingSettings;
      if (s != null && mounted) {
        setState(() {
          _base2dController.text = '${s.base2d}';
          _base3dController.text = '${s.base3d}';
          _baseImaxController.text = '${s.baseImax}';
          _surchargeVipController.text = '${s.surchargeVip}';
          _surchargeCoupleController.text = '${s.surchargeCouple}';
          _surchargeWeekendController.text = '${s.surchargeWeekend}';
          _surchargePrimeController.text = '${s.surchargePrime}';
          _primeStartHourController.text = '${s.primeStartHour}';
          _primeEndHourController.text = '${s.primeEndHour}';
        });
      }
    });
  }

  @override
  void dispose() {
    _base2dController.dispose();
    _base3dController.dispose();
    _baseImaxController.dispose();
    _surchargeVipController.dispose();
    _surchargeCoupleController.dispose();
    _surchargeWeekendController.dispose();
    _surchargePrimeController.dispose();
    _primeStartHourController.dispose();
    _primeEndHourController.dispose();
    super.dispose();
  }

  int _calculateSimulatedPrice() {
    int base = int.tryParse(_base2dController.text.trim()) ?? 80000;
    if (_simFormat == '3D') {
      base = int.tryParse(_base3dController.text.trim()) ?? 100000;
    } else if (_simFormat == 'IMAX') {
      base = int.tryParse(_baseImaxController.text.trim()) ?? 120000;
    }

    final int baseMult = _simSeatType == 'couple' ? 2 : 1;

    int seatExtra = 0;
    if (_simSeatType == 'vip') {
      seatExtra = int.tryParse(_surchargeVipController.text.trim()) ?? 20000;
    } else if (_simSeatType == 'couple') {
      seatExtra = int.tryParse(_surchargeCoupleController.text.trim()) ?? 20000;
    }

    final weekendExtra = _simIsWeekend
        ? (int.tryParse(_surchargeWeekendController.text.trim()) ?? 10000)
        : 0;
    final primeExtra = _simIsPrime
        ? (int.tryParse(_surchargePrimeController.text.trim()) ?? 10000)
        : 0;

    return (base * baseMult) + seatExtra + weekendExtra + primeExtra;
  }

  Future<void> _savePricingSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final settings = PricingSettingsModel(
      id: 1,
      base2d: int.parse(_base2dController.text.trim()),
      base3d: int.parse(_base3dController.text.trim()),
      baseImax: int.parse(_baseImaxController.text.trim()),
      surchargeVip: int.parse(_surchargeVipController.text.trim()),
      surchargeCouple: int.parse(_surchargeCoupleController.text.trim()),
      surchargeWeekend: int.parse(_surchargeWeekendController.text.trim()),
      surchargePrime: int.parse(_surchargePrimeController.text.trim()),
      primeStartHour: int.parse(_primeStartHourController.text.trim()),
      primeEndHour: int.parse(_primeEndHourController.text.trim()),
      updatedAt: DateTime.now(),
    );

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.canvasElevated,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.zeroRadius),
        title: Text(
          'XÁC NHẬN CẬP NHẬT BẢNG GIÁ'.toUpperCase(),
          style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
        ),
        content: Text(
          'Bảng giá mới sẽ được áp dụng cho toàn bộ các suất chiếu và giao dịch đặt vé phát sinh sau thời điểm này. Bạn có chắc chắn muốn lưu?',
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
              backgroundColor: AppColors.primary,
              elevation: 0,
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.zeroRadius),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final provider = context.read<ManagementProvider>();
              final success = await provider.savePricingSettings(settings);
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cập nhật bảng giá hệ thống thành công'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(provider.errorMessage ?? 'Cập nhật thất bại'),
                      backgroundColor: AppColors.warning,
                    ),
                  );
                }
              }
            },
            child: Text(
              'XÁC NHẬN LƯU'.toUpperCase(),
              style: AppTextStyles.button.copyWith(color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final isAdmin = user?.role == UserRole.admin;
    final provider = context.watch<ManagementProvider>();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        title: Text(
          'BẢNG GIÁ VÀ PHỤ THU ĐỘNG'.toUpperCase(),
          style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
        ),
        actions: [
          if (isAdmin)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: TextButton.icon(
                onPressed: _savePricingSettings,
                icon: const Icon(Icons.save_outlined, color: AppColors.primary, size: 20),
                label: Text(
                  'LƯU BẢNG GIÁ'.toUpperCase(),
                  style: AppTextStyles.button.copyWith(color: AppColors.primary),
                ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Center(
                child: AppBadge(label: 'CHỈ XEM', backgroundColor: AppColors.muted),
              ),
            ),
        ],
      ),
      body: _buildBody(context, provider, isAdmin),
    );
  }

  Widget _buildBody(BuildContext context, ManagementProvider provider, bool isAdmin) {
    if (provider.isLoading && provider.pricingSettings == null) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            SkeletonBox(width: double.infinity, height: 140),
            SizedBox(height: AppSpacing.md),
            SkeletonBox(width: double.infinity, height: 140),
          ],
        ),
      );
    }

    if (provider.errorMessage != null && provider.pricingSettings == null) {
      return Center(
        child: ErrorState(
          message: provider.errorMessage!,
          onRetry: () => provider.loadPricingSettings(),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Group 1: Base Prices
            _buildSectionCard(
              title: '1. GIÁ CƠ SỞ THEO ĐỊNH DẠNG (VND)',
              children: [
                _buildNumberField(_base2dController, 'Giá cơ sở 2D', enabled: isAdmin),
                const SizedBox(height: AppSpacing.sm),
                _buildNumberField(_base3dController, 'Giá cơ sở 3D', enabled: isAdmin),
                const SizedBox(height: AppSpacing.sm),
                _buildNumberField(_baseImaxController, 'Giá cơ sở IMAX', enabled: isAdmin),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // 2. Group 2: Seat Surcharges
            _buildSectionCard(
              title: '2. PHỤ THU THEO LOẠI GHẾ (VND)',
              children: [
                _buildNumberField(_surchargeVipController, 'Phụ thu ghế VIP', enabled: isAdmin),
                const SizedBox(height: AppSpacing.sm),
                _buildNumberField(_surchargeCoupleController, 'Phụ thu ghế Đôi (Couple)', enabled: isAdmin),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // 3. Group 3: Time Surcharges
            _buildSectionCard(
              title: '3. PHỤ THU THEO THỜI ĐIỂM (VND)',
              children: [
                _buildNumberField(_surchargeWeekendController, 'Phụ thu Cuối tuần (T6, T7, CN)', enabled: isAdmin),
                const SizedBox(height: AppSpacing.sm),
                _buildNumberField(_surchargePrimeController, 'Phụ thu Giờ vàng', enabled: isAdmin),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: _buildNumberField(_primeStartHourController, 'Giờ vàng từ (h)', enabled: isAdmin),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _buildNumberField(_primeEndHourController, 'Đến giờ (h)', enabled: isAdmin),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // 4. Interactive Simulator Card (Khối VÍ DỤ kiểm tra công thức)
            _buildSimulatorCard(),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.canvasElevated,
        borderRadius: AppRadius.zeroRadius,
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTextStyles.captionUppercase.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }

  Widget _buildNumberField(TextEditingController controller, String label, {bool enabled = true}) {
    return AppTextField(
      controller: controller,
      label: label.toUpperCase(),
      enabled: enabled,
      keyboardType: TextInputType.number,
      onChanged: (_) => setState(() {}),
      validator: (val) {
        if (val == null || val.trim().isEmpty) return 'Bắt buộc';
        final n = int.tryParse(val.trim());
        if (n == null || n < 0) return 'Phải là số nguyên >= 0';
        return null;
      },
    );
  }

  Widget _buildSimulatorCard() {
    final simTotal = _calculateSimulatedPrice();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.canvasElevated,
        borderRadius: AppRadius.zeroRadius,
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calculate_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'MÔ PHỎNG TÍNH GIÁ TRỰC TIẾP (TEST FORMULA)'.toUpperCase(),
                style: AppTextStyles.captionUppercase.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Selector: Format
          Text('Định dạng:', style: AppTextStyles.caption.copyWith(color: AppColors.muted)),
          const SizedBox(height: AppSpacing.xxs),
          Row(
            children: ['2D', '3D', 'IMAX'].map((fmt) {
              final isSel = _simFormat == fmt;
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: ChoiceChip(
                  label: Text(fmt),
                  selected: isSel,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.canvas,
                  onSelected: (_) => setState(() => _simFormat = fmt),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Selector: Seat Type
          Text('Loại ghế:', style: AppTextStyles.caption.copyWith(color: AppColors.muted)),
          const SizedBox(height: AppSpacing.xxs),
          Row(
            children: [
              _buildSimSeatChip('Thường', 'standard'),
              const SizedBox(width: AppSpacing.xs),
              _buildSimSeatChip('VIP', 'vip'),
              const SizedBox(width: AppSpacing.xs),
              _buildSimSeatChip('Đôi (Couple)', 'couple'),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          // Switches
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
              title: const Text('Áp dụng suất Cuối tuần (T6–CN)', style: TextStyle(color: AppColors.ink)),
              value: _simIsWeekend,
              activeThumbColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => _simIsWeekend = val),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
              title: const Text('Áp dụng khung Giờ vàng (18h–22h)', style: TextStyle(color: AppColors.ink)),
              value: _simIsPrime,
              activeThumbColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => _simIsPrime = val),
            ),
          ),

          const Divider(color: AppColors.hairline, height: AppSpacing.md),

          // Result Formula
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'GIÁ VÉ MÔ PHỎNG:',
                style: AppTextStyles.captionUppercase.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                CurrencyFormatter.format(simTotal),
                style: AppTextStyles.displayLg.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimSeatChip(String label, String value) {
    final isSel = _simSeatType == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSel,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.canvas,
      onSelected: (_) => setState(() => _simSeatType = value),
    );
  }
}
