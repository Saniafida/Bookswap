import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../admin/models/category_model.dart';
import '../core/services/supabase_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  CategoryProvider — user-facing, live categories from Supabase
//
//  Subscribes to Supabase Realtime so admin changes (create / update / delete)
//  are instantly reflected in the user app without a manual refresh.
// ─────────────────────────────────────────────────────────────────────────────

enum CategoryStatus { initial, loading, loaded, error }

class CategoryProvider extends ChangeNotifier {
  CategoryStatus _status = CategoryStatus.initial;
  List<CategoryModel> _categories = [];
  String? _error;
  RealtimeChannel? _channel;

  CategoryStatus get status => _status;
  List<CategoryModel> get categories => _categories;
  String? get error => _error;
  bool get isLoading => _status == CategoryStatus.loading;

  /// Category names only (for dropdowns / filter chips).
  List<String> get categoryNames =>
      _categories.map((c) => c.name).toList();

  /// "All Books" + live category names (for home feed filter row).
  List<String> get filterOptions => ['All Books', ...categoryNames];

  // ── Fetch ─────────────────────────────────────────────────────────────────

  Future<void> fetchCategories() async {
    _status = CategoryStatus.loading;
    _error = null;
    notifyListeners();
    try {
      final data = await SupabaseService.table('categories')
          .select()
          .eq('is_active', true)
          .order('name');

      _categories =
          (data as List).map((e) => CategoryModel.fromJson(e)).toList();
      _status = CategoryStatus.loaded;
    } catch (e) {
      _error = e.toString();
      _status = CategoryStatus.error;
    }
    notifyListeners();
  }

  // ── Realtime subscription ─────────────────────────────────────────────────

  void subscribeToCategories() {
    _channel = SupabaseService.client
        .channel('public:categories')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'categories',
          callback: (_) => fetchCategories(),
        )
        .subscribe();
  }

  void unsubscribeFromCategories() {
    _channel?.unsubscribe();
    _channel = null;
  }

  @override
  void dispose() {
    unsubscribeFromCategories();
    super.dispose();
  }
}
