import 'package:antiquewebemquiry/Global/sales.dart';
import 'package:antiquewebemquiry/Global/yearlytotalquantity.dart';
import 'package:antiquewebemquiry/Global/yearlytotalsales.dart';
import 'package:antiquewebemquiry/Global/username.dart';
import 'package:antiquewebemquiry/Global/vendorid.dart';
import 'package:antiquewebemquiry/Services/firebase_options.dart';
import 'package:antiquewebemquiry/app_data.dart';
import 'package:antiquewebemquiry/view/splash_screen.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;
import 'Services/notification.dart';
import 'viewmodel/login_viewmodel.dart';

// ✅ GLOBAL NAVIGATOR KEY (for TestFlight debug UI)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// ✅ FIXED Background handler (NO UI / local notifications here)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Background message received: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

  FlutterError.onError =
      FirebaseCrashlytics.instance.recordFlutterFatalError;

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(
      error,
      stack,
      fatal: true,
    );
    return true;
  };

  await Username.loadusername();
  await Vendor.loadVendorId();
  await TotalSales.load();
  await TotalQuantity.load();
  await MonthlyTotalItems.load();
  await DailyTotalItems.load();
  await MonthlyTotalSales.load();
  await DailyTotalSales.load();

  runApp(const AntiqueSoftApp());
}

class AntiqueSoftApp extends StatefulWidget {
  const AntiqueSoftApp({super.key});

  @override
  State<AntiqueSoftApp> createState() => _AntiqueSoftAppState();
}

class _AntiqueSoftAppState extends State<AntiqueSoftApp> {
  bool _error = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      print('Initializing Push Notifications...');

      await _setupPushNotifications();

      print('Push notifications setup complete');
    } catch (e, stackTrace) {
      print('App initialization failed: $e');
      print('Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          _error = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _setupPushNotifications() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;

      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      print('iOS permission status: ${settings.authorizationStatus}');

      if (Platform.isIOS) {
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      NotificationService notificationService = NotificationService();
      await notificationService.init();

      // ✅ PRINT TOKEN
      String? token = await messaging.getToken();
      print('FCM Token: $token');

      // ✅ FOREGROUND LISTENER (WITH UI DEBUG)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        print("🔥 FOREGROUND MESSAGE: ${message.notification?.title}");
        print("🔥 DATA: ${message.data}");

        // ✅ SHOW POPUP (CRITICAL FOR TESTFLIGHT DEBUG)
        if (navigatorKey.currentContext != null) {
          showDialog(
            context: navigatorKey.currentContext!,
            builder: (context) => AlertDialog(
              title: Text(message.notification?.title ?? "No Title"),
              content: Text(message.notification?.body ?? "No Body"),
            ),
          );
        }

        try {
          if (Platform.isAndroid) {
            if (message.notification != null) {
              await notificationService.showNotification(message);
            }
          } else if (Platform.isIOS) {
            await notificationService.showNotification(message);
          }
        } catch (e) {
          print('Failed to show notification: $e');
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('App opened from notification: ${message.notification?.title}');
      });

      RemoteMessage? initialMessage =
          await messaging.getInitialMessage();

      if (initialMessage != null) {
        print('App launched from notification: ${initialMessage.notification?.title}');
      }
    } catch (e) {
      print('Push notification setup failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return MaterialApp(
        home: Scaffold(
          body: Center(child: Text(_errorMessage)),
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginViewModel()),
        ChangeNotifierProvider(create: (_) => AppData()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey, // ✅ IMPORTANT
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
      ),
    );
  }
}