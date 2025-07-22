import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:antiquewebemquiry/Constants/baseurl.dart';
import 'package:antiquewebemquiry/Global/location.dart';
import 'package:antiquewebemquiry/Global/vendorid.dart';
import 'package:antiquewebemquiry/Global/yearlytotalquantity.dart';
import 'package:antiquewebemquiry/Global/yearlytotalsales.dart';
import 'package:antiquewebemquiry/view/home_screen/home_screen.dart';

class YearlySalesReportPage extends StatefulWidget {
  const YearlySalesReportPage({super.key});

  @override
  _YearlySalesReportPageState createState() => _YearlySalesReportPageState();
}

class _YearlySalesReportPageState extends State<YearlySalesReportPage>
    with SingleTickerProviderStateMixin {
  final List<String> years = [
    for (int year = 2010; year <= 2025; year++) year.toString()
  ];

  final List<String> months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  List<Map<String, dynamic>> salesData = [];
  String selectedYear = '2025';

  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 1), // slide down
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    fetchYearlySales(selectedYear);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> fetchYearlySales(String year) async {
    try {
      final uri = Uri.parse(
        '$baseurl/Home/YearlySales?location=${Location.location}&vendorId=${Vendor.vendorid}&year=$year',
      );
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> apiMonthlySales = jsonResponse['monthlySales'];

        Map<String, Map<String, dynamic>> apiDataMap = {
          for (var item in apiMonthlySales)
            item['month']: {
              'quantity': item['totalQuantity'],
              'sales': (item['totalSales'] as num).toDouble(),
            }
        };

        salesData = months.map((month) {
          return {
            'month': month,
            'quantity': apiDataMap[month]?['quantity'] ?? 0,
            'sales': apiDataMap[month]?['sales'] ?? 0.0,
          };
        }).toList();

        final totals = _calculateTotals();
        await TotalQuantity.save(totals['quantity'] as int);
        await TotalSales.save(totals['sales'] as double);

        setState(() {});
      } else {
        showError("Failed to fetch yearly sales data: ${response.statusCode}");
      }
    } catch (e) {
      showError("Failed to fetch yearly sales data:\n$e");
    }
  }

  void showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showYearPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SizedBox(
          height: 400,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Select Year',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: years.length,
                  itemBuilder: (context, index) {
                    final year = years[index];
                    return ListTile(
                      title: Text(
                        year,
                        style: TextStyle(
                          color: selectedYear == year ? Colors.pink : Colors.black,
                        ),
                      ),
                      onTap: () async {
                        setState(() {
                          selectedYear = year;
                        });
                        Navigator.pop(context);
                        await fetchYearlySales(year);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Map<String, num> _calculateTotals() {
    int totalQuantity = salesData.fold(0, (sum, item) => sum + (item['quantity'] as int));
    double totalSales = salesData.fold(0.0, (sum, item) => sum + (item['sales'] as double));
    return {'quantity': totalQuantity, 'sales': totalSales};
  }

  @override
  Widget build(BuildContext context) {
    final totals = _calculateTotals();

    return SlideTransition(
      position: _slideAnimation,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1EDE8),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.black),
                onPressed: () async {
                  await _controller.forward(); // Start slide down animation
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                },
              ),
            ),
          ],
          title: const Text(
            'Yearly Sales Report',
            style: TextStyle(
              color: Color(0xFF172B4D),
              fontWeight: FontWeight.bold,
              fontFamily: 'DM Sans',
            ),
          ),
          centerTitle: true,
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.black.withOpacity(0.1)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.black),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => _showYearPicker(context),
                          child: Text(
                            selectedYear,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: salesData.length,
                    itemBuilder: (context, index) {
                      final item = salesData[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        height: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFD685),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(15),
                                    bottomLeft: Radius.circular(15),
                                  ),
                                ),
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  item['month'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Quantity Sold', style: TextStyle(fontSize: 10)),
                                          Text(
                                            '${item['quantity']}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Total Sales', style: TextStyle(fontSize: 10)),
                                          Text(
                                            '\$${(item['sales'] as double).toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text('  Total Quantity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('  Grand Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text(
                            '         ${totals['quantity']}',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '         \$${(totals['sales'] as double).toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
