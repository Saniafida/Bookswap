import 'package:flutter/foundation.dart';
import '../admin/models/app_settings_model.dart';
import '../core/services/supabase_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  AppSettingsProvider — user-facing dynamic app settings from Supabase
//
//  Reads the app_settings key-value table and exposes a typed AppSettingsModel.
//  Used in the user app for displaying app name, contact info, etc.
// ─────────────────────────────────────────────────────────────────────────────

enum AppSettingsStatus { initial, loading, loaded, error }

class AppSettingsProvider extends ChangeNotifier {
  AppSettingsStatus _status = AppSettingsStatus.initial;
  AppSettingsModel _settings = const AppSettingsModel();
  String? _error;

  AppSettingsStatus get status => _status;
  AppSettingsModel get settings => _settings;
  String? get error => _error;
  bool get isLoading => _status == AppSettingsStatus.loading;

  // ── Convenience getters ───────────────────────────────────────────────────
  String get appName => _settings.appName;
  String get contactEmail => _settings.contactEmail;
  String get privacyPolicy => _settings.privacyPolicy;
  String get termsAndConditions => _settings.termsAndConditions;

  // ── Fetch ─────────────────────────────────────────────────────────────────

  Future<void> fetchSettings() async {
    _status = AppSettingsStatus.loading;
    _error = null;
    notifyListeners();
    try {
      final data = await SupabaseService.table('app_settings').select();
      _settings = AppSettingsModel.fromRows(
        (data as List).cast<Map<String, dynamic>>(),
      );
      _status = AppSettingsStatus.loaded;
    } catch (e) {
      _error = e.toString();
      _status = AppSettingsStatus.error;
      // Keep defaults on error — app stays functional
    }
    notifyListeners();
  }
}
