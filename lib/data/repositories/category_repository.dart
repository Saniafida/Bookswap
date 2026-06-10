import '../../core/services/supabase_service.dart';
import '../../admin/models/category_model.dart';

class CategoryRepository {
  const CategoryRepository();

  Future<List<CategoryModel>> fetchActiveCategories() async {
    final data = await SupabaseService.table('categories')
        .select()
        .eq('is_active', true)
        .order('display_order')
        .order('name');
    return (data as List).map((e) => CategoryModel.fromJson(e)).toList();
  }

  Future<List<CategoryModel>> fetchFeaturedCategories() async {
    final data = await SupabaseService.table('categories')
        .select()
        .eq('is_active', true)
        .eq('is_featured', true)
        .order('display_order')
        .order('name');
    return (data as List).map((e) => CategoryModel.fromJson(e)).toList();
  }

  Future<CategoryModel?> getCategory(String id) async {
    try {
      final data = await SupabaseService.table('categories')
          .select()
          .eq('id', id)
          .single();
      return CategoryModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }
}
