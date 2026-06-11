import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/notification_model.dart';
import 'supabase_service.dart';

class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance => _instance ??= NotificationService._();

  final _notificationsController = StreamController<List<NotificationModel>>.broadcast();
  final _unreadCountController = StreamController<int>.broadcast();
  RealtimeChannel? _channel;

  NotificationService._();

  Stream<List<NotificationModel>> get notificationsStream => _notificationsController.stream;
  Stream<int> get unreadCountStream => _unreadCountController.stream;

  void dispose() {
    _channel?.unsubscribe();
    _notificationsController.close();
    _unreadCountController.close();
  }

  Future<void> subscribeToNotifications(String userId) async {
    _channel?.unsubscribe();
    _channel = SupabaseService.client
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (_) => _refreshNotifications(userId),
        )
        .subscribe();

    await _refreshNotifications(userId);
  }

  Future<List<NotificationModel>> getNotifications(String userId, {int limit = 50}) async {
    final response = await SupabaseService.table('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);

    final list = (response as List).map((e) => NotificationModel.fromJson(e)).toList();
    return list;
  }

  Future<int> getUnreadCount(String userId) async {
    final response = await SupabaseService.table('notifications')
        .select('id')
        .eq('user_id', userId)
        .eq('is_read', false)
        .count();

    return response.count!;
  }

  Future<void> markAsRead(String notificationId) async {
    await SupabaseService.table('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  Future<void> markAllAsRead(String userId) async {
    await SupabaseService.table('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  Future<void> deleteNotification(String id) async {
    await SupabaseService.table('notifications').delete().eq('id', id);
  }

  Future<void> createNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    Map<String, dynamic> data = const {},
  }) async {
    await SupabaseService.client.rpc('create_notification', params: {
      'p_user_id': userId,
      'p_type': type,
      'p_title': title,
      'p_message': message,
      'p_data': data,
    });
  }

  Future<void> _refreshNotifications(String userId) async {
    try {
      final list = await getNotifications(userId);
      _notificationsController.add(list);
      final unread = list.where((n) => !n.isRead).length;
      _unreadCountController.add(unread);
    } catch (_) {}
  }

  Future<void> unsubscribe() async {
    _channel?.unsubscribe();
    _channel = null;
  }
}
