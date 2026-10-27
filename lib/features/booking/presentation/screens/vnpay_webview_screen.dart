import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';

/// S08B VNPay Sandbox WebView Screen.
/// References: ROLE_FLOWS.md Section 1, TECH_STACK.md Section 8, m3_plan.md Section 3.5
class VNPayWebviewScreen extends StatefulWidget {
  final String paymentUrl;
  final String bookingCode;
  final String? txnRef;

  const VNPayWebviewScreen({
    super.key,
    required this.paymentUrl,
    required this.bookingCode,
    this.txnRef,
  });

  @override
  State<VNPayWebviewScreen> createState() => _VNPayWebviewScreenState();
}

class _VNPayWebviewScreenState extends State<VNPayWebviewScreen> {
  WebViewController? _webViewController;
  bool _isLoading = true;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    try {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              if (mounted) setState(() => _isLoading = true);
              _inspectUrl(url);
            },
            onPageFinished: (String url) {
              if (mounted) setState(() => _isLoading = false);
              _inspectUrl(url);
            },
            onNavigationRequest: (NavigationRequest request) {
              if (_inspectUrl(request.url)) {
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
          ),
        );

      if (widget.paymentUrl.isNotEmpty) {
        controller.loadRequest(Uri.parse(widget.paymentUrl));
      }
      _webViewController = controller;
    } catch (_) {
      _webViewController = null;
      _isLoading = false;
    }
  }

  bool _inspectUrl(String url) {
    if (_isFinished) return true;

    // Detect payment success redirect
    if (url.startsWith('cinemaapp://payment-success') || url.contains('vnp_ResponseCode=00')) {
      _isFinished = true;
      _handlePaymentSuccess();
      return true;
    }

    // Detect payment cancel or failure redirect
    if (url.startsWith('cinemaapp://payment-failed') ||
        (url.contains('vnp_ResponseCode=') && !url.contains('vnp_ResponseCode=00'))) {
      _isFinished = true;
      _handlePaymentFailed();
      return true;
    }

    return false;
  }

  void _handlePaymentSuccess() {
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.ticketSuccess,
      (route) => route.settings.name == AppRoutes.home,
      arguments: {'bookingCode': widget.bookingCode},
    );
  }

  void _handlePaymentFailed() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.canvasElevated,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.zeroRadius),
        title: Text(
          'THANH TOÁN THẤT BẠI'.toUpperCase(),
          style: AppTextStyles.titleMd.copyWith(color: AppColors.ink),
        ),
        content: Text(
          'Giao dịch thanh toán không thành công hoặc đã bị hủy. Quý khách có thể thử lại nếu thời gian giữ ghế vẫn còn.',
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.body),
        ),
        actions: [
          AppButton.primary(
            label: 'QUAY LẠI ĐƠN HÀNG',
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.ink),
        title: Text(
          'CỔNG THANH TOÁN VNPAY'.toUpperCase(),
          style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
        ),
      ),
      body: Stack(
        children: [
          if (_webViewController != null)
            WebViewWidget(controller: _webViewController!)
          else
            _buildFallbackView(),

          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFallbackView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.payment, size: 64, color: AppColors.primary),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'MÔ PHỎNG THANH TOÁN VNPAY SANDBOX'.toUpperCase(),
              style: AppTextStyles.titleMd.copyWith(color: AppColors.ink),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Mã đặt vé: ${widget.bookingCode}',
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton.primary(
              label: 'XÁC NHẬN THANH TOÁN THÀNH CÔNG',
              onPressed: _handlePaymentSuccess,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton.outline(
              label: 'HỦY GIAO DỊCH',
              onPressed: _handlePaymentFailed,
            ),
          ],
        ),
      ),
    );
  }
}
