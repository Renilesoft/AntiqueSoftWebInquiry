class SalesReportModel {
  final double salesReturns;
  final double voids;
  final double total;
  final double flatCommissionPercentage;
  final double commissionOnSales;
  final double consignmentCommission;
  final double cardCharges;
  final double adjustments;
  final double commissionTotal;
  final double rentalDues;
  final double dueAmount;

  SalesReportModel({
    this.salesReturns = 0.0,
    this.voids = 0.0,
    this.total = 272.50,
    this.flatCommissionPercentage = 7.0,
    this.commissionOnSales = 19.22,
    this.consignmentCommission = 0.0,
    this.cardCharges = 0.0,
    this.adjustments = 0.0,
    this.commissionTotal = 19.22,
    this.rentalDues = 108.60,
    this.dueAmount = 149.68,
  });
}
