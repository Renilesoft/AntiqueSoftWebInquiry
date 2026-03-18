import 'package:antiquewebemquiry/Global/sales.dart';
import 'package:antiquewebemquiry/Global/yearlytotalquantity.dart';
import 'package:antiquewebemquiry/Global/yearlytotalsales.dart';

import 'package:antiquewebemquiry/Global/username.dart';
import 'package:antiquewebemquiry/Global/vendorid.dart';
import 'package:antiquewebemquiry/Services/firebase_options.dart';
import 'package:antiquewebemquiry/app_data.dart';

import 'package:antiquewebemquiry/view/splash_screen.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:provider/provider.dart';
import 'dart:io' show Platform;
import 'Services/notification.dart';
import 'viewmodel/login_viewmodel.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Background message handler - MUST be top-level
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    print('🔔 Background message received: ${message.messageId}');
    print('   Title: ${message.notification?.title}');
    print('   Body: ${message.notification?.body}');
    
    // Show notification in background
    try {
      NotificationService().showNotification(message);
    } catch (e) {
      print('   Error showing background notification: $e');
    }
  } catch (e) {
    print('❌ Background message handler error: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set background message handler BEFORE running app
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(true);
      
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
      print('\n╔════════════════════════════════════════╗');
      print('║  PUSH NOTIFICATION INITIALIZATION      ║');
      print('╚════════════════════════════════════════╝\n');

      await _setupPushNotifications();

      print('\n✅ Push notifications setup complete\n');

      if (mounted) {
        setState(() {});
      }
    } catch (e, stackTrace) {
      print('\n❌ App initialization failed: $e');
      print('Stack trace: $stackTrace\n');

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
      final messaging = FirebaseMessaging.instance;

      print('1️⃣  REQUESTING NOTIFICATION PERMISSION...');
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );

      print('   ✅ Permission requested');
      print('   Authorization Status: ${settings.authorizationStatus}');
      print('   Alert: ${settings.alert}');
      print('   Badge: ${settings.badge}');
      print('   Sound: ${settings.sound}');

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        print('   ⚠️  WARNING: User did not authorize notifications!');
      }

      // iOS-specific foreground presentation
      if (Platform.isIOS) {
        print('\n2️⃣  CONFIGURING iOS FOREGROUND PRESENTATION...');
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
        print('   ✅ iOS foreground options configured');
      }

      print('\n3️⃣  INITIALIZING NOTIFICATION SERVICE...');
      NotificationService notificationService = NotificationService();
      await notificationService.init();
      print('   ✅ Notification service initialized');

      print('\n4️⃣  GETTING TOKENS...');
      
      // Get FCM Token
      final fcmToken = await messaging.getToken();
      if (fcmToken != null) {
        print('   ✅ FCM Token obtained:');
        print('      ${fcmToken.substring(0, 50)}...');
      } else {
        print('   ❌ FCM Token is NULL!');
        print('      Possible causes:');
        print('      - GoogleService-Info.plist is missing or wrong');
        print('      - Firebase initialization failed');
      }

      // Get APNs Token (iOS only)
      if (Platform.isIOS) {
        final apnsToken = await messaging.getAPNSToken();
        if (apnsToken != null) {
          print('   ✅ APNs Token obtained:');
          print('      ${apnsToken.substring(0, 50)}...');
        } else {
          print('   ❌ APNs Token is NULL!');
          print('      Possible causes:');
          print('      - Provisioning profile expired or incorrect');
          print('      - Bundle ID mismatch');
          print('      - Code signing issue');
        }
      }

      print('\n5️⃣  SETTING UP MESSAGE LISTENERS...');

      // Foreground message listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        print('   🔥 FOREGROUND MESSAGE RECEIVED:');
        print('      Title: ${message.notification?.title}');
        print('      Body: ${message.notification?.body}');
        print('      MessageId: ${message.messageId}');

        try {
          if (Platform.isAndroid) {
            if (message.notification != null) {
              print('   📱 Showing Android notification...');
              await notificationService.showNotification(message);
            }
          } else if (Platform.isIOS) {
            print('   📱 Showing iOS notification...');
            await notificationService.showNotification(message);
          }
        } catch (e) {
          print('   ❌ Failed to show notification: $e');
        }
      });
      print('   ✅ Foreground listener attached');

      // Message opened listener
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('   📭 APP OPENED FROM NOTIFICATION:');
        print('      Title: ${message.notification?.title}');
        print('      MessageId: ${message.messageId}');
      });
      print('   ✅ Message opened listener attached');

      // Check for initial message
      print('\n6️⃣  CHECKING INITIAL MESSAGE...');
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        print('   📬 App launched from notification:');
        print('      Title: ${initialMessage.notification?.title}');
      } else {
        print('   ℹ️  App launched normally (not from notification)');
      }

      // Token refresh listener
      print('\n7️⃣  TOKEN REFRESH LISTENER...');
      messaging.onTokenRefresh.listen((newToken) {
        print('   🔄 FCM Token refreshed: ${newToken.substring(0, 30)}...');
      });
      print('   ✅ Token refresh listener attached');

      print('\n╔════════════════════════════════════════╗');
      print('║          FINAL CHECKLIST                ║');
      print('╚════════════════════════════════════════╝');
      print('   ✅ Firebase initialized');
      print('   ${fcmToken != null ? '✅' : '❌'} FCM Token obtained');
      if (Platform.isIOS) {
        final apnsToken = await messaging.getAPNSToken();
        print('   ${apnsToken != null ? '✅' : '❌'} APNs Token obtained');
      }
      print('   ${settings.authorizationStatus == AuthorizationStatus.authorized ? '✅' : '❌'} User authorized');
      print('   ✅ All listeners configured');
      print('   ✅ Ready to receive notifications! 🎉\n');

    } catch (e, stackTrace) {
      print('\n❌ Push notification setup failed: $e');
      print('Stack trace: $stackTrace\n');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return MaterialApp(
        title: 'AntiqueSoft',
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Initialization Failed',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _error = false;
                        _errorMessage = '';
                      });
                      _initializeApp();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginViewModel()),
        ChangeNotifierProvider(create: (_) => AppData()),
      ],
      child: MaterialApp(
        title: 'AntiqueSoft',
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF172B4D)),
          useMaterial3: true,
          textTheme: const TextTheme(
            bodyLarge: TextStyle(fontFamily: 'DM Sans'),
            bodyMedium: TextStyle(fontFamily: 'DM Sans'),
            displayLarge: TextStyle(fontFamily: 'DM Sans', fontWeight: FontWeight.bold),
            displayMedium: TextStyle(fontFamily: 'DM Sans', fontStyle: FontStyle.italic),
            displaySmall: TextStyle(fontFamily: 'DM Sans', fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}