import '../../core/services/supabase_service.dart';
import '../../models/user_model.dart';
import '../../data/models/listing_model.dart';

class AdminUserRepository {
  const AdminUserRepository();

  Future<List<UserModel>> fetchUsers({
    String? search,
    bool? bannedOnly,
    int page = 0,
    int pageSize = 30,
  }) async {
    var query = SupabaseService.table('profiles')
        .select('id, email, full_name, avatar_url, bio, location, swap_count, created_at, role, is_banned');

    if (bannedOnly == true) {
      query = query.eq('is_banned', true);
    }

    if (search != null && search.isNotEmpty) {
      query = query.or('full_name.ilike.%$search%,email.ilike.%$search%');
    }

    final data = await query
        .order('created_at', ascending: false)
        .range(page * pageSize, (page + 1) * pageSize - 1);

    return (data as List).map((e) => UserModel.fromJson(e)).toList();
  }

  Future<UserModel> fetchUserDetail(String uid) async {
    final data = await SupabaseService.table('profiles')
        .select('id, email, full_name, avatar_url, bio, location, swap_count, created_at, role, is_banned')
        .eq('id', uid)
        .single();
    return UserModel.fromJson(data);
  }

  Future<List<ListingModel>> fetchUserListings(String uid) async {
    final data = await SupabaseService.table('listings')
        .select('*, profiles(full_name, avatar_url), categories(name, icon), listing_images(*)')
        .eq('user_id', uid)
        .order('created_at', ascending: false);
    return (data as List).map((e) => ListingModel.fromJson(e)).toList();
  }

  Future<void> banUser(String uid) async {
    await SupabaseService.table('profiles')
        .update({'is_banned': true}).eq('id', uid);
  }

  Future<void> unbanUser(String uid) async {
    await SupabaseService.table('profiles')
        .update({'is_banned': false}).eq('id', uid);
  }

  Future<void> deleteUser(String uid) async {
    await SupabaseService.table('profiles').delete().eq('id', uid);
  }

  Future<void> changeRole(String uid, String role) async {
    await SupabaseService.table('profiles')
        .update({'role': role}).eq('id', uid);
  }
}
