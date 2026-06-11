class NotificationModel {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.data = const {},
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      data: json['data'] is Map ? Map<String, dynamic>.from(json['data']) : {},
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      userId: userId,
      type: type,
      title: title,
      message: message,
      data: data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  /// Group label for section headers
  String get groupLabel {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return 'This Week';
    return 'Earlier';
  }

  /// Icon per notification type
  String get iconAsset {
    switch (type) {
      case 'new_message': return 'chat_bubble';
      case 'new_listing': return 'inventory_2';
      case 'favorite_update': return 'favorite';
      case 'price_drop': return 'trending_down';
      case 'exchange_request': return 'swap_horiz';
      case 'donation_request': return 'volunteer_activism';
      case 'listing_approved': return 'verified';
      case 'listing_removed': return 'delete';
      case 'admin_announcement': return 'campaign';
      case 'account_action': return 'security';
      default: return 'notifications';
    }
  }
}
