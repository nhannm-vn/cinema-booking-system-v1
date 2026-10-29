import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../data/models/audit_log_model.dart';
import '../controllers/management_provider.dart';

/// Screen S29: System Audit Logs Viewer with filters and JSON diff inspector.
/// References: ROLE_FLOWS.md Section 5.8, BUSINESS_RULES.md Section 11
class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  String _selectedAction = 'ALL';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLogs();
    });
  }

  void _loadLogs() {
    context.read<ManagementProvider>().loadAuditLogs(
      action: _selectedAction,
    );
  }

  void _openDetailModal(BuildContext context, AuditLogModel log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.canvasElevated,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.zeroRadius),
      builder: (_) => _AuditDetailModal(log: log),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ManagementProvider>();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        title: Text(
          'NHẬT KÝ THAO TÁC HỆ THỐNG'.toUpperCase(),
          style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
        ),
      ),
      body: Column(
        children: [
          // Action Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                _buildActionChip('TẤT CẢ', 'ALL'),
                const SizedBox(width: AppSpacing.xs),
                _buildActionChip('SOÁT VÉ', 'checkIn'),
                const SizedBox(width: AppSpacing.xs),
                _buildActionChip('HỦY SUẤT', 'cancelShowtime'),
                const SizedBox(width: AppSpacing.xs),
                _buildActionChip('HOÀN TIỀN', 'refund'),
                const SizedBox(width: AppSpacing.xs),
                _buildActionChip('ĐỔI GIÁ', 'changePrice'),
                const SizedBox(width: AppSpacing.xs),
                _buildActionChip('KHÓA USER', 'lockUser'),
                const SizedBox(width: AppSpacing.xs),
                _buildActionChip('SƠ ĐỒ GHẾ', 'updateRoomLayout'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Audit List
          Expanded(
            child: _buildBody(context, provider),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(String label, String value) {
    final isSelected = _selectedAction == value;
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
      onSelected: (_) {
        setState(() => _selectedAction = value);
        _loadLogs();
      },
    );
  }

  Widget _buildBody(BuildContext context, ManagementProvider provider) {
    if (provider.isLoading) {
      return ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, __) => const SkeletonBox(
          width: double.infinity,
          height: 90,
        ),
      );
    }

    if (provider.errorMessage != null) {
      return Center(
        child: ErrorState(
          message: provider.errorMessage!,
          onRetry: () => _loadLogs(),
        ),
      );
    }

    if (provider.auditLogs.isEmpty) {
      return const Center(
        child: EmptyState(
          title: 'KHÔNG CÓ NHẬT KÝ',
          message: 'Không có nhật ký thao tác nào',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadLogs(),
      color: AppColors.primary,
      backgroundColor: AppColors.canvasElevated,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: provider.auditLogs.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final log = provider.auditLogs[index];
          return _buildLogCard(context, log);
        },
      ),
    );
  }

  Widget _buildLogCard(BuildContext context, AuditLogModel log) {
    Color actionColor = AppColors.info;
    if (log.action.contains('cancel') || log.action.contains('lock')) {
      actionColor = AppColors.warning;
    } else if (log.action.contains('Price') || log.action.contains('create')) {
      actionColor = AppColors.primary;
    } else if (log.action.contains('checkIn')) {
      actionColor = AppColors.success;
    }

    return InkWell(
      onTap: () => _openDetailModal(context, log),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
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
                AppBadge(label: log.actionLabel, backgroundColor: actionColor),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  DateFormatter.formatDateTime(log.createdAt),
                  style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.muted),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),

            Text(
              'Thực hiện: ${log.actorName ?? log.actorRole.toUpperCase()}${log.cinemaName != null ? ' · ${log.cinemaName}' : ''}',
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),

            Text(
              'Mục tiêu: ${log.targetType} [${log.targetId}]',
              style: AppTextStyles.caption.copyWith(color: AppColors.muted),
            ),
            if (log.reason != null && log.reason!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xxxs),
              Text(
                'Lý do: ${log.reason}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.ink,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AuditDetailModal extends StatelessWidget {
  final AuditLogModel log;

  const _AuditDetailModal({required this.log});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                AppBadge(label: log.actionLabel, backgroundColor: AppColors.primary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'CHI TIẾT NHẬT KÝ'.toUpperCase(),
                    style: AppTextStyles.titleSm.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            _buildDetailRow('Thời điểm', DateFormatter.formatDateTime(log.createdAt)),
            _buildDetailRow('Thực hiện bởi', '${log.actorName ?? '---'} (${log.actorRole.toUpperCase()})'),
            _buildDetailRow('Rạp', log.cinemaName ?? log.cinemaId ?? 'TOÀN HỆ THỐNG'),
            _buildDetailRow('Đối tượng', '${log.targetType}: ${log.targetId}'),
            if (log.reason != null) _buildDetailRow('Lý do thao tác', log.reason!),

            const SizedBox(height: AppSpacing.md),

            // JSON Diff section
            if (log.oldData != null || log.newData != null) ...[
              Text(
                'THAY ĐỔI DỮ LIỆU (JSON DIFF):',
                style: AppTextStyles.captionUppercase.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              if (log.oldData != null) ...[
                Text('DỮ LIỆU CŨ (TRƯỚC THAY ĐỔI):', style: AppTextStyles.caption.copyWith(color: AppColors.warning)),
                const SizedBox(height: AppSpacing.xxxs),
                _buildJsonBox(log.oldData!, AppColors.warning.withValues(alpha: 0.1)),
                const SizedBox(height: AppSpacing.sm),
              ],
              if (log.newData != null) ...[
                Text('DỮ LIỆU MỚI (SAU THAY ĐỔI):', style: AppTextStyles.caption.copyWith(color: AppColors.success)),
                const SizedBox(height: AppSpacing.xxxs),
                _buildJsonBox(log.newData!, AppColors.success.withValues(alpha: 0.1)),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],

            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.canvas,
                elevation: 0,
                shape: const RoundedRectangleBorder(borderRadius: AppRadius.zeroRadius),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(
                'ĐÓNG'.toUpperCase(),
                style: AppTextStyles.button.copyWith(color: AppColors.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(color: AppColors.muted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJsonBox(Map<String, dynamic> data, Color bgColor) {
    const encoder = JsonEncoder.withIndent('  ');
    final formatted = encoder.convert(data);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.zeroRadius,
        border: Border.all(color: AppColors.hairline),
      ),
      child: SelectableText(
        formatted,
        style: const TextStyle(
          color: AppColors.ink,
          fontFamily: 'monospace',
          fontSize: 11,
        ),
      ),
    );
  }
}
