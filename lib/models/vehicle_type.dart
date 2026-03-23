import '../core/localization/app_localizations.dart';

class VehicleTypeOption {
  const VehicleTypeOption({
    required this.id,
    required this.priceFactor,
    required this.labels,
  });

  final String id;
  final double priceFactor;
  final Map<String, String> labels;

  String label(AppLocalizations l10n) =>
      labels[l10n.locale.languageCode] ?? labels['uz'] ?? id;

  String percentLabel() {
    final int percent = ((priceFactor - 1) * 100).round();
    if (percent == 0) {
      return '0%';
    }
    return '${percent > 0 ? '+' : ''}$percent%';
  }
}

const List<VehicleTypeOption> vehicleTypes = <VehicleTypeOption>[
  VehicleTypeOption(
    id: 'compact',
    priceFactor: 0.9,
    labels: <String, String>{
      'uz': 'Kompakt',
      'ru': 'Компакт',
      'en': 'Compact',
    },
  ),
  VehicleTypeOption(
    id: 'sedan',
    priceFactor: 1.0,
    labels: <String, String>{
      'uz': 'Sedan',
      'ru': 'Седан',
      'en': 'Sedan',
    },
  ),
  VehicleTypeOption(
    id: 'crossover',
    priceFactor: 1.1,
    labels: <String, String>{
      'uz': 'Krossover',
      'ru': 'Кроссовер',
      'en': 'Crossover',
    },
  ),
  VehicleTypeOption(
    id: 'suv',
    priceFactor: 1.2,
    labels: <String, String>{
      'uz': 'SUV',
      'ru': 'SUV',
      'en': 'SUV',
    },
  ),
  VehicleTypeOption(
    id: 'pickup',
    priceFactor: 1.25,
    labels: <String, String>{
      'uz': 'Pikap',
      'ru': 'Пикап',
      'en': 'Pickup',
    },
  ),
  VehicleTypeOption(
    id: 'minivan',
    priceFactor: 1.15,
    labels: <String, String>{
      'uz': 'Miniven',
      'ru': 'Минивэн',
      'en': 'Minivan',
    },
  ),
];

VehicleTypeOption defaultVehicleType() => vehicleTypes[1];

VehicleTypeOption vehicleTypeById(String raw) {
  final String normalized = raw.trim().toLowerCase();
  for (final VehicleTypeOption item in vehicleTypes) {
    if (item.id == normalized) {
      return item;
    }
  }
  return defaultVehicleType();
}

int adjustedVehiclePrice({
  required int basePrice,
  required String vehicleTypeId,
}) {
  final double factor = vehicleTypeById(vehicleTypeId).priceFactor;
  return (basePrice * factor).round();
}
