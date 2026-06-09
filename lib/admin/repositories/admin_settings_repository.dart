import '../../core/services/supabase_service.dart';
import '../models/app_settings_model.dart';

class AdminSettingsRepository {
  const AdminSettingsRepository();

  Future<AppSettingsModel> fetchSettings() async {
    final data = await SupabaseService.table('app_settings').select('key, value');
    return AppSettingsModel.fromRows(List<Map<String, dynamic>>.from(data as List));
  }

  Future<void> saveSettings(AppSettingsModel settings) async {
    final rows = settings.toRows();
    for (final row in rows) {
      await SupabaseService.table('app_settings')
          .upsert({...row, 'updated_at': DateTime.now().toIso8601String()});
    }
  }

  Future<void> updateSetting(String key, String value) async {
    await SupabaseService.table('app_settings').upsert({
      'key': key,
      'value': value,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
