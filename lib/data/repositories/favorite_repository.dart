import '../../core/services/supabase_service.dart';
import '../models/listing_model.dart';
import '../models/listing_image_model.dart';

class FavoriteRepository {
  const FavoriteRepository();

  String _baseListingSelect() {
    return '*, profiles(full_name, avatar_url), categories(name, icon), listing_images(*)';
  }

  ListingModel _parseListing(Map<String, dynamic> json) {
    final model = ListingModel.fromJson(json);
    final sortedImages = List<ListingImageModel>.from(model.images)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return model.copyWith(images: sortedImages);
  }

  Future<List<ListingModel>> fetchFavorites(String userId) async {
    final favData = await SupabaseService.table('favorites')
        .select('listing_id')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final listingIds = (favData as List)
        .map((e) => e['listing_id'] as String)
        .toList();

    if (listingIds.isEmpty) return [];

    final data = await SupabaseService.table('listings')
        .select(_baseListingSelect())
        .inFilter('id', listingIds)
        .order('created_at', ascending: false);

    return (data as List)
        .map((e) => _parseListing(e).copyWith(isFavorited: true))
        .toList();
  }

  Future<bool> isFavorited(String userId, String listingId) async {
    try {
      final data = await SupabaseService.table('favorites')
          .select('id')
          .eq('user_id', userId)
          .eq('listing_id', listingId)
          .maybeSingle();
      return data != null;
    } catch (e) {
      return false;
    }
  }

  Future<bool> toggleFavorite(String userId, String listingId) async {
    try {
      final existing = await SupabaseService.table('favorites')
          .select('id')
          .eq('user_id', userId)
          .eq('listing_id', listingId)
          .maybeSingle();

      if (existing != null) {
        await SupabaseService.table('favorites')
            .delete()
            .eq('user_id', userId)
            .eq('listing_id', listingId);
        return false;
      } else {
        await SupabaseService.table('favorites').insert({
          'user_id': userId,
          'listing_id': listingId,
        });
        return true;
      }
    } catch (e) {
      return false;
    }
  }

  Future<int> getFavoriteCount(String listingId) async {
    try {
      final data = await SupabaseService.table('favorites')
          .select('id')
          .eq('listing_id', listingId);
      return (data as List).length;
    } catch (e) {
      return 0;
    }
  }
}
