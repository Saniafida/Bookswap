import 'package:flutter/foundation.dart';
import '../data/repositories/report_repository.dart';
import '../data/models/report_model.dart';

enum ReportStatus { initial, loading, loaded, error }

class ReportProvider extends ChangeNotifier {
  final ReportRepository _repository = const ReportRepository();

  ReportStatus _status = ReportStatus.initial;
  List<ReportModel> _myReports = [];
  String? _errorMessage;

  ReportStatus get status => _status;
  List<ReportModel> get myReports => _myReports;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == ReportStatus.loading;

  Future<bool> submitReport({
    required String reporterId,
    required String listingId,
    required String reason,
    String? description,
  }) async {
    _setLoading();
    try {
      await _repository.submitReport({
        'reporter_id': reporterId,
        'listing_id': listingId,
        'reason': reason,
        'description': description,
        'status': 'pending',
      });
      _status = ReportStatus.loaded;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> submitReportUser({
    required String reporterId,
    required String userId,
    required String reason,
    String? description,
  }) async {
    _setLoading();
    try {
      await _repository.submitReport({
        'reporter_id': reporterId,
        'user_id': userId,
        'reason': reason,
        'description': description,
        'status': 'pending',
      });
      _status = ReportStatus.loaded;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<void> fetchMyReports(String userId) async {
    _setLoading();
    try {
      _myReports = await _repository.fetchMyReports(userId);
      _status = ReportStatus.loaded;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  void _setLoading() {
    _status = ReportStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status = ReportStatus.error;
    _errorMessage = message;
    notifyListeners();
  }
}
