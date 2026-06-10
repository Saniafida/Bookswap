class CategoryModel {
  final String id;
  final String name;
  final String? icon;
  final String? color;
  final bool isActive;
  final bool isFeatured;
  final int displayOrder;
  final DateTime createdAt;

  const CategoryModel({
    required this.id,
    required this.name,
    this.icon,
    this.color,
    this.isActive = true,
    this.isFeatured = false,
    this.displayOrder = 0,
    required this.createdAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      isFeatured: json['is_featured'] as bool? ?? false,
      displayOrder: json['display_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'icon': icon,
        'color': color,
        'is_active': isActive,
        'is_featured': isFeatured,
        'display_order': displayOrder,
      };

  CategoryModel copyWith({
    String? name,
    String? icon,
    String? color,
    bool? isActive,
    bool? isFeatured,
    int? displayOrder,
  }) {
    return CategoryModel(
      id: id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt,
    );
  }
}
