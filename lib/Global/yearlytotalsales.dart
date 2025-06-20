import 'package:shared_preferences/shared_preferences.dart';

class TotalSales {
  static double totalsales = 0.0;

  static Future<void> save(double value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('yearly_total_sales', value);
    totalsales = value;
  }

  static Future<void> load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    totalsales = prefs.getDouble('yearly_total_sales') ?? 0.0;
  }
}

