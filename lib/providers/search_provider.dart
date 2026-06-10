import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/services/supabase_service.dart';
import '../data/models/listing_model.dart';
import '../data/repositories/listing_repository.dart';
import '../models/user_model.dart';

enum SearchTab { items, users }

enum SearchStatus { initial, loading, loaded, error }

class SearchProvider extends ChangeNotifier {
  SearchStatus _status = SearchStatus.initial;
  SearchTab _activeTab = SearchTab.items;
  String _query = '';
  String? _errorMessage;

  List<ListingModel> _listingResults = [];
  List<UserModel> _userResults = [];

  String? _selectedCategory;
  String? _selectedListingType;
  String? _selectedCondition;

  Timer? _debounceTimer;
  RealtimeChannel? _listingsChannel;
  int _searchGeneration = 0;
  String? _currentUserId;

  final ListingRepository _listingRepository = const ListingRepository();

  // ── Getters ───────────────────────────────────────────────────────────────
  SearchStatus get status => _status;
  SearchTab get activeTab => _activeTab;
  String get query => _query;
  String? get errorMessage => _errorMessage;
  List<ListingModel> get listingResults => _listingResults;
  List<UserModel> get userResults => _userResults;
  String? get selectedCategory => _selectedCategory;
  String? get selectedListingType => _selectedListingType;
  String? get selectedCondition => _selectedCondition;

  bool get isLoading => _status == SearchStatus.loading;
  bool get hasActiveFilters =>
      _selectedCategory != null ||
      _selectedListingType != null ||
      _selectedCondition != null;

  int get resultCount =>
      _activeTab == SearchTab.items ? _listingResults.length : _userResults.length;

  // ── Tab & query ───────────────────────────────────────────────────────────
  void setActiveTab(SearchTab tab) {
    if (_activeTab == tab) return;
    _activeTab = tab;
    notifyListeners();
    _runSearch(immediate: true);
  }

  void updateQuery(String value) {
    _query = value;
    notifyListeners();
    _runSearch();
  }

  void clearQuery() {
    _query = '';
    notifyListeners();
    _runSearch(immediate: true);
  }

  // ── Filters ─────────────────────────────────────────────────────────────────
  void setCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
    _runSearch(immediate: true);
  }

  void setListingType(String? type) {
    _selectedListingType = type;
    notifyListeners();
    _runSearch(immediate: true);
  }

  void setCondition(String? condition) {
    _selectedCondition = condition;
    notifyListeners();
    _runSearch(immediate: true);
  }

  void clearFilters() {
    _selectedCategory = null;
    _selectedListingType = null;
    _selectedCondition = null;
    notifyListeners();
    _runSearch(immediate: true);
  }

  // ── Search execution ────────────────────────────────────────────────────────
  void _runSearch({bool immediate = false}) {
    _debounceTimer?.cancel();
    if (immediate) {
      _executeSearch();
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 350), _executeSearch);
  }

  Future<void> _executeSearch() async {
    final generation = ++_searchGeneration;
    _setLoading();

    try {
      if (_activeTab == SearchTab.items) {
        await _searchListings();
      } else {
        await _searchUsers(excludeUserId: _currentUserId);
      }
      if (generation != _searchGeneration) return;
      _status = SearchStatus.loaded;
      notifyListeners();
    } catch (e) {
      if (generation != _searchGeneration) return;
      _setError(e.toString());
    }
  }

  Future<void> _searchListings() async {
    final trimmed = _query.trim();
    final results = await _listingRepository.searchListings(trimmed);
    _listingResults = results.where((l) {
      if (_selectedCategory != null && l.categoryName != _selectedCategory) {
        return false;
      }
      if (_selectedListingType != null && l.listingType != _selectedListingType) {
        return false;
      }
      if (_selectedCondition != null && l.condition != _selectedCondition) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> _searchUsers({String? excludeUserId}) async {
    final trimmed = _query.trim();
    var builder = SupabaseService.table('profiles').select();

    if (excludeUserId != null) {
      builder = builder.neq('id', excludeUserId);
    }
    if (trimmed.isNotEmpty) {
      builder = builder.or(
        'full_name.ilike.%$trimmed%,email.ilike.%$trimmed%,location.ilike.%$trimmed%,bio.ilike.%$trimmed%',
      );
    }

    final data = await builder.order('created_at', ascending: false).limit(30);
    _userResults =
        (data as List).map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> refresh({String? currentUserId}) async {
    if (currentUserId != null) _currentUserId = currentUserId;
    if (_activeTab == SearchTab.users) {
      await _searchUsers(excludeUserId: _currentUserId);
    } else {
      await _searchListings();
    }
    _status = SearchStatus.loaded;
    notifyListeners();
  }

  Future<void> initialize({String? currentUserId}) async {
    _currentUserId = currentUserId;
    _activeTab = SearchTab.items;
    _query = '';
    await refresh(currentUserId: currentUserId);
  }

  void setCurrentUserId(String? userId) {
    _currentUserId = userId;
  }

  // ── Realtime: refresh listing results when listings change ──────────────────
  void subscribeToListings() {
    _listingsChannel?.unsubscribe();
    _listingsChannel = SupabaseService.client
        .channel('public:search-listings')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'listings',
          callback: (_) {
            if (_activeTab == SearchTab.items) {
              _runSearch(immediate: true);
            }
          },
        )
        .subscribe();
  }

  void unsubscribe() {
    _listingsChannel?.unsubscribe();
    _listingsChannel = null;
  }

  // ── Private helpers ───────────────────────────────────────────────────────
  void _setLoading() {
    _status = SearchStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status = SearchStatus.error;
    _errorMessage = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    unsubscribe();
    super.dispose();
  }
}
