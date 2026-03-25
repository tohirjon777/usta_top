class ServicePriceQuote {
  const ServicePriceQuote({
    required this.basePrice,
    required this.price,
    this.matchedRule = false,
    this.matchedVehicleLabel = '',
  });

  final int basePrice;
  final int price;
  final bool matchedRule;
  final String matchedVehicleLabel;

  factory ServicePriceQuote.fromJson(Map<String, dynamic> json) {
    return ServicePriceQuote(
      basePrice: _toInt(json['basePrice']),
      price: _toInt(json['price']),
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
