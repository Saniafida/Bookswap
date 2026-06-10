import 'package:flutter/foundation.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/storage_service.dart';
import '../models/listing_model.dart';
import '../models/listing_image_model.dart';

class ListingRepository {
  const ListingRepository();

  String _baseSelect() {
    return '*, profiles(full_name, avatar_url), categories(name, icon), listing_images(*)';
  }

  ListingModel _parseListing(Map<String, dynamic> json) {
    final model = ListingModel.fromJson(json);
    final sortedImages = List<ListingImageModel>.from(model.images)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return model.copyWith(images: sortedImages);
  }

  Future<List<ListingModel>> fetchListings({
    String? search,
    String? categoryId,
    String? listingType,
    String? userId,
    String? status,
    bool? featuredOnly,
    bool? approvedOnly,
    String? excludeUserId,
    String orderBy = 'created_at',
    bool ascending = false,
    int page = 0,
    int pageSize = 20,
  }) async {
    var query = SupabaseService.table('listings').select(_baseSelect());

    if (search != null && search.isNotEmpty) {
      query = query.or('title.ilike.%$search%,description.ilike.%$search%');
    }
    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.eq('category_id', categoryId);
    }
    if (listingType != null && listingType.isNotEmpty) {
      query = query.eq('listing_type', listingType);
    }
    if (userId != null && userId.isNotEmpty) {
      query = query.eq('user_id', userId);
    }
    if (status != null && status.isNotEmpty) {
      query = query.eq('status', status);
    }
    if (featuredOnly == true) {
      query = query.eq('is_featured', true);
    }
    if (approvedOnly == true) {
      query = query.eq('is_approved', true);
    }
    if (excludeUserId != null && excludeUserId.isNotEmpty) {
      query = query.neq('user_id', excludeUserId);
    }

    final data = await query
        .order(orderBy, ascending: ascending)
        .range(page * pageSize, (page + 1) * pageSize - 1);

    return (data as List).map((e) => _parseListing(e)).toList();
  }

  Future<ListingModel?> fetchListing(String id) async {
    try {
      final data = await SupabaseService.table('listings')
          .select(_baseSelect())
          .eq('id', id)
          .single();
      return _parseListing(data);
    } catch (e) {
      return null;
    }
  }

  Future<void> incrementViewCount(String id) async {
    final current = await SupabaseService.table('listings')
        .select('view_count')
        .eq('id', id)
        .single();
    final count = (current['view_count'] as int? ?? 0) + 1;
    await SupabaseService.table('listings')
        .update({'view_count': count})
        .eq('id', id);
  }

  Future<bool> createListing(
    Map<String, dynamic> listingData,
    List<Map<String, dynamic>> imageData,
  ) async {
    try {
      final listing = await SupabaseService.table('listings')
          .insert(listingData)
          .select()
          .single();
      final listingId = listing['id'] as String;
      for (final img in imageData) {
        img['listing_id'] = listingId;
        await SupabaseService.table('listing_images').insert(img);
      }
      return true;
    } catch (e) {
      debugPrint('[ListingRepository] createListing error: $e');
      return false;
    }
  }

  Future<bool> updateListing(String id, Map<String, dynamic> data) async {
    try {
      await SupabaseService.table('listings').update(data).eq('id', id);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteListing(String id) async {
    try {
      final images = await SupabaseService.table('listing_images')
          .select('url')
          .eq('listing_id', id);
      for (final img in images as List) {
        await StorageService.deleteImageByUrl(img['url'] as String);
      }
      await SupabaseService.table('listing_images').delete().eq('listing_id', id);
      await SupabaseService.table('favorites').delete().eq('listing_id', id);
      await SupabaseService.table('listings').delete().eq('id', id);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<ListingModel>> fetchUserListings(String userId) async {
    final data = await SupabaseService.table('listings')
        .select(_baseSelect())
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => _parseListing(e)).toList();
  }

  Future<List<ListingModel>> searchListings(String searchTerm) async {
    final data = await SupabaseService.table('listings')
        .select(_baseSelect())
        .or('title.ilike.%$searchTerm%,description.ilike.%$searchTerm%')
        .eq('is_approved', true)
        .eq('status', 'active')
        .order('created_at', ascending: false);
    return (data as List).map((e) => _parseListing(e)).toList();
  }

  Future<void> submitForApproval(String id) async {
    await SupabaseService.table('listings')
        .update({'is_approved': false, 'status': 'pending'})
        .eq('id', id);
  }

  Future<void> setApproval(String id, bool approved) async {
    await SupabaseService.table('listings')
        .update({'is_approved': approved})
        .eq('id', id);
  }

  Future<void> setFeatured(String id, bool featured) async {
    await SupabaseService.table('listings')
        .update({'is_featured': featured})
        .eq('id', id);
  }

  Future<void> setStatus(String id, String status) async {
    await SupabaseService.table('listings')
        .update({'status': status})
        .eq('id', id);
  }
}
