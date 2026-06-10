class FavoriteModel {
  final String id;
  final String userId;
  final String listingId;
  final DateTime createdAt;

  const FavoriteModel({
    required this.id,
    required this.userId,
    required this.listingId,
    required this.createdAt,
  });

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    return FavoriteModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      listingId: json['listing_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'listing_id': listingId,
    };
  }

  FavoriteModel copyWith({
    String? userId,
    String? listingId,
  }) {
    return FavoriteModel(
      id: id,
      userId: userId ?? this.userId,
      listingId: listingId ?? this.listingId,
      createdAt: createdAt,
    );
  }
}
