import 'package:flutter/foundation.dart';
import '../../models/post_model.dart';
import '../repositories/admin_book_repository.dart';

enum AdminBookStatus { initial, loading, loaded, error }

class AdminBookProvider extends ChangeNotifier {
  final AdminBookRepository _repo;
  AdminBookProvider({AdminBookRepository? repo})
      : _repo = repo ?? const AdminBookRepository();

  AdminBookStatus _status = AdminBookStatus.initial;
  List<PostModel> _books = [];
  String? _error;
  String _searchQuery = '';
  String? _categoryFilter;
  int _page = 0;
  bool _hasMore = true;

  AdminBookStatus get status => _status;
  List<PostModel> get books => _books;
  String? get error => _error;
  bool get isLoading => _status == AdminBookStatus.loading;
  bool get hasMore => _hasMore;

  Future<void> fetchBooks({bool refresh = false}) async {
    if (refresh) {
      _page = 0;
      _books = [];
      _hasMore = true;
    }
    if (!_hasMore) return;
    _status = AdminBookStatus.loading;
    _error = null;
    notifyListeners();
    try {
      final result = await _repo.fetchBooks(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        category: _categoryFilter,
        page: _page,
      );
      if (result.length < 30) _hasMore = false;
      _books = refresh ? result : [..._books, ...result];
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
    fetchBooks(refresh: true);
  }

  void setCategory(String? cat) {
    _categoryFilter = cat;
    fetchBooks(refresh: true);
  }

  Future<bool> createBook(Map<String, dynamic> data) =>
      _action(() => _repo.createBook(data));

  Future<bool> deleteBook(String id) => _action(() => _repo.deleteBook(id));

  Future<bool> setFeatured(String id, {required bool featured}) =>
      _action(() => _repo.setFeatured(id, featured: featured));

  Future<bool> updateBook(String id, Map<String, dynamic> data) =>
      _action(() => _repo.updateBook(id, data));

  Future<bool> _action(Future<void> Function() fn) async {
    try {
      await fn();
      await fetchBooks(refresh: true);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
