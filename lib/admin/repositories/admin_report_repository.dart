import '../../core/services/supabase_service.dart';
import '../models/report_model.dart';

class AdminReportRepository {
  const AdminReportRepository();

  Future<List<ReportModel>> fetchReports({ReportStatus? status}) async {
    var query = SupabaseService.table('reports').select(
      'id, reporter_id, reported_post_id, reported_user_id, reason, status, admin_note, created_at, resolved_at, '
      'reporter:profiles!reporter_id(full_name), '
      'reported_post:posts!reported_post_id(title), '
      'reported_user:profiles!reported_user_id(full_name)',
    );

    if (status != null) {
      query = query.eq('status', status.name);
    }

    final data = await query.order('created_at', ascending: false);
    return (data as List).map((e) => ReportModel.fromJson(e)).toList();
  }

  Future<void> resolveReport(String id, {String? adminNote}) async {
    await SupabaseService.table('reports').update({
      'status': 'resolved',
      'admin_note': adminNote,
      'resolved_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> dismissReport(String id, {String? adminNote}) async {
    await SupabaseService.table('reports').update({
      'status': 'dismissed',
      'admin_note': adminNote,
      'resolved_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> deleteReport(String id) async {
    await SupabaseService.table('reports').delete().eq('id', id);
  }
}
