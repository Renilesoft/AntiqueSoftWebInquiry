import 'package:antiquewebemquiry/view/home_screen/home_screen.dart';
import 'package:antiquewebemquiry/viewmodel/SalesReportViewModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class SalesReportPage extends StatelessWidget {
  const SalesReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SalesReportViewModel(),
      child: const SalesReportView(),
    );
  }
}

class SalesReportView extends StatefulWidget {
  const SalesReportView({super.key});

  @override
  State<SalesReportView> createState() => _SalesReportViewState();
}

class _SalesReportViewState extends State<SalesReportView> {
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('MM/dd/yyyy');
  DateTime? _fromDate;
  DateTime? _toDate;


  @override
  void initState() {
    super.initState();
    _fromDate = DateTime.now().subtract(const Duration(days: 30));
    _toDate = DateTime.now();
    _fromDateController.text = _dateFormat.format(_fromDate!);
    _toDateController.text = _dateFormat.format(_toDate!);
  }

  void _navigateToHome(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate ? _fromDate! : _toDate!,
      firstDate: DateTime(2020),
      lastDate: DateTime(2025),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF8500),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFF8500),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
          _fromDateController.text = _dateFormat.format(picked);
        } else {
          _toDate = picked;
          _toDateController.text = _dateFormat.format(picked);
        }
      });
      _updateDateRange();
    }
  }

  void _updateDateRange() {
    if (_fromDate != null && _toDate != null) {
      final viewModel = context.read<SalesReportViewModel>();
      viewModel.updateDateRange(
        DateTimeRange(start: _fromDate!, end: _toDate!),
        _toDate!,
      );
    }
  }

@override
  Widget build(BuildContext context) {
    Provider.of<SalesReportViewModel>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF1EDE8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Sales Report',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        actions: [
          Stack(
            children: [
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: const Center(
                    child: Text(
                      '1',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Fixed Date Selection Container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            color: const Color(0xFFF1EDE8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(child: _buildDateField(context, true)),
                const SizedBox(width: 16),
                Expanded(child: _buildDateField(context, false)),
              ],
            ),
          ),
          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
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
                              'Market Payable',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF172B4D),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildPayableRow('Retail Sales', '\$16,110.41'),
                            _buildPayableRow('Wholesales', '\$368.00'),
                            _buildPayableRow('Online Sales', '\$325.26'),
                            _buildPayableRow('Layaway Sales', '\$0.00'),
                            _buildPayableRow('Sales Tax', '\$0.00'),
                            const Divider(height: 24),
                            _buildPayableRow('Total', '\$16,803.67', isBold: true),
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
                            _buildPayableRow('Sales Returns', '\$0.00'),
                            _buildPayableRow('Voids', '\$0.00'),
                            const Divider(height: 24),
                            _buildPayableRow('Total', '\$16,803.67', isBold: true),
                            const Divider(height: 24),
                            
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
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
                            _buildPayableRow('Flat Commission%', '7.00'),
                            _buildPayableRow('Commission on Sales', '\$1,176.26'),
                            _buildPayableRow('Consignment Commission', '\$0.00'),
                            _buildPayableRow('Credit/Debit Card Charges', '\$0.00'),
                            _buildPayableRow('Adjustments(if any)', '\$0.00'),
                            const Divider(height: 24),
                            _buildPayableRow('Total', '\$1,176.26', isBold: true),
                            const Divider(height: 24),
                            _buildPayableRow('Rental Dues', '\$0.00'),
                            _buildPayableRow('Due', '\$1,176.26', isBold: true),
                          ],
                        ),
                      ),
                    ),
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

  Widget _buildDateField(BuildContext context, bool isFromDate) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () => _selectDate(context, isFromDate),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 20,
                  color: Color(0xFF172B4D),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isFromDate ? _fromDateController.text : _toDateController.text,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF172B4D),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
            isSelected: false,
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
            color:  const Color(0xFFFF8500)
          ),
        ),
      ],
    );
  }
}

