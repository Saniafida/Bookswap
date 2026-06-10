import 'package:flutter/foundation.dart';
import '../data/repositories/favorite_repository.dart';
import '../data/models/listing_model.dart';

enum FavoriteStatus { initial, loading, loaded, error }

class FavoriteProvider extends ChangeNotifier {
  final FavoriteRepository _repository = const FavoriteRepository();

  FavoriteStatus _status = FavoriteStatus.initial;
  List<ListingModel> _favoriteListings = [];
  Set<String> _favoriteIds = {};
  String? _errorMessage;

  FavoriteStatus get status => _status;
  List<ListingModel> get favoriteListings => _favoriteListings;
  Set<String> get favoriteIds => _favoriteIds;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == FavoriteStatus.loading;

  Future<void> fetchFavorites(String userId) async {
    _setLoading();
    try {
      _favoriteListings = await _repository.fetchFavorites(userId);
      _favoriteIds = _favoriteListings.map((l) => l.id).toSet();
      _status = FavoriteStatus.loaded;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<bool> toggleFavorite(String userId, String listingId) async {
    try {
      final isNowFavorited = await _repository.toggleFavorite(userId, listingId);
      if (isNowFavorited) {
        _favoriteIds.add(listingId);
      } else {
        _favoriteIds.remove(listingId);
        _favoriteListings.removeWhere((l) => l.id == listingId);
      }
      notifyListeners();
      return isNowFavorited;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  bool isFavorited(String listingId) {
    return _favoriteIds.contains(listingId);
  }

  void _setLoading() {
    _status = FavoriteStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status = FavoriteStatus.error;
    _errorMessage = message;
    notifyListeners();
  }
}
