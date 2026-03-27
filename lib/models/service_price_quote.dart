class ServicePriceQuote {
  const ServicePriceQuote({
    required this.basePrice,
    required this.price,
    required this.prepaymentPercent,
    required this.prepaymentAmount,
    required this.remainingAmount,
    required this.requiresPrepayment,
    this.matchedRule = false,
    this.matchedVehicleLabel = '',
  });

  final int basePrice;
  final int price;
  final int prepaymentPercent;
  final int prepaymentAmount;
  final int remainingAmount;
  final bool requiresPrepayment;
  final bool matchedRule;
  final String matchedVehicleLabel;

  factory ServicePriceQuote.fromJson(Map<String, dynamic> json) {
    return ServicePriceQuote(
      basePrice: _toInt(json['basePrice']),
      price: _toInt(json['price']),
      prepaymentPercent: _toInt(json['prepaymentPercent']),
      prepaymentAmount: _toInt(json['prepaymentAmount']),
      remainingAmount: _toInt(json['remainingAmount']),
      requiresPrepayment: json['requiresPrepayment'] == true,
      matchedRule: json['matchedRule'] == true,
      matchedVehicleLabel: (json['matchedVehicleLabel'] ?? '').toString(),
    );
  }

  static int _toInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse('$value') ?? 0;
  }
}
