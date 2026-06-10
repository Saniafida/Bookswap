import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/services/storage_service.dart';
import '../core/services/supabase_service.dart';
import '../data/repositories/listing_repository.dart';
import '../data/models/listing_model.dart';

enum ListingsLoadState { initial, loading, loaded, error }

class ListingProvider extends ChangeNotifier {
  final ListingRepository _repository = const ListingRepository();

  ListingsLoadState _status = ListingsLoadState.initial;
  List<ListingModel> _listings = [];
  List<ListingModel> _myListings = [];
  String? _errorMessage;
  int _currentPage = 0;
  bool _hasMore = true;
  RealtimeChannel? _listingsChannel;

  ListingsLoadState get status => _status;
  List<ListingModel> get listings => _listings;
  List<ListingModel> get myListings => _myListings;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  bool get hasMore => _hasMore;
  bool get isLoading => _status == ListingsLoadState.loading;

  Future<void> fetchListings({
    String? search,
    String? categoryId,
    String? listingType,
    bool? featuredOnly,
    bool refresh = false,
  }) async {
    if (refresh) {
      _currentPage = 0;
      _hasMore = true;
    }
    if (!refresh && !_hasMore) return;
    if (_currentPage == 0) _setLoading();

    try {
      final data = await _repository.fetchListings(
        search: search,
        categoryId: categoryId,
        listingType: listingType,
        featuredOnly: featuredOnly,
        page: _currentPage,
      );

      if (refresh || _currentPage == 0) {
        _listings = data;
      } else {
        _listings.addAll(data);
      }
      _hasMore = data.length >= 20;
      _currentPage++;
      _status = ListingsLoadState.loaded;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> fetchMyListings(String userId) async {
    _setLoading();
    try {
      _myListings = await _repository.fetchUserListings(userId);
      _status = ListingsLoadState.loaded;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<ListingModel?> fetchListing(String id) async {
    try {
      return await _repository.fetchListing(id);
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  Future<bool> createListing({
    required String userId,
    required String title,
    String? description,
    required String condition,
    required String listingType,
    double? price,
    bool isNegotiable = true,
    String? categoryId,
    String? location,
    double? latitude,
    double? longitude,
    List<XFile>? imageFiles,
  }) async {
    _setLoading();
    try {
      List<Map<String, dynamic>> imageData = [];
      if (imageFiles != null && imageFiles.isNotEmpty) {
        final fileData = await Future.wait(
          imageFiles.map((f) async => (bytes: await f.readAsBytes(), name: f.name)),
        );
        final urls = await StorageService.uploadMultipleImages(fileData, userId);
        if (urls.isEmpty) {
          throw Exception('All image uploads failed. Check bucket policies.');
        }
        imageData = urls.asMap().entries.map((e) => {
          'url': e.value,
          'sort_order': e.key,
        }).toList();
      }

      final json = {
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
      };

      final success = await _repository.createListing(json, imageData);
      if (success) {
        await fetchListings(refresh: true);
      } else {
        debugPrint('[ListingProvider] createListing returned false');
      }
      _status = ListingsLoadState.loaded;
      notifyListeners();
      return success;
    } catch (e) {
      debugPrint('[ListingProvider] createListing error: $e');
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> updateListing(String id, Map<String, dynamic> data) async {
    try {
      await _repository.updateListing(id, data);
      final idx = _listings.indexWhere((l) => l.id == id);
      if (idx != -1) {
        _listings[idx] = _listings[idx].copyWith(
          title: data['title'] as String?,
          description: data['description'] as String?,
          condition: data['condition'] as String?,
          listingType: data['listing_type'] as String?,
          price: (data['price'] as num?)?.toDouble(),
          isNegotiable: data['is_negotiable'] as bool?,
          location: data['location'] as String?,
          latitude: (data['latitude'] as num?)?.toDouble(),
          longitude: (data['longitude'] as num?)?.toDouble(),
        );
      }
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> deleteListing(String id) async {
    try {
      final listing = _listings.firstWhere(
        (l) => l.id == id,
        orElse: () => _myListings.firstWhere(
          (l) => l.id == id,
          orElse: () => throw StateError('not found'),
        ),
      );
      await _repository.deleteListing(id);
      for (final image in listing.images) {
        await StorageService.deleteImageByUrl(image.url);
      }
      _listings.removeWhere((l) => l.id == id);
      _myListings.removeWhere((l) => l.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<void> incrementViewCount(String id) async {
    try {
      await _repository.incrementViewCount(id);
    } catch (_) {}
  }

  Future<void> setFeatured(String id, {required bool featured}) async {
    try {
      await _repository.setFeatured(id, featured);
      _updateLocalListing(id, isFeatured: featured);
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> setApproved(String id, {required bool approved}) async {
    try {
      await _repository.setApproval(id, approved);
      _updateLocalListing(id, isApproved: approved);
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> setStatus(String id, {required String status}) async {
    try {
      await _repository.setStatus(id, status);
      _listings.removeWhere((l) => l.id == id);
      _myListings.removeWhere((l) => l.id == id);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<List<ListingModel>> searchListings(String query) async {
    try {
      return await _repository.searchListings(query);
    } catch (e) {
      _setError(e.toString());
      return [];
    }
  }

  void subscribeToListings() {
    _listingsChannel?.unsubscribe();
    _listingsChannel = SupabaseService.client
        .channel('public:listings')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'listings',
          callback: (_) => fetchListings(refresh: true),
        )
        .subscribe();
  }

  void unsubscribeListings() {
    _listingsChannel?.unsubscribe();
    _listingsChannel = null;
  }

  void _updateLocalListing(String id, {bool? isFeatured, bool? isApproved}) {
    final update = (ListingModel l) {
      if (l.id == id) {
        return l.copyWith(
          isFeatured: isFeatured,
          isApproved: isApproved,
        );
      }
      return l;
    };
    _listings = _listings.map(update).toList();
    _myListings = _myListings.map(update).toList();
    notifyListeners();
  }

  void _setLoading() {
    _status = ListingsLoadState.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status = ListingsLoadState.error;
    _errorMessage = message;
    notifyListeners();
  }

  @override
  void dispose() {
    unsubscribeListings();
    super.dispose();
  }
}
