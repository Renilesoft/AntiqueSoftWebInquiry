import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:http/http.dart' as http;
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
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.bottomSlide,
      title: 'Logout',
      desc: 'Are you sure you want to logout?',
      btnCancelText: 'No',
      btnOkText: 'Yes',
      btnCancelOnPress: () {},
      btnOkOnPress: () {
        // Call logout AFTER dialog closes
        Future.delayed(const Duration(milliseconds: 300), () {
          _performLogout(context);
        });
      },
    ).show();
  }

  Future<void> _performLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final location = prefs.getString('location') ?? '';
    final username = prefs.getString('username') ?? '';
    String? fcmToken = await FirebaseMessaging.instance.getToken();

    final url = Uri.parse('http://192.168.10.26/Antiquesoft/Home/logout');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      "location": location,
      "username": username,
      "fcmToken": fcmToken,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        // Clear user session
        await prefs.clear();

        // Navigate to login screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      } else {
        _showErrorDialog(context, 'Logout failed (${response.statusCode})');
      }
    } catch (e) {
      _showErrorDialog(context, 'Error: ${e.toString()}');
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      title: 'Error',
      desc: message,
      btnOkOnPress: () {},
    ).show();
  }
}
