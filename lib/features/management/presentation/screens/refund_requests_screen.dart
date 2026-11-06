import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../data/models/refund_request_model.dart';
import '../controllers/refund_requests_provider.dart';

/// Tài khoản SePay sandbox dùng để CHI tiền hoàn vé.
const String kRefundSourceAccount = '0000000001';

/// Admin: danh sách yêu cầu hoàn vé của khách.
/// Admin mở chi tiết → tạo giao dịch "Tiền ra" trên SePay sandbox từ STK 0000000001
/// đúng số tiền + nội dung mã vé → webhook gọi complete_refund → màn hình tự chuyển HOÀN THÀNH.
class RefundRequestsScreen extends StatelessWidget {
  const RefundRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RefundRequestsProvider()
        ..load()
        ..startRealtime(),
      child: const _RefundRequestsView(),
    );
  }
}

class _RefundRequestsView extends StatelessWidget {
  const _RefundRequestsView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RefundRequestsProvider>();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        title: Text(
          'YÊU CẦU HOÀN VÉ'.toUpperCase(),
          style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
        ),
      ),
      body: Column(
        children: [
          const SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            child: Row(
              children: [
                _FilterChip(label: 'CHỜ HOÀN', value: 'pending'),
                SizedBox(width: AppSpacing.xs),
                _FilterChip(label: 'ĐÃ HOÀN', value: 'completed'),
                SizedBox(width: AppSpacing.xs),
                _FilterChip(label: 'TẤT CẢ', value: 'ALL'),
              ],
            ),
          ),
          Expanded(child: _buildBody(context, provider)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, RefundRequestsProvider provider) {
    if (provider.isLoading) {
      return ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, __) => const SkeletonBox(height: 96),
      );
    }
    if (provider.errorMessage != null) {
      return ErrorState(message: provider.errorMessage!, onRetry: () => provider.load());
    }
    if (provider.requests.isEmpty) {
      return const EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'Không có yêu cầu',
        message: 'Chưa có yêu cầu hoàn vé nào trong mục này.',
      );
    }
    return RefreshIndicator(
      onRefresh: () => provider.load(),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: provider.requests.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (ctx, i) => _RefundCard(request: provider.requests[i]),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  const _FilterChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RefundRequestsProvider>();
    final isSelected = provider.statusFilter == value;
    return ChoiceChip(
      label: Text(
        label.toUpperCase(),
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
      onSelected: (_) => provider.load(status: value),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  final RefundRequestModel request;
  const _StatusLabel({required this.request});

  @override
  Widget build(BuildContext context) {
    final color = request.isCompleted
        ? AppColors.success
        : (request.isPending ? AppColors.info : AppColors.muted);
    final text = request.isCompleted
        ? 'HOÀN THÀNH'
        : (request.isPending ? 'CHỜ HOÀN TIỀN' : 'TỪ CHỐI');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxxs),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: AppRadius.zeroRadius,
      ),
      child: Text(
        text.toUpperCase(),
        style: AppTextStyles.captionUppercase.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _RefundCard extends StatelessWidget {
  final RefundRequestModel request;
  const _RefundCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openDetail(context),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.canvasElevated,
          border: Border.all(color: AppColors.hairline),
          borderRadius: AppRadius.zeroRadius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '#${request.bookingCode}',
                    style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
                  ),
                ),
                _StatusLabel(request: request),
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              request.movieTitle,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.ink),
            ),
            Text(
              '${request.cinemaName} · ${DateFormatter.formatDateTime(request.showtimeStart)}',
              style: AppTextStyles.caption.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              CurrencyFormatter.format(request.amount),
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(BuildContext context) {
    final provider = context.read<RefundRequestsProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.canvasElevated,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.zeroRadius),
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: _RefundDetailSheet(requestId: request.id, initial: request),
      ),
    );
  }
}

class _RefundDetailSheet extends StatefulWidget {
  final String requestId;
  final RefundRequestModel initial;
  const _RefundDetailSheet({required this.requestId, required this.initial});

  @override
  State<_RefundDetailSheet> createState() => _RefundDetailSheetState();
}

class _RefundDetailSheetState extends State<_RefundDetailSheet> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Bắt đầu định kỳ hỏi trạng thái mỗi 2 giây nếu đang pending
    if (widget.initial.isPending) {
      _startPolling();
    }
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!mounted) return;
      final provider = context.read<RefundRequestsProvider>();
      final updated = await provider.refreshRequest(widget.requestId);
      if (updated != null && !updated.isPending) {
        _timer?.cancel();
        _timer = null;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RefundRequestsProvider>();
    final r = provider.findById(widget.requestId) ?? widget.initial;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'CHI TIẾT HOÀN VÉ'.toUpperCase(),
                    style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
                  ),
                ),
                _StatusLabel(request: r),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _row(context, 'Mã vé', r.bookingCode, copy: r.bookingCode),
            _row(context, 'Số tiền hoàn', CurrencyFormatter.format(r.amount), copy: r.amount.toString()),
            _row(context, 'Rạp', r.cinemaName),
            _row(context, 'Phim', r.movieTitle),
            _row(context, 'Suất chiếu', DateFormatter.formatDateTime(r.showtimeStart)),
            _row(context, 'Gửi lúc', DateFormatter.formatDateTime(r.createdAt)),
            if (r.reason != null && r.reason!.isNotEmpty) _row(context, 'Lý do', r.reason!),
            const SizedBox(height: AppSpacing.sm),
            const Divider(color: AppColors.hairline, height: 1),
            const SizedBox(height: AppSpacing.sm),
            if (r.isPending) ...[
              Text(
                'HƯỚNG DẪN HOÀN TIỀN SEPAY SANDBOX'.toUpperCase(),
                style: AppTextStyles.captionUppercase.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Tạo giao dịch "Tiền ra" trên SePay sandbox với đúng thông tin dưới đây. Sai tài khoản hoặc sai số tiền, webhook sẽ từ chối.',
                style: AppTextStyles.caption.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: AppSpacing.xs),
              _row(context, 'Tài khoản chi', kRefundSourceAccount, copy: kRefundSourceAccount),
              _row(context, 'Loại giao dịch', 'Tiền ra'),
              _row(context, 'Số tiền', CurrencyFormatter.format(r.amount), copy: r.amount.toString()),
              _row(context, 'Nội dung CK', r.bookingCode, copy: r.bookingCode),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const SizedBox(
                    width: AppSpacing.md,
                    height: AppSpacing.md,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Đang chờ webhook SePay xác nhận giao dịch...',
                      style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                    ),
                  ),
                ],
              ),
            ] else if (r.isCompleted) ...[
              Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'REFUND THÀNH CÔNG'.toUpperCase(),
                      style: AppTextStyles.titleSm.copyWith(color: AppColors.success),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              _row(context, 'Mã GD SePay', r.sepayTransactionId ?? '—'),
              if (r.processedAt != null)
                _row(context, 'Hoàn lúc', DateFormatter.formatDateTime(r.processedAt!)),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(color: AppColors.hairline),
                    shape: const RoundedRectangleBorder(borderRadius: AppRadius.zeroRadius),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  ),
                  child: Text(
                    'ĐÃ HIỂU & ĐÓNG'.toUpperCase(),
                    style: AppTextStyles.captionUppercase.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value, {String? copy}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.muted)),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600),
            ),
          ),
          if (copy != null)
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: copy));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.canvasElevated,
                    duration: const Duration(seconds: 1),
                    content: Text(
                      'ĐÃ SAO CHÉP $copy'.toUpperCase(),
                      style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                    ),
                  ),
                );
              },
              child: const Icon(Icons.copy, size: 16, color: AppColors.primary),
            ),
        ],
      ),
    );
  }
}
