import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:antiquewebemquiry/app_data.dart';
import 'package:antiquewebemquiry/user_data.dart';
import 'package:antiquewebemquiry/view/login_screen.dart';
import 'package:antiquewebemquiry/view/home_screen/home_screen.dart';
import '../Global/location.dart';
import '../Global/username.dart';
import '../Global/vendorid.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Show splash screen for at least 2 seconds for better UX
    await Future.delayed(const Duration(seconds: 2));
    
    // Check login status and navigate accordingly
    await _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if user session exists
      final username = prefs.getString('username');
      final location = prefs.getString('location');
      final vendorId = prefs.getInt('vendorid');
      
      if (username != null && location != null && vendorId != null) {
        // User is logged in, restore session and go to home
        await _restoreUserSession(username, location, vendorId);
      } else {
        // User is not logged in, go to login screen
        _navigateToLogin();
      }
    } catch (e) {
      print('Error checking login status: $e');
      // If there's an error, safely navigate to login
      _navigateToLogin();
    }
  }

  Future<void> _restoreUserSession(String username, String location, int vendorId) async {
    try {
      // The global data is already loaded in main.dart, but let's refresh it
      await Location.loadlocation();
      await Username.loadusername();
      await Vendor.loadVendorId();

      // Get the app data provider
      final appData = Provider.of<AppData>(context, listen: false);
      
      final prefs = await SharedPreferences.getInstance();
      
      // Try to get additional user data if stored
      final userDataJson = prefs.getString('userData');
      if (userDataJson != null) {
        // If you stored complete user data as JSON during login
        final userData = UserData.fromJsonString(userDataJson);
        appData.updateUserData([userData]);
        
        // Initialize SignalR connection
       
      } else {
        // If only basic data is stored, create a minimal UserData object
        // Get additional stored data with default values
        final alphaNumericVendorID = prefs.getString('alphaNumericVendorID') ?? '';
        final vendorName = prefs.getString('vendorName') ?? '';
        final joinedDateString = prefs.getString('joinedDate');
        final joinedDate = joinedDateString != null 
            ? DateTime.tryParse(joinedDateString) ?? DateTime.now()
            : DateTime.now();

        final userData = UserData(
          vendorID: vendorId,
          alphaNumericVendorID: alphaNumericVendorID,
          vendorName: vendorName,
          joinedDate: joinedDate,
        );
        appData.updateUserData([userData]);
        
        // Initialize SignalR connection
        
      }
      
      // Set sales date time
      appData.setSalesDateTime(DateTime.now().toUtc());

      // Navigate to home screen
      _navigateToHome();
    } catch (e) {
      print('Error restoring session: $e');
      // If restoration fails, go to login
      _navigateToLogin();
    }
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  void _navigateToLogin() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLogoWithText(),
            const SizedBox(height: 30),
            // Add a loading indicator
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0C2A5D)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoWithText() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = constraints.maxWidth;
        double scaleFactor = screenWidth / 422; // Base width scaling

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FractionallySizedBox(
              widthFactor: 0.20, // 20% of screen width
              child: AspectRatio(
                aspectRatio: 1, // Maintain square logo shape
                child: SvgPicture.asset(
                  'assets/logo.svg',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            SizedBox(height: 8 * scaleFactor),
            Text(
              'AntiqueSoft',
              style: TextStyle(
                color: const Color(0xFF0C2A5D),
                fontWeight: FontWeight.bold,
                fontSize: 16 * scaleFactor,
              ),
            ),
            Text(
              'Web Inquiry',
              style: TextStyle(
                color: const Color(0xFF0C2A5D),
                fontWeight: FontWeight.bold,
                fontSize: 16 * scaleFactor,
              ),
            ),
          ],
        );
      },
    );
  }
}