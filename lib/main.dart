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

// 🔔 Initialize local notifications plugin (GLOBAL)
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// 🔔 BACKGROUND HANDLER (MANDATORY FOR FIREBASE MESSAGING)
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print("📩 Background message: ${message.messageId}");
  print("📩 Title: ${message.notification?.title}");
  print("📩 Body: ${message.notification?.body}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// ⏳ STEP 1 — Initialize Firebase Core
  print('🔥 Initializing Firebase...');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  /// 🔥 STEP 2 — Register background handler FIRST (MUST be done before runApp)
  print('🔔 Registering background message handler...');
  FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler);

  /// 🔔 STEP 3 — Initialize local notifications
  print('🔔 Initializing local notifications...');
  await initializeLocalNotifications();

  /// 🔥 STEP 4 — Request notification permission (iOS + Android 13+)
  print('🔐 Requesting notification permissions...');
  await requestNotificationPermission();

  /// 🔥 STEP 5 — Get FCM Token and setup token refresh listener
  print('🔥 Fetching FCM token...');
  await getFCMToken();

  /// 🔥 EXISTING DATA LOAD (UNCHANGED)
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

/// 🔔 REQUEST PERMISSION (iOS + Android 13+)
Future<void> requestNotificationPermission() async {
  try {
    NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    print('🔐 Permission Status: ${settings.authorizationStatus}');

    // Check if permission was granted
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      print('❌ User denied notification permissions');
    } else if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Notification permissions granted');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('⚠️ Provisional permissions granted (iOS)');
    }
  } catch (e) {
    print('❌ Error requesting permissions: $e');
  }
}

/// 🔥 GET FCM TOKEN (WITH iOS APNS FIX)
Future<void> getFCMToken() async {
  try {
    // 🍎 iOS: Get APNS token FIRST
    if (Platform.isIOS) {
      print('🍎 Getting APNS token for iOS...');
      String? apnsToken =
          await FirebaseMessaging.instance.getAPNSToken();
      print("🍎 APNS Token: $apnsToken");

      if (apnsToken == null) {
        print("⚠️ WARNING: APNS token is null!");
        print("📱 iOS Troubleshooting Checklist:");
        print("   1. Check Apple Developer Account APNS certificate");
        print("   2. Verify Firebase iOS setup in GoogleService-Info.plist");
        print("   3. Ensure app has notification entitlements");
        print("   4. Try reinstalling the app");
      }

      // Add delay to ensure APNS is ready before FCM
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // Get FCM Token
    String? token = await FirebaseMessaging.instance.getToken();
    print("🔥 FCM TOKEN: $token");

    if (token == null) {
      print("❌ ERROR: FCM token is null");
      if (Platform.isIOS) {
        print("📱 iOS FCM Token Troubleshooting:");
        print("   1. Check Apple Developer Account APNS certificate");
        print("   2. Verify Firebase iOS setup in GoogleService-Info.plist");
        print("   3. Ensure NSUserNotificationCenter permission granted");
        print("   4. Try uninstalling and reinstalling app");
      }
    }

    // 🔄 Listen to token refresh and update backend when token changes
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      print("🔄 Token refreshed: $newToken");
      // TODO: Send new token to your backend API
      // Example:
      // await updateTokenInBackend(newToken);
    });

    print('✅ FCM token setup complete');
  } catch (e) {
    print("❌ Token error: $e");
  }
}

/// 🔔 INITIALIZE LOCAL NOTIFICATIONS (ANDROID CHANNEL + iOS SETTINGS)
Future<void> initializeLocalNotifications() async {
  try {
    // 🍎 iOS Settings
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );

    // 🤖 Android Settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Combined initialization
    const InitializationSettings initializationSettings =
        InitializationSettings(
      iOS: initializationSettingsIOS,
      android: initializationSettingsAndroid,
    );

    // Initialize the plugin
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          onDidReceiveNotificationResponse,
    );

    // 🤖 CRITICAL: Create Android notification channel (MUST match your manifest)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 🍎 iOS: Enable foreground notification display
    if (Platform.isIOS) {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,  // Show alert banner
        badge: true,  // Show badge
        sound: true,  // Play sound
      );
      print('✅ iOS foreground presentation enabled');
    }

    print('✅ Local notifications initialized');
  } catch (e) {
    print('❌ Error initializing local notifications: $e');
  }
}

/// 🔔 HANDLE NOTIFICATION TAP (Both foreground and background)
void onDidReceiveNotificationResponse(
    NotificationResponse notificationResponse) {
  print('📱 Notification tapped: ${notificationResponse.payload}');
  // TODO: Add navigation logic based on payload
  // Example:
  // navigatorKey.currentState?.pushNamed('/details', arguments: notificationResponse.payload);
}

class AntiqueSoftApp extends StatefulWidget {
  const AntiqueSoftApp({super.key});

  @override
  State<AntiqueSoftApp> createState() => _AntiqueSoftAppState();
}

class _AntiqueSoftAppState extends State<AntiqueSoftApp> {
  @override
  void initState() {
    super.initState();
    
    // Setup foreground message handler (SAFE HERE in StatefulWidget)
    _setupForegroundHandler();
    
    // Setup notification tap handler
    _setupNotificationTapHandler();
  }

  /// 🔔 FOREGROUND MESSAGE HANDLER (Messages while app is open)
  void _setupForegroundHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📩 Foreground message received: ${message.notification?.title}");
      print("📩 Body: ${message.notification?.body}");

      // Show local notification for foreground messages
      if (message.notification != null) {
        _showLocalNotification(message);
      }

      // Handle data payload if present
      if (message.data.isNotEmpty) {
        print('📦 Data Payload: ${message.data}');
        // TODO: Process data payload
      }
    });
  }

  /// 📲 NOTIFICATION TAP HANDLER (App opened from notification)
  void _setupNotificationTapHandler() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('👆 FCM notification tapped: ${message.notification?.title}');
      print('👆 Payload: ${message.messageId}');
      // TODO: Add navigation logic based on notification data
    });
  }

  /// 🔔 SHOW LOCAL NOTIFICATION (For foreground messages)
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final String title = message.notification?.title ?? "Notification";
      final String body = message.notification?.body ?? "";
      final String? payload = message.messageId;

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

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      print('🔊 Local notification displayed: $title');
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
            displayLarge: TextStyle(
                fontFamily: 'DM Sans', fontWeight: FontWeight.bold),
            displayMedium: TextStyle(
                fontFamily: 'DM Sans', fontStyle: FontStyle.italic),
            displaySmall: TextStyle(
                fontFamily: 'DM Sans',
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}