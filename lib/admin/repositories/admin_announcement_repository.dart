import '../../core/services/supabase_service.dart';
import '../models/announcement_model.dart';

class AdminAnnouncementRepository {
  const AdminAnnouncementRepository();

  Future<List<AnnouncementModel>> fetchAnnouncements() async {
    final data = await SupabaseService.table('announcements')
        .select()
        .order('priority', ascending: false)
        .order('created_at', ascending: false);
    return (data as List).map((e) => AnnouncementModel.fromJson(e)).toList();
  }

  Future<AnnouncementModel> createAnnouncement(AnnouncementModel ann) async {
    final data = await SupabaseService.table('announcements')
        .insert(ann.toJson())
        .select()
        .single();
    return AnnouncementModel.fromJson(data);
  }

  Future<AnnouncementModel> updateAnnouncement(AnnouncementModel ann) async {
    final data = await SupabaseService.table('announcements')
        .update({...ann.toJson(), 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', ann.id)
        .select()
        .single();
    return AnnouncementModel.fromJson(data);
  }

  Future<void> deleteAnnouncement(String id) async {
    await SupabaseService.table('announcements').delete().eq('id', id);
  }

  Future<void> toggleActive(String id, {required bool active}) async {
    await SupabaseService.table('announcements')
        .update({
          'is_active': active,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }
}
