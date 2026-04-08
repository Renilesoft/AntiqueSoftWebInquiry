import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// 🔥 Channel (MUST match Manifest)
  static const AndroidNotificationChannel _channel =
      AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    importance: Importance.max,
  );

  /// 🚀 INIT
  static Future<void> init() async {
    /// ✅ Android Init
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    /// ✅ iOS Init
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        print('📲 Local notification tapped: ${response.payload}');
        // Handle local notification tap
        _handleNotificationTap(response.payload);
      },
    );

    /// ✅ Create Android Channel (VERY IMPORTANT)
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    /// 🍎 iOS CRITICAL: Enable foreground notifications display
    if (Platform.isIOS) {
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,   // Show alert banner
        badge: true,   // Show badge
        sound: true,   // Play sound
      );
      print('✅ iOS foreground presentation enabled');
    }

    /// 🔔 Foreground Listener - SINGLE SOURCE OF TRUTH
    _setupForegroundHandler();

    /// 📲 Click Listener
    _setupNotificationTapHandler();
  }

  /// 🔔 SETUP FOREGROUND HANDLER (Single listener)
  static void _setupForegroundHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 Foreground message received: ${message.notification?.title}');

      if (message.notification != null) {
        showNotification(message);
      } else {
        print('⚠️ No notification content in message');
      }

      // Optional: Handle data payload
      if (message.data.isNotEmpty) {
        print('📦 Data Payload: ${message.data}');
      }
    });
  }

  /// 📲 SETUP TAP HANDLER
  static void _setupNotificationTapHandler() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('👆 FCM notification tapped: ${message.notification?.title}');
      _handleNotificationTap(message.messageId);
    });
  }

  /// 🔔 SHOW NOTIFICATION
  static Future<void> showNotification(RemoteMessage message) async {
    // Extract notification details
    final String title = message.notification?.title ?? "Notification";
    final String body = message.notification?.body ?? "";
    final String? payload = message.messageId;

    print('🔊 Displaying notification: $title');

    try {
      if (Platform.isAndroid) {
        await _showAndroidNotification(title, body, payload);
      } else if (Platform.isIOS) {
        await _showIOSNotification(title, body, payload);
      }
    } catch (e) {
      print('❌ Error showing notification: $e');
    }
  }

  /// 🤖 Android Notification
  static Future<void> _showAndroidNotification(
    String title,
    String body,
    String? payload,
  ) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // Use unique ID based on timestamp
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// 🍎 iOS Notification
  static Future<void> _showIOSNotification(
    String title,
    String body,
    String? payload,
  ) async {
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details =
        NotificationDetails(iOS: iosDetails);

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // Use unique ID based on timestamp
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// 📲 HANDLE TAP (Navigation Hook)
  static void _handleNotificationTap(String? payload) {
    print('🎯 Handling notification tap with payload: $payload');
    // TODO: Add your navigation logic here
    // Example:
    // navigatorKey.currentState?.pushNamed('/details', arguments: payload);
  }

  /// 🔥 Get FCM Token
  static Future<String?> getToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      print('🔥 FCM Token: $token');
      return token;
    } catch (e) {
      print('❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// 🔄 Listen to Token Refresh
  static void listenToTokenRefresh() {
    _firebaseMessaging.onTokenRefresh.listen((fcmToken) {
      print('🔄 FCM Token Refreshed: $fcmToken');
      // TODO: Send new token to your backend
    });
  }
}