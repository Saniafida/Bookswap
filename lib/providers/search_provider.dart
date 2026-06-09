import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/services/supabase_service.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';

enum SearchTab { books, users }

enum SearchStatus { initial, loading, loaded, error }

class SearchProvider extends ChangeNotifier {
  SearchStatus _status = SearchStatus.initial;
  SearchTab _activeTab = SearchTab.books;
  String _query = '';
  String? _errorMessage;

  List<PostModel> _bookResults = [];
  List<UserModel> _userResults = [];

  String? _selectedCategory;
  ListingType? _selectedListingType;
  BookCondition? _selectedCondition;

  Timer? _debounceTimer;
  RealtimeChannel? _postsChannel;
  int _searchGeneration = 0;
  String? _currentUserId;

  // ── Getters ───────────────────────────────────────────────────────────────
  SearchStatus get status => _status;
  SearchTab get activeTab => _activeTab;
  String get query => _query;
  String? get errorMessage => _errorMessage;
  List<PostModel> get bookResults => _bookResults;
  List<UserModel> get userResults => _userResults;
  String? get selectedCategory => _selectedCategory;
  ListingType? get selectedListingType => _selectedListingType;
  BookCondition? get selectedCondition => _selectedCondition;

  bool get isLoading => _status == SearchStatus.loading;
  bool get hasActiveFilters =>
      _selectedCategory != null ||
      _selectedListingType != null ||
      _selectedCondition != null;

  int get resultCount =>
      _activeTab == SearchTab.books ? _bookResults.length : _userResults.length;

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

  void setListingType(ListingType? type) {
    _selectedListingType = type;
    notifyListeners();
    _runSearch(immediate: true);
  }

  void setCondition(BookCondition? condition) {
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
      if (_activeTab == SearchTab.books) {
        await _searchBooks();
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

  Future<void> _searchBooks() async {
    final trimmed = _query.trim();
    var builder = SupabaseService.table('posts')
        .select('*, profiles(full_name, avatar_url)')
        .eq('is_available', true);

    if (trimmed.isNotEmpty) {
      builder = builder.or('title.ilike.%$trimmed%,author.ilike.%$trimmed%');
    }
    if (_selectedCategory != null) {
      builder = builder.eq('category', _selectedCategory!);
    }
    if (_selectedListingType != null) {
      builder = builder.eq('listing_type', _selectedListingType!.name);
    }
    if (_selectedCondition != null) {
      builder = builder.eq('condition', _selectedCondition!.name);
    }

    final data = await builder.order('created_at', ascending: false);
    _bookResults =
        (data as List).map((e) => PostModel.fromJson(e as Map<String, dynamic>)).toList();
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
      await _searchBooks();
    }
    _status = SearchStatus.loaded;
    notifyListeners();
  }

  Future<void> initialize({String? currentUserId}) async {
    _currentUserId = currentUserId;
    _activeTab = SearchTab.books;
    _query = '';
    await refresh(currentUserId: currentUserId);
  }

  void setCurrentUserId(String? userId) {
    _currentUserId = userId;
  }

  // ── Realtime: refresh book results when posts change ────────────────────────
  void subscribeToPosts() {
    _postsChannel?.unsubscribe();
    _postsChannel = SupabaseService.client
        .channel('public:search-posts')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'posts',
          callback: (_) {
            if (_activeTab == SearchTab.books) {
              _runSearch(immediate: true);
            }
          },
        )
        .subscribe();
  }

  void unsubscribe() {
    _postsChannel?.unsubscribe();
    _postsChannel = null;
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
