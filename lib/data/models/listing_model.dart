import 'package:flutter/material.dart';
import 'listing_image_model.dart';

enum ListingType { sell, exchange, donate, sellExchange }

enum ItemCondition { brandNew, likeNew, good, fair, poor }

enum ListingStatus { active, sold, removed, expired }

class ListingModel {
  final String id;
  final String userId;
  final String? categoryId;
  final String title;
  final String? description;
  final String condition;
  final String listingType;
  final double? price;
  final bool isNegotiable;
  final String? location;
  final double? latitude;
  final double? longitude;
  final bool isFeatured;
  final bool isApproved;
  final String status;
  final int viewCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined
  final List<ListingImageModel> images;
  final String? categoryName;
  final String? categoryIcon;
  final String? ownerName;
  final String? ownerAvatarUrl;
  final int favoriteCount;
  final bool? isFavorited;

  const ListingModel({
    required this.id,
    required this.userId,
    this.categoryId,
    required this.title,
    this.description,
    this.condition = 'good',
    this.listingType = 'sell',
    this.price,
    this.isNegotiable = true,
    this.location,
    this.latitude,
    this.longitude,
    this.isFeatured = false,
    this.isApproved = true,
    this.status = 'active',
    this.viewCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.images = const [],
    this.categoryName,
    this.categoryIcon,
    this.ownerName,
    this.ownerAvatarUrl,
    this.favoriteCount = 0,
    this.isFavorited,
  });

  factory ListingModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    final category = json['categories'] as Map<String, dynamic>?;
    final rawImages = json['listing_images'] as List<dynamic>?;

    return ListingModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      categoryId: json['category_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      condition: json['condition'] as String? ?? 'good',
      listingType: json['listing_type'] as String? ?? 'sell',
      price: (json['price'] as num?)?.toDouble(),
      isNegotiable: json['is_negotiable'] as bool? ?? true,
      location: json['location'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isFeatured: json['is_featured'] as bool? ?? false,
      isApproved: json['is_approved'] as bool? ?? true,
      status: json['status'] as String? ?? 'active',
      viewCount: json['view_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      images: rawImages != null
          ? rawImages
              .map((e) => ListingImageModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      categoryName: category?['name'] as String?,
      categoryIcon: category?['icon'] as String?,
      ownerName: profile?['full_name'] as String?,
      ownerAvatarUrl: profile?['avatar_url'] as String?,
      favoriteCount: json['favorite_count'] as int? ?? 0,
      isFavorited: json['is_favorited'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'category_id': categoryId,
      'title': title,
      'description': description,
      'condition': condition,
      'listing_type': listingType,
      'price': price,
      'is_negotiable': isNegotiable,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'is_featured': isFeatured,
      'is_approved': isApproved,
      'status': status,
      'view_count': viewCount,
    };
  }

  ListingModel copyWith({
    String? categoryId,
    String? title,
    String? description,
    String? condition,
    String? listingType,
    double? price,
    bool? isNegotiable,
    String? location,
    double? latitude,
    double? longitude,
    bool? isFeatured,
    bool? isApproved,
    String? status,
    int? viewCount,
    List<ListingImageModel>? images,
    String? categoryName,
    String? categoryIcon,
    String? ownerName,
    String? ownerAvatarUrl,
    int? favoriteCount,
    bool? isFavorited,
  }) {
    return ListingModel(
      id: id,
      userId: userId,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      description: description ?? this.description,
      condition: condition ?? this.condition,
      listingType: listingType ?? this.listingType,
      price: price ?? this.price,
      isNegotiable: isNegotiable ?? this.isNegotiable,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isFeatured: isFeatured ?? this.isFeatured,
      isApproved: isApproved ?? this.isApproved,
      status: status ?? this.status,
      viewCount: viewCount ?? this.viewCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
      images: images ?? this.images,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      ownerName: ownerName ?? this.ownerName,
      ownerAvatarUrl: ownerAvatarUrl ?? this.ownerAvatarUrl,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      isFavorited: isFavorited ?? this.isFavorited,
    );
  }

  String get priceLabel {
    if (price != null) return '\$${price!.toStringAsFixed(0)}';
    return listingType == 'donate' ? 'Free' : '';
  }

  String get listingTypeLabel {
    return switch (listingType) {
      'sell' => 'For Sale',
      'exchange' => 'For Exchange',
      'donate' => 'Free',
      'sellExchange' => 'Sell or Exchange',
      'sell_exchange' => 'Sell or Exchange',
      _ => listingType,
    };
  }

  IconData get listingTypeIcon {
    return switch (listingType) {
      'sell' => Icons.sell,
      'exchange' => Icons.swap_horiz,
      'donate' => Icons.card_giftcard,
      'sellExchange' => Icons.swap_vert,
      'sell_exchange' => Icons.swap_vert,
      _ => Icons.sell,
    };
  }

  String get conditionLabel {
    return switch (condition) {
      'brandNew' => 'Brand New',
      'likeNew' => 'Like New',
      'good' => 'Good',
      'fair' => 'Fair',
      'poor' => 'Poor',
      _ => condition,
    };
  }

  bool get isActive => status == 'active';
}
