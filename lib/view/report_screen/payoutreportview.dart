import 'package:antiquewebemquiry/Global/location.dart';
import 'package:antiquewebemquiry/Global/vendorid.dart';
import 'package:antiquewebemquiry/model/payoutmodel.dart';
import 'package:antiquewebemquiry/viewmodel/payout_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:antiquewebemquiry/view/date_range.dart';
import 'package:antiquewebemquiry/view/home_screen/home_screen.dart';
import 'package:intl/intl.dart';

/// Entry widget for Payout Report
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

/// Actual screen content separated to avoid provider being rebuilt
class PayoutReportView extends StatefulWidget {
  const PayoutReportView({super.key});

  @override
  State<PayoutReportView> createState() => _PayoutReportViewState();
}

class _PayoutReportViewState extends State<PayoutReportView> {
  final currencyFormat = NumberFormat.currency(symbol: "\$", decimalDigits: 2);
  bool _firstOpen = true; // Track first page open

  // CHANGED: load Auto Deduct Rent when the screen opens
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PayoutReportViewModel>().getAutoDeductRent(
            vendorID: Vendor.vendorid!,
            location: Location.location,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PayoutReportViewModel>();

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
          // Date Range Picker
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            color: const Color(0xFFF1EDE8),
            child: DateRangePickerWidget(
              onDateRangeSelected: (DateTimeRange range) {
                setState(() {
                  _firstOpen = false; // Hide message after first search
                });
                vm.getPayoutSummary(
                  location: Location.location,
                  vendorID: Vendor.vendorid!,
                  fromDate: range.start,
                  toDate: range.end,
                );
              },
              onSearch: () {},
            ),
          ),

          // Report Body
          Expanded(
            child: Builder(
              builder: (_) {
                if (_firstOpen) {
                  return const Center(
                    child: Text(
                      "Please choose the month",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  );
                }

                if (vm.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (vm.errorMessage != null) {
                  return Center(child: Text(vm.errorMessage!));
                }

                final data = vm.payoutReport;
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // CHANGED: pass the API value
                        _buildMarketPayableCard(data, vm.autoDeductRent),
                        const SizedBox(height: 20),
                        _buildMarketReceivableCard(data),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  /// --- Market Payable Card ---
  // CHANGED: new `autoDeduct` parameter
  Widget _buildMarketPayableCard(PayoutReportModel data, bool? autoDeduct) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CHANGED: no longer const; shows Yes / No from the API
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
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
                    const Text(
                      'Auto Deduct Rent : ',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        color: Color(0xFF172B4D),
                      ),
                    ),
                    Text(
                      autoDeduct == null ? '-' : (autoDeduct ? 'Yes' : 'No'),
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: autoDeduct == true
                            ? const Color(0xFF00CF9D)
                            : Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPayableRow('Retail Sales', currencyFormat.format(data.retailSales)),
            _buildPayableRow('Wholesales', currencyFormat.format(data.wholeSales)),
            _buildPayableRow('Online Sales', currencyFormat.format(data.onlineSales)),
            _buildPayableRow('Layaway Sales', currencyFormat.format(data.layawaySales)),
            _buildPayableRow('Sales Tax', currencyFormat.format(data.salesTax)),
            const Divider(height: 24),
            _buildPayable('Total Sales', currencyFormat.format(data.totalSales), isBold: true),
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
            _buildPayableRow('Sales Returns', currencyFormat.format(data.salesReturns)),
            _buildPayableRow('Voids', currencyFormat.format(data.voids)),
            const Divider(height: 24),
            _buildPayable('Total Sales', currencyFormat.format(data.totalSalesWithReturns),
                isBold: true),
          ],
        ),
      ),
    );
  }

  /// --- Market Receivable Card ---
  Widget _buildMarketReceivableCard(PayoutReportModel data) {
    final totalDue = data.totalSalesWithReturns - data.receivableTotal - data.rentalDues;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
            _buildPayableRow('Flat Commission%', '${data.flatComm}%'),
            _buildPayableRow('Commission on Sales', currencyFormat.format(data.commOnSales)),
            _buildPayableRow('Consignment Commission', currencyFormat.format(data.consignComm)),
            _buildPayableRow('Credit/Debit Card Charges', currencyFormat.format(data.ccCharges)),
            _buildPayableRow('Adjustments(if any)', currencyFormat.format(data.adjustments)),
            const Divider(height: 24),
            _buildPayableRow('Total', currencyFormat.format(data.receivableTotal), isBold: true),
            const Divider(height: 24),
            _buildPayableRow('Rental Dues', currencyFormat.format(data.rentalDues)),
            const Divider(height: 24),
            _buildPayable('Total Due', currencyFormat.format(data.receivableTotal + data.rentalDues),
                isBold: true),
            const Divider(height: 24),
            _buildAutoDetect('Total Sales - Total Due', currencyFormat.format(totalDue),
                isBold: true),
            const Divider(height: 24),
          ],
        ),
      ),
    );
  }

  /// --- Common Widgets ---
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

  /// --- Bottom Navigation ---
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
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            ),
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
        SvgPicture.asset(imagePath, width: 40, height: 40),
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
