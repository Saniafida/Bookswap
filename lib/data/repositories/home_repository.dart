import '../../core/services/supabase_service.dart';
import '../models/listing_model.dart';
import '../models/listing_image_model.dart';

class HomeSection {
  final String title;
  final String type;
  final String? categoryId;
  final int limit;
  final int displayOrder;

  const HomeSection({
    required this.title,
    required this.type,
    this.categoryId,
    this.limit = 10,
    this.displayOrder = 0,
  });

  factory HomeSection.fromJson(Map<String, dynamic> json) {
    return HomeSection(
      title: json['title'] as String,
      type: json['type'] as String,
      categoryId: json['category_id'] as String?,
      limit: json['limit'] as int? ?? 10,
      displayOrder: json['display_order'] as int? ?? 0,
    );
  }
}

class HomeRepository {
  const HomeRepository();

  String _baseSelect() {
    return '*, profiles(full_name, avatar_url), categories(name, icon), listing_images(*)';
  }

  ListingModel _parseListing(Map<String, dynamic> json) {
    final model = ListingModel.fromJson(json);
    final sortedImages = List<ListingImageModel>.from(model.images)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return model.copyWith(images: sortedImages);
  }

  Future<List<HomeSection>> fetchHomeSections() async {
    final data = await SupabaseService.table('app_settings')
        .select('home_sections')
        .single();
    final sections = data['home_sections'] as List<dynamic>? ?? [];
    return (sections
            .map((e) => HomeSection.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder)))
        .toList();
  }

  Future<List<ListingModel>> fetchFeaturedListings({int limit = 10}) async {
    final data = await SupabaseService.table('listings')
        .select(_baseSelect())
        .eq('is_featured', true)
        .eq('is_approved', true)
        .eq('status', 'active')
        .order('created_at', ascending: false)
        .limit(limit);
    return (data as List).map((e) => _parseListing(e)).toList();
  }

  Future<List<ListingModel>> fetchRecentListings({int limit = 20}) async {
    final data = await SupabaseService.table('listings')
        .select(_baseSelect())
        .eq('is_approved', true)
        .eq('status', 'active')
        .order('created_at', ascending: false)
        .limit(limit);
    return (data as List).map((e) => _parseListing(e)).toList();
  }

  Future<List<ListingModel>> fetchPopularListings({int limit = 10}) async {
    final data = await SupabaseService.table('listings')
        .select(_baseSelect())
        .eq('is_approved', true)
        .eq('status', 'active')
        .order('view_count', ascending: false)
        .limit(limit);
    return (data as List).map((e) => _parseListing(e)).toList();
  }

  Future<List<ListingModel>> fetchListingsByCategory(
    String categoryId, {
    int limit = 10,
  }) async {
    final data = await SupabaseService.table('listings')
        .select(_baseSelect())
        .eq('category_id', categoryId)
        .eq('is_approved', true)
        .eq('status', 'active')
        .order('created_at', ascending: false)
        .limit(limit);
    return (data as List).map((e) => _parseListing(e)).toList();
  }
}
