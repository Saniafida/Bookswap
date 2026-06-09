import 'package:flutter/foundation.dart';
import '../models/announcement_model.dart';
import '../repositories/admin_announcement_repository.dart';

enum AdminAnnouncementStatus { initial, loading, loaded, error }

class AdminAnnouncementProvider extends ChangeNotifier {
  final AdminAnnouncementRepository _repo;
  AdminAnnouncementProvider({AdminAnnouncementRepository? repo})
      : _repo = repo ?? const AdminAnnouncementRepository();

  AdminAnnouncementStatus _status = AdminAnnouncementStatus.initial;
  List<AnnouncementModel> _announcements = [];
  String? _error;

  AdminAnnouncementStatus get status => _status;
  List<AnnouncementModel> get announcements => _announcements;
  String? get error => _error;
  bool get isLoading => _status == AdminAnnouncementStatus.loading;

  Future<void> fetchAnnouncements() async {
    _status = AdminAnnouncementStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _announcements = await _repo.fetchAnnouncements();
      _status = AdminAnnouncementStatus.loaded;
    } catch (e) {
      _status = AdminAnnouncementStatus.error;
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<bool> create(AnnouncementModel ann) => _mutate(() => _repo.createAnnouncement(ann));
  Future<bool> update(AnnouncementModel ann) => _mutate(() => _repo.updateAnnouncement(ann));
  Future<bool> delete(String id) => _mutate(() => _repo.deleteAnnouncement(id));
  Future<bool> toggleActive(String id, {required bool active}) =>
      _mutate(() => _repo.toggleActive(id, active: active));

  Future<bool> _mutate(Future<dynamic> Function() fn) async {
    try {
      await fn();
      await fetchAnnouncements();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
