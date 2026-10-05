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


final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Background message received: ${message.messageId}");
  print("Title: ${message.notification?.title}");
  print("Body: ${message.notification?.body}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('Initializing Firebase...');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  print(' Background message handler registered');

  print(' Initializing local notifications...');
  await initializeLocalNotifications();


  print('🔐 Requesting notification permissions...');
  await requestNotificationPermission();


  print(' Fetching FCM token...');
  await getFCMToken();

  // STEP 6 — Load app data (unchanged from your original)
  print(' Loading app data...');
  await Username.loadusername();
  await Vendor.loadVendorId();
  await TotalSales.load();
  await TotalQuantity.load();
  await MonthlyTotalItems.load();
  await DailyTotalItems.load();
  await MonthlyTotalSales.load();
  await DailyTotalSales.load();

  print(' All initialization complete. Running app...');
  runApp(const AntiqueSoftApp());
}

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
        print('Notification permission: AUTHORIZED');
        break;
      case AuthorizationStatus.provisional:
        print('Notification permission: PROVISIONAL (iOS)');
        break;
      case AuthorizationStatus.denied:
        print('Notification permission: DENIED');
        break;
      case AuthorizationStatus.notDetermined:
        print('Notification permission: NOT DETERMINED');
        break;
    }
  } catch (e) {
    print('Error requesting notification permission: $e');
  }
}

Future<void> getFCMToken() async {
  try {
    if (Platform.isIOS) {
      print('iOS platform detected — attempting APNS token fetch...');

      // Try to get APNs token (takes time on real devices, may be null on simulator)
      String? apnsToken;
      for (int i = 0; i < 5; i++) {
        apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken != null) {
          print('APNs token obtained: $apnsToken');
          break;
        }
        print('APNs token not ready (${i + 1}/5), retrying...');
        await Future.delayed(const Duration(seconds: 1));
      }

      // Log status but DON'T block if null
      if (apnsToken == null) {
        print('⚠️ APNs token is null');
        print('   This is normal on simulator or if APNs not fully provisioned.');
        print('   If on real iOS device: Verify APNs certificate in Apple Developer Portal');
        print('   If on real iOS device: Verify APNs .p8 uploaded to Firebase Console');
        print('   If on real iOS device: Verify Runner.entitlements has aps-environment=production');
        print('   Proceeding to fetch FCM token anyway...');
      }
    } else {
      print('💻 Non-iOS platform detected (Windows/Android/Web)');
      print('   APNS is iOS-only, skipping APNS check.');
    }

    // IMPORTANT: Always try to get FCM token, regardless of APNS result
    print('Fetching FCM token...');
    final String? fcmToken = await FirebaseMessaging.instance.getToken();

    if (fcmToken != null) {
      print('FCM Token successfully obtained: $fcmToken');
      // TODO: Send this token to your backend
      // Example:
      // await _sendTokenToBackend(fcmToken);
    } else {
      print('FCM token is null (this is unusual)');
      if (Platform.isIOS) {
        print('   On iOS: Ensure APNs is properly configured');
        print('   On iOS: Try uninstalling and reinstalling the app');
      } else {
        print('   On Android: Check Google Play Services is up to date');
      }
    }

    // Listen for token refresh events (e.g., app reinstall, token rotation)
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      print('FCM token refreshed: $newToken');
      // TODO: Send updated token to your backend
      // await _sendTokenToBackend(newToken);
    });

    print('FCM token setup complete');
  } catch (e) {
    print('FCM token error: $e');
    // Don't crash, just log the error
  }
}

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


    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    print('Local notifications initialized');
  } catch (e) {
    print('Error initializing local notifications: $e');
  }
}


void onDidReceiveNotificationResponse(
    NotificationResponse notificationResponse) {
  print('Notification tapped — payload: ${notificationResponse.payload}');
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
    _setupForegroundHandler();
    _setupNotificationTapHandler();
  }

  void _setupForegroundHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');

      if (message.notification != null) {
        _showLocalNotification(message);
      }

      if (message.data.isNotEmpty) {
        print('Data payload: ${message.data}');
      }
    });
  }

  void _setupNotificationTapHandler() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification tapped — title: ${message.notification?.title}');
    });
  }

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

      print('Local notification shown: ${message.notification?.title}');
    } catch (e) {
      print('Error showing local notification: $e');
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