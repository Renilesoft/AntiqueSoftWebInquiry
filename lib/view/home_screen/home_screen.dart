import 'package:antiquewebemquiry/Constants/baseurl.dart';
import 'package:antiquewebemquiry/Global/location.dart';
import 'package:antiquewebemquiry/Global/username.dart';
import 'package:antiquewebemquiry/Global/vendorid.dart';
import 'package:antiquewebemquiry/Services/notification.dart';
import 'package:antiquewebemquiry/view/hamburger.dart';
import 'package:antiquewebemquiry/view/message.dart';
import 'package:antiquewebemquiry/view/notification.dart';
import 'package:antiquewebemquiry/view/notificationspage.dart';
import 'package:antiquewebemquiry/view/popupmessage.dart';
import 'package:antiquewebemquiry/view/salesreport.dart';
import 'package:antiquewebemquiry/viewmodel/home_viewmodel.dart';
import 'package:antiquewebemquiry/view/yearlysales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/Provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../report_screen/report_screen.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  final bool showWelcomeMessage;
  const HomeScreen({super.key, this.showWelcomeMessage = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  bool _showWelcomeNotification = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String selectedFilter = 'Daily';
  bool _showReport = false;
  late AnimationController _animationController;
  late Animation<double> _animation;
  List<FlSpot> dailySalesSpots = [];
  List<String> dailySalesLabels = [];
  List<String> dailySalesFullLabels = [];
  bool isLoadingDailySales = false;
  double maxDailySales = 5000.0;

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

  Timer? _notificationTimer;
  int _notificationCount = 0;
  bool _isLoadingNotifications = false;
  bool _isNotificationRequestPending = false;
  Set<String> _notifiedSalesIds = {};

  static const int FAST_POLLING_INTERVAL_SECONDS = 1;
  static const int REQUEST_TIMEOUT_SECONDS = 8;

  String vendorName = 'Loading...';
  bool isLoadingVendorName = true;

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

    _showWelcomeNotification = widget.showWelcomeMessage;

    _fetchVendorName();
    _fetchDailySalesData();
    _fetchMonthlySalesData();
    _fetchYearlySalesData();
    _refreshPage();
    _fetchMarketMessage();
    _fetchDailySalesStats();
    _fetchMonthlySalesStats();
    _fetchYearlyStats();
    
    _fetchNotifications();
    _startNotificationTimer();
  }

  void _startNotificationTimer() {
    _notificationTimer = Timer.periodic(
      const Duration(seconds: FAST_POLLING_INTERVAL_SECONDS),
      (timer) {
        _fetchNotifications();
      },
    );
    debugPrint('🚀 [NOTIFICATION] Polling started - every $FAST_POLLING_INTERVAL_SECONDS seconds');
  }

  void _stopNotificationTimer() {
    _notificationTimer?.cancel();
    _notificationTimer = null;
    debugPrint('🛑 [NOTIFICATION] Polling stopped');
  }

  Future<void> _fetchNotifications() async {
    if (_isNotificationRequestPending || _isLoadingNotifications) {
      return;
    }

    _isNotificationRequestPending = true;

    try {
      final String url =
          '$baseurl/Home/newSalesAndNotify?location=${Location.location}&vendorId=${Vendor.vendorid}';

      debugPrint('📡 [FETCH] Polling API for new sales...');

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(
            const Duration(seconds: REQUEST_TIMEOUT_SECONDS),
            onTimeout: () {
              throw TimeoutException('API request timed out');
            },
          );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> salesList = data['sales'] ?? [];

        debugPrint('📊 [FETCH] Got ${salesList.length} sales from API');

        if (salesList.isNotEmpty) {
          final List<Map<String, dynamic>> salesToNotify = [];

          for (var sale in salesList) {
            final int notificationStatus = sale['notificationStatus'] ?? 0;
            final String dateTime = sale['dateTime'] ?? '';
            final String itemDescription = sale['itemDescription'] ?? '';
            final String saleKey = '${dateTime}_$itemDescription';

            if (notificationStatus == 1 && !_notifiedSalesIds.contains(saleKey)) {
              salesToNotify.add(sale);
              _notifiedSalesIds.add(saleKey);
              debugPrint('✅ [NEW] Sale ready to notify: $itemDescription at $dateTime');
            } else if (_notifiedSalesIds.contains(saleKey)) {
              debugPrint('⏭️ [SKIP] Sale already notified: $itemDescription');
            } else {
              debugPrint('⏭️ [SKIP] Sale not ready (status: $notificationStatus): $itemDescription');
            }
          }

          if (salesToNotify.isNotEmpty) {
            debugPrint('🎯 [ACTION] Sending notifications for ${salesToNotify.length} sale(s)');
            _showAllNotificationsInstantly(salesToNotify);
          }
        }

        if (mounted) {
          setState(() {
            _notificationCount = data['salesCount'] ?? 0;
          });
        }
      } else {
        debugPrint('❌ [ERROR] API returned: ${response.statusCode}');
      }
    } on TimeoutException {
      debugPrint('⏱️ [TIMEOUT] API request timeout after $REQUEST_TIMEOUT_SECONDS seconds');
    } catch (e) {
      debugPrint('❌ [ERROR] Fetch exception: $e');
    } finally {
      _isNotificationRequestPending = false;
      _isLoadingNotifications = false;
    }
  }

  void _showAllNotificationsInstantly(List<Map<String, dynamic>> sales) {
    debugPrint('📬 [DISPATCH] Sending ${sales.length} notification(s) with staggered delays...');

    for (var i = 0; i < sales.length; i++) {
      final sale = sales[i];
      final String itemDescription = sale['itemDescription'] ?? 'New Sale';
      final int quantity = sale['quantity'] ?? 0;
      final int delayMs = i * 500;

      _sendNotificationAsync(itemDescription, quantity, sale, i, sales.length, delayMs);
    }
  }

  void _sendNotificationAsync(String itemDescription, int quantity, Map<String, dynamic> sale, int index, int total, int delayMs) {
    Future.delayed(Duration(milliseconds: delayMs), () async {
      try {
        final String notificationId = '${DateTime.now().millisecondsSinceEpoch}_${index}_${sale['dateTime'] ?? ''}';
        final String saleDateTime = sale['dateTime'] ?? '';
        
        await NotificationService().showLocalNotification(
          title: '🎉 New Sale! (#${index + 1}/$total)',
          body: '$itemDescription\nQuantity: $quantity\n$saleDateTime',
          payload: jsonEncode({
            ...sale,
            'notificationId': notificationId,
          }),
        );
        debugPrint('✅ [SENT] Sale #${index + 1}/$total: $itemDescription (Qty: $quantity) [ID: $notificationId] [Delay: ${delayMs}ms]');
      } catch (e) {
        debugPrint('❌ [ERROR] Failed to send notification: $e');
      }
    });
  }

  Future<void> _refreshPage() async {
    final futures = [
      _fetchVendorName(),
      _fetchMarketMessage(),
      _fetchDailySalesStats(),
      _fetchDailySalesData(),
      _fetchMonthlySalesData(),
      _fetchYearlySalesData(),
      _fetchMonthlySalesStats(),
      _fetchYearlyStats(),
    ];

    await Future.wait(futures);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _fetchYearlyStats() async {
    setState(() {
      isLoadingYearlyStats = true;
    });

    try {
      final DateTime now = DateTime.now();
      final int currentYearParam = now.year;

      final String url =
          '$baseurl/Home/YearlySales?location=${Location.location}&vendorId=${Vendor.vendorid}&year=$currentYearParam';

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: REQUEST_TIMEOUT_SECONDS));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (mounted) {
          setState(() {
            double totalSalesAmount = (data['totalSalesAmount'] ?? 0.0).toDouble();
            String formattedSales = NumberFormat.currency(
              symbol: '\$',
              decimalDigits: 2,
            ).format(totalSalesAmount);

            yearlyStats = {
              'totalItems': NumberFormat('#,###').format(data['totalQuantitySold'] ?? 0),
              'totalSales': formattedSales,
            };
            isLoadingYearlyStats = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            yearlyStats = {
              'totalItems': '0',
              'totalSales': '\$0.00',
            };
            isLoadingYearlyStats = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ [ERROR] YearlyStats: $e');
      if (mounted) {
        setState(() {
          yearlyStats = {
            'totalItems': '0',
            'totalSales': '\$0.00',
          };
          isLoadingYearlyStats = false;
        });
      }
    }
  }

  Future<void> _fetchDailySalesStats() async {
    setState(() {
      isLoadingDailyStats = true;
    });

    try {
      final DateTime now = DateTime.now();
      final String currentDate =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final String url =
          '$baseurl/Home/DailySales?location=${Location.location}&vendorId=${Vendor.vendorid}&startDate=${currentDate}T00:00:00&endDate=${currentDate}T23:59:59';

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: REQUEST_TIMEOUT_SECONDS));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (mounted) {
          setState(() {
            double totalSalesAmount = (data['totalSales'] ?? 0.0).toDouble();
            String formattedSales = NumberFormat.currency(
              symbol: '\$',
              decimalDigits: 2,
            ).format(totalSalesAmount);

            dailyStats = {
              'totalItems': NumberFormat('#,###').format(data['totalItems'] ?? 0),
              'totalSales': formattedSales,
            };
            isLoadingDailyStats = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            dailyStats = {
              'totalItems': '0',
              'totalSales': '\$0.00',
            };
            isLoadingDailyStats = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ [ERROR] DailySalesStats: $e');
      if (mounted) {
        setState(() {
          dailyStats = {
            'totalItems': '0',
            'totalSales': '\$0.00',
          };
          isLoadingDailyStats = false;
        });
      }
    }
  }

  Future<void> _fetchMarketMessage() async {
    try {
      final String url = '$baseurl/Home/getMarketMessage?location=${Location.location}';

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: REQUEST_TIMEOUT_SECONDS));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            marketMessage = data['marketMessage'] ?? 'No message available';
            isLoadingMarketMessage = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            marketMessage = 'Failed to load message';
            isLoadingMarketMessage = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ [ERROR] MarketMessage: $e');
      if (mounted) {
        setState(() {
          marketMessage = 'Error loading message';
          isLoadingMarketMessage = false;
        });
      }
    }
  }

  Future<void> _fetchMonthlySalesStats() async {
    setState(() {
      isLoadingMonthlyStats = true;
    });

    try {
      final DateTime now = DateTime.now();
      final String currentMonth =
          '${now.year}-${now.month.toString().padLeft(2, '0')}';

      final String url =
          '$baseurl/Home/MonthlySales?location=${Location.location}&vendorId=${Vendor.vendorid}&startMonth=$currentMonth&endMonth=$currentMonth';

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: REQUEST_TIMEOUT_SECONDS));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (mounted) {
          setState(() {
            double totalSalesAmount = (data['totalSales'] ?? 0.0).toDouble();
            String formattedSales = NumberFormat.currency(
              symbol: '\$',
              decimalDigits: 2,
            ).format(totalSalesAmount);

            monthlyStats = {
              'totalItems': NumberFormat('#,###').format(data['totalItems'] ?? 0),
              'totalSales': formattedSales,
            };
            isLoadingMonthlyStats = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            monthlyStats = {
              'totalItems': '0',
              'totalSales': '\$0.00',
            };
            isLoadingMonthlyStats = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ [ERROR] MonthlySalesStats: $e');
      if (mounted) {
        setState(() {
          monthlyStats = {
            'totalItems': '0',
            'totalSales': '\$0.00',
          };
          isLoadingMonthlyStats = false;
        });
      }
    }
  }

  Future<void> _fetchYearlySalesData() async {
    setState(() {
      isLoadingYearlySales = true;
    });

    try {
      final DateTime now = DateTime.now();
      final int currentYearParam = now.year;

      final String url =
          '$baseurl/Home/YearlySales?location=${Location.location}&vendorId=${Vendor.vendorid}&year=$currentYearParam';

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: REQUEST_TIMEOUT_SECONDS));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> monthlySales = data['monthlySales'] ?? [];

        yearlySalesSpots.clear();
        currentYear = data['year'] ?? currentYearParam;

        Map<String, double> salesByMonth = {};

        for (var monthData in monthlySales) {
          String month = monthData['month'] ?? '';
          double totalSales = (monthData['totalSales'] ?? 0).toDouble();
          salesByMonth[month] = totalSales;
        }

        List<String> monthNames = [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December'
        ];

        for (int i = 0; i < monthNames.length; i++) {
          String monthName = monthNames[i];
          double salesAmount = salesByMonth[monthName] ?? 0.0;
          yearlySalesSpots.add(FlSpot(i.toDouble(), salesAmount));
        }

        double maxValue = yearlySalesSpots.isNotEmpty
            ? yearlySalesSpots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b)
            : 0;
        maxYearlySales = maxValue > 0 ? (maxValue * 1.2).ceilToDouble() : 100000.0;

        if (mounted) {
          setState(() {
            isLoadingYearlySales = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isLoadingYearlySales = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ [ERROR] YearlySalesData: $e');
      if (mounted) {
        setState(() {
          isLoadingYearlySales = false;
        });
      }
    }
  }

  Future<void> _fetchDailySalesData() async {
    setState(() {
      isLoadingDailySales = true;
    });

    try {
      final DateTime now = DateTime.now();
      final String currentDate =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final String url =
          '$baseurl/Home/graphSalesDaily?location=${Location.location}&vendorId=${Vendor.vendorid}&date=$currentDate';

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: REQUEST_TIMEOUT_SECONDS));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> dailySales = data['dailySales'];

        dailySalesSpots.clear();
        dailySalesLabels.clear();
        dailySalesFullLabels.clear();

        dailySales.sort((a, b) {
          final dateA = DateTime.parse(a['date']);
          final dateB = DateTime.parse(b['date']);
          return dateA.compareTo(dateB);
        });

        for (int i = 0; i < dailySales.length; i++) {
          final salesData = dailySales[i];
          final double totalSales = (salesData['totalSales'] ?? 0).toDouble();
          final String date = salesData['date'] ?? '';
          final String day = salesData['day'] ?? '';

          final String dayAbbr = _getDayAbbreviation(day);
          final String simpleLabel = dayAbbr;

          final DateTime parsedDate = DateTime.parse(date);
          final String monthName = _getMonthName(parsedDate.month);
          final String fullLabel =
              '$dayAbbr\n($monthName ${parsedDate.day})\n${parsedDate.year}';

          dailySalesSpots.add(FlSpot(i.toDouble(), totalSales));
          dailySalesLabels.add(simpleLabel);
          dailySalesFullLabels.add(fullLabel);
        }

        maxDailySales = 100.0;

        if (mounted) {
          setState(() {
            isLoadingDailySales = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isLoadingDailySales = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ [ERROR] DailySalesData: $e');
      if (mounted) {
        setState(() {
          isLoadingDailySales = false;
        });
      }
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
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
      final DateTime now = DateTime.now();
      final String currentMonthParam =
          '${now.year}-${now.month.toString().padLeft(2, '0')}';

      final String url =
          '$baseurl/Home/graphSalesMonthly?location=${Location.location}&vendorId=${Vendor.vendorid}&month=$currentMonthParam';

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: REQUEST_TIMEOUT_SECONDS));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final Map<String, dynamic> weeklySales = data['weeklySales'];

        monthlySalesSpots.clear();
        currentMonth = data['month'] ?? '';

        int index = 0;
        weeklySales.forEach((week, sales) {
          final double salesAmount = (sales ?? 0).toDouble();
          monthlySalesSpots.add(FlSpot(index.toDouble(), salesAmount));
          index++;
        });

        double maxValue = monthlySalesSpots.isNotEmpty
            ? monthlySalesSpots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b)
            : 0;
        maxMonthlySales = maxValue > 0 ? (maxValue * 1.2).ceilToDouble() : 10000.0;

        if (mounted) {
          setState(() {
            isLoadingMonthlySales = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isLoadingMonthlySales = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ [ERROR] MonthlySalesData: $e');
      if (mounted) {
        setState(() {
          isLoadingMonthlySales = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _stopNotificationTimer();
    super.dispose();
  }

  Future<void> _fetchVendorName() async {
    try {
      final String url =
          '$baseurl/Home/getClientName?location=${Location.location}&email=${Uri.encodeComponent(Username.username)}';

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: REQUEST_TIMEOUT_SECONDS));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            vendorName = data['vendorName'] ?? 'User';
            isLoadingVendorName = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            vendorName = 'User';
            isLoadingVendorName = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ [ERROR] VendorName: $e');
      if (mounted) {
        setState(() {
          vendorName = 'User';
          isLoadingVendorName = false;
        });
      }
    }
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

  void _closeWelcomeNotification() {
    setState(() {
      _showWelcomeNotification = false;
    });
  }

  void _openWelcomeNotification() {
    _closeWelcomeNotification();
  }

  void _navigateToMessagePage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MessagePage(initialTabIndex: 0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  if (_showWelcomeNotification)
                    WelcomeNotification(
                      message: isLoadingMarketMessage
                          ? 'Loading message...'
                          : marketMessage,
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
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenSize.width * 0.05,
                                ),
                                child: Row(
                                  children: [
                                    Flexible(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  'Hi ${_getFirstName(vendorName)}',
                                                  style: const TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF2D3142),
                                                  ),
                                                  textScaleFactor: 1.0,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (isLoadingVendorName) ...[
                                                const SizedBox(width: 8),
                                                const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                            Color>(
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
                                            textScaleFactor: 1.0,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Flexible(
                                      flex: 1,
                                      child: SvgPicture.asset(
                                        'assets/welcome.svg',
                                        height: screenSize.height * 0.12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: screenSize.height * 0.03),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenSize.width * 0.05,
                                ),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    double buttonWidth =
                                        (constraints.maxWidth - (2 * 12)) / 3;
                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        _buildFilterButton(
                                            'Daily', buttonWidth),
                                        const SizedBox(width: 12),
                                        _buildFilterButton(
                                            'Monthly', buttonWidth),
                                        const SizedBox(width: 12),
                                        _buildFilterButton(
                                            'Yearly', buttonWidth),
                                      ],
                                    );
                                  },
                                ),
                              ),
                              SizedBox(height: screenSize.height * 0.03),
                              Center(
                                child: SizedBox(
                                  width: isTablet
                                      ? screenSize.width * 0.4
                                      : 155,
                                  height: screenSize.height * 0.06,
                                  child: ElevatedButton(
                                    onPressed: _toggleReport,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          const Color(0xFFFF6B00),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(30),
                                      ),
                                    ),
                                    child: const FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'View Sales',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.normal,
                                          color: Colors.white,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: screenSize.height * 0.03),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenSize.width * 0.05,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatCard(
                                        'Total Items Sold',
                                        statistics[selectedFilter]![
                                            'totalItems']!,
                                        screenSize,
                                      ),
                                    ),
                                    SizedBox(width: screenSize.width * 0.04),
                                    Expanded(
                                      child: _buildStatCard(
                                        'Total Sales Amount',
                                        statistics[selectedFilter]![
                                            'totalSales']!,
                                        screenSize,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: screenSize.height * 0.03),
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
                  ),
                  _buildBottomNavBar(screenSize),
                ],
              ),
              if (_showReport)
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Positioned(
                      top: _animation.value *
                          MediaQuery.of(context).padding.top,
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
                                child: selectedFilter == 'Yearly'
                                    ? const YearlySalesReportPage()
                                    : SalesReport(
                                        filterType: selectedFilter,
                                        onClose: _toggleReport,
                                        location: Location.location,
                                        vendorId: Vendor.vendorid!,
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
        if (text == 'Daily') {
          _fetchDailySalesData();
          _fetchDailySalesStats();
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
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF8500) : Colors.grey,
          borderRadius: BorderRadius.circular(1),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.normal,
              fontSize: 13,
            ),
            textScaleFactor: 1.0,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Size screenSize) {
    return Container(
      height: screenSize.height * 0.16,
      padding: EdgeInsets.all(screenSize.width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF11AB86),
              ),
              textScaleFactor: 1.0,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                flex: 3,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: screenSize.width > 600 ? 24 : 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D3142),
                    ),
                    textScaleFactor: 1.0,
                  ),
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
              Flexible(
                child: Text(
                  '$selectedFilter Sales',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF8500),
                  ),
                  textScaleFactor: 1.0,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (selectedFilter == 'Monthly' && currentMonth.isNotEmpty)
                Text(
                  currentMonth,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: Color(0xFF2D3142),
                  ),
                  textScaleFactor: 1.0,
                ),
              if (selectedFilter == 'Yearly' && currentYear > 0)
                Text(
                  currentYear.toString(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: Color(0xFF2D3142),
                  ),
                  textScaleFactor: 1.0,
                ),
            ],
          ),
          SizedBox(height: screenSize.height * 0.02),
          SizedBox(
            height: screenSize.height * 0.5,
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

  Widget _buildNavItem(
      String iconPath, String label, bool isSelected, Size screenSize) {
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
            textScaleFactor: 1.0,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildChart(Size screenSize) {
    final Map<String, Map<String, dynamic>> chartConfigs = {
      'Daily': {
        'labels': dailySalesLabels.isNotEmpty
            ? dailySalesLabels
            : [
                'Sun\n(Jun 15)',
                'Mon\n(Jun 16)',
                'Tue\n(Jun 17)',
                'Wed\n(Jun 18)',
                'Thu\n(Jun 19)',
                'Fri\n(Jun 20)',
                'Sat\n(Jun 21)'
              ],
        'maxY': 500.0,
        'interval': 100.0,
        'spots': dailySalesSpots.isNotEmpty ? dailySalesSpots : <FlSpot>[],
      },
      'Monthly': {
        'labels': monthlySalesLabels,
        'maxY': 5000.0,
        'interval': 1000.0,
        'spots': monthlySalesSpots.isNotEmpty
            ? monthlySalesSpots
            : const [
                FlSpot(0, 2000),
                FlSpot(1, 4000),
                FlSpot(2, 7000),
                FlSpot(3, 5000),
              ],
      },
      'Yearly': {
        'labels': yearlySalesLabels,
        'maxY': 20000.0,
        'interval': 5000.0,
        'spots': yearlySalesSpots.isNotEmpty
            ? yearlySalesSpots
            : const [
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

    double chartWidth = selectedFilter == 'Yearly'
        ? screenSize.width * (screenSize.width > 600 ? 2.5 : 3.5)
        : screenSize.width - (screenSize.width * 0.08);

    Widget chartWidget = SizedBox(
      width: chartWidth,
      height: screenSize.height * 0.40,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            0,
            screenSize.height * 0.013,
            screenSize.width * 0.03,
            screenSize.height * 0.010),
        child: isLoadingDailySales && selectedFilter == 'Daily'
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Color(0xFF00BFA6)),
                ),
              )
            : (selectedFilter == 'Daily' && currentConfig['spots'].isEmpty) ||
                    (selectedFilter == 'Monthly' &&
                        monthlySalesSpots.isEmpty) ||
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
                                padding: EdgeInsets.only(
                                    right: screenSize.width * 0.01),
                                child: Text(
                                  value.toInt().toString(),
                                  style: TextStyle(
                                    fontSize: screenSize.width > 600 ? 14 : 12,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w900,
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
                            reservedSize: screenSize.height * 0.060,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >=
                                  currentConfig['labels'].length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: EdgeInsets.only(
                                    top: screenSize.height * 0.010),
                                child: Text(
                                  currentConfig['labels'][value.toInt()],
                                  style: TextStyle(
                                    fontSize: screenSize.width > 600 ? 14 : 12,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w900,
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
                        border: Border.all(
                            color: const Color(0xFFE5E5E5)),
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
                            color: const Color(0xFF00BFA6)
                                .withOpacity(0.1),
                          ),
                        ),
                      ],
                      minX: 0,
                      maxX:
                          (currentConfig['labels'].length - 1).toDouble(),
                      minY: 0,
                      maxY: currentConfig['maxY'],
                      lineTouchData: LineTouchData(
                        touchTooltipData:
                            LineTouchTooltipData(
                          tooltipBgColor:
                              Colors.black.withOpacity(0.8),
                          tooltipRoundedRadius: 8,
                          getTooltipItems:
                              (List<LineBarSpot> touchedSpots) {
                            return touchedSpots
                                .map((LineBarSpot touchedSpot) {
                              String label;
                              if (selectedFilter == 'Daily' &&
                                  dailySalesFullLabels.isNotEmpty) {
                                int index = touchedSpot.x.toInt();
                                if (index <
                                    dailySalesFullLabels.length) {
                                  label = dailySalesFullLabels[index];
                                } else {
                                  label =
                                      'Day ${index + 1}';
                                }
                              } else {
                                label = currentConfig['labels']
                                    [touchedSpot.x.toInt()];
                                label =
                                    label.replaceAll('\n', ' ');
                              }
                              return LineTooltipItem(
                                '$label\n\$${touchedSpot.y.toStringAsFixed(2)}',
                                TextStyle(
                                  color: Colors.white,
                                  fontSize:
                                      screenSize.width > 600
                                          ? 16
                                          : 14,
                                ),
                              );
                            }).toList();
                          },
                        ),
                        touchCallback: (FlTouchEvent event,
                            LineTouchResponse? touchResponse) {
                          if (event is FlTapUpEvent ||
                              event is FlPanUpdateEvent) {
                            setState(() {});
                          }
                        },
                        getTouchedSpotIndicator:
                            (LineChartBarData barData,
                                List<int> spotIndexes) {
                          return spotIndexes.map((spotIndex) {
                            return TouchedSpotIndicatorData(
                              const FlLine(
                                color: Color(0xFF00BFA6),
                                strokeWidth: 3,
                              ),
                              FlDotData(
                                show: true,
                                getDotPainter:
                                    (spot, percent, barData,
                                        index) {
                                  return FlDotCirclePainter(
                                    radius:
                                        screenSize.width *
                                            0.015,
                                    color: Colors.white,
                                    strokeWidth: 3,
                                    strokeColor: const Color(
                                        0xFF00BFA6),
                                  );
                                },
                              ),
                            );
                          }).toList();
                        },
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