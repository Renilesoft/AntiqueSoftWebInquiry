import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodel/login_viewmodel.dart';
import 'view/login_screen.dart'; // ✅ Re-enable LoginScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔒 Keep Firebase temporarily commented
  // await Firebase.initializeApp();
  // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  // await _setupPushNotifications();

  runApp(const AntiqueSoftApp());
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
        home: const LoginScreen(), // 🔄 Now test LoginScreen again
      ),
    );
  }
}