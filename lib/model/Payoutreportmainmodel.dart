class MonthlyPayableResponse {
  final double retailSales;
  final double wholesaleSales;
  final double onlineSales;
  final double layawaySales;
  final double returnSales;
  final double voidSales;
  final double salesTax;
  final double total;
  final double totalSales;

  MonthlyPayableResponse({
    required this.retailSales,
    required this.wholesaleSales,
    required this.onlineSales,
    required this.layawaySales,
    required this.returnSales,
    required this.voidSales,
    required this.salesTax,
    required this.total,
    required this.totalSales,
  });

  factory MonthlyPayableResponse.fromJson(Map<String, dynamic> json) {
    return MonthlyPayableResponse(
      retailSales: (json['retailSales'] ?? 0).toDouble(),
      wholesaleSales: (json['wholesaleSales'] ?? 0).toDouble(),
      onlineSales: (json['onlineSales'] ?? 0).toDouble(),
      layawaySales: (json['layawaySales'] ?? 0).toDouble(),
      returnSales: (json['returnSales'] ?? 0).toDouble(),
      voidSales: (json['voidSales'] ?? 0).toDouble(),
      salesTax: (json['salesTax'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      totalSales: (json['totalSales'] ?? 0).toDouble(),
    );
  }
}

// Model for Monthly Receivable API response
class MonthlyReceivableResponse {
  final int vendorId;
  final String startDate;
  final String endDate;
  final Financials financials;

  MonthlyReceivableResponse({
    required this.vendorId,
    required this.startDate,
    required this.endDate,
    required this.financials,
  });

  factory MonthlyReceivableResponse.fromJson(Map<String, dynamic> json) {
    return MonthlyReceivableResponse(
      vendorId: json['vendorId'] ?? 0,
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      financials: Financials.fromJson(json['financials'] ?? {}),
    );
  }
}

class Financials {
  final double flatCommissionPercent;
  final double commissionOnSales;
  final double creditCardCharges;
  final double consignmentCommission;
  final double vendorAdjustments;
  final double rentalDues;

  Financials({
    required this.flatCommissionPercent,
    required this.commissionOnSales,
    required this.creditCardCharges,
    required this.consignmentCommission,
    required this.vendorAdjustments,
    required this.rentalDues,
  });

  factory Financials.fromJson(Map<String, dynamic> json) {
    return Financials(
      flatCommissionPercent: (json['flatCommissionPercent'] ?? 0).toDouble(),
      commissionOnSales: (json['commissionOnSales'] ?? 0).toDouble(),
      creditCardCharges: (json['creditCardCharges'] ?? 0).toDouble(),
      consignmentCommission: (json['consignmentCommission'] ?? 0).toDouble(),
      vendorAdjustments: (json['vendorAdjustments'] ?? 0).toDouble(),
      rentalDues: (json['rentalDues'] ?? 0).toDouble(),
    );
  }
}