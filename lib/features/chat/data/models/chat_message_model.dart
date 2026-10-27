/// Model tin nhắn hỗ trợ trực tuyến (S31).
class ChatMessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final String? bookingCode;
  final DateTime createdAt;

  const ChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    this.bookingCode,
    required this.createdAt,
  });

  factory ChatMessageModel.fromMap(Map<String, dynamic> map) {
    return ChatMessageModel(
      id: map['id'] as String,
      conversationId: map['conversation_id'] as String,
      senderId: map['sender_id'] as String,
      text: map['text'] as String,
      bookingCode: map['booking_code'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }
}
