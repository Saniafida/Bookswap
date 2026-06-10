import 'package:flutter/foundation.dart';
import '../data/repositories/home_repository.dart';
import '../data/models/listing_model.dart';

enum HomeStatus { initial, loading, loaded, error }

class HomeProvider extends ChangeNotifier {
  final HomeRepository _repository = const HomeRepository();

  HomeStatus _status = HomeStatus.initial;
  List<ListingModel> _featuredListings = [];
  List<ListingModel> _recentListings = [];
  List<ListingModel> _popularListings = [];
  String? _errorMessage;

  HomeStatus get status => _status;
  List<ListingModel> get featuredListings => _featuredListings;
  List<ListingModel> get recentListings => _recentListings;
  List<ListingModel> get popularListings => _popularListings;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == HomeStatus.loading;

  Future<void> fetchHomeData() async {
    _setLoading();
    try {
      final results = await Future.wait<dynamic>([
        _repository.fetchFeaturedListings(),
        _repository.fetchRecentListings(),
        _repository.fetchPopularListings(),
      ]);

      _featuredListings = results[0] as List<ListingModel>;
      _recentListings = results[1] as List<ListingModel>;
      _popularListings = results[2] as List<ListingModel>;

      _status = HomeStatus.loaded;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> refreshHome() async {
    await fetchHomeData();
  }

  void _setLoading() {
    _status = HomeStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status = HomeStatus.error;
    _errorMessage = message;
    notifyListeners();
  }
}
