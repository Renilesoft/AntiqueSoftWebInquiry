import 'package:antiquewebemquiry/Global/sales.dart';
import 'package:antiquewebemquiry/Global/yearlytotalquantity.dart';
import 'package:antiquewebemquiry/Global/yearlytotalsales.dart';
import 'package:antiquewebemquiry/Global/username.dart';
import 'package:antiquewebemquiry/Global/vendorid.dart';
import 'package:antiquewebemquiry/app_data.dart';
import 'package:antiquewebemquiry/view/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;
import 'viewmodel/login_viewmodel.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

// ─────────────────────────────────────────────────────────────
// GLOBAL: Local notifications plugin instance
// ─────────────────────────────────────────────────────────────
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// ─────────────────────────────────────────────────────────────
// BACKGROUND HANDLER
// Must be a top-level function (not inside a class)
// DO NOT call Firebase.initializeApp() here — already initialized
// ─────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("📩 Background message received: ${message.messageId}");
  print("📩 Title: ${message.notification?.title}");
  print("📩 Body: ${message.notification?.body}");
}

// ─────────────────────────────────────────────────────────────
// MAIN
// ─────────────────────────────────────────────────────────────
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // STEP 1 — Initialize Firebase ONCE via Dart (AppDelegate does NOT call FirebaseApp.configure())
  print('🔥 Initializing Firebase...');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // STEP 2 — Register background handler immediately after Firebase.initializeApp()
  // This MUST happen before runApp()
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  print('🔔 Background message handler registered');

  // STEP 3 — Initialize local notifications
  print('🔔 Initializing local notifications...');
  await initializeLocalNotifications();

  // STEP 4 — Request notification permission (iOS requires explicit request)
  print('🔐 Requesting notification permissions...');
  await requestNotificationPermission();

  // STEP 5 — Fetch FCM token (iOS: waits for APNs token first)
  print('🔥 Fetching FCM token...');
  await getFCMToken();

  // STEP 6 — Load app data (unchanged from your original)
  print('📊 Loading app data...');
  await Username.loadusername();
  await Vendor.loadVendorId();
  await TotalSales.load();
  await TotalQuantity.load();
  await MonthlyTotalItems.load();
  await DailyTotalItems.load();
  await MonthlyTotalSales.load();
  await DailyTotalSales.load();

  print('✅ All initialization complete. Running app...');
  runApp(const AntiqueSoftApp());
}

// ─────────────────────────────────────────────────────────────
// REQUEST NOTIFICATION PERMISSION
// iOS requires explicit runtime permission
// Android 13+ also requires this
// ─────────────────────────────────────────────────────────────
Future<void> requestNotificationPermission() async {
  try {
    final NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    switch (settings.authorizationStatus) {
      case AuthorizationStatus.authorized:
        print('✅ Notification permission: AUTHORIZED');
        break;
      case AuthorizationStatus.provisional:
        print('⚠️ Notification permission: PROVISIONAL (iOS)');
        break;
      case AuthorizationStatus.denied:
        print('❌ Notification permission: DENIED');
        break;
      case AuthorizationStatus.notDetermined:
        print('⚠️ Notification permission: NOT DETERMINED');
        break;
    }
  } catch (e) {
    print('❌ Error requesting notification permission: $e');
  }
}

// ─────────────────────────────────────────────────────────────
// GET FCM TOKEN
// iOS: APNs token must resolve before FCM token is available
// ─────────────────────────────────────────────────────────────
Future<void> getFCMToken() async {
  try {
    if (Platform.isIOS) {
      print('🍎 iOS detected — fetching APNs token first...');

      // APNs token can take a moment — retry up to 5 times
      String? apnsToken;
      for (int i = 0; i < 5; i++) {
        apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken != null) break;
        print('⏳ APNs token not ready, retrying (${i + 1}/5)...');
        await Future.delayed(const Duration(seconds: 1));
      }

      if (apnsToken == null) {
        print('❌ APNs token is still null after retries.');
        print('   Check: Push Notifications enabled in Apple Developer Portal?');
        print('   Check: APNs .p8 key uploaded to Firebase Console?');
        print('   Check: Runner.entitlements has aps-environment = production?');
        // Don't proceed — FCM token will also be null without APNs
        return;
      }

      print('✅ APNs token: $apnsToken');
    }

    // Now safe to get FCM token
    final String? fcmToken = await FirebaseMessaging.instance.getToken();

    if (fcmToken != null) {
      print('✅ FCM Token: $fcmToken');
      // TODO: Send this token to your backend
    } else {
      print('❌ FCM token is null.');
      if (Platform.isIOS) {
        print('   Ensure APNs is configured and aps-environment = production');
      }
    }

    // Listen for token refresh (e.g. app reinstall, token rotation)
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      print('🔄 FCM token refreshed: $newToken');
      // TODO: Send updated token to your backend
    });

    print('✅ FCM token setup complete');
  } catch (e) {
    print('❌ FCM token error: $e');
  }
}

// ─────────────────────────────────────────────────────────────
// INITIALIZE LOCAL NOTIFICATIONS
// Sets up Android channel + iOS foreground display options
// ─────────────────────────────────────────────────────────────
Future<void> initializeLocalNotifications() async {
  try {
    const DarwinInitializationSettings iOSSettings =
        DarwinInitializationSettings(
      requestSoundPermission: false, // We handle permission separately via FCM
      requestBadgePermission: false,
      requestAlertPermission: false,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      iOS: iOSSettings,
      android: androidSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );

    // Android: Create high importance notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'Used for important push notifications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // iOS: Show notifications while app is in foreground
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    print('✅ Local notifications initialized');
  } catch (e) {
    print('❌ Error initializing local notifications: $e');
  }
}

// ─────────────────────────────────────────────────────────────
// NOTIFICATION TAP HANDLER
// ─────────────────────────────────────────────────────────────
void onDidReceiveNotificationResponse(
    NotificationResponse notificationResponse) {
  print('📱 Notification tapped — payload: ${notificationResponse.payload}');
  // TODO: Navigate based on payload
  // navigatorKey.currentState?.pushNamed('/details', arguments: notificationResponse.payload);
}

// ─────────────────────────────────────────────────────────────
// ROOT APP WIDGET
// ─────────────────────────────────────────────────────────────
class AntiqueSoftApp extends StatefulWidget {
  const AntiqueSoftApp({super.key});

  @override
  State<AntiqueSoftApp> createState() => _AntiqueSoftAppState();
}

class _AntiqueSoftAppState extends State<AntiqueSoftApp> {
  @override
  void initState() {
    super.initState();
    _setupForegroundHandler();
    _setupNotificationTapHandler();
  }

  // Foreground: message received while app is open
  void _setupForegroundHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 Foreground message: ${message.notification?.title}');
      print('📩 Body: ${message.notification?.body}');

      if (message.notification != null) {
        _showLocalNotification(message);
      }

      if (message.data.isNotEmpty) {
        print('📦 Data payload: ${message.data}');
      }
    });
  }

  // App opened by tapping a notification
  void _setupNotificationTapHandler() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('👆 Notification tapped — title: ${message.notification?.title}');
      // TODO: Navigate to relevant screen
    });
  }

  // Display local notification for foreground FCM messages
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'Used for important push notifications',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
      );

      const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      await flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        message.notification?.title ?? 'Notification',
        message.notification?.body ?? '',
        notificationDetails,
        payload: message.messageId,
      );

      print('🔊 Local notification shown: ${message.notification?.title}');
    } catch (e) {
      print('❌ Error showing local notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginViewModel()),
        ChangeNotifierProvider(create: (_) => AppData()),
      ],
      child: MaterialApp(
        title: 'AntiqueSoft',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme:
              ColorScheme.fromSeed(seedColor: const Color(0xFF172B4D)),
          useMaterial3: true,
          textTheme: const TextTheme(
            bodyLarge: TextStyle(fontFamily: 'DM Sans'),
            bodyMedium: TextStyle(fontFamily: 'DM Sans'),
            displayLarge:
                TextStyle(fontFamily: 'DM Sans', fontWeight: FontWeight.bold),
            displayMedium:
                TextStyle(fontFamily: 'DM Sans', fontStyle: FontStyle.italic),
            displaySmall: TextStyle(
              fontFamily: 'DM Sans',
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}