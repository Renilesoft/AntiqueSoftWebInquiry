class SalesModel {
  final int totalItemsSold;
  final double totalSalesAmount;

  SalesModel({required this.totalItemsSold, required this.totalSalesAmount});
}

class SalesData {
  final DateTime date;
  final String description;
  final int quantity;
  final double price;
  final double netPrice;

  SalesData({
    required this.date,
    required this.description,
    required this.quantity,
    required this.price,
    required this.netPrice,
  });

  factory SalesData.fromJson(Map<String, dynamic> json) {
    return SalesData(
      date: DateTime.parse(json['date']),
      description: json['description'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      netPrice: (json['netPrice'] ?? 0).toDouble(),
    );
  }
}

class SalesResponse {
  final int? vendorId;
  final DateTime? startDate;
  final DateTime? endDate;
  final int totalItems;
  final double totalSales;
  final List<SalesData> salesData;

  SalesResponse({
    this.vendorId,
    this.startDate,
    this.endDate,
    required this.totalItems,
    required this.totalSales,
    required this.salesData,
  });

  factory SalesResponse.fromJson(Map<String, dynamic> json) {
    return SalesResponse(
      vendorId: json['vendorId'],
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      totalItems: json['totalItems'] ?? 0,
      totalSales: (json['totalSales'] ?? 0).toDouble(),
      salesData: (json['salesData'] as List<dynamic>?)
          ?.map((item) => SalesData.fromJson(item))
          .toList() ?? [],
    );
  }
}