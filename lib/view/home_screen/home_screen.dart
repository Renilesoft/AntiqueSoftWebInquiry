import 'package:antiquewebemquiry/view/hamburger.dart';
import 'package:antiquewebemquiry/view/salesreport.dart';
import 'package:antiquewebemquiry/viewmodel/home_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../report_screen/report_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String selectedFilter = 'Daily';
  bool _showReport = false;
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  final Map<String, Map<String, String>> statistics = {
    'Daily': {
      'totalItems': '135',
      'totalSales': '\$345.97'
    },
    'Monthly': {
      'totalItems': '325',
      'totalSales': '\$11,985'
    },
    'Yearly': {
      'totalItems': '3897',
      'totalSales': '\$89,000'
    }
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleReport() {
    setState(() {
      _showReport = !_showReport;
      if (_showReport) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive calculations
    final Size screenSize = MediaQuery.of(context).size;
    final bool isTablet = screenSize.width > 600;

    return ChangeNotifierProvider(
      create: (_) => HomeViewModel(),
      child: Scaffold(
        key: _scaffoldKey,
        endDrawer: const DrawerMenu(),
        backgroundColor: const Color(0xFFF1EDE8),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // App Bar
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenSize.width * 0.04,
                      vertical: screenSize.height * 0.02,
                    ),
                    color: Colors.white,
                    child: Row(
                      children: [
                        const Text(
                          ' Home',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.normal,
                            color: Color(0xFF2D3142),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Stack(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.notifications_outlined),
                                  color: Colors.black,
                                  onPressed: () {},
                                ),
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 14,
                                      minHeight: 14,
                                    ),
                                    child: const Text(
                                      '1',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.menu),
                              color: Colors.black,
                              onPressed: () {
                                _scaffoldKey.currentState?.openEndDrawer();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: screenSize.height * 0.1,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: screenSize.height * 0.03),
                            
                            // Welcome Section
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenSize.width * 0.05,
                              ),
                              child: Row(
                                children: [
                                  const Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Hi Jack',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2D3142),
                                        ),
                                      ),
                                      Text(
                                        'Welcome back!',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2D3142),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  SvgPicture.asset(
                                    'assets/welcome.svg',
                                    height: screenSize.height * 0.12,
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: screenSize.height * 0.03),

                            // Filter Buttons
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenSize.width * 0.05,
                              ),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  double buttonWidth = (constraints.maxWidth - (2 * 12)) / 3;
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildFilterButton('Daily', buttonWidth),
                                      const SizedBox(width: 12),
                                      _buildFilterButton('Monthly', buttonWidth),
                                      const SizedBox(width: 12),
                                      _buildFilterButton('Yearly', buttonWidth),
                                    ],
                                  );
                                },
                              ),
                            ),

                            SizedBox(height: screenSize.height * 0.03),

                            // View Report Button
                            Center(
                              child: SizedBox(
                                width: isTablet ? screenSize.width * 0.4: 147,
                                height: screenSize.height * 0.06,
                                child: ElevatedButton(
                                  onPressed: _toggleReport,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF6B00),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: const Text(
                                    'View Report',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.white
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: screenSize.height * 0.03),

                            // Statistics Cards
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenSize.width * 0.05,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      'Total Items Sold',
                                      statistics[selectedFilter]!['totalItems']!,
                                      screenSize,
                                    )
                                  ),
                                  SizedBox(width: screenSize.width * 0.04),
                                  Expanded(
                                    child: _buildStatCard(
                                      'Total Sales Amount',
                                      statistics[selectedFilter]!['totalSales']!,
                                      screenSize,
                                    )
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: screenSize.height * 0.03),

                            // Chart Section
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenSize.width * 0.05,
                              ),
                              child: _buildChartSection(screenSize),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bottom Navigation
                  _buildBottomNavBar(screenSize),
                ],
              ),
              
              // Animated Sales Report Overlay
              if (_showReport)
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Positioned(
                      top: _animation.value * MediaQuery.of(context).padding.top,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 1),
                          end: Offset.zero,
                        ).animate(_animation),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, -5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: SalesReport(
                                  filterType: selectedFilter,
                                  onClose: _toggleReport,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(String text, double width) {
    bool isSelected = selectedFilter == text;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = text;
        });
      },
      child: Container(
        width: width,
        height:42.5,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF8500) : Colors.grey,
          borderRadius: BorderRadius.circular(1),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white,
              fontWeight: FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Size screenSize) {
    return Container(
      height: screenSize.height * 0.15,
      padding: EdgeInsets.all(screenSize.width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF11AB86),
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: screenSize.width > 600 ? 24 : 21,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3142),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00BFA6).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/trending.png',
                  width: screenSize.width * 0.06,
                  height: screenSize.width * 0.06,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(Size screenSize) {
    // Chart configuration remains the same
    // Just update the container sizing to be responsive
    return Container(
      padding: EdgeInsets.all(screenSize.width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'OVERVIEW',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF9A9A9A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$selectedFilter Sales',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF8500),
            ),
          ),
          SizedBox(height: screenSize.height * 0.02),
          SizedBox(
            height: screenSize.height * 0.4,
            child: _buildChart(screenSize),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(Size screenSize) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: screenSize.height * 0.02,
        horizontal: screenSize.width * 0.04,
      ),
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
          _buildNavItem('assets/home.png', 'Home', true, screenSize),
          _buildNavItem('assets/report.png', 'Reports', false, screenSize),
        ],
      ),
    );
  }

  Widget _buildNavItem(String iconPath, String label, bool isSelected, Size screenSize) {
    double iconSize = screenSize.width > 600 ? 48 : 40;
    
    return GestureDetector(
      onTap: () {
        if (label == 'Reports') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ReportsPage()),
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            iconPath,
            width: iconSize,
            height: iconSize,
          ),
          SizedBox(height: screenSize.height * 0.01),
          Text(
            label,
            style: TextStyle(
              fontSize: screenSize.width > 600 ? 14 : 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFF8500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(Size screenSize) {
    final Map<String, Map<String, dynamic>> chartConfigs = {
      'Daily': {
        'labels': ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
        'maxY': 1000.0,
        'interval': 100.0,
        'spots': const [
          FlSpot(0, 200),
          FlSpot(1, 400),
          FlSpot(2, 300),
          FlSpot(3, 600),
          FlSpot(4, 500),
          FlSpot(5, 700),
          FlSpot(6, 450),
        ],
      },
      'Monthly': {
        'labels': ['Week 1', 'Week 2', 'Week 3', 'Week 4'],
        'maxY': 10000.0,
        'interval': 1000.0,
        'spots': const [
          FlSpot(0, 2000),
          FlSpot(1, 4000),
          FlSpot(2, 7000),
          FlSpot(3, 5000),
        ],
      },
      'Yearly': {
        'labels': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
        'maxY': 100000.0,
        'interval': 10000.0,
        'spots': const [
          FlSpot(0, 15000),
          FlSpot(1, 25000),
          FlSpot(2, 45000),
          FlSpot(3, 35000),
          FlSpot(4, 55000),
          FlSpot(5, 75000),
          FlSpot(6, 65000),
          FlSpot(7, 85000),
          FlSpot(8, 70000),
          FlSpot(9, 90000),
          FlSpot(10, 80000),
          FlSpot(11, 95000),
        ],
      },
    };

    var currentConfig = chartConfigs[selectedFilter]!;
    
    // Calculate responsive chart width
    double chartWidth = selectedFilter == 'Yearly' 
        ? screenSize.width * (screenSize.width > 600 ? 2.5 : 3.5)
        : screenSize.width - (screenSize.width * 0.08);

    Widget chartWidget = SizedBox(
      width: chartWidth,
      height: screenSize.height * 0.35,
      child: Padding(
        padding: EdgeInsets.fromLTRB(0, screenSize.height * 0.015, screenSize.width * 0.03, screenSize.height * 0.015),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawHorizontalLine: true,
              drawVerticalLine: true,
              getDrawingHorizontalLine: (value) {
                return const FlLine(
                  color: Color(0xFFE5E5E5),
                  strokeWidth: 1,
                );
              },
              getDrawingVerticalLine: (value) {
                return const FlLine(
                  color: Color(0xFFE5E5E5),
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: screenSize.width * 0.15,
                  getTitlesWidget: (value, meta) {
                    return Padding(
                      padding: EdgeInsets.only(right: screenSize.width * 0.02),
                      child: Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          fontSize: screenSize.width > 600 ? 13 : 11,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    );
                  },
                  interval: currentConfig['interval'],
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: screenSize.height * 0.045,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= currentConfig['labels'].length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: EdgeInsets.only(top: screenSize.height * 0.01),
                      child: Text(
                        currentConfig['labels'][value.toInt()],
                        style: TextStyle(
                          fontSize: screenSize.width > 600 ? 16 : 14,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                  interval: 1,
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: const Color(0xFFE5E5E5)),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: currentConfig['spots'],
                isCurved: true,
                color: const Color(0xFF00BFA6),
                barWidth: screenSize.width * 0.008,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: screenSize.width * 0.015,
                      color: Colors.white,
                      strokeWidth: 3,
                      strokeColor: const Color(0xFF00BFA6),
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: const Color(0xFF00BFA6).withOpacity(0.1),
                ),
              ),
            ],
            minX: 0,
            maxX: (currentConfig['labels'].length - 1).toDouble(),
            minY: 0,
            maxY: currentConfig['maxY'],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                tooltipBgColor: Colors.black.withOpacity(0.8),
                tooltipRoundedRadius: 8,
                getTooltipItems: (List<LineBarSpot> touchedSpots) {
                  return touchedSpots.map((LineBarSpot touchedSpot) {
                    return LineTooltipItem(
                      '${currentConfig['labels'][touchedSpot.x.toInt()]}\n${touchedSpot.y.toInt()}',
                      TextStyle(
                        color: Colors.white,
                        fontSize: screenSize.width > 600 ? 14 : 12,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
          ),
        ),
      ),
    );

    return selectedFilter == 'Yearly'
        ? SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: chartWidget,
          )
        : chartWidget;
  }
}