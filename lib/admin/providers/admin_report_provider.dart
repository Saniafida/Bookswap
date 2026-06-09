import 'package:flutter/foundation.dart';
import '../models/report_model.dart';
import '../repositories/admin_report_repository.dart';

enum AdminReportStatus { initial, loading, loaded, error }

class AdminReportProvider extends ChangeNotifier {
  final AdminReportRepository _repo;
  AdminReportProvider({AdminReportRepository? repo})
      : _repo = repo ?? const AdminReportRepository();

  AdminReportStatus _status = AdminReportStatus.initial;
  List<ReportModel> _reports = [];
  ReportStatus _filter = ReportStatus.pending;
  String? _error;

  AdminReportStatus get status => _status;
  List<ReportModel> get reports => _reports;
  ReportStatus get filter => _filter;
  String? get error => _error;
  bool get isLoading => _status == AdminReportStatus.loading;

  Future<void> fetchReports({ReportStatus? statusFilter}) async {
    _filter = statusFilter ?? _filter;
    _status = AdminReportStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _reports = await _repo.fetchReports(status: _filter);
      _status = AdminReportStatus.loaded;
    } catch (e) {
      _status = AdminReportStatus.error;
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<bool> resolveReport(String id, {String? note}) async {
    try {
      await _repo.resolveReport(id, adminNote: note);
      await fetchReports();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> dismissReport(String id, {String? note}) async {
    try {
      await _repo.dismissReport(id, adminNote: note);
      await fetchReports();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteReport(String id) async {
    try {
      await _repo.deleteReport(id);
      await fetchReports();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
