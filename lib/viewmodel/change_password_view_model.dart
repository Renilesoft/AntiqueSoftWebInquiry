import 'dart:convert';
import 'package:antiquewebemquiry/Global/vendorid.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:antiquewebemquiry/Constants/baseurl.dart';
import 'package:antiquewebemquiry/Global/location.dart';
import 'package:antiquewebemquiry/model/change_password_model.dart';

class ChangePasswordViewModel extends ChangeNotifier {
  final ChangePasswordModel _model = ChangePasswordModel();
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setCurrentPassword(String value) {
    _model.currentPassword = value;
    notifyListeners();
  }

  void setNewPassword(String value) {
    _model.newPassword = value;
    notifyListeners();
  }

  void setConfirmPassword(String value) {
    _model.confirmPassword = value;
    notifyListeners();
  }

  Future<bool> updatePassword() async {
  if (!_validateInputs()) return false;

  _isLoading = true;
  _errorMessage = null;
  notifyListeners();

  try {
    final url = Uri.parse('$baseurl/Home/changePassword');

    final encryptedOldPassword = encryptString(_model.currentPassword);
    final encryptedNewPassword = encryptString(_model.newPassword);

    final body = jsonEncode({
      "oldPassword": encryptedOldPassword,
      "newPassword": encryptedNewPassword,
      "location": Location.location,
      "vendorID": Vendor.vendorid,
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    _isLoading = false;
    notifyListeners();

    if (response.statusCode == 200) {
      return true;
    } else {
      //  Detailed logging in debug console
      debugPrint("ChangePassword API failed with status: ${response.statusCode}");
      debugPrint("Response body: ${response.body}");

      _errorMessage = " ${response.body} ";
      return false;
    }
  } catch (e, stacktrace) {
    _isLoading = false;

    //  Detailed debug print
    debugPrint("Exception in updatePassword: $e");
    debugPrint("Stack trace: $stacktrace");

    _errorMessage = 'Exception: ${e.toString()}';
    notifyListeners();
    return false;
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


  bool _validateInputs() {
    if (_model.currentPassword.isEmpty ||
        _model.newPassword.isEmpty ||
        _model.confirmPassword.isEmpty) {
      _errorMessage = 'All fields are required';
      notifyListeners();
      return false;
    }

    if (_model.newPassword != _model.confirmPassword) {
      _errorMessage = 'New password and confirm password do not match';
      notifyListeners();
      return false;
    }


    return true;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
