import 'package:flutter/foundation.dart';
import '../../data/models/listing_model.dart';
import '../../data/repositories/listing_repository.dart';

enum AdminBookStatus { initial, loading, loaded, error }

class AdminBookProvider extends ChangeNotifier {
  final ListingRepository _repo;
  AdminBookProvider({ListingRepository? repo})
      : _repo = repo ?? const ListingRepository();

  AdminBookStatus _status = AdminBookStatus.initial;
  List<ListingModel> _listings = [];
  String? _error;
  String _searchQuery = '';
  String? _categoryFilter;
  int _page = 0;
  bool _hasMore = true;

  AdminBookStatus get status => _status;
  List<ListingModel> get listings => _listings;
  String? get error => _error;
  bool get isLoading => _status == AdminBookStatus.loading;
  bool get hasMore => _hasMore;

  Future<void> fetchListings({bool refresh = false}) async {
    if (refresh) {
      _page = 0;
      _listings = [];
      _hasMore = true;
    }
    if (!_hasMore) return;
    _status = AdminBookStatus.loading;
    _error = null;
    notifyListeners();
    try {
      final result = await _repo.fetchListings(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        categoryId: _categoryFilter,
        page: _page,
      );
      if (result.length < 30) _hasMore = false;
      _listings = refresh ? result : [..._listings, ...result];
      _page++;
      _status = AdminBookStatus.loaded;
    } catch (e) {
      _status = AdminBookStatus.error;
      _error = e.toString();
    }
    notifyListeners();
  }

  void setSearch(String q) {
    _searchQuery = q;
    fetchListings(refresh: true);
  }

  void setCategory(String? cat) {
    _categoryFilter = cat;
    fetchListings(refresh: true);
  }

  Future<bool> createListing(Map<String, dynamic> data, {List<Map<String, dynamic>> images = const []}) =>
      _action(() => _repo.createListing(data, images));

  Future<bool> deleteListing(String id) =>
      _action(() => _repo.deleteListing(id));

  Future<bool> setFeatured(String id, {required bool featured}) =>
      _action(() => _repo.setFeatured(id, featured));

  Future<bool> updateListing(String id, Map<String, dynamic> data) =>
      _action(() => _repo.updateListing(id, data));

  Future<bool> setApproval(String id, {required bool approved}) =>
      _action(() => _repo.setApproval(id, approved));

  Future<bool> setStatus(String id, String status) =>
      _action(() => _repo.setStatus(id, status));

  Future<bool> _action(Future<void> Function() fn) async {
    try {
      await fn();
      await fetchListings(refresh: true);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
