import 'package:flutter/foundation.dart';
import '../models/app_settings_model.dart';
import '../repositories/admin_settings_repository.dart';

enum AdminSettingsStatus { initial, loading, loaded, saving, error }

class AdminSettingsProvider extends ChangeNotifier {
  final AdminSettingsRepository _repo;
  AdminSettingsProvider({AdminSettingsRepository? repo})
      : _repo = repo ?? const AdminSettingsRepository();

  AdminSettingsStatus _status = AdminSettingsStatus.initial;
  AppSettingsModel _settings = const AppSettingsModel();
  String? _error;

  AdminSettingsStatus get status => _status;
  AppSettingsModel get settings => _settings;
  String? get error => _error;
  bool get isLoading => _status == AdminSettingsStatus.loading;
  bool get isSaving => _status == AdminSettingsStatus.saving;

  Future<void> fetchSettings() async {
    _status = AdminSettingsStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _settings = await _repo.fetchSettings();
      _status = AdminSettingsStatus.loaded;
    } catch (e) {
      _status = AdminSettingsStatus.error;
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<bool> saveSettings(AppSettingsModel updated) async {
    _status = AdminSettingsStatus.saving;
    _error = null;
    notifyListeners();
    try {
      await _repo.saveSettings(updated);
      _settings = updated;
      _status = AdminSettingsStatus.loaded;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AdminSettingsStatus.error;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
