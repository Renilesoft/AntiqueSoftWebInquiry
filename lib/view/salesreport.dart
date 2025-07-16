import 'package:antiquewebemquiry/Constants/baseurl.dart';
import 'package:antiquewebemquiry/Global/sales.dart';
import 'package:antiquewebemquiry/model/sales_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SalesReport extends StatefulWidget {
  final String filterType;
  final VoidCallback onClose;
  final String location;
  final int vendorId;

  const SalesReport({
    super.key,
    required this.filterType,
    required this.onClose,
    required this.location,
    required this.vendorId,
  });

  @override
  State<SalesReport> createState() => _SalesReportState();
}

class _SalesReportState extends State<SalesReport> {
  DateTime? startDate;
  DateTime? endDate;
  final DateFormat dateFormat = DateFormat('MM/dd/yyyy');
  
  // API related variables
  SalesResponse? salesResponse;
  bool isLoading = false;
  String? errorMessage;
  
  // Helper method to format currency properly
  String _formatCurrency(double amount) {
    if (amount < 0) {
      return '-\$${(-amount).toStringAsFixed(2)}';
    } else {
      return '\$${amount.toStringAsFixed(2)}';
    }
  }

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();

    switch (widget.filterType) {
      case 'Daily':
        startDate = now;
        endDate = now;
        break;
      
      case 'Monthly':
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month, now.day);
        break;
      
      default:
        startDate = DateTime(2010, 1, 1);
        endDate = DateTime(2026, 12, 31);
    }
    
    // Load initial data
    _fetchSalesData();
    
  }

Future<void> _fetchSalesData() async {
  if (startDate == null || endDate == null) return;
  
  setState(() {
    isLoading = true;
    errorMessage = null;
  });

  try {
    final response = await _callSalesAPI();
    setState(() {
      salesResponse = response;
      isLoading = false;
    });
    
    // Save the totals to SharedPreferences based on filter type
    if (widget.filterType == 'Monthly') {
      await MonthlyTotalItems.save(response.totalItems);
      await MonthlyTotalSales.save(response.totalSales);
    } else if (widget.filterType == 'Daily') {
      await DailyTotalItems.save(response.totalItems);
      await DailyTotalSales.save(response.totalSales);
    }
    
  } catch (e) {
    setState(() {
      errorMessage = e.toString();
      isLoading = false;
    });
  }
}

  Future<SalesResponse> _callSalesAPI() async {
    String url;
    
    if (widget.filterType == 'Monthly') {
      // Use Monthly Sales API endpoint
      final String startMonth = DateFormat('yyyy-MM').format(startDate!);
      final String endMonth = DateFormat('yyyy-MM').format(endDate!);
      
      url = '$baseurl/Home/MonthlySales?location=${widget.location}&vendorId=${widget.vendorId}&startMonth=$startMonth&endMonth=$endMonth';
    } else {
      // Use Daily Sales API endpoint for Daily and other filter types
      final DateTime adjustedStartDate = DateTime(startDate!.year, startDate!.month, startDate!.day, 0, 0, 0);
      final DateTime adjustedEndDate = DateTime(endDate!.year, endDate!.month, endDate!.day, 23, 59, 59);

      final String formattedStartDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(adjustedStartDate);
      final String formattedEndDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(adjustedEndDate);
      
      url = '$baseurl/Home/DailySales?location=${widget.location}&vendorId=${widget.vendorId}&startDate=$formattedStartDate&endDate=$formattedEndDate';
    }
    
    print('API Call URL: $url'); // Debug log
    
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      print('API Response: $jsonData'); // Debug log
      return SalesResponse.fromJson(jsonData);
    } else {
      throw Exception('Failed to load sales data: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    switch (widget.filterType) {
      case 'Daily':
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: isStartDate ? startDate ?? DateTime.now() : endDate ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Colors.orange,
                  onPrimary: Colors.white,
                  onSurface: Colors.black,
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.orange,
                  ),
                ),
              ),
              child: child!,
            );
          },
        );

        if (picked != null) {
          setState(() {
            if (isStartDate) {
              startDate = picked;
              if (endDate != null && picked.isAfter(endDate!)) {
                endDate = picked;
              }
            } else {
              endDate = picked;
              if (startDate != null && picked.isBefore(startDate!)) {
                startDate = picked;
              }
            }
          });
          _fetchSalesData();
        }
        break;
      
      case 'Monthly':
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: isStartDate ? startDate ?? DateTime.now() : endDate ?? DateTime.now(),
          firstDate: DateTime(2020, 1),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Colors.orange,
                  onPrimary: Colors.white,
                  onSurface: Colors.black,
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.orange,
                  ),
                ),
              ),
              child: child!,
            );
          },
        );

        if (picked != null) {
          setState(() {
            if (isStartDate) {
              startDate = DateTime(picked.year, picked.month, 1);
              // For monthly, if end date is in the same month or before, update it
              if (endDate != null && 
                  (endDate!.year < picked.year || 
                   (endDate!.year == picked.year && endDate!.month < picked.month))) {
                endDate = DateTime(picked.year, picked.month, DateTime(picked.year, picked.month + 1, 0).day);
              }
            } else {
              endDate = DateTime(picked.year, picked.month, DateTime(picked.year, picked.month + 1, 0).day);
              // For monthly, if start date is in the same month or after, update it
              if (startDate != null && 
                  (startDate!.year > picked.year || 
                   (startDate!.year == picked.year && startDate!.month > picked.month))) {
                startDate = DateTime(picked.year, picked.month, 1);
              }
            }
          });
          _fetchSalesData();
        }
        break;
      
      default:
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: isStartDate ? startDate ?? DateTime.now() : endDate ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2026),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Colors.orange,
                  onPrimary: Colors.white,
                  onSurface: Colors.black,
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.orange,
                  ),
                ),
              ),
              child: child!,
            );
          },
        );

        if (picked != null) {
          setState(() {
            if (isStartDate) {
              startDate = picked;
            } else {
              endDate = picked;
            }
          });
          _fetchSalesData();
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isTablet = screenWidth > 600;
    final bool isLargeTablet = screenWidth > 900;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.description, color: Color(0xFF172B4D)),
            const SizedBox(width: 8),
            Text(
              '${widget.filterType} Sales Report',
              style: const TextStyle(
                color: Color(0xFF172B4D),
                fontWeight: FontWeight.w600,
                fontFamily: "DM Sans"
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: widget.onClose,
          ),
        ],
      ),
      body: _buildResponsiveLayout(screenWidth, screenHeight, isTablet, isLargeTablet),
    );
  }

  Widget _buildResponsiveLayout(double screenWidth, double screenHeight, bool isTablet, bool isLargeTablet) {
    return SizedBox(
      width: screenWidth,
      height: screenHeight - kToolbarHeight,
      child: Column(
        children: [
          // Date Picker Section
          Container(
            width: screenWidth,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildDatePicker(true)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildDatePicker(false)),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Sales List with loading/error handling
          Expanded(
            child: SizedBox(
              width: screenWidth,
              child: _buildSalesContent(screenWidth),
            ),
          ),
          
          // Total Section
          _buildTotalSection(screenWidth),
        ],
      ),
    );
  }

  Widget _buildSalesContent(double screenWidth) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
        ),
      );
    }
    
    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchSalesData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    if (salesResponse?.salesData.isEmpty ?? true) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No sales data found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try selecting a different date range',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: salesResponse!.salesData.length,
      itemBuilder: (context, index) => _buildSalesItem(salesResponse!.salesData[index], screenWidth),
    );
  }

  Widget _buildTotalSection(double screenWidth) {
    return Container(
      width: screenWidth,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 1,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTotalItem(
                'Total Items', 
                '${salesResponse?.totalItems ?? 0}', 
                Colors.orange
              ),
              _buildTotalItem(
                'Total Sales', 
                _formatCurrency(salesResponse?.totalSales ?? 0.0), 
                const Color(0xFF00A81C)
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker(bool isStartDate) {
    return InkWell(
      onTap: () => _selectDate(context, isStartDate),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.black),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.black),
                const SizedBox(width: 8),
                Text(
                  widget.filterType == 'Monthly'
                    ? DateFormat('MMMM yyyy').format(isStartDate ? startDate! : endDate!)
                    : dateFormat.format(isStartDate ? startDate! : endDate!),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesItem(SalesData data, double screenWidth) {
    final bool isTablet = screenWidth > 600;
    final double dateWidth = isTablet ? 100 : 75;
    final double itemHeight = isTablet ? 70 : 60;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      height: itemHeight,
      child: Row(
        children: [
          // Date Container (Yellow)
          Container(
            width: dateWidth,
            decoration: const BoxDecoration(
              color: Color(0xFFFFD685),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                bottomLeft: Radius.circular(4),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateFormat.format(data.date),
                  style: TextStyle(
                    fontSize: isTablet ? 11 : 9,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Details Container (Light Green)
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFDBFFF0),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isTablet ? 16 : 8),
                child: Row(
                  children: [
                    // Description
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Description',
                            style: TextStyle(
                              fontSize: isTablet ? 12 : 10,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              data.description,
                              style: TextStyle(
                                fontSize: isTablet ? 15: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Quantity
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Quantity',
                            style: TextStyle(
                              fontSize: isTablet ? 12 : 10,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${data.quantity}',
                              style: TextStyle(
                                fontSize: isTablet ? 15 : 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Price
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Price',
                            style: TextStyle(
                              fontSize: isTablet ? 12 : 10,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _formatCurrency(data.price),
                              style: TextStyle(
                                fontSize: isTablet ? 15 : 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF00A81C),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Net Price
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Net Price',
                            style: TextStyle(
                              fontSize: isTablet ? 12 : 10,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _formatCurrency(data.netPrice),
                              style: TextStyle(
                                fontSize: isTablet ? 15 : 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF00A81C),
                              ),
                            ),
                          ),
                        ]
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalItem(String label, String value, Color valueColor) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth > 600;
    
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? 15 : 13,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isTablet ? 22 : 19,
            fontWeight: FontWeight.w900,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}