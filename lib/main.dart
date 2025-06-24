
import 'package:antiquewebemquiry/Global/sales.dart';
import 'package:antiquewebemquiry/Global/yearlytotalquantity.dart';
import 'package:antiquewebemquiry/Global/yearlytotalsales.dart';
import 'package:antiquewebemquiry/Services/firebase_options.dart';
import 'package:antiquewebemquiry/Global/location.dart';
import 'package:antiquewebemquiry/Global/username.dart';
import 'package:antiquewebemquiry/Global/vendorid.dart';
import 'package:antiquewebemquiry/view/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;
import 'Services/notification.dart';
import 'viewmodel/login_viewmodel.dart';

// Background message handler
@pragma('vm:entry-point') // Ensures iOS handles background properly
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    // ignore: avoid_print
    print(' Background message received: ${message.messageId}');
    NotificationService().showNotification(message);
  } catch (e) {
    // ignore: avoid_print
    print(' Background message handler error: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Location.loadlocation();
  await Username.loadusername();
  await Vendor.loadVendorId();
  await TotalSales.load(); // loads saved double into TotalSales.totalsales
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
  bool _initialized = false;
  bool _error = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // ignore: avoid_print
      print('Initializing Firebase...');
      
      // Initialize Firebase with timeout
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Firebase initialization timed out after 30 seconds');
        },
      );
      
      // ignore: avoid_print
      print('Firebase initialized successfully');

      // Setup FCM background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      // ignore: avoid_print
      print('Background message handler set');

      // Setup push notifications
      await _setupPushNotifications();
      // ignore: avoid_print
      print('Push notifications setup complete');

      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
      
    } catch (e, stackTrace) {
      // ignore: avoid_print
      print('App initialization failed: $e');
      // ignore: avoid_print
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

      // Request notification permissions (especially for iOS)
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        // IMPORTANT: These are crucial for iOS foreground notifications
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );

      // ignore: avoid_print
      print('iOS permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // ignore: avoid_print
        print('Notification permissions granted');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        // ignore: avoid_print
        print('Provisional notification permissions granted');
      } else {
        // ignore: avoid_print
        print(' Notification permissions denied');
      }

      // CRITICAL FOR iOS: Configure foreground notification presentation options
      if (Platform.isIOS) {
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,  // Show alert/banner
          badge: true,  // Update app badge
          sound: true,  // Play notification sound
        );
        // ignore: avoid_print
        print(' iOS foreground notification options configured');
      }

      // Initialize local notification service
      NotificationService notificationService = NotificationService();
      await notificationService.init();
      // ignore: avoid_print
      print('Local notification service initialized');

      // Get FCM token
      try {
        String? token = await messaging.getToken();
        // ignore: avoid_print
        print('FCM Token: ${token ?? 'No token received'}');
      } catch (e) {
        // ignore: avoid_print
        print('Failed to get FCM token: $e');
      }

      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        // ignore: avoid_print
        print('Foreground message received: ${message.notification?.title}');
        // ignore: avoid_print
        print('Platform: ${Platform.isIOS ? 'iOS' : 'Android'}');
        
        try {
          // For iOS, the system notification should now appear due to 
          // setForegroundNotificationPresentationOptions above
          // But we can also show local notification as backup
          notificationService.showNotification(message);
        } catch (e) {
          // ignore: avoid_print
          print('Failed to show notification: $e');
        }
      });

      // Listen for when user taps notification while app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        // ignore: avoid_print
        print('App opened from notification: ${message.notification?.title}');
        // Handle navigation here if needed
      });

      // Handle initial message when app is launched from terminated state
      RemoteMessage? initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        // ignore: avoid_print
        print('App launched from notification: ${initialMessage.notification?.title}');
        // Handle navigation here if needed
      }

    } catch (e) {
      // ignore: avoid_print
      print('Push notification setup failed: $e');
      // Don't throw here, just log the error
    }
  }

  @override
  Widget build(BuildContext context) {
    // Error state
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
                        _initialized = false;
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
      ],
      child: MaterialApp(
        title: 'AntiqueSoft',
        debugShowCheckedModeBanner: false,
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