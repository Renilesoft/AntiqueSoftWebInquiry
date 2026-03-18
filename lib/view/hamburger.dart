import 'dart:convert';
import 'package:antiquewebemquiry/Constants/baseurl.dart';
import 'package:antiquewebemquiry/app_data.dart';
import 'package:antiquewebemquiry/viewmodel/login_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:quickalert/quickalert.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:antiquewebemquiry/view/login_screen.dart';
import 'change_password.dart';

class DrawerMenu extends StatelessWidget {
  const DrawerMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: 0.7,
      child: Drawer(
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              Container(
                height: 120,
                width: double.infinity,
                color: const Color(0xFFFF8500),
                padding: const EdgeInsets.only(top: 40),
                child: const Center(
                  child: Text(
                    'Menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontFamily: 'DM Sans',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.lock_outline, color: Color(0xFFFF8500)),
                title: const Text(
                  'Change Password',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 16,
                    color: Color(0xFF172B4D),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Color(0xFFFF8500)),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 16,
                    color: Color(0xFF172B4D),
                  ),
                ),
                onTap: () {
                  _showLogoutDialog(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.warning,
      title: 'Logout',
      text: 'Are you sure you want to logout?',
      confirmBtnText: 'Yes',
      cancelBtnText: 'No',
      showCancelBtn: true,
      onConfirmBtnTap: () {
        Navigator.of(context).pop(); // Close the alert
        Future.delayed(const Duration(milliseconds: 300), () {
          // ignore: use_build_context_synchronously
          _performLogout(context);
        });
      },
      onCancelBtnTap: () {
        Navigator.of(context).pop(); // Close the alert
      },
    );
  }

  Future<void> _performLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final location = prefs.getString('location') ?? '';
    final username = prefs.getString('username') ?? '';
    
    // ✅ Get device UUID instead of FCM token
    final deviceUUID = await LoginViewModel.getDeviceUUID();
    print('📱 Logout with UUID: $deviceUUID');

    final url = Uri.parse('$baseurl/Home/logout');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      "location": location,
      "username": username,
      "fcmToken": deviceUUID,  // ✅ Changed from fcmToken to deviceUUID
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        // ignore: use_build_context_synchronously
        Provider.of<AppData>(context, listen: false);

        // ignore: use_build_context_synchronously
        final loginViewModel = Provider.of<LoginViewModel>(context, listen: false);
        await loginViewModel.logout();

        await _clearSessionData();

        // Mark that this device has not logged in anymore
        await prefs.setBool('hasLoggedInOnThisDevice', false);

        Navigator.pushAndRemoveUntil(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      } else {
        // ignore: use_build_context_synchronously
        _showErrorDialog(context, 'Logout failed (${response.statusCode})');
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      _showErrorDialog(context, 'Error: ${e.toString()}');
    }
  }

  Future<void> _clearSessionData() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('rememberMe') ?? false;
    String? rememberedStoreCode;
    String? rememberedUsername;
    String? rememberedPassword;

    if (rememberMe) {
      rememberedStoreCode = prefs.getString('rememberedStoreCode');
      rememberedUsername = prefs.getString('rememberedUsername');
      rememberedPassword = prefs.getString('rememberedPassword');
    }

    await prefs.clear();

    if (rememberMe &&
        rememberedStoreCode != null &&
        rememberedUsername != null &&
        rememberedPassword != null) {
      await prefs.setBool('rememberMe', true);
      await prefs.setString('rememberedStoreCode', rememberedStoreCode);
      await prefs.setString('rememberedUsername', rememberedUsername);
      await prefs.setString('rememberedPassword', rememberedPassword);
    }
    
    // ✅ Preserve device UUID across sessions
    // Get UUID before clear
    String? deviceUUID = prefs.getString('device_uuid');
    
    // Preserve it after clear if it exists
    if (deviceUUID != null && deviceUUID.isNotEmpty) {
      await prefs.setString('device_uuid', deviceUUID);
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.error,
      title: 'Error',
      text: message,
      confirmBtnText: 'OK',
      onConfirmBtnTap: () {
        Navigator.of(context).pop(); // Close the alert
      },
    );
  }
}