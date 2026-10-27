import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import 'app_button.dart';

/// Camera viewfinder for scanning tickets following DESIGN_TOKENS.md & BUSINESS_RULES.md Section 8
class QrScannerView extends StatefulWidget {
  final ValueChanged<String> onScan;
  final VoidCallback? onManualInput;

  const QrScannerView({
    super.key,
    required this.onScan,
    this.onManualInput,
  });

  @override
  State<QrScannerView> createState() => _QrScannerViewState();
}

class _QrScannerViewState extends State<QrScannerView> {
  final MobileScannerController _controller = MobileScannerController();
  bool _hasDetected = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (_hasDetected) return;
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final code = barcode.rawValue;
      if (code != null && code.isNotEmpty) {
        setState(() => _hasDetected = true);
        widget.onScan(code.trim());
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const double scanBoxSize = 260.0;

    return Stack(
      children: [
        // Camera stream
        MobileScanner(
          controller: _controller,
          onDetect: _handleBarcode,
        ),

        // Darkened overlay with cutout
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            AppColors.canvas.withValues(alpha: 0.6),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Center(
                child: Container(
                  width: scanBoxSize,
                  height: scanBoxSize,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.zero,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Red primary viewfinder border
        Center(
          child: Container(
            width: scanBoxSize,
            height: scanBoxSize,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary, width: 2),
            ),
          ),
        ),

        // Bottom manual input option
        Positioned(
          bottom: AppSpacing.lg,
          left: AppSpacing.xs,
          right: AppSpacing.xs,
          child: Column(
            children: [
              Text(
                'Hướng camera về phía mã QR trên vé của khách',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.ink),
                textAlign: TextAlign.center,
              ),
              if (widget.onManualInput != null) ...[
                const SizedBox(height: AppSpacing.sm),
                AppButton.outline(
                  label: 'NHẬP MÃ TAY',
                  onPressed: widget.onManualInput!,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
