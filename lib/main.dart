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
  await Firebase.initializeApp();
  print('📦 Background message received: ${message.messageId}');
  NotificationService().showNotification(message);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Setup FCM background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Setup push notifications and local notifications
  await _setupPushNotifications();

  runApp(const AntiqueSoftApp());
}

Future<void> _setupPushNotifications() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Request notification permissions (especially for iOS)
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  print('🔐 iOS permission status: ${settings.authorizationStatus}');

  // Initialize local notification service
  NotificationService notificationService = NotificationService();
  await notificationService.init();

  // Get FCM token
  String? token = await messaging.getToken();
  print('📱 FCM Token: $token');

  // Listen for foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('📲 Foreground message: ${message.notification?.title}');
    notificationService.showNotification(message);
  });
}

class AntiqueSoftApp extends StatelessWidget {
  const AntiqueSoftApp({super.key});

  @override
  Widget build(BuildContext context) {
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
