import 'package:antiquewebemquiry/model/salesitem.dart';

import 'package:flutter/foundation.dart';
// ignore: implementation_imports
import 'package:flutter/src/material/date.dart';


class SalesReportViewModel extends ChangeNotifier {
  final SalesReportModel _model = SalesReportModel();

  SalesReportModel get model => _model;

  get dateRange => null;

  void refreshData() {
    // Implement refresh logic here
    notifyListeners();
  }

  void updateDateRange(DateTimeRange picked, DateTime end) {}
}