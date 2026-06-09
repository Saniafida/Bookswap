class AnnouncementModel {
  final String id;
  final String title;
  final String body;
  final bool isActive;
  final int priority;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.body,
    this.isActive = true,
    this.priority = 0,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      isActive: json['is_active'] as bool? ?? true,
      priority: json['priority'] as int? ?? 0,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'body': body,
        'is_active': isActive,
        'priority': priority,
        'created_by': createdBy,
      };

  AnnouncementModel copyWith({
    String? title,
    String? body,
    bool? isActive,
    int? priority,
  }) {
    return AnnouncementModel(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      isActive: isActive ?? this.isActive,
      priority: priority ?? this.priority,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
