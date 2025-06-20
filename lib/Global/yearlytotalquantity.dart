import 'package:shared_preferences/shared_preferences.dart';

class TotalQuantity {
  static int totalQuantity = 0;

  static Future<void> save(int value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('yearly_total_quantity', value);
    totalQuantity = value;
  }

  static Future<void> load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    totalQuantity = prefs.getInt('yearly_total_quantity') ?? 0;
  }
}