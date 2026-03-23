class VehicleTypePricing {
  const VehicleTypePricing({
    required this.id,
    required this.priceFactor,
    required this.labels,
  });

  final String id;
  final double priceFactor;
  final Map<String, String> labels;

  String label(String lang) => labels[lang] ?? labels['uz'] ?? id;

  String percentLabel() {
    final int percent = ((priceFactor - 1) * 100).round();
    if (percent == 0) {
      return '0%';
    }
    return '${percent > 0 ? '+' : ''}$percent%';
  }
}

const List<VehicleTypePricing> vehicleTypePricings = <VehicleTypePricing>[
  VehicleTypePricing(
    id: 'compact',
    priceFactor: 0.9,
    labels: <String, String>{
      'uz': 'Kompakt',
      'ru': 'Компакт',
      'en': 'Compact',
    },
  ),
  VehicleTypePricing(
    id: 'sedan',
    priceFactor: 1.0,
    labels: <String, String>{
      'uz': 'Sedan',
      'ru': 'Седан',
      'en': 'Sedan',
    },
  ),
  VehicleTypePricing(
    id: 'crossover',
    priceFactor: 1.1,
    labels: <String, String>{
      'uz': 'Krossover',
      'ru': 'Кроссовер',
      'en': 'Crossover',
    },
  ),
  VehicleTypePricing(
    id: 'suv',
    priceFactor: 1.2,
    labels: <String, String>{
      'uz': 'SUV',
      'ru': 'SUV',
      'en': 'SUV',
    },
  ),
  VehicleTypePricing(
    id: 'pickup',
    priceFactor: 1.25,
    labels: <String, String>{
      'uz': 'Pikap',
      'ru': 'Пикап',
      'en': 'Pickup',
    },
  ),
  VehicleTypePricing(
    id: 'minivan',
    priceFactor: 1.15,
    labels: <String, String>{
      'uz': 'Miniven',
      'ru': 'Минивэн',
      'en': 'Minivan',
    },
  ),
];

VehicleTypePricing defaultVehicleTypePricing() => vehicleTypePricings[1];

VehicleTypePricing vehicleTypePricingById(String raw) {
  final String normalized = raw.trim().toLowerCase();
  for (final VehicleTypePricing item in vehicleTypePricings) {
    if (item.id == normalized) {
      return item;
    }
  }
  return defaultVehicleTypePricing();
}

int adjustedServicePrice({
  required int basePrice,
  required String vehicleTypeId,
}) {
  final double factor = vehicleTypePricingById(vehicleTypeId).priceFactor;
  return (basePrice * factor).round();
}
