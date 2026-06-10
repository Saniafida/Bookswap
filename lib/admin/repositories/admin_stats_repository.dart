import '../../core/services/supabase_service.dart';
import '../models/admin_stats_model.dart';

class AdminStatsRepository {
  const AdminStatsRepository();

  Future<AdminStatsModel> fetchStats() async {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day).toIso8601String();

    final results = await Future.wait([
      SupabaseService.table('profiles').select('id').count(),
      SupabaseService.table('listings').select('id').count(),
      SupabaseService.table('chats').select('id').count(),
      SupabaseService.table('listings').select('id').eq('listing_type', 'donate').count(),
      SupabaseService.table('listings').select('id').eq('listing_type', 'exchange').count(),
      SupabaseService.table('listings').select('id').eq('listing_type', 'sell').count(),
      SupabaseService.table('profiles').select('id').gte('created_at', todayStart).count(),
      SupabaseService.table('listings').select('id').gte('created_at', todayStart).count(),
      SupabaseService.table('reports').select('id').eq('status', 'pending').count(),
      SupabaseService.table('announcements').select('id').eq('is_active', true).count(),
    ]);

    return AdminStatsModel(
      totalUsers: results[0].count,
      totalBooks: results[1].count,
      totalChats: results[2].count,
      totalDonations: results[3].count,
      totalExchanges: results[4].count,
      totalSells: results[5].count,
      newUsersToday: results[6].count,
      newBooksToday: results[7].count,
      pendingReports: results[8].count,
      activeAnnouncements: results[9].count,
    );
  }

  /// Returns user counts grouped by month for the last 6 months.
  Future<List<Map<String, dynamic>>> fetchUserGrowth() async {
    try {
      final data = await SupabaseService.client.rpc('get_user_growth_monthly');
      return List<Map<String, dynamic>>.from(data as List);
    } catch (_) {
      return [];
    }
  }

  /// Returns listing counts grouped by listing_type.
  Future<Map<String, int>> fetchBookStats() async {
    final data = await SupabaseService.table('listings')
        .select('listing_type')
        .order('listing_type');
    final map = <String, int>{};
    for (final row in data as List) {
      final t = row['listing_type'] as String;
      map[t] = (map[t] ?? 0) + 1;
    }
    return map;
  }

  /// Returns listing counts grouped by category.
  Future<Map<String, int>> fetchCategoryStats() async {
    final data = await SupabaseService.table('listings')
        .select('category_id');
    final map = <String, int>{};
    for (final row in data as List) {
      final c = row['category_id'] as String? ?? 'Uncategorized';
      map[c] = (map[c] ?? 0) + 1;
    }
    return map;
  }
}
