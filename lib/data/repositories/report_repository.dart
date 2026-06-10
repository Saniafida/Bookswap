import '../../core/services/supabase_service.dart';
import '../models/report_model.dart';

class ReportRepository {
  const ReportRepository();

  Future<bool> submitReport(Map<String, dynamic> data) async {
    try {
      await SupabaseService.table('reports').insert(data);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<ReportModel>> fetchMyReports(String userId) async {
    final data = await SupabaseService.table('reports')
        .select()
        .eq('reporter_id', userId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => ReportModel.fromJson(e)).toList();
  }
}
