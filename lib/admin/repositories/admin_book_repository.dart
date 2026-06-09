import '../../core/services/supabase_service.dart';
import '../../models/post_model.dart';

class AdminBookRepository {
  const AdminBookRepository();

  Future<List<PostModel>> fetchBooks({
    String? search,
    String? category,
    bool? featuredOnly,
    int page = 0,
    int pageSize = 30,
  }) async {
    var query = SupabaseService.table('posts')
        .select('*, profiles(full_name, avatar_url)');

    if (search != null && search.isNotEmpty) {
      query = query.or('title.ilike.%$search%,author.ilike.%$search%');
    }
    if (category != null && category.isNotEmpty) {
      query = query.eq('category', category);
    }
    if (featuredOnly == true) {
      query = query.eq('is_featured', true);
    }

    final data = await query
        .order('created_at', ascending: false)
        .range(page * pageSize, (page + 1) * pageSize - 1);

    return (data as List).map((e) => PostModel.fromJson(e)).toList();
  }

  Future<void> createBook(Map<String, dynamic> data) async {
    await SupabaseService.table('posts').insert(data);
  }

  Future<void> updateBook(String id, Map<String, dynamic> data) async {
    await SupabaseService.table('posts').update(data).eq('id', id);
  }

  Future<void> deleteBook(String id) async {
    await SupabaseService.table('posts').delete().eq('id', id);
  }

  Future<void> setFeatured(String id, {required bool featured}) async {
    await SupabaseService.table('posts')
        .update({'is_featured': featured}).eq('id', id);
  }

  Future<void> setAvailability(String id, {required bool available}) async {
    await SupabaseService.table('posts')
        .update({'is_available': available}).eq('id', id);
  }
}
