class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final bool isRead;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    this.isRead = false,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      chatId: json['chat_id'] as String,
      senderId: json['sender_id'] as String,
      text: json['text'] as String,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chat_id': chatId,
      'sender_id': senderId,
      'text': text,
      'is_read': isRead,
    };
  }

  MessageModel copyWith({bool? isRead}) {
    return MessageModel(
      id: id,
      chatId: chatId,
      senderId: senderId,
      text: text,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}
