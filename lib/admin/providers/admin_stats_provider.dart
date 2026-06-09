import 'package:flutter/foundation.dart';
import '../models/admin_stats_model.dart';
import '../repositories/admin_stats_repository.dart';

enum AdminStatsStatus { initial, loading, loaded, error }

class AdminStatsProvider extends ChangeNotifier {
  final AdminStatsRepository _repo;
  AdminStatsProvider({AdminStatsRepository? repo})
      : _repo = repo ?? const AdminStatsRepository();

  AdminStatsStatus _status = AdminStatsStatus.initial;
  AdminStatsModel _stats = const AdminStatsModel();
  Map<String, int> _bookStats = {};
  Map<String, int> _categoryStats = {};
  String? _error;

  AdminStatsStatus get status => _status;
  AdminStatsModel get stats => _stats;
  Map<String, int> get bookStats => _bookStats;
  Map<String, int> get categoryStats => _categoryStats;
  String? get error => _error;
  bool get isLoading => _status == AdminStatsStatus.loading;

  Future<void> fetchAll() async {
    _status = AdminStatsStatus.loading;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repo.fetchStats(),
        _repo.fetchBookStats(),
        _repo.fetchCategoryStats(),
      ]);
      _stats = results[0] as AdminStatsModel;
      _bookStats = results[1] as Map<String, int>;
      _categoryStats = results[2] as Map<String, int>;
      _status = AdminStatsStatus.loaded;
    } catch (e) {
      _status = AdminStatsStatus.error;
      _error = e.toString();
    }
    notifyListeners();
  }
}
