import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/chat_message_model.dart';
import '../../data/repositories/support_chat_repository.dart';

/// Provider quản lý hội thoại hỗ trợ trực tuyến (S31).
class SupportChatProvider extends ChangeNotifier {
  final SupportChatRepository _repo;

  SupportChatProvider([SupportChatRepository? repo])
      : _repo = repo ?? SupportChatRepository();

  bool _isLoading = false;
  String? _errorMessage;
  String? _conversationId;
  List<ChatMessageModel> _messages = [];
  RealtimeChannel? _subscription;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get conversationId => _conversationId;
  List<ChatMessageModel> get messages => List.unmodifiable(_messages);

  /// Khởi tạo phiên trò chuyện với rạp.
  Future<void> initConversation(String userId, String cinemaId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _conversationId = await _repo.getOrCreateConversation(userId, cinemaId);
      _messages = await _repo.getMessages(_conversationId!);

      // Lắng nghe realtime
      _subscription?.unsubscribe();
      _subscription = _repo.subscribeMessages(_conversationId!, (msg) {
        _messages.add(msg);
        notifyListeners();
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Không thể tải cuộc trò chuyện: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Gửi tin nhắn.
  Future<bool> sendMessage(String text, {String? bookingCode}) async {
    if (_conversationId == null || text.trim().isEmpty) return false;

    try {
      await _repo.sendMessage(
        conversationId: _conversationId!,
        text: text.trim(),
        bookingCode: bookingCode,
      );
      return true;
    } catch (e) {
      _errorMessage = 'Gửi tin nhắn thất bại: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }
}
