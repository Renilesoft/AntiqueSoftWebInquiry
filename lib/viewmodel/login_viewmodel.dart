import 'dart:convert';
import 'dart:io' show Platform;
import 'package:antiquewebemquiry/app_data.dart';
import 'package:antiquewebemquiry/user_data.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';                    // ← ADD to pubspec.yaml

import '../Constants/baseurl.dart';
import '../Global/location.dart';
import '../Global/username.dart';
import '../Global/vendorid.dart';
import '../view/home_screen/home_screen.dart';

class LoginViewModel extends ChangeNotifier {
  final TextEditingController storeCodeController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool get isPasswordVisible => _isPasswordVisible;

  bool _rememberMe = false;
  bool get rememberMe => _rememberMe;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isInitialized = false;

  LoginViewModel() {
    _initializeCredentials();
  }

  Future<void> _initializeCredentials() async {
    if (!_isInitialized) {
      await restoreSavedCredentials();
      _isInitialized = true;
    }
  }

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  void toggleRememberMe() async {
    _rememberMe = !_rememberMe;
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setBool('rememberMe', true);
      await _saveCredentials();
    } else {
      await prefs.setBool('rememberMe', false);
    }
    notifyListeners();
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('rememberedStoreCode', storeCodeController.text.trim());
    await prefs.setString('rememberedUsername', usernameController.text.trim());
    await prefs.setString('rememberedPassword', passwordController.text.trim());
  }

  Future<void> restoreSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    _rememberMe = prefs.getBool('rememberMe') ?? false;
    if (_rememberMe) {
      storeCodeController.text = prefs.getString('rememberedStoreCode') ?? '';
      usernameController.text = prefs.getString('rememberedUsername') ?? '';
      passwordController.text = prefs.getString('rememberedPassword') ?? '';
    }
    notifyListeners();
  }

  Future<void> clearRememberedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('rememberedStoreCode');
    await prefs.remove('rememberedUsername');
    await prefs.remove('rememberedPassword');
    await prefs.setBool('rememberMe', false);
    _rememberMe = false;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String encryptString(String input) {
    int xorKey = 30;
    return String.fromCharCodes(input.runes.map((r) => r ^ xorKey));
  }

  // ─────────────────────────────────────────────────────────
  // GET DEVICE TOKEN
  // iOS: Uses UUID as fallback while APNs/FCM token is being resolved
  // Android: Uses real FCM token as before
  // ─────────────────────────────────────────────────────────
  Future<String> _getDeviceToken() async {
    final prefs = await SharedPreferences.getInstance();

    if (Platform.isIOS) {
      // ── FCM TOKEN TEMPORARILY COMMENTED OUT FOR iOS ──────
      // String? fcmToken = await FirebaseMessaging.instance.getToken();
      // if (fcmToken != null && fcmToken.isNotEmpty) {
      //   print('🔥 iOS FCM Token: $fcmToken');
      //   return fcmToken;
      // }
      // ─────────────────────────────────────────────────────

      // ✅ iOS FALLBACK — use stable UUID stored in SharedPreferences
      // This ensures login works while APNs/FCM is being set up
      String? storedUUID = prefs.getString('ios_device_uuid');
      if (storedUUID != null && storedUUID.isNotEmpty) {
        print('📱 Using existing iOS UUID: $storedUUID');
        return storedUUID;
      }

      // Generate and store a new UUID for this device
      final newUUID = const Uuid().v4();
      await prefs.setString('ios_device_uuid', newUUID);
      print('📱 Generated new iOS UUID: $newUUID');
      return newUUID;

    } else {
      // ── ANDROID — use real FCM token ──────────────────────
      String? fcmToken = await FirebaseMessaging.instance.getToken();

      if (fcmToken == null || fcmToken.isEmpty) {
        print('⚠️ Android FCM token null, retrying...');
        await Future.delayed(const Duration(milliseconds: 500));
        fcmToken = await FirebaseMessaging.instance.getToken();
      }

      if (fcmToken != null && fcmToken.isNotEmpty) {
        print('🔥 Android FCM Token: $fcmToken');
        await prefs.setString('fcm_token', fcmToken);
        return fcmToken;
      }

      // Android fallback UUID (should rarely hit this)
      String? storedUUID = prefs.getString('android_device_uuid');
      if (storedUUID != null && storedUUID.isNotEmpty) return storedUUID;
      final newUUID = const Uuid().v4();
      await prefs.setString('android_device_uuid', newUUID);
      print('⚠️ Android FCM fallback UUID: $newUUID');
      return newUUID;
    }
  }

  // ─────────────────────────────────────────────────────────
  // LOGIN
  // ─────────────────────────────────────────────────────────
  Future<bool> login(BuildContext context) async {
    _setLoading(true);

    try {
      final storeCode = storeCodeController.text.trim();
      final username = usernameController.text.trim();
      final password = passwordController.text.trim();

      // Get token (UUID on iOS, real FCM on Android)
      final String deviceToken = await _getDeviceToken();
      print('📤 Sending device token to server: $deviceToken');

      final response = await http.post(
        Uri.parse("$baseurl/Home/login"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "location": storeCode,
          "username": username,
          "password": encryptString(password),
          "fcmToken": deviceToken,
        }),
      ).timeout(const Duration(seconds: 10));

      print('📥 Login response status: ${response.statusCode}');
      print('📥 Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonMap = jsonDecode(response.body);

        if (jsonMap.containsKey('userCredentials') &&
            jsonMap['userCredentials'] is List &&
            jsonMap['message'] == "Success") {

          final userCredentials = jsonMap['userCredentials'];
          final userDataList = userCredentials
              .map<UserData>((item) => UserData.fromJson(item['userData']))
              .toList();

          final user = userDataList.first;
          final prefs = await SharedPreferences.getInstance();

          // Store session data
          await prefs.setString('username', username);
          await prefs.setString('location', storeCode);
          await prefs.setInt('vendorid', user.vendorID);
          await prefs.setString('userData', jsonEncode(user.toJson()));
          await prefs.setInt('loginTimestamp', DateTime.now().millisecondsSinceEpoch);
          await prefs.setString('fcm_token', deviceToken);
          await prefs.setBool('hasLoggedInOnThisDevice', true);

          // Remember Me
          if (_rememberMe) {
            await prefs.setBool('rememberMe', true);
            await _saveCredentials();
          } else {
            await prefs.remove('rememberedStoreCode');
            await prefs.remove('rememberedUsername');
            await prefs.remove('rememberedPassword');
            await prefs.setBool('rememberMe', false);
          }

          await Location.loadlocation();
          await Username.loadusername();
          await Vendor.loadVendorId();

          final appData = Provider.of<AppData>(context, listen: false);
          appData.updateUserData(userDataList);
          appData.setSalesDateTime(DateTime.now().toUtc());

          _setLoading(false);

          if (context.mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const HomeScreen(showWelcomeMessage: true),
              ),
            );
          }

          return true;
        } else {
          _setLoading(false);
          debugPrint('❌ Login failed: ${jsonMap["message"]}');
          return false;
        }
      } else {
        _setLoading(false);
        debugPrint('❌ Login HTTP error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      _setLoading(false);
      debugPrint('❌ Login exception: $e');
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    await prefs.remove('location');
    await prefs.remove('vendorid');
    await prefs.remove('userData');
    await prefs.remove('loginTimestamp');
    // ❗ DO NOT remove FCM token or UUID on logout
    if (!_rememberMe) clearStoredData();
    notifyListeners();
  }

  void clearStoredData() {
    storeCodeController.clear();
    usernameController.clear();
    passwordController.clear();
    notifyListeners();
  }

  Future<void> refreshCredentials() async {
    await restoreSavedCredentials();
  }

  @override
  void dispose() {
    storeCodeController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}