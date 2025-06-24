import 'package:shared_preferences/shared_preferences.dart';

// Monthly Total Items
class MonthlyTotalItems {
  static int totalItems = 0;

  static Future<void> save(int value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('monthly_total_items', value);
    totalItems = value;
  }

  static Future<void> load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    totalItems = prefs.getInt('monthly_total_items') ?? 0;
  }

  static int get() {
    return totalItems;
  }

  static Future<void> clear() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('monthly_total_items');
    totalItems = 0;
  }
}

// Daily Total Items
class DailyTotalItems {
  static int totalItems = 0;

  static Future<void> save(int value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('daily_total_items', value);
    totalItems = value;
  }

  static Future<void> load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    totalItems = prefs.getInt('daily_total_items') ?? 0;
  }

  static int get() {
    return totalItems;
  }

  static Future<void> clear() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('daily_total_items');
    totalItems = 0;
  }
}

// Monthly Total Sales
class MonthlyTotalSales {
  static double totalSales = 0.0;

  static Future<void> save(double value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('monthly_total_sales', value);
    totalSales = value;
  }

  static Future<void> load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    totalSales = prefs.getDouble('monthly_total_sales') ?? 0.0;
  }

  static double get() {
    return totalSales;
  }

  static Future<void> clear() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('monthly_total_sales');
    totalSales = 0.0;
  }
}

// Daily Total Sales
class DailyTotalSales {
  static double totalSales = 0.0;

  static Future<void> save(double value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('daily_total_sales', value);
    totalSales = value;
  }

  static Future<void> load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    totalSales = prefs.getDouble('daily_total_sales') ?? 0.0;
  }

  static double get() {
    return totalSales;
  }

  static Future<void> clear() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('daily_total_sales');
    totalSales = 0.0;
  }
}