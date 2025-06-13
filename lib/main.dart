import 'package:antiquewebemquiry/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';

import 'notification.dart';
import 'view/login_screen.dart';
import 'viewmodel/login_viewmodel.dart';

// Background message handler
@pragma('vm:entry-point') // Ensures iOS handles background properly
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    print('📦 Background message received: ${message.messageId}');
    NotificationService().showNotification(message);
  } catch (e) {
    print('❌ Background message handler error: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 Starting app initialization...');
  
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
      print('🔥 Initializing Firebase...');
      
      // Initialize Firebase with timeout
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Firebase initialization timed out after 30 seconds');
        },
      );
      
      print('✅ Firebase initialized successfully');

      // Setup FCM background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      print('📱 Background message handler set');

      // Setup push notifications
      await _setupPushNotifications();
      print('🔔 Push notifications setup complete');

      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
      
    } catch (e, stackTrace) {
      print('❌ App initialization failed: $e');
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
      );

      print('🔐 iOS permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ Notification permissions granted');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('⚠️ Provisional notification permissions granted');
      } else {
        print('❌ Notification permissions denied');
      }

      // Initialize local notification service
      NotificationService notificationService = NotificationService();
      await notificationService.init();
      print('📲 Local notification service initialized');

      // Get FCM token
      try {
        String? token = await messaging.getToken();
        print('📱 FCM Token: ${token ?? 'No token received'}');
      } catch (e) {
        print('⚠️ Failed to get FCM token: $e');
      }

      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('📲 Foreground message received: ${message.notification?.title}');
        try {
          notificationService.showNotification(message);
        } catch (e) {
          print('❌ Failed to show notification: $e');
        }
      });

      // Listen for when user taps notification while app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('📲 App opened from notification: ${message.notification?.title}');
        // Handle navigation here if needed
      });

    } catch (e) {
      print('❌ Push notification setup failed: $e');
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

    // Loading state
    if (!_initialized) {
      return MaterialApp(
        title: 'AntiqueSoft',
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    const Color(0xFF172B4D),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Initializing AntiqueSoft...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF172B4D),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please wait while we set up the app',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Main app - only shown when Firebase is successfully initialized
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
        home: const LoginScreen(),
      ),
    );
  }
}