// models/home_model.dart

import 'package:antiquewebemquiry/Global/yearlytotalquantity.dart';
import 'package:antiquewebemquiry/Global/yearlytotalsales.dart';
import 'package:fl_chart/fl_chart.dart';

class SalesData {
  final String date;
  final String day;
  final double totalSales;

  SalesData({
    required this.date,
    required this.day,
    required this.totalSales,
  });

  factory SalesData.fromJson(Map<String, dynamic> json) {
    return SalesData(
      date: json['date'] ?? '',
      day: json['day'] ?? '',
      totalSales: (json['totalSales'] ?? 0).toDouble(),
    );
  }
}

class WeeklySalesData {
  final Map<String, double> weeklySales;
  final String month;

  WeeklySalesData({
    required this.weeklySales,
    required this.month,
  });

  factory WeeklySalesData.fromJson(Map<String, dynamic> json) {
    final weeklySalesMap = <String, double>{};
    final weeklySales = json['weeklySales'] as Map<String, dynamic>? ?? {};
    
    weeklySales.forEach((key, value) {
      weeklySalesMap[key] = (value ?? 0).toDouble();
    });

    return WeeklySalesData(
      weeklySales: weeklySalesMap,
      month: json['month'] ?? '',
    );
  }
}

class MonthlySalesData {
  final String month;
  final double totalSales;

  MonthlySalesData({
    required this.month,
    required this.totalSales,
  });

  factory MonthlySalesData.fromJson(Map<String, dynamic> json) {
    return MonthlySalesData(
      month: json['month'] ?? '',
      totalSales: (json['totalSales'] ?? 0).toDouble(),
    );
  }
}

class YearlySalesData {
  final List<MonthlySalesData> monthlySales;
  final int year;

  YearlySalesData({
    required this.monthlySales,
    required this.year,
  });

  factory YearlySalesData.fromJson(Map<String, dynamic> json) {
    final List<dynamic> monthlySalesList = json['monthlySales'] ?? [];
    final monthlySales = monthlySalesList
        .map((item) => MonthlySalesData.fromJson(item))
        .toList();

    return YearlySalesData(
      monthlySales: monthlySales,
      year: json['year'] ?? DateTime.now().year,
    );
  }
}

class VendorInfo {
  final String vendorName;

  VendorInfo({required this.vendorName});

  factory VendorInfo.fromJson(Map<String, dynamic> json) {
    return VendorInfo(
      vendorName: json['vendorName'] ?? 'User',
    );
  }
}

class ChartData {
  final List<FlSpot> spots;
  final List<String> labels;
  final double maxY;
  final double interval;
  final bool isLoading;
  final String? error;

  ChartData({
    required this.spots,
    required this.labels,
    required this.maxY,
    required this.interval,
    this.isLoading = false,
    this.error,
  });

  factory ChartData.loading() {
    return ChartData(
      spots: [],
      labels: [],
      maxY: 100.0,
      interval: 20.0,
      isLoading: true,
    );
  }

  factory ChartData.error(String errorMessage) {
    return ChartData(
      spots: [],
      labels: [],
      maxY: 100.0,
      interval: 20.0,
      error: errorMessage,
    );
  }

  get hasError => null;

  ChartData copyWith({
    List<FlSpot>? spots,
    List<String>? labels,
    double? maxY,
    double? interval,
    bool? isLoading,
    String? error,
  }) {
    return ChartData(
      spots: spots ?? this.spots,
      labels: labels ?? this.labels,
      maxY: maxY ?? this.maxY,
      interval: interval ?? this.interval,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class Statistics {
  final String totalItems;
  final String totalSales;

  Statistics({
    required this.totalItems,
    required this.totalSales,
  });
}

enum FilterType { daily, monthly, yearly }

class HomeState {
  final FilterType selectedFilter;
  final bool showReport;
  final bool showWelcomeNotification;
  final VendorInfo? vendorInfo;
  final bool isLoadingVendorInfo;
  final ChartData dailyChartData;
  final ChartData monthlyChartData;
  final ChartData yearlyChartData;
  final String? error;

  HomeState({
    this.selectedFilter = FilterType.daily,
    this.showReport = false,
    this.showWelcomeNotification = true,
    this.vendorInfo,
    this.isLoadingVendorInfo = true,
    required this.dailyChartData,
    required this.monthlyChartData,
    required this.yearlyChartData,
    this.error,
  });

  HomeState copyWith({
    FilterType? selectedFilter,
    bool? showReport,
    bool? showWelcomeNotification,
    VendorInfo? vendorInfo,
    bool? isLoadingVendorInfo,
    ChartData? dailyChartData,
    ChartData? monthlyChartData,
    ChartData? yearlyChartData,
    String? error,
  }) {
    return HomeState(
      selectedFilter: selectedFilter ?? this.selectedFilter,
      showReport: showReport ?? this.showReport,
      showWelcomeNotification: showWelcomeNotification ?? this.showWelcomeNotification,
      vendorInfo: vendorInfo ?? this.vendorInfo,
      isLoadingVendorInfo: isLoadingVendorInfo ?? this.isLoadingVendorInfo,
      dailyChartData: dailyChartData ?? this.dailyChartData,
      monthlyChartData: monthlyChartData ?? this.monthlyChartData,
      yearlyChartData: yearlyChartData ?? this.yearlyChartData,
      error: error ?? this.error,
    );
  }

  ChartData get currentChartData {
    switch (selectedFilter) {
      case FilterType.daily:
        return dailyChartData;
      case FilterType.monthly:
        return monthlyChartData;
      case FilterType.yearly:
        return yearlyChartData;
    }
  }

  Statistics get currentStatistics {
    final Map<FilterType, Statistics> stats = {
      FilterType.daily: Statistics(
        totalItems: '135',
        totalSales: '\$345.97',
      ),
      FilterType.monthly: Statistics(
        totalItems: '325',
        totalSales: '\$11,985',
      ),
      FilterType.yearly: Statistics(
        totalItems: '${TotalQuantity.totalQuantity}',
        totalSales: '\$${TotalSales.totalsales.toStringAsFixed(2)}',
      ),
    };
    return stats[selectedFilter]!;
  }
}