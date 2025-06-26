import 'package:antiquewebemquiry/Constants/baseurl.dart';
import 'package:antiquewebemquiry/Global/location.dart';
import 'package:antiquewebemquiry/Global/username.dart';
import 'package:antiquewebemquiry/Global/vendorid.dart';
import 'package:antiquewebemquiry/view/hamburger.dart';
import 'package:antiquewebemquiry/view/message.dart';
// ignore: unused_import 
import 'package:antiquewebemquiry/view/notification.dart';
import 'package:antiquewebemquiry/view/popupmessage.dart';
import 'package:antiquewebemquiry/view/salesreport.dart';
import 'package:antiquewebemquiry/viewmodel/home_viewmodel.dart';
import 'package:antiquewebemquiry/view/yearlysales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
  bool _showWelcomeNotification = true; // Control the visibility of the welcome notification
  late AnimationController _animationController;
  late Animation<double> _animation;
  List<FlSpot> dailySalesSpots = [];
  List<String> dailySalesLabels = [];
  bool isLoadingDailySales = false;
  double maxDailySales = 1000.0;

  List<FlSpot> monthlySalesSpots = [];
  List<String> monthlySalesLabels = ['Week 1', 'Week 2', 'Week 3', 'Week 4'];
  bool isLoadingMonthlySales = false;
  double maxMonthlySales = 10000.0;
  String currentMonth = '';

  List<FlSpot> yearlySalesSpots = [];
  List<String> yearlySalesLabels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  bool isLoadingYearlySales = false;
  double maxYearlySales = 100000.0;
  int currentYear = 0;

  String marketMessage = 'Loading...';
  bool isLoadingMarketMessage = true;

  
  // API related variables
  String vendorName = 'Loading...'; // Default value while loading
  bool isLoadingVendorName = true;
  
  Map<String, Map<String, String>> get statistics {
  return {
    'Daily': {
      'totalItems': isLoadingDailyStats ? 'Loading...' : dailyStats['totalItems']!,
      'totalSales': isLoadingDailyStats ? 'Loading...' : dailyStats['totalSales']!,
    },
    'Monthly': {
      'totalItems': isLoadingMonthlyStats ? 'Loading...' : monthlyStats['totalItems']!,
      'totalSales': isLoadingMonthlyStats ? 'Loading...' : monthlyStats['totalSales']!,
    },
    'Yearly': {
      'totalItems': isLoadingYearlyStats ? 'Loading...' : yearlyStats['totalItems']!,
      'totalSales': isLoadingYearlyStats ? 'Loading...' : yearlyStats['totalSales']!,
    },
  };
}

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

  _fetchVendorName();
  _fetchDailySalesData();
  _fetchMonthlySalesData();
  _fetchYearlySalesData();
  _refreshPage();
  _fetchMarketMessage();
  _fetchDailySalesStats();
  _fetchMonthlySalesStats();
  _fetchYearlyStats();// 👈 Load shared prefs
  
}

Map<String, String> dailyStats = {
  'totalItems': '0',
  'totalSales': '\$0.00',
};
bool isLoadingDailyStats = false;

Map<String, String> monthlyStats = {
  'totalItems': '0',
  'totalSales': '\$0.00',
};
bool isLoadingMonthlyStats = false;

Map<String, String> yearlyStats = {
  'totalItems': '0',
  'totalSales': '\$0.00',
};
bool isLoadingYearlyStats = false;

Future<void> _refreshPage() async {
  // Refresh all data
  await _fetchVendorName();
  await _fetchMarketMessage(); 
  await _fetchDailySalesStats();// Add this line
  await _fetchDailySalesData();
  await _fetchMonthlySalesData();
  await _fetchYearlySalesData();
  await _fetchMonthlySalesStats();
  await _fetchYearlyStats();
  
  // Update the UI
  setState(() {});
}

Future<void> _fetchYearlyStats() async {
  setState(() {
    isLoadingYearlyStats = true;
  });

  try {
    // Get current year
    final DateTime now = DateTime.now();
    final int currentYearParam = now.year;
    
    final String url = '$baseurl/Home/YearlySales?location=${Location.location}&vendorId=${Vendor.vendorid}&year=$currentYearParam';
    
    print('Yearly Stats API URL: $url'); // Debug print
    
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    print('Yearly Stats Response Status: ${response.statusCode}'); // Debug print
    print('Yearly Stats Response Body: ${response.body}'); // Debug print

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      
      setState(() {
        yearlyStats = {
          'totalItems': (data['totalQuantitySold'] ?? 0).toString(),
          'totalSales': '\$${(data['totalSalesAmount'] ?? 0.0).toStringAsFixed(2)}',
        };
        isLoadingYearlyStats = false;
      });
    } else {
      setState(() {
        yearlyStats = {
          'totalItems': '0',
          'totalSales': '\$0.00',
        };
        isLoadingYearlyStats = false;
      });
      _showErrorSnackBar('Failed to load yearly stats: ${response.statusCode}');
    }
  } catch (e) {
    setState(() {
      yearlyStats = {
        'totalItems': '0',
        'totalSales': '\$0.00',
      };
      isLoadingYearlyStats = false;
    });
    print('Yearly Stats Error: $e'); // Debug print
    _showErrorSnackBar('Error loading yearly stats: ${e.toString()}');
  }
}

Future<void> _fetchDailySalesStats() async {
  setState(() {
    isLoadingDailyStats = true;
  });

  try {
    // Get current date in the required format
    final DateTime now = DateTime.now();
    final String currentDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    final String url = '$baseurl/Home/DailySales?location=${Location.location}&vendorId=${Vendor.vendorid}&startDate=${currentDate}T00:00:00&endDate=${currentDate}T23:59:59';
    
    print('Daily Sales Stats API URL: $url'); // Debug print
    
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    print('Daily Sales Stats Response Status: ${response.statusCode}'); // Debug print
    print('Daily Sales Stats Response Body: ${response.body}'); // Debug print

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      
      setState(() {
        dailyStats = {
          'totalItems': (data['totalItems'] ?? 0).toString(),
          'totalSales': '\$${(data['totalSales'] ?? 0.0).toStringAsFixed(2)}',
        };
        isLoadingDailyStats = false;
      });
    } else {
      setState(() {
        dailyStats = {
          'totalItems': '0',
          'totalSales': '\$0.00',
        };
        isLoadingDailyStats = false;
      });
      _showErrorSnackBar('Failed to load daily sales stats: ${response.statusCode}');
    }
  } catch (e) {
    setState(() {
      dailyStats = {
        'totalItems': '0',
        'totalSales': '\$0.00',
      };
      isLoadingDailyStats = false;
    });
    print('Daily Sales Stats Error: $e'); // Debug print
    _showErrorSnackBar('Error loading daily sales stats: ${e.toString()}');
  }
}



Future<void> _fetchMarketMessage() async {
  try {
    final String url = '$baseurl/Home/getMarketMessage?location=${Location.location}';
    
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      setState(() {
        marketMessage = data['marketMessage'] ?? 'No message available';
        isLoadingMarketMessage = false;
      });
    } else {
      setState(() {
        marketMessage = 'Failed to load message';
        isLoadingMarketMessage = false;
      });
    }
  } catch (e) {
    setState(() {
      marketMessage = 'Error loading message';
      isLoadingMarketMessage = false;
    });
  }
}

Future<void> _fetchMonthlySalesStats() async {
  setState(() {
    isLoadingMonthlyStats = true;
  });

  try {
    // Get current month in the required format (YYYY-MM)
    final DateTime now = DateTime.now();
    final String currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    
    final String url = '$baseurl/Home/MonthlySales?location=${Location.location}&vendorId=${Vendor.vendorid}&startMonth=$currentMonth&endMonth=$currentMonth';
    
    print('Monthly Sales Stats API URL: $url'); // Debug print
    
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    print('Monthly Sales Stats Response Status: ${response.statusCode}'); // Debug print
    print('Monthly Sales Stats Response Body: ${response.body}'); // Debug print

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      
      setState(() {
        monthlyStats = {
          'totalItems': (data['totalItems'] ?? 0).toString(),
          'totalSales': '\$${(data['totalSales'] ?? 0.0).toStringAsFixed(2)}',
        };
        isLoadingMonthlyStats = false;
      });
    } else {
      setState(() {
        monthlyStats = {
          'totalItems': '0',
          'totalSales': '\$0.00',
        };
        isLoadingMonthlyStats = false;
      });
      _showErrorSnackBar('Failed to load monthly sales stats: ${response.statusCode}');
    }
  } catch (e) {
    setState(() {
      monthlyStats = {
        'totalItems': '0',
        'totalSales': '\$0.00',
      };
      isLoadingMonthlyStats = false;
    });
    print('Monthly Sales Stats Error: $e'); // Debug print
    _showErrorSnackBar('Error loading monthly sales stats: ${e.toString()}');
  }
}

Future<void> _fetchYearlySalesData() async {
  setState(() {
    isLoadingYearlySales = true;
  });

  try {
    // Get current year
    final DateTime now = DateTime.now();
    final int currentYearParam = now.year;
    
    final String url = '$baseurl/Home/YearlySales?location=${Location.location}&vendorId=${Vendor.vendorid}&year=$currentYearParam';
    
    print('Yearly Sales API URL: $url'); // Debug print
    
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    print('Yearly Sales Response Status: ${response.statusCode}'); // Debug print
    print('Yearly Sales Response Body: ${response.body}'); // Debug print

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> monthlySales = data['monthlySales'] ?? [];
      
      // Clear existing data
      yearlySalesSpots.clear();
      
      // Set the year for display
      currentYear = data['year'] ?? currentYearParam;
      
      // Create a map to store sales data by month
      Map<String, double> salesByMonth = {};
      
      // Process the monthly sales data
      for (var monthData in monthlySales) {
        String month = monthData['month'] ?? '';
        double totalSales = (monthData['totalSales'] ?? 0).toDouble();
        salesByMonth[month] = totalSales;
      }
      
      // Create spots for all 12 months, using 0 for months with no data
      List<String> monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 
                                'July', 'August', 'September', 'October', 'November', 'December'];
      
      for (int i = 0; i < monthNames.length; i++) {
        String monthName = monthNames[i];
        double salesAmount = salesByMonth[monthName] ?? 0.0;
        yearlySalesSpots.add(FlSpot(i.toDouble(), salesAmount));
      }
      
      // Calculate max Y value based on data or set a minimum
      double maxValue = yearlySalesSpots.isNotEmpty 
          ? yearlySalesSpots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b)
          : 0;
      maxYearlySales = maxValue > 0 ? (maxValue * 1.2).ceilToDouble() : 100000.0;
      
      setState(() {
        isLoadingYearlySales = false;
      });
    } else {
      setState(() {
        isLoadingYearlySales = false;
      });
      _showErrorSnackBar('Failed to load yearly sales data: ${response.statusCode}');
    }
  } catch (e) {
    setState(() {
      isLoadingYearlySales = false;
    });
    print('Yearly Sales Error: $e'); // Debug print
    _showErrorSnackBar('Error loading yearly sales data: ${e.toString()}');
  }
}

Future<void> _fetchDailySalesData() async {
  setState(() {
    isLoadingDailySales = true;
  });

  try {
    // Get current date in the required format
    final DateTime now = DateTime.now();
    final String currentDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    final String url = '$baseurl/Home/graphSalesDaily?location=${Location.location}&vendorId=${Vendor.vendorid}&date=$currentDate';
    
    print('API URL: $url'); // Debug print
    
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    print('Response Status: ${response.statusCode}'); // Debug print
    print('Response Body: ${response.body}'); // Debug print

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> dailySales = data['dailySales'];
      
      // Clear existing data
      dailySalesSpots.clear();
      dailySalesLabels.clear();
      
      // Sort the data by date to ensure proper order
      dailySales.sort((a, b) {
        final dateA = DateTime.parse(a['date']);
        final dateB = DateTime.parse(b['date']);
        return dateA.compareTo(dateB);
      });
      
      // Process the API response
      for (int i = 0; i < dailySales.length; i++) {
        final salesData = dailySales[i];
        final double totalSales = (salesData['totalSales'] ?? 0).toDouble();
        final String date = salesData['date'] ?? '';
        final String day = salesData['day'] ?? '';
        
        // Format: "Sun\n(July 1)\n2025" - Day abbreviation, date in brackets, year
        final DateTime parsedDate = DateTime.parse(date);
        final String dayAbbr = _getDayAbbreviation(day);
        final String monthName = _getMonthName(parsedDate.month);
        final String formattedLabel = '$dayAbbr\n$monthName ${parsedDate.day}\n${parsedDate.year}';
        
        dailySalesSpots.add(FlSpot(i.toDouble(), totalSales));
        dailySalesLabels.add(formattedLabel);
      }
      
      // Set fixed max Y value to 100
      maxDailySales = 100.0;
      
      setState(() {
        isLoadingDailySales = false;
      });
    } else {
      setState(() {
        isLoadingDailySales = false;
      });
      _showErrorSnackBar('Failed to load daily sales data: ${response.statusCode}');
    }
  } catch (e) {
    setState(() {
      isLoadingDailySales = false;
    });
    print('Error: $e'); // Debug print
    _showErrorSnackBar('Error loading daily sales data: ${e.toString()}');
  }
}



String _getMonthName(int month) {
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  return months[month - 1];
}

String _getDayAbbreviation(String fullDay) {
  switch (fullDay.toLowerCase()) {
    case 'sunday':
      return 'Sun';
    case 'monday':
      return 'Mon';
    case 'tuesday':
      return 'Tue';
    case 'wednesday':
      return 'Wed';
    case 'thursday':
      return 'Thu';
    case 'friday':
      return 'Fri';
    case 'saturday':
      return 'Sat';
    default:
      return fullDay.length >= 3 ? fullDay.substring(0, 3) : fullDay;
  }
}

Future<void> _fetchMonthlySalesData() async {
  setState(() {
    isLoadingMonthlySales = true;
  });

  try {
    // Get current date in the required format (YYYY-MM)
    final DateTime now = DateTime.now();
    final String currentMonthParam = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    
    final String url = '$baseurl/Home/graphSalesMonthly?location=${Location.location}&vendorId=${Vendor.vendorid}&month=$currentMonthParam';
    
    print('Monthly Sales API URL: $url'); // Debug print
    
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    print('Monthly Sales Response Status: ${response.statusCode}'); // Debug print
    print('Monthly Sales Response Body: ${response.body}'); // Debug print

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final Map<String, dynamic> weeklySales = data['weeklySales'];
      
      // Clear existing data
      monthlySalesSpots.clear();
      
      // Set the month for display
      currentMonth = data['month'] ?? '';
      
      // Process the weekly sales data
      int index = 0;
      weeklySales.forEach((week, sales) {
        final double salesAmount = (sales ?? 0).toDouble();
        monthlySalesSpots.add(FlSpot(index.toDouble(), salesAmount));
        index++;
      });
      
      // Calculate max Y value based on data or set a minimum
      double maxValue = monthlySalesSpots.isNotEmpty 
          ? monthlySalesSpots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b)
          : 0;
      maxMonthlySales = maxValue > 0 ? (maxValue * 1.2).ceilToDouble() : 10000.0;
      
      setState(() {
        isLoadingMonthlySales = false;
      });
    } else {
      setState(() {
        isLoadingMonthlySales = false;
      });
      _showErrorSnackBar('Failed to load monthly sales data: ${response.statusCode}');
    }
  } catch (e) {
    setState(() {
      isLoadingMonthlySales = false;
    });
    print('Monthly Sales Error: $e'); // Debug print
    _showErrorSnackBar('Error loading monthly sales data: ${e.toString()}');
  }
}




  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // API call to fetch vendor name
  Future<void> _fetchVendorName() async {
    try {
      // Replace these with actual values from your app's state/preferences
      
      final String url = '$baseurl/Home/getClientName?location=${Location.location}&email=${Uri.encodeComponent(Username.username)}';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          vendorName = data['vendorName'] ?? 'User';
          isLoadingVendorName = false;
        });
      } else {
        // Handle error response
        setState(() {
          vendorName = 'User';
          isLoadingVendorName = false;
        });
        _showErrorSnackBar('Failed to load vendor name: ${response.statusCode}');
      }
    } catch (e) {
      // Handle network or parsing errors
      setState(() {
        vendorName = 'User';
        isLoadingVendorName = false;
      });
      _showErrorSnackBar('Error loading vendor name: ${e.toString()}');
    }
  }

  // Show error message to user
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _toggleReport() {
    if (selectedFilter == 'Yearly') {
      // Navigate to YearlySalesReport for Yearly filter
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const YearlySalesReportPage(),
        ),
      );
    } else {
      // Existing toggle report logic for Daily and Monthly
      setState(() {
        _showReport = !_showReport;
        if (_showReport) {
          _animationController.forward();
        } else {
          _animationController.reverse();
        }
      });
    }
  }
  
  // Handle closing the welcome notification
  void _closeWelcomeNotification() {
    setState(() {
      _showWelcomeNotification = false;
    });
  }
  
  // Handle opening action for the welcome notification
  void _openWelcomeNotification() {
    // Implement action for when "Open" is clicked
    // For example, navigate to a specific page or show more details
    _closeWelcomeNotification();
  }
  
  // Navigate to MessagePage
  void _navigateToMessagePage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MessagePage(initialTabIndex: 0,),
      ),
    );
  }

  void _navigateToNotificationPage() {
    // Navigator.push(
    //   context,
    //   // MaterialPageRoute(
    //   //   builder: (context) => const NotificationPopupScreen(),
    //   // ),
    // );
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
                                  icon: const Icon(Icons.email_outlined),
                                  color: Colors.black,
                                  onPressed: _navigateToMessagePage,
                                ),
                                Positioned(
                                  right: 9,
                                  top: 11,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 10,
                                      minHeight: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Stack(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.notifications_outlined),
                                  color: Colors.black,
                                  onPressed: _navigateToNotificationPage,
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

                  // Welcome Notification - displayed just below the AppBar
                if (_showWelcomeNotification)
                  WelcomeNotification(
                    message: isLoadingMarketMessage ? 'Loading message...' : marketMessage,
                    onClose: _closeWelcomeNotification,
                    onOpen: _openWelcomeNotification,
                  ),

                  Expanded(
                    child: RefreshIndicator(
                    onRefresh: _refreshPage,
                    color: const Color(0xFF00BFA6),
                    backgroundColor: Colors.white,
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: screenSize.height * 0.1,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: screenSize.height * 0.03),
                            
                            // Welcome Section with API-fetched name
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenSize.width * 0.05,
                              ),
                              child: Row(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'Hi ${_getFirstName(vendorName)}',
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF2D3142),
                                            ),
                                          ),
                                          if (isLoadingVendorName) ...[
                                            const SizedBox(width: 8),
                                            const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                  Color(0xFF2D3142),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const Text(
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
                                width: isTablet ? screenSize.width * 0.4: 155,
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
                                    'View Sales',
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
                  )
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
                                  onClose: _toggleReport, location: Location.location, vendorId: Vendor.vendorid!
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

  // Helper method to extract first name from full name
  String _getFirstName(String fullName) {
    if (fullName.isEmpty || fullName == 'Loading...') {
      return fullName;
    }
    return fullName.split(' ').first;
  }

  Widget _buildFilterButton(String text, double width) {
    bool isSelected = selectedFilter == text;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = text;
        });
        // Refresh data when filter is selected
        if (text == 'Daily') {
          _fetchDailySalesData();
          _fetchDailySalesStats(); // Add this line
        } else if (text == 'Monthly') {
          _fetchMonthlySalesData();
          _fetchMonthlySalesStats();
        } else if (text == 'Yearly') {
          _fetchYearlySalesData();
          _fetchYearlyStats();
        }
      },
      child: Container(
        width: width,
        height: 42.5,
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
                child: SvgPicture.asset(
                  'assets/trending.svg',
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$selectedFilter Sales',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF8500),
              ),
            ),
            // Display month for Monthly filter or year for Yearly filter
            if (selectedFilter == 'Monthly' && currentMonth.isNotEmpty)
              Text(
                currentMonth,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF2D3142),
                ),
              ),
            if (selectedFilter == 'Yearly' && currentYear > 0)
              Text(
                currentYear.toString(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF2D3142),
                ),
              ),
          ],
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
        vertical: screenSize.height * 0.01,
        horizontal: screenSize.width * 0.03,
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
          _buildNavItem('assets/home.svg', 'Home', true, screenSize),
          _buildNavItem('assets/report.svg', 'Reports', false, screenSize),
        ],
      ),
    );
  }

  Widget _buildNavItem(String iconPath, String label, bool isSelected, Size screenSize) {
    double iconSize = screenSize.width > 600 ? 40 : 40;
    
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
          SvgPicture.asset(
            iconPath,
            width: iconSize,
            height: iconSize,
          ),
          SizedBox(height: screenSize.height * 0.002),
          Text(
            label,
            style: TextStyle(
              fontSize: screenSize.width > 600 ? 14 : 12,
              fontWeight: FontWeight.normal,
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
    'labels': dailySalesLabels.isNotEmpty ? dailySalesLabels : ['Sun\n(Jun 15)', 'Mon\n(Jun 16)', 'Tue\n(Jun 17)', 'Wed\n(Jun 18)', 'Thu\n(Jun 19)', 'Fri\n(Jun 20)', 'Sat\n(Jun 21)'],
    'maxY': 1000.0, // Fixed to 100
    'interval': 100.0, // Y-axis intervals of 20 (0, 20, 40, 60, 80, 100)
    'spots': dailySalesSpots.isNotEmpty ? dailySalesSpots : <FlSpot>[],
  },
'Monthly': {
  'labels': monthlySalesLabels,
  'maxY': 5000.0,
  'interval': 1000.0, // Dynamic interval based on max value
  'spots': monthlySalesSpots.isNotEmpty ? monthlySalesSpots : const [
    FlSpot(0, 2000),
    FlSpot(1, 4000),
    FlSpot(2, 7000),
    FlSpot(3, 5000),
  ],
},
'Yearly': {
  'labels': yearlySalesLabels,
  'maxY': maxYearlySales,
  'interval': maxYearlySales / 5, // Dynamic interval based on max value
  'spots': yearlySalesSpots.isNotEmpty ? yearlySalesSpots : const [
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
    child: isLoadingDailySales && selectedFilter == 'Daily'
        ? const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BFA6)),
            ),
          )
        // 👈 Add condition for empty data
        : (selectedFilter == 'Daily' && currentConfig['spots'].isEmpty) || 
          (selectedFilter == 'Monthly' && monthlySalesSpots.isEmpty) ||
          (selectedFilter == 'Yearly' && yearlySalesSpots.isEmpty)
            ? const Center(
                child: Text(
                  'No sales data available',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              )
            : LineChart(
                LineChartData(
                  // ... rest of your LineChart configuration remains the same
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
                        reservedSize: screenSize.width * 0.124,
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
                        reservedSize: screenSize.height * 0.047, // Increased for three-line labels
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= currentConfig['labels'].length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: EdgeInsets.only(top: screenSize.height * 0.005),
                            child: Text(
                              currentConfig['labels'][value.toInt()],
                              style: TextStyle(
                                fontSize: screenSize.width > 600 ? 11 : 9, // Slightly smaller font for 3 lines
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
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
                      isCurved: false,
                      color: const Color(0xFF00BFA6),
                      barWidth: screenSize.width * 0.005,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: screenSize.width * 0.007,
                            color: Colors.white,
                            strokeWidth: 1.5,
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
                          String label = currentConfig['labels'][touchedSpot.x.toInt()];
                          label = label.replaceAll('\n', ' ');
                          return LineTooltipItem(
                            '$label\n\$${touchedSpot.y.toStringAsFixed(2)}',
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