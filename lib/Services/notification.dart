import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io' show Platform;

class NotificationService {
  // ignore: unused_field
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Singleton pattern for better resource management
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> init() async {
    try {
      // Android initialization
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('app_icon');
      
      // iOS initialization with comprehensive settings
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        requestCriticalPermission: false,
        requestProvisionalPermission: false,
        // Additional iOS-specific settings
        defaultPresentAlert: true,
        defaultPresentBadge: true,
        defaultPresentSound: true,
      );

      // Combined initialization settings
      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) async {
          await _handleNotificationTap(response);
        },
      );

      // Create notification channel for Android
      if (Platform.isAndroid) {
        await _createNotificationChannel();
      }

      // ignore: avoid_print
      print('NotificationService initialized successfully');
    } catch (e) {
      // ignore: avoid_print
      print('NotificationService initialization failed: $e');
      rethrow;
    }
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // Channel ID
      'High Importance Notifications', // Channel name
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(channel);
      // ignore: avoid_print
      print('Android notification channel created');
    }
  }

  Future<void> _showNotification(RemoteMessage message) async {
    try {
      // Generate unique notification ID
      int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      // Android notification settings
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'high_importance_channel', // Use the channel we created
        'High Importance Notifications',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        icon: 'app_icon',
        enableVibration: true,
        playSound: true,
        // Additional Android settings
        autoCancel: true,
        ongoing: false,
      );

      // iOS notification settings with comprehensive options
      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,    // Show alert when app is in foreground
        presentBadge: true,    // Update app badge
        presentSound: true,    // Play sound
        sound: 'default',      // Use default sound
        // Additional iOS settings
        badgeNumber: null,     // Let the system handle badge numbers
        threadIdentifier: 'antiquesoft_notifications',
        categoryIdentifier: 'general',
      );

      // Combined notification settings
      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      // Extract notification data
      String title = message.notification?.title ?? 'AntiqueSoft';
      String body = message.notification?.body ?? 'You have a new message';
      String? payload = message.data.isNotEmpty ? message.data.toString() : null;

      await _flutterLocalNotificationsPlugin.show(
        notificationId,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );

      // ignore: avoid_print
      print('Local notification shown successfully');
      // ignore: avoid_print
      print('Platform: ${Platform.isIOS ? 'iOS' : 'Android'}');
      // ignore: avoid_print
      print('Title: $title');
      // ignore: avoid_print
      print(' Body: $body');
      
    } catch (e) {
      // ignore: avoid_print
      print('Failed to show local notification: $e');
    }
  }

  Future<void> _handleNotificationTap(NotificationResponse response) async {
    try {
      // ignore: avoid_print
      print('Notification tapped with payload: ${response.payload}');
      
      // Parse payload and handle navigation
      if (response.payload != null) {
        // Add your navigation logic here
        // Example: Navigate to specific screen based on payload
        // ignore: avoid_print
        print('📱 Handling notification tap with payload: ${response.payload}');
      }
    } catch (e) {
      // ignore: avoid_print
      print(' Error handling notification tap: $e');
    }
  }

  // Public method to show notification (called from main.dart)
  Future<void> showNotification(RemoteMessage message) async {
    // ignore: avoid_print
    print('showNotification called for: ${message.notification?.title}');
    // ignore: avoid_print
    print('Message data: ${message.data}');
    
    // Always show local notification for consistency across platforms
    await _showNotification(message);
  }

  // Simple method to show local notification directly (call this from your API)
  Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    try {
      int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      const DarwinNotificationDetails iOSDetails =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        notificationId,
        title,
        body,
        platformChannelSpecifics,
      );

      // ignore: avoid_print
      print('✅ Local notification shown: $title - $body');
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error showing notification: $e');
    }
  }

  // Method to cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      // ignore: avoid_print
      print('All notifications cancelled');
    } catch (e) {
      // ignore: avoid_print
      print('Failed to cancel notifications: $e');
    }
  }

  // Method to cancel specific notification
  Future<void> cancelNotification(int id) async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(id);
      // ignore: avoid_print
      print('Notification $id cancelled');
    } catch (e) {
      // ignore: avoid_print
      print('Failed to cancel notification $id: $e');
    }
  }

  // Method to get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
    } catch (e) {
      // ignore: avoid_print
      print(' Failed to get pending notifications: $e');
      return [];
    }
  }

  // Method to check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    try {
      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
            _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        return await androidPlugin?.areNotificationsEnabled() ?? false;
      } else if (Platform.isIOS) {
        final IOSFlutterLocalNotificationsPlugin? iosPlugin =
            _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
        return await iosPlugin?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ?? false;
      }
      return false;
    } catch (e) {
      // ignore: avoid_print
      print('Failed to check notification permissions: $e');
      return false;
    }
  }
}