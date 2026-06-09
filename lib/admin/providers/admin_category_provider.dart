import 'package:flutter/foundation.dart';
import '../models/category_model.dart';
import '../repositories/admin_category_repository.dart';

enum AdminCategoryStatus { initial, loading, loaded, error }

class AdminCategoryProvider extends ChangeNotifier {
  final AdminCategoryRepository _repo;
  AdminCategoryProvider({AdminCategoryRepository? repo})
      : _repo = repo ?? const AdminCategoryRepository();

  AdminCategoryStatus _status = AdminCategoryStatus.initial;
  List<CategoryModel> _categories = [];
  String? _error;

  AdminCategoryStatus get status => _status;
  List<CategoryModel> get categories => _categories;
  String? get error => _error;
  bool get isLoading => _status == AdminCategoryStatus.loading;

  Future<void> fetchCategories() async {
    _status = AdminCategoryStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _categories = await _repo.fetchCategories();
      _status = AdminCategoryStatus.loaded;
    } catch (e) {
      _status = AdminCategoryStatus.error;
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<bool> addCategory(CategoryModel cat) => _mutate(() => _repo.addCategory(cat));

  Future<bool> updateCategory(CategoryModel cat) =>
      _mutate(() => _repo.updateCategory(cat));

  Future<bool> deleteCategory(String id) => _mutate(() => _repo.deleteCategory(id));

  Future<bool> toggleActive(String id, {required bool active}) =>
      _mutate(() => _repo.toggleActive(id, active: active));

  Future<bool> _mutate(Future<dynamic> Function() fn) async {
    try {
      await fn();
      await fetchCategories();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
