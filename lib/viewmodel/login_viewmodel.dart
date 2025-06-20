import 'dart:convert';
import 'package:antiquewebemquiry/Constants/baseurl.dart';
import 'package:antiquewebemquiry/Global/location.dart';
import 'package:antiquewebemquiry/Global/username.dart';
import 'package:antiquewebemquiry/Global/vendorid.dart';
import 'package:antiquewebemquiry/view/home_screen/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginViewModel extends ChangeNotifier {
  final TextEditingController storeCodeController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool get isPasswordVisible => _isPasswordVisible;

  bool _rememberMe = false;
  bool get rememberMe => _rememberMe;

  // Stored credentials
  String? _savedStoreCode;
  String? _savedUsername;
  String? _savedPassword;

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  void toggleRememberMe() {
    _rememberMe = !_rememberMe;
    if (_rememberMe) {
      _savedStoreCode = storeCodeController.text.trim();
      _savedUsername = usernameController.text.trim();
      _savedPassword = passwordController.text.trim();
    } else {
      _savedStoreCode = null;
      _savedUsername = null;
      _savedPassword = null;
      storeCodeController.clear();
      usernameController.clear();
      passwordController.clear();
    }
    notifyListeners();
  }

  void restoreSavedCredentials() {
    if (_rememberMe && _savedStoreCode != null) {
      storeCodeController.text = _savedStoreCode!;
      usernameController.text = _savedUsername!;
      passwordController.text = _savedPassword!;
    }
  }

  String encryptString(String input) {
  int xorKey = 30;
  String result = '';

  for (int i = 0; i < input.length; i++) {
    int charCode = input.codeUnitAt(i);
    int encryptedCharCode = charCode ^ xorKey;
    result += String.fromCharCode(encryptedCharCode);
  }

  return result;
}

  /// 👇 MAIN LOGIN METHOD WITH API INTEGRATION
Future<bool> login(BuildContext context) async {
  String storeCode = storeCodeController.text.trim();
  String username = usernameController.text.trim();
  String password = passwordController.text.trim();

  // Get FCM token
  String? fcmToken = await FirebaseMessaging.instance.getToken();
  if (fcmToken == null) {
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to get FCM token')),
    );
    return false;
  }

  final url = Uri.parse('$baseurl/Home/login');
  final headers = {'Content-Type': 'application/json'};
  final body = jsonEncode({
    "location": storeCode,
    "username": username,
    "password": encryptString(password),
    "fcmToken": fcmToken,
  });

  try {
    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);

      if (jsonResponse["message"] == "Success") {
        final vendorid = jsonResponse["userCredentials"][0]["userData"]["vendorID"];

        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', username);
        await prefs.setString('location', storeCode);
        await prefs.setInt('vendorid', vendorid);

        // Load into static global variables
        await Location.loadlocation();
        await Username.loadusername();
        await Vendor.loadVendorId();

        // Store locally if rememberMe is true
        if (_rememberMe) {
          _savedStoreCode = storeCode;
          _savedUsername = username;
          _savedPassword = password;
        }

        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
        return true;
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login failed: ${jsonResponse["message"]}")),
        );
        return false;
      }
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed: ${response.statusCode}")),
      );
      return false;
    }
  } catch (e) {
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: ${e.toString()}")),
    );
    return false;
  }
}


  void clearStoredData() {
    _rememberMe = false;
    _savedStoreCode = null;
    _savedUsername = null;
    _savedPassword = null;
    storeCodeController.clear();
    usernameController.clear();
    passwordController.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    storeCodeController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}