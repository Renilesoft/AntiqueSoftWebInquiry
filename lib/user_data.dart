import 'dart:convert';

class UserData {
  int vendorID;
  String alphaNumericVendorID;
  String vendorName;
  DateTime joinedDate;

  UserData({
    required this.vendorID,
    required this.alphaNumericVendorID,
    required this.vendorName,
    required this.joinedDate,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      vendorID: json['vendorID'] ?? json['VendorID'] ?? 0,
      alphaNumericVendorID: json['alphaNumericVendorID'] ?? json['AlphaNumericVendorID'] ?? '',
      vendorName: json['vendorName'] ?? json['VendorName'] ?? '',
      joinedDate: DateTime.parse(json['joinedDate'] ?? json['JoinedDate'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Fixed fromJsonString method
  factory UserData.fromJsonString(String jsonString) {
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      return UserData.fromJson(json);
    } catch (e) {
      print('Error parsing UserData from JSON string: $e');
      // Return a default UserData object if parsing fails
      return UserData(
        vendorID: 0,
        alphaNumericVendorID: '',
        vendorName: '',
        joinedDate: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'vendorID': vendorID,
      'alphaNumericVendorID': alphaNumericVendorID,
      'vendorName': vendorName,
      'joinedDate': joinedDate.toIso8601String(),
    };
  }

  // Helper method to convert UserData to JSON string
  String toJsonString() {
    return jsonEncode(toJson());
  }
}