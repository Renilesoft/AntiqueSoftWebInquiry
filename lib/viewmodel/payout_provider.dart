import 'package:antiquewebemquiry/Repository/PayoutRepository.dart';
import 'package:antiquewebemquiry/model/payoutmodel.dart';
import 'package:flutter/material.dart';

class PayoutReportViewModel extends ChangeNotifier {
  final PayoutReportRepository _repository = PayoutReportRepository();

  bool isLoading = false;
  PayoutReportModel payoutReport = PayoutReportModel.empty();
  String? errorMessage;

  // NEW: null = not loaded or failed
  bool? autoDeductRent;

  Future<void> getPayoutSummary({
    required String location,
    required int vendorID,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final result = await _repository.fetchPayoutSummary(
        location: location,
        vendorID: vendorID,
        fromDate: fromDate,
        toDate: toDate,
      );

      payoutReport = result;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // NEW
  Future<void> getAutoDeductRent({
    required int vendorID,
    required String location,
  }) async {
    try {
      autoDeductRent = await _repository.fetchAutoDeductRent(
        vendorID: vendorID,
        location: location,
      );
    } catch (_) {
      autoDeductRent = null; // UI shows "-"
    }
    notifyListeners();
  }
}