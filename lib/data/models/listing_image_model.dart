class ListingImageModel {
  final String id;
  final String listingId;
  final String url;
  final int sortOrder;

  const ListingImageModel({
    required this.id,
    required this.listingId,
    required this.url,
    this.sortOrder = 0,
  });

  factory ListingImageModel.fromJson(Map<String, dynamic> json) {
    return ListingImageModel(
      id: json['id'] as String,
      listingId: json['listing_id'] as String,
      url: json['url'] as String,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'listing_id': listingId,
      'url': url,
      'sort_order': sortOrder,
    };
  }

  ListingImageModel copyWith({
    String? url,
    int? sortOrder,
  }) {
    return ListingImageModel(
      id: id,
      listingId: listingId,
      url: url ?? this.url,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
