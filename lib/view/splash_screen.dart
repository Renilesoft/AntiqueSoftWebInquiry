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
    await Future.delayed(const Duration(seconds: 2));
    await _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final username = prefs.getString('username');
      final location = prefs.getString('location');
      final vendorId = prefs.getInt('vendorid');
      final hasLoggedIn = prefs.getBool('hasLoggedInOnThisDevice') ?? false;

      if (username != null && location != null && vendorId != null && hasLoggedIn) {
        await _restoreUserSession(username, location, vendorId);
      } else {
        _navigateToLogin();
      }
    } catch (e) {
      _navigateToLogin();
    }
  }

  Future<void> _restoreUserSession(String username, String location, int vendorId) async {
    try {
      await Location.loadlocation();
      await Username.loadusername();
      await Vendor.loadVendorId();

      final appData = Provider.of<AppData>(context, listen: false);
      final prefs = await SharedPreferences.getInstance();
      final userDataJson = prefs.getString('userData');

      if (userDataJson != null) {
        final userData = UserData.fromJsonString(userDataJson);
        appData.updateUserData([userData]);
      } else {
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
      }

      appData.setSalesDateTime(DateTime.now().toUtc());
      _navigateToHome();
    } catch (e) {
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
        double scaleFactor = screenWidth / 422;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FractionallySizedBox(
              widthFactor: 0.20,
              child: AspectRatio(
                aspectRatio: 1,
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
