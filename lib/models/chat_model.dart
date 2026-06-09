class ChatModel {
  final String id;
  final String user1Id;
  final String user2Id;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount1;
  final int unreadCount2;
  final DateTime createdAt;

  // Optional: participant profile (joined)
  final String? participantName;
  final String? participantAvatarUrl;

  const ChatModel({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount1 = 0,
    this.unreadCount2 = 0,
    required this.createdAt,
    this.participantName,
    this.participantAvatarUrl,
  });

  int unreadCountFor(String userId) =>
    userId == user1Id ? unreadCount1 : unreadCount2;

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return ChatModel(
      id: json['id'] as String,
      user1Id: json['user1_id'] as String,
      user2Id: json['user2_id'] as String,
      lastMessage: json['last_message'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      unreadCount1: json['unread_count_1'] as int? ?? 0,
      unreadCount2: json['unread_count_2'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      participantName: profile?['full_name'] as String?,
      participantAvatarUrl: profile?['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user1_id': user1Id,
      'user2_id': user2Id,
      'last_message': lastMessage,
      'last_message_at': lastMessageAt?.toIso8601String(),
    };
  }

  ChatModel copyWith({
    String? lastMessage,
    DateTime? lastMessageAt,
    String? participantName,
    String? participantAvatarUrl,
    int? unreadCount1,
    int? unreadCount2,
  }) {
    return ChatModel(
      id: id,
      user1Id: user1Id,
      user2Id: user2Id,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount1: unreadCount1 ?? this.unreadCount1,
      unreadCount2: unreadCount2 ?? this.unreadCount2,
      createdAt: createdAt,
      participantName: participantName ?? this.participantName,
      participantAvatarUrl: participantAvatarUrl ?? this.participantAvatarUrl,
    );
  }
}
