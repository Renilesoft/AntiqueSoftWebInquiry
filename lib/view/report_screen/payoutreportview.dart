import 'package:antiquewebemquiry/Constants/baseurl.dart';
import 'package:antiquewebemquiry/Global/location.dart';
import 'package:antiquewebemquiry/Global/vendorid.dart';
import 'package:antiquewebemquiry/model/Payoutreportmainmodel.dart';
import 'package:antiquewebemquiry/view/date_range.dart';

import 'package:antiquewebemquiry/view/home_screen/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:antiquewebemquiry/viewmodel/payoutreportviewmodel.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Model for Monthly Payable API response
class PayoutReportPage extends StatelessWidget {
  const PayoutReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PayoutReportViewModel(),
      child: const PayoutReportView(),
    );
  }
}

class PayoutReportView extends StatefulWidget {
  const PayoutReportView({super.key});

  @override
  State<PayoutReportView> createState() => _PayoutReportViewState();
}

class _PayoutReportViewState extends State<PayoutReportView> {
  MonthlyPayableResponse? monthlyPayableData;
  MonthlyReceivableResponse? monthlyReceivableData;
  bool isLoading = false;
  String? errorMessage;
  
  // Store the final total for later use
  double? finalTotalSales;

  @override
  void initState() {
    super.initState();
    // Load initial data with default date range if needed
    _loadData();
  }

  void _navigateToHome(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  Future<void> _loadData({DateTimeRange? dateRange}) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Default date range if not provided
      final now = DateTime.now();
      final startDate = dateRange?.start ?? DateTime(now.year, now.month, 1);
      final endDate = dateRange?.end ?? DateTime(now.year, now.month + 1, 0);

      // Load both APIs simultaneously
      final futures = await Future.wait([
        _fetchMonthlyPayable(
          location: Location.location,
          vendorId: Vendor.vendorid!,
          startDate: startDate,
          endDate: endDate,
        ),
        _fetchMonthlyReceivable(
          location: Location.location,
          vendorId: Vendor.vendorid!,
          startDate: startDate,
          endDate: endDate,
        ),
      ]);

      final payableData = futures[0] as MonthlyPayableResponse;
      final receivableData = futures[1] as MonthlyReceivableResponse;

      setState(() {
        monthlyPayableData = payableData;
        monthlyReceivableData = receivableData;
        // Calculate and store final total sales (Total Sales - Less)
        final totalSales = payableData.retailSales + payableData.wholesaleSales + 
                          payableData.onlineSales + payableData.layawaySales + payableData.salesTax;
        final lessAmount = payableData.returnSales + payableData.voidSales;
        finalTotalSales = totalSales - lessAmount;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  String formatCurrency(double amount) {

    final isNegative = amount < 0;
    final value = amount.abs().toStringAsFixed(2);
    return isNegative ? '-\$${value}' : '\$${value}';

  }

  Future<MonthlyPayableResponse> _fetchMonthlyPayable({
    required String location,
    required int vendorId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final startDateStr = startDate.toIso8601String().split('T')[0];
    final endDateStr = endDate.toIso8601String().split('T')[0];
    
    final url = '$baseurl/Home/ getMonthlyPayable'
        '?location=$location'
        '&vendorId=$vendorId'
        '&startDate=$startDateStr'
        '&endDate=$endDateStr';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return MonthlyPayableResponse.fromJson(data);
    } else {
      throw Exception('Failed to load monthly payable data: ${response.statusCode}');
    }
  }

  Future<MonthlyReceivableResponse> _fetchMonthlyReceivable({
    required String location,
    required int vendorId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final startDateStr = startDate.toIso8601String().split('T')[0];
    final endDateStr = endDate.toIso8601String().split('T')[0];
    
    final url = '$baseurl/Home/getMonthlyReceivable'
        '?location=$location'
        '&vendorId=$vendorId'
        '&startDate=$startDateStr'
        '&endDate=$endDateStr';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return MonthlyReceivableResponse.fromJson(data);
    } else {
      throw Exception('Failed to load monthly receivable data: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<PayoutReportViewModel>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF1EDE8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Payout Report',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 20,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            color: const Color(0xFFF1EDE8),
            child: DateRangePickerWidget(
              onDateRangeSelected: (DateTimeRange range) {
                // Load data when date range changes
                _loadData(dateRange: range);
              },
              onSearch: () {
                // Implement additional search functionality if needed
              },
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Error: $errorMessage',
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadData(),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildMarketPayableCard(),
                              const SizedBox(height: 20),
                              _buildMarketReceivableCard(),
                            ],
                          ),
                        ),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildMarketPayableCard() {
    if (monthlyPayableData == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No data available'),
        ),
      );
    }

    final data = monthlyPayableData!;
    // Calculate first total (before deducting returns and voids)
    final firstTotalSales = data.retailSales + data.wholesaleSales + 
                           data.onlineSales + data.layawaySales + data.salesTax;
    // Calculate final total (after deducting returns and voids)
    final finalTotal = firstTotalSales - (data.returnSales + data.voidSales);

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Market Payable',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF172B4D),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'Auto Deduct Rent : ',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        color: Color(0xFF172B4D),
                        fontWeight: FontWeight.normal
                      ),
                    ),
                    Text(
                      'YES',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00CF9D),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPayableRow('Retail Sales', formatCurrency(data.retailSales)),
            _buildPayableRow('Wholesales', formatCurrency(data.wholesaleSales)),
            _buildPayableRow('Online Sales', formatCurrency(data.onlineSales)),
            _buildPayableRow('Layaway Sales', formatCurrency(data.layawaySales)),
            _buildPayableRow('Sales Tax', formatCurrency(data.salesTax)),
            const Divider(height: 24),
            _buildPayable('Total Sales', formatCurrency(firstTotalSales), isBold: true),
            const Divider(height: 24),
            const Text(
              'Less',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 14,
                color: Color(0xFF172B4D),
              ),
            ),
            const SizedBox(height: 8),
            _buildPayableRow('Sales Returns', formatCurrency(data.returnSales)),
            _buildPayableRow('Voids', formatCurrency(data.voidSales)),
            const Divider(height: 24),
            _buildPayable('Total Sales', formatCurrency(finalTotal), isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketReceivableCard() {
    if (monthlyReceivableData == null || finalTotalSales == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No receivable data available'),
        ),
      );
    }

    final receivableData = monthlyReceivableData!;
    final financials = receivableData.financials;
    
    // Calculate Commission on Sales as percentage of final total sales
    final calculatedCommissionOnSales = (financials.flatCommissionPercent / 100) * finalTotalSales!;
    
    // Calculate Total (Commission + Consignment + Credit Card + Adjustments)
    final total = calculatedCommissionOnSales + 
                 financials.consignmentCommission + 
                 financials.creditCardCharges + 
                 financials.vendorAdjustments;
    
    // Calculate Total Due (Rental Dues + Total)
    final totalDue = financials.rentalDues + total;
    
    // Calculate Final Amount (Total Sales - Total Due)
    final finalAmount = finalTotalSales! - totalDue;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Market Receivable',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF172B4D),
              ),
            ),
            const SizedBox(height: 16),
            _buildPayableRow('Flat Commission%', '${financials.flatCommissionPercent.toStringAsFixed(2)}%'),
            _buildPayableRow('Commission on Sales', '\$${calculatedCommissionOnSales.toStringAsFixed(2)}'),
            _buildPayableRow('Consignment Commission', '\$${financials.consignmentCommission.toStringAsFixed(2)}'),
            _buildPayableRow('Credit/Debit Card Charges', '\$${financials.creditCardCharges.toStringAsFixed(2)}'),
            _buildPayableRow('Adjustments(if any)', '\$${financials.vendorAdjustments.toStringAsFixed(2)}'),
            const Divider(height: 24),
            _buildPayableRow('Total', '\$${total.toStringAsFixed(2)}', isBold: true),
            const Divider(height: 24),
            _buildPayableRow('Rental Dues', '\$${financials.rentalDues.toStringAsFixed(2)}'),
            const Divider(height: 24),
            _buildPayable('Total Due', '\$${totalDue.toStringAsFixed(2)}', isBold: true),
            const Divider(height: 24),
            _buildAutoDetect('Total Sales - Total Due', formatCurrency(finalAmount), isBold: true),
            const Divider(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPayableRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 14,
              color: const Color(0xFF172B4D),
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 14,
              color: const Color(0xFF172B4D),
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayable(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 14,
              color: const Color(0xFF00CF9D),
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 14,
              color: const Color(0xFF00CF9D),
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoDetect(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 14,
              color: const Color(0xFFFF8500),
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 14,
              color: const Color(0xFFFF8500),
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => _navigateToHome(context),
            child: _buildBottomNavItem(
              imagePath: 'assets/home.svg',
              label: 'Home',
              isSelected: false,
            ),
          ),
          _buildBottomNavItem(
            imagePath: 'assets/report.svg',
            label: 'Reports',
            isSelected: true,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem({
    required String imagePath,
    required String label,
    required bool isSelected,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          imagePath,
          width: 40,
          height: 40,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: const Color(0xFFFF8500),
          ),
        ),
      ],
    );
  }
}