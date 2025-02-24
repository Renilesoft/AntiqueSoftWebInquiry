import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SalesReport extends StatefulWidget {
  final String filterType;
  final VoidCallback onClose;

  const SalesReport({
    super.key,
    required this.filterType,
    required this.onClose,
  });

  @override
  State<SalesReport> createState() => _SalesReportState();
}

class _SalesReportState extends State<SalesReport> {
  DateTime? startDate;
  DateTime? endDate;
  final DateFormat dateFormat = DateFormat('MM/dd/yyyy');
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    startDate = DateTime(2025, 1, 1);
    endDate = DateTime(2025, 12, 31);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? startDate ?? DateTime.now() : endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2025),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen width
    double screenWidth = MediaQuery.of(context).size.width;
    
    // Determine if we're on a tablet/desktop
    bool isTabletOrDesktop = screenWidth > 768;

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
              'Daily Sales Report',
              style: TextStyle(
                color: Color(0xFF172B4D),
                fontWeight: FontWeight.w600,
                fontSize: isTabletOrDesktop ? 24 : 20,
                fontFamily: "DM Sans"
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: Colors.grey, size: isTabletOrDesktop ? 28 : 24),
            onPressed: widget.onClose,
          ),
        ],
      ),
      body: Column(
        children: [
          // Date Picker Section
          Container(
            padding: EdgeInsets.all(isTabletOrDesktop ? 24 : 16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildDatePicker(true)),
                    SizedBox(width: isTabletOrDesktop ? 24 : 16),
                    Expanded(child: _buildDatePicker(false)),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Sales List
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  width: isTabletOrDesktop 
                    ? constraints.maxWidth * 0.8 // 80% of screen width for tablet/desktop
                    : constraints.maxWidth,
                  margin: EdgeInsets.symmetric(
                    horizontal: isTabletOrDesktop ? constraints.maxWidth * 0.1 : 0
                  ),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(isTabletOrDesktop ? 16 : 8),
                    itemCount: _salesData.length,
                    itemBuilder: (context, index) => _buildSalesItem(_salesData[index], isTabletOrDesktop),
                  ),
                );
              },
            ),
          ),
          
          // Total Section
          Container(
            padding: EdgeInsets.all(isTabletOrDesktop ? 24 : 16),
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
                    _buildTotalItem('Total Items', '234', Colors.orange, isTabletOrDesktop),
                    _buildTotalItem('Total Sales', '\$47,892', Color(0xFF00A81C), isTabletOrDesktop),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker(bool isStartDate) {
    bool isTabletOrDesktop = MediaQuery.of(context).size.width > 768;
    
    return InkWell(
      onTap: () => _selectDate(context, isStartDate),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTabletOrDesktop ? 16 : 12,
          vertical: isTabletOrDesktop ? 12 : 8
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: isTabletOrDesktop ? 20 : 16,
                  color: Colors.grey[600]
                ),
                SizedBox(width: isTabletOrDesktop ? 12 : 8),
                Text(
                  dateFormat.format(isStartDate ? startDate! : endDate!),
                  style: TextStyle(
                    fontSize: isTabletOrDesktop ? 15 : 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesItem(Map<String, String> data, bool isTabletOrDesktop) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      height: isTabletOrDesktop ? 80 : 60,
      child: Row(
        children: [
          // Date Container (Yellow)
          Container(
            width: isTabletOrDesktop ? 120 : 85,
            decoration: const BoxDecoration(
              color: Color(0xFFFFD685),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                bottomLeft: Radius.circular(4),
              ),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: isTabletOrDesktop ? 16 : 8
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['date']!,
                  style: TextStyle(
                    fontSize: isTabletOrDesktop ? 14 : 11.9,
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
                padding: EdgeInsets.symmetric(
                  horizontal: isTabletOrDesktop ? 24 : 12
                ),
                child: Row(
                  children: [
                    // Description
                    Expanded(
                      flex: isTabletOrDesktop ? 3 : 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Description',
                            style: TextStyle(
                              fontSize: isTabletOrDesktop ? 13 : 11,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: isTabletOrDesktop ? 6 : 4),
                          Text(
                            data['description']!,
                            style: TextStyle(
                              fontSize: isTabletOrDesktop ? 16 : 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Quantity
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Quantity',
                            style: TextStyle(
                              fontSize: isTabletOrDesktop ? 13 : 11,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: isTabletOrDesktop ? 6 : 4),
                          Text(
                            data['quantity']!,
                            style: TextStyle(
                              fontSize: isTabletOrDesktop ? 16 : 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Price
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Price',
                            style: TextStyle(
                              fontSize: isTabletOrDesktop ? 13 : 11,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: isTabletOrDesktop ? 6 : 4),
                          Text(
                            data['price']!,
                            style: TextStyle(
                              fontSize: isTabletOrDesktop ? 16 : 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00A81C),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Net Price
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Net Price',
                            style: TextStyle(
                              fontSize: isTabletOrDesktop ? 13 : 11,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: isTabletOrDesktop ? 6 : 4),
                          Text(
                            data['netPrice']!,
                            style: TextStyle(
                              fontSize: isTabletOrDesktop ? 16 : 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00A81C),
                            ),
                          ),
                        ],
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

  Widget _buildTotalItem(String label, String value, Color valueColor, bool isTabletOrDesktop) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTabletOrDesktop ? 15 : 13,
            color: Colors.black,
          ),
        ),
        SizedBox(height: isTabletOrDesktop ? 6 : 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isTabletOrDesktop ? 20 : 16,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  final List<Map<String, String>> _salesData = [
    {
      'date': 'Feb 24, 2025',
      'description': 'Coffee Mug',
      'quantity': '15',
      'price': '\$12.99',
      'netPrice': '\$194.85',
    },
    {
      'date': 'Feb 24, 2025',
      'description': 'Wine Glass',
      'quantity': '24',
      'price': '\$8.99',
      'netPrice': '\$215.76',
    },
    {
      'date': 'Feb 24, 2025',
      'description': 'Plate Set',
      'quantity': '08',
      'price': '\$45.99',
      'netPrice': '\$367.92',
    },
    {
      'date': 'Feb 24, 2025',
      'description': 'Bowl Set',
      'quantity': '12',
      'price': '\$32.99',
      'netPrice': '\$395.88',
    },
    {
      'date': 'Feb 24, 2025',
      'description': 'Cutlery',
      'quantity': '30',
      'price': '\$24.99',
      'netPrice': '\$749.70',
    },
    {
      'date': 'Feb 24, 2025',
      'description': 'Teapot',
      'quantity': '06',
      'price': '\$55.99',
      'netPrice': '\$335.94',
    },
    {
      'date': 'Feb 24, 2025',
      'description': 'Vase',
      'quantity': '10',
      'price': '\$28.99',
      'netPrice': '\$289.90',
    },
    {
      'date': 'Feb 24, 2025',
      'description': 'Pitcher',
      'quantity': '09',
      'price': '\$34.99',
      'netPrice': '\$314.91',
    },
    {
      'date': 'Feb 24, 2025',
      'description': 'Salt Set',
      'quantity': '20',
      'price': '\$15.99',
      'netPrice': '\$319.80',
    },
    {
      'date': 'Feb 24, 2025',
      'description': 'Serving Bowl',
      'quantity': '14',
      'price': '\$42.99',
      'netPrice': '\$601.86',
    },
    {
      'date': 'Feb 24, 2025',
      'description': 'Mug Rack',
      'quantity': '07',
      'price': '\$39.99',
      'netPrice': '\$279.93',
    },
    {
      'date': 'Feb 24, 2025',
      'description': 'Coaster Set',
      'quantity': '25',
      'price': '\$19.99',
      'netPrice': '\$499.75',
    },
  ];
}