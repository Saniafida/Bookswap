import '../../core/services/supabase_service.dart';
import '../models/category_model.dart';

class AdminCategoryRepository {
  const AdminCategoryRepository();

  Future<List<CategoryModel>> fetchCategories() async {
    final data = await SupabaseService.table('categories')
        .select()
        .order('name');
    return (data as List).map((e) => CategoryModel.fromJson(e)).toList();
  }

  Future<CategoryModel> addCategory(CategoryModel cat) async {
    final data = await SupabaseService.table('categories')
        .insert(cat.toJson())
        .select()
        .single();
    return CategoryModel.fromJson(data);
  }

  Future<CategoryModel> updateCategory(CategoryModel cat) async {
    final data = await SupabaseService.table('categories')
        .update(cat.toJson())
        .eq('id', cat.id)
        .select()
        .single();
    return CategoryModel.fromJson(data);
  }

  Future<void> deleteCategory(String id) async {
    await SupabaseService.table('categories').delete().eq('id', id);
  }

  Future<void> toggleActive(String id, {required bool active}) async {
    await SupabaseService.table('categories')
        .update({'is_active': active}).eq('id', id);
  }
}
