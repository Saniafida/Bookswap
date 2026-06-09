import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../admin/models/announcement_model.dart';
import '../core/services/supabase_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  AnnouncementProvider — user-facing live announcements from Supabase
//
//  Fetches active announcements ordered by priority (highest first).
//  Subscribes to Realtime so new admin announcements appear instantly.
//  Tracks which announcements the user has dismissed this session.
// ─────────────────────────────────────────────────────────────────────────────

enum AnnouncementStatus { initial, loading, loaded, error }

class AnnouncementProvider extends ChangeNotifier {
  AnnouncementStatus _status = AnnouncementStatus.initial;
  List<AnnouncementModel> _announcements = [];
  final Set<String> _dismissed = {};
  String? _error;
  RealtimeChannel? _channel;

  AnnouncementStatus get status => _status;
  String? get error => _error;
  bool get isLoading => _status == AnnouncementStatus.loading;

  /// Active, non-dismissed announcements ready to show to the user.
  List<AnnouncementModel> get visibleAnnouncements =>
      _announcements.where((a) => !_dismissed.contains(a.id)).toList();

  bool get hasVisible => visibleAnnouncements.isNotEmpty;

  // ── Top announcement (for banner) ─────────────────────────────────────────

  AnnouncementModel? get topAnnouncement =>
      visibleAnnouncements.isEmpty ? null : visibleAnnouncements.first;

  // ── Fetch ─────────────────────────────────────────────────────────────────

  Future<void> fetchAnnouncements() async {
    _status = AnnouncementStatus.loading;
    _error = null;
    notifyListeners();
    try {
      final data = await SupabaseService.table('announcements')
          .select()
          .eq('is_active', true)
          .order('priority', ascending: false)
          .order('created_at', ascending: false);

      _announcements = (data as List)
          .map((e) => AnnouncementModel.fromJson(e))
          .toList();
      _status = AnnouncementStatus.loaded;
    } catch (e) {
      _error = e.toString();
      _status = AnnouncementStatus.error;
    }
    notifyListeners();
  }

  // ── Dismiss (session-only) ────────────────────────────────────────────────

  void dismiss(String id) {
    _dismissed.add(id);
    notifyListeners();
  }

  // ── Realtime subscription ─────────────────────────────────────────────────

  void subscribeToAnnouncements() {
    _channel = SupabaseService.client
        .channel('public:announcements')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'announcements',
          callback: (_) => fetchAnnouncements(),
        )
        .subscribe();
  }

  void unsubscribeFromAnnouncements() {
    _channel?.unsubscribe();
    _channel = null;
  }

  @override
  void dispose() {
    unsubscribeFromAnnouncements();
    super.dispose();
  }
}
