import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message_model.dart';

/// Repository xử lý tin nhắn hỗ trợ khách hàng với rạp chiếu (S31).
class SupportChatRepository {
  final SupabaseClient? _client;

  SupportChatRepository([SupabaseClient? supabase]) : _client = supabase;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  /// Lấy hoặc tạo phiên hội thoại giữa khách và rạp.
  Future<String> getOrCreateConversation(String userId, String cinemaId) async {
    final conversationId = '${userId}_$cinemaId';

    await _supabase.from('conversations').upsert({
      'id': conversationId,
      'user_id': userId,
      'cinema_id': cinemaId,
    });

    return conversationId;
  }

  /// Lấy lịch sử tin nhắn của phiên chat.
  Future<List<ChatMessageModel>> getMessages(String conversationId) async {
    final response = await _supabase
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);

    return (response as List).map((m) => ChatMessageModel.fromMap(m)).toList();
  }

  /// Gửi tin nhắn mới.
  Future<void> sendMessage({
    required String conversationId,
    required String text,
    String? bookingCode,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập');

    await _supabase.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': user.id,
      'text': text,
      'booking_code': bookingCode,
    });
  }

  /// Đăng ký lắng nghe Realtime tin nhắn mới.
  RealtimeChannel subscribeMessages(
    String conversationId,
    void Function(ChatMessageModel message) onMessage,
  ) {
    return _supabase
        .channel('messages:$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            onMessage(ChatMessageModel.fromMap(payload.newRecord));
          },
        )
        .subscribe();
  }
}
