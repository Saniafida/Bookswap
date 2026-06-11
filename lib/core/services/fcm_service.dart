import 'package:firebase_messaging/firebase_messaging.dart';
import 'supabase_service.dart';

class FcmService {
  FcmService._();

  static Future<void> initialize() async {
    final messaging = FirebaseMessaging.instance;

    // Request permission (iOS)
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM token
    final token = await messaging.getToken();
    if (token != null) {
      await _saveToken(token);
    }

    // Listen for token refresh
    messaging.onTokenRefresh.listen(_saveToken);

    // Foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background message tap
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpened);
  }

  static Future<String?> getToken() async {
    return FirebaseMessaging.instance.getToken();
  }

  static Future<void> _saveToken(String token) async {
    final user = SupabaseService.currentUser;
    if (user == null) return;

    await SupabaseService.table('device_tokens').upsert({
      'user_id': user.id,
      'token': token,
      'platform': 'mobile',
    });
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    // Handled by NotificationProvider via Realtime subscription
  }

  static void _handleMessageOpened(RemoteMessage message) {
    // Navigation handled in main.dart via notification provider
  }

  static Future<void> deleteToken(String userId) async {
    await SupabaseService.table('device_tokens')
        .delete()
        .eq('user_id', userId);
  }
}
