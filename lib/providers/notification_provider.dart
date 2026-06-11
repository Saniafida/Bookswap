import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../core/services/supabase_service.dart';
import '../core/services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  StreamSubscription<List<NotificationModel>>? _sub;
  StreamSubscription<int>? _countSub;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  void init() {
    final user = SupabaseService.currentUser;
    if (user == null) return;

    _sub?.cancel();
    _countSub?.cancel();

    NotificationService.instance.subscribeToNotifications(user.id);

    _sub = NotificationService.instance.notificationsStream.listen((list) {
      _notifications = list;
      _unreadCount = list.where((n) => !n.isRead).length;
      notifyListeners();
    });

    _countSub = NotificationService.instance.unreadCountStream.listen((count) {
      _unreadCount = _unreadCount + count;
      notifyListeners();
    });
  }

  void disposeProvider() {
    _sub?.cancel();
    _countSub?.cancel();
  }

  Future<void> refresh() async {
    final user = SupabaseService.currentUser;
    if (user == null) return;
    _isLoading = true;
    notifyListeners();
    await NotificationService.instance.subscribeToNotifications(user.id);
    _isLoading = false;
  }

  Future<void> markAsRead(String notificationId) async {
    await NotificationService.instance.markAsRead(notificationId);
    final idx = _notifications.indexWhere((n) => n.id == notificationId);
    if (idx != -1) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      _unreadCount = _notifications.where((n) => !n.isRead).length;
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    final user = SupabaseService.currentUser;
    if (user == null) return;
    await NotificationService.instance.markAllAsRead(user.id);
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    _unreadCount = 0;
    notifyListeners();
  }

  Future<void> deleteNotification(String id) async {
    await NotificationService.instance.deleteNotification(id);
    _notifications.removeWhere((n) => n.id == id);
    _unreadCount = _notifications.where((n) => !n.isRead).length;
    notifyListeners();
  }
}
