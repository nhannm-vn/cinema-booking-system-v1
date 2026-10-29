import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../auth/presentation/controllers/auth_provider.dart';
import '../../data/models/chat_message_model.dart';
import '../controllers/support_chat_provider.dart';

/// Screen S31: In-app Customer Support Chat with Realtime synchronization.
/// References: ROLE_FLOWS.md Section 1.11, 4.2 & 5.1
class SupportChatScreen extends StatefulWidget {
  final String? cinemaId;
  final String? initialBookingCode;

  const SupportChatScreen({
    super.key,
    this.cinemaId,
    this.initialBookingCode,
  });

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _attachedBookingCode;
  late String _activeCinemaId;

  @override
  void initState() {
    super.initState();
    _attachedBookingCode = widget.initialBookingCode;
    _activeCinemaId = widget.cinemaId ?? 'cn_q1';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      final userId = user?.id ?? 'guest_customer';
      if (user?.cinemaId != null && user!.cinemaId!.isNotEmpty) {
        _activeCinemaId = user.cinemaId!;
      }
      context.read<SupportChatProvider>().initConversation(userId, _activeCinemaId);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    final provider = context.read<SupportChatProvider>();
    final code = _attachedBookingCode;

    setState(() {
      _attachedBookingCode = null; // Clear attached code after attaching
    });

    final success = await provider.sendMessage(text, bookingCode: code);
    if (success) {
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().currentUser;
    final currentUserId = currentUser?.id ?? '';
    final provider = context.watch<SupportChatProvider>();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'HỖ TRỢ TRỰC TUYẾN'.toUpperCase(),
              style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
            ),
            const SizedBox(height: AppSpacing.xxxs),
            Text(
              'RẠP ${_activeCinemaId.toUpperCase()}',
              style: AppTextStyles.caption.copyWith(color: AppColors.primary),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Message List
          Expanded(
            child: _buildMessageList(context, provider, currentUserId),
          ),

          // Attached Booking Code Chip Preview
          if (_attachedBookingCode != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xxs,
              ),
              color: AppColors.canvasElevated,
              child: Row(
                children: [
                  const Icon(Icons.confirmation_number_outlined, color: AppColors.primary, size: 16),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Đính kèm vé: #${_attachedBookingCode!.toUpperCase()}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16, color: AppColors.muted),
                    onPressed: () => setState(() => _attachedBookingCode = null),
                  ),
                ],
              ),
            ),

          // Input Bar
          _buildInputBar(context),
        ],
      ),
    );
  }

  Widget _buildMessageList(
    BuildContext context,
    SupportChatProvider provider,
    String currentUserId,
  ) {
    if (provider.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: SkeletonBox(width: 220, height: 48),
            ),
            SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: SkeletonBox(width: 180, height: 48),
            ),
            SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: SkeletonBox(width: 260, height: 48),
            ),
          ],
        ),
      );
    }

    if (provider.errorMessage != null) {
      return Center(
        child: ErrorState(
          message: provider.errorMessage!,
          onRetry: () {
            final user = context.read<AuthProvider>().currentUser;
            final userId = user?.id ?? 'guest_customer';
            provider.initConversation(userId, _activeCinemaId);
          },
        ),
      );
    }

    if (provider.messages.isEmpty) {
      return const Center(
        child: EmptyState(
          title: 'CHƯA CÓ TIN NHẮN',
          message: 'Chưa có tin nhắn nào. Hãy gửi tin nhắn để bắt đầu cuộc trò chuyện với rạp.',
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: provider.messages.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (context, index) {
        final msg = provider.messages[index];
        final isMe = msg.senderId == currentUserId;
        return _buildMessageBubble(msg, isMe);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessageModel msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppColors.canvasElevated : AppColors.canvas,
          borderRadius: AppRadius.zeroRadius,
          border: Border.all(
            color: isMe ? AppColors.primary : AppColors.hairline,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (msg.bookingCode != null && msg.bookingCode!.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.xxs),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  border: Border.all(color: AppColors.primary),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.confirmation_number, color: AppColors.primary, size: 12),
                    const SizedBox(width: AppSpacing.xxs),
                    Text(
                      '#${msg.bookingCode!.toUpperCase()}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Text(
              msg.text,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.ink),
            ),
            const SizedBox(height: AppSpacing.xxxs),
            Text(
              DateFormatter.formatTime(msg.createdAt),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.muted,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.xs,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xs,
      ),
      decoration: const BoxDecoration(
        color: AppColors.canvasElevated,
        border: Border(top: BorderSide(color: AppColors.hairline)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.ink),
              decoration: const InputDecoration(
                hintText: 'Nhập tin nhắn hỗ trợ...',
                hintStyle: TextStyle(color: AppColors.muted),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _handleSendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: AppColors.primary),
            onPressed: _handleSendMessage,
          ),
        ],
      ),
    );
  }
}
