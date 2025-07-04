
import 'package:antiquewebemquiry/model/sales_table_modal.dart';
import 'package:antiquewebemquiry/user_data.dart';
import 'package:flutter/material.dart';

class AppData extends ChangeNotifier {
  
  String displayMsg = "No message";
  String location = "";
  List<UserData> userDataList = [];
  int selectedVendor = 0;
  List<SalesTableModel> salesTableData = [];
  String salesforDay = "0.00";
  String salesforMonth = "0.00";
  String salesforYear = "0.00";
  String rentDue = "0.00";
  String totalDue = "0.00";
  String otherDue = "0.00";
  String marketName = "";
  String address = "";
  String phone = "";
  String email = "";
  String zipCode = "";
  String stateCode = "";
  String city = "";
  String selectedDateRange = "";
  int salesCount = 0;
  int salesCountflag = 0;
  DateTime salesDate = DateTime.utc(1970, 1, 1, 0, 0, 0);


  void setSalesDateTime(DateTime newValue) {
    salesDate = newValue;
    notifyListeners();
  }

  void setSalesCount(int newValue) {
    salesCount = newValue;
    notifyListeners();
  }

  void setSalesCountflag(int newValue) {
    salesCountflag = newValue;
    notifyListeners();
  }

  void updateSalesTableData(List<SalesTableModel> newValue) {
    salesTableData = newValue;
    notifyListeners();
  }

  void updateUserData(List<UserData> newValue) {
    userDataList = newValue;
    notifyListeners();
  }


}