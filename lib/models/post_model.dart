enum ListingType { swap, sell, both, donate }
enum BookCondition { brandNew, likeNew, good, fair, poor }

class PostModel {
  final String id;
  final String userId;
  final String title;
  final String author;
  final String? description;
  final String? imageUrl;
  final List<String> imageUrls;
  final BookCondition condition;
  final ListingType listingType;
  final double? price;
  final String? category;
  final String? location;
  final bool isAvailable;
  final bool isFeatured;
  final DateTime createdAt;

  // Optional: joined profile data
  final String? ownerName;
  final String? ownerAvatarUrl;

  const PostModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.author,
    this.description,
    this.imageUrl,
    this.imageUrls = const [],
    required this.condition,
    required this.listingType,
    this.price,
    this.category,
    this.location,
    this.isAvailable = true,
    this.isFeatured = false,
    required this.createdAt,
    this.ownerName,
    this.ownerAvatarUrl,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;

    List<String> parseUrls(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) return raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
      return [];
    }

    final urls = parseUrls(json['image_urls']);
    final singleUrl = json['image_url'] as String?;

    return PostModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      description: json['description'] as String?,
      imageUrl: urls.isNotEmpty ? urls.first : singleUrl,
      imageUrls: urls.isNotEmpty ? urls : (singleUrl != null ? [singleUrl] : []),
      condition: BookCondition.values.firstWhere(
      (e) => e.name == json['condition'],
        orElse: () => BookCondition.good,
      ),
      listingType: ListingType.values.firstWhere(
        (e) => e.name == json['listing_type'],
        orElse: () => ListingType.swap,
      ),
      price: (json['price'] as num?)?.toDouble(),
      category: json['category'] as String?,
      location: json['location'] as String?,
      isAvailable: json['is_available'] as bool? ?? true,
      isFeatured: json['is_featured'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      ownerName: profile?['full_name'] as String?,
      ownerAvatarUrl: profile?['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'title': title,
      'author': author,
      'description': description,
      'image_url': imageUrl,
      'image_urls': imageUrls.isNotEmpty ? imageUrls : null,
      'condition': condition.name,
      'listing_type': listingType.name,
      'price': price,
      'category': category,
      'location': location,
      'is_available': isAvailable,
      'is_featured': isFeatured,
    };
  }

  PostModel copyWith({
    String? title,
    String? author,
    String? description,
    String? imageUrl,
    List<String>? imageUrls,
    BookCondition? condition,
    ListingType? listingType,
    double? price,
    String? category,
    String? location,
    bool? isAvailable,
    bool? isFeatured,
  }) {
    return PostModel(
      id: id,
      userId: userId,
      title: title ?? this.title,
      author: author ?? this.author,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      condition: condition ?? this.condition,
      listingType: listingType ?? this.listingType,
      price: price ?? this.price,
      category: category ?? this.category,
      location: location ?? this.location,
      isAvailable: isAvailable ?? this.isAvailable,
      isFeatured: isFeatured ?? this.isFeatured,
      createdAt: createdAt,
      ownerName: ownerName,
      ownerAvatarUrl: ownerAvatarUrl,
    );
  }
}
