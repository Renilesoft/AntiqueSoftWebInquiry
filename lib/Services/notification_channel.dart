import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io' show Platform;

class NotificationChannel {
  static Future<void> createNotificationChannels() async {
    // Only create channel on Android (iOS doesn't need it)
    if (!Platform.isAndroid) {
      return;
    }

    try {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'default_notification_channel_id',
        'Default Notifications',
        description: 'This channel is used for default notifications.',
        importance: Importance.max,
        playSound: true,
      );

      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation;
              AndroidFlutterLocalNotificationsPlugin()
          ?.createNotificationChannel(channel);

      print('✅ Android notification channel created');
    } catch (e) {
      print('❌ Error creating notification channel: $e');
    }
  }
}