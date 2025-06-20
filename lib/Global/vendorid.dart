import 'package:shared_preferences/shared_preferences.dart';

class Vendor {
  static int? vendorid;

  /// Load the vendor ID from SharedPreferences into the static variable
  static Future<void> loadVendorId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    vendorid = prefs.getInt('vendorid');
  }

  /// Save the vendor ID into SharedPreferences and static variable
  static Future<void> saveVendorId(int id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('vendorid', id);
    vendorid = id;
  }

  /// Get the vendor ID, loading from SharedPreferences if needed
  static Future<int?> getVendorId() async {
    if (vendorid == null) {
      await loadVendorId();
    }
    return vendorid;
  }

  /// Clear the vendor ID from both memory and SharedPreferences
  static Future<void> clearVendorId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('vendorid');
    vendorid = null;
  }

  /// Use this method if you want to safely re-save the vendor ID
  static Future<void> resaveVendorId() async {
    if (vendorid != null) {
      await saveVendorId(vendorid!); // Safe because we check for null
    }
  }
}
