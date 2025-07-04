class SalesTableModel {
  DateTime invsDtmDateTime;
  String description;
  int invsSngQuantity;
  double invsCurRate;
  double invsCurNetPrice;

  SalesTableModel({
    required this.invsDtmDateTime,
    required this.description,
    required this.invsSngQuantity,
    required this.invsCurRate,
    required this.invsCurNetPrice,
  });

  factory SalesTableModel.fromJson(Map<String, dynamic> json) {
    return SalesTableModel(
      invsDtmDateTime: DateTime.parse(json['invs_dtm_DateTime']),
      description: json['description'],
      invsSngQuantity: json['invs_sng_Quantity'].toInt(),
      invsCurRate: json['invs_cur_Rate'].toDouble(),
      invsCurNetPrice: json['invs_cur_NetPrice'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invs_dtm_DateTime': invsDtmDateTime.toIso8601String(),
      'Description': description,
      'invs_sng_Quantity': invsSngQuantity,
      'invs_cur_Rate': invsCurRate,
      'invs_cur_NetPrice': invsCurNetPrice,
    };
  }
}