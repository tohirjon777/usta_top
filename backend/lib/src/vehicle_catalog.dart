class VehicleCatalogEntryModel {
  const VehicleCatalogEntryModel({
    required this.id,
    required this.brand,
    required this.model,
    required this.vehicleTypeId,
    required this.popularityRank,
    required this.isUzbekistanGm,
  });

  final String id;
  final String brand;
  final String model;
  final String vehicleTypeId;
  final int popularityRank;
  final bool isUzbekistanGm;

  String get displayName => formatVehicleDisplayName(
        brand: brand,
        model: model,
      );
}

const List<VehicleCatalogEntryModel> vehicleCatalogEntries =
    <VehicleCatalogEntryModel>[
  VehicleCatalogEntryModel(
    id: 'chevrolet-cobalt',
    brand: 'Chevrolet',
    model: 'Cobalt',
    vehicleTypeId: 'sedan',
    popularityRank: 1,
    isUzbekistanGm: true,
  ),
  VehicleCatalogEntryModel(
    id: 'chevrolet-damas',
    brand: 'Chevrolet',
    model: 'Damas',
    vehicleTypeId: 'minivan',
    popularityRank: 2,
    isUzbekistanGm: true,
  ),
  VehicleCatalogEntryModel(
    id: 'chevrolet-tracker',
    brand: 'Chevrolet',
    model: 'Tracker',
    vehicleTypeId: 'crossover',
    popularityRank: 3,
    isUzbekistanGm: true,
  ),
  VehicleCatalogEntryModel(
    id: 'chevrolet-gentra',
    brand: 'Chevrolet',
    model: 'Gentra',
    vehicleTypeId: 'sedan',
    popularityRank: 4,
    isUzbekistanGm: true,
  ),
  VehicleCatalogEntryModel(
    id: 'chevrolet-lacetti',
    brand: 'Chevrolet',
    model: 'Lacetti',
    vehicleTypeId: 'sedan',
    popularityRank: 5,
    isUzbekistanGm: true,
  ),
  VehicleCatalogEntryModel(
    id: 'chevrolet-onix',
    brand: 'Chevrolet',
    model: 'Onix',
    vehicleTypeId: 'sedan',
    popularityRank: 6,
    isUzbekistanGm: true,
  ),
  VehicleCatalogEntryModel(
    id: 'chevrolet-spark',
    brand: 'Chevrolet',
    model: 'Spark',
    vehicleTypeId: 'compact',
    popularityRank: 7,
    isUzbekistanGm: true,
  ),
  VehicleCatalogEntryModel(
    id: 'chevrolet-malibu',
    brand: 'Chevrolet',
    model: 'Malibu',
    vehicleTypeId: 'sedan',
    popularityRank: 8,
    isUzbekistanGm: true,
  ),
  VehicleCatalogEntryModel(
    id: 'chevrolet-nexia-3',
    brand: 'Chevrolet',
    model: 'Nexia 3',
    vehicleTypeId: 'sedan',
    popularityRank: 9,
    isUzbekistanGm: true,
  ),
  VehicleCatalogEntryModel(
    id: 'chevrolet-labo',
    brand: 'Chevrolet',
    model: 'Labo',
    vehicleTypeId: 'pickup',
    popularityRank: 10,
    isUzbekistanGm: true,
  ),
  VehicleCatalogEntryModel(
    id: 'daewoo-matiz',
    brand: 'Daewoo',
    model: 'Matiz',
    vehicleTypeId: 'compact',
    popularityRank: 11,
    isUzbekistanGm: true,
  ),
  VehicleCatalogEntryModel(
    id: 'daewoo-nexia',
    brand: 'Daewoo',
    model: 'Nexia',
    vehicleTypeId: 'sedan',
    popularityRank: 12,
    isUzbekistanGm: true,
  ),
  VehicleCatalogEntryModel(
    id: 'chevrolet-captiva',
    brand: 'Chevrolet',
    model: 'Captiva',
    vehicleTypeId: 'suv',
    popularityRank: 13,
    isUzbekistanGm: false,
  ),
  VehicleCatalogEntryModel(
    id: 'kia-k5',
    brand: 'Kia',
    model: 'K5',
    vehicleTypeId: 'sedan',
    popularityRank: 14,
    isUzbekistanGm: false,
  ),
  VehicleCatalogEntryModel(
    id: 'kia-sportage',
    brand: 'Kia',
    model: 'Sportage',
    vehicleTypeId: 'suv',
    popularityRank: 15,
    isUzbekistanGm: false,
  ),
  VehicleCatalogEntryModel(
    id: 'hyundai-tucson',
    brand: 'Hyundai',
    model: 'Tucson',
    vehicleTypeId: 'suv',
    popularityRank: 16,
    isUzbekistanGm: false,
  ),
  VehicleCatalogEntryModel(
    id: 'hyundai-elantra',
    brand: 'Hyundai',
    model: 'Elantra',
    vehicleTypeId: 'sedan',
    popularityRank: 17,
    isUzbekistanGm: false,
  ),
  VehicleCatalogEntryModel(
    id: 'toyota-camry',
    brand: 'Toyota',
    model: 'Camry',
    vehicleTypeId: 'sedan',
    popularityRank: 18,
    isUzbekistanGm: false,
  ),
  VehicleCatalogEntryModel(
    id: 'byd-song-plus',
    brand: 'BYD',
    model: 'Song Plus',
    vehicleTypeId: 'suv',
    popularityRank: 19,
    isUzbekistanGm: false,
  ),
  VehicleCatalogEntryModel(
    id: 'chery-tiggo-7-pro',
    brand: 'Chery',
    model: 'Tiggo 7 Pro',
    vehicleTypeId: 'crossover',
    popularityRank: 20,
    isUzbekistanGm: false,
  ),
  VehicleCatalogEntryModel(
    id: 'haval-jolion',
    brand: 'Haval',
    model: 'Jolion',
    vehicleTypeId: 'crossover',
    popularityRank: 21,
    isUzbekistanGm: false,
  ),
];

VehicleCatalogEntryModel? vehicleCatalogEntryById(String raw) {
  final String id = raw.trim();
  for (final VehicleCatalogEntryModel item in vehicleCatalogEntries) {
    if (item.id == id) {
      return item;
    }
  }
  return null;
}

VehicleCatalogEntryModel? vehicleCatalogEntryByBrandAndModel({
  required String brand,
  required String model,
}) {
  final String normalizedBrand = normalizeVehicleBrand(brand);
  final String normalizedModel = normalizeVehicleModelName(model);
  if (normalizedBrand.isEmpty || normalizedModel.isEmpty) {
    return null;
  }

  for (final VehicleCatalogEntryModel item in vehicleCatalogEntries) {
    if (item.brand.toLowerCase() == normalizedBrand.toLowerCase() &&
        item.model.toLowerCase() == normalizedModel.toLowerCase()) {
      return item;
    }
  }
  return null;
}

List<VehicleCatalogEntryModel> sortedVehicleCatalogEntries() {
  final List<VehicleCatalogEntryModel> items = vehicleCatalogEntries.toList()
    ..sort((VehicleCatalogEntryModel a, VehicleCatalogEntryModel b) {
      return a.popularityRank.compareTo(b.popularityRank);
    });
  return List<VehicleCatalogEntryModel>.unmodifiable(items);
}

String normalizeVehicleBrand(String raw) {
  final String value = raw.trim();
  if (value.isEmpty) {
    return '';
  }
  return value
      .split(RegExp(r'\s+'))
      .where((String item) => item.isNotEmpty)
      .map((String item) {
        final String lower = item.toLowerCase();
        return '${lower[0].toUpperCase()}${lower.substring(1)}';
      })
      .join(' ');
}

String normalizeVehicleModelName(String raw) {
  final String value = raw.trim();
  if (value.isEmpty) {
    return '';
  }
  return value.replaceAll(RegExp(r'\s+'), ' ');
}

String formatVehicleDisplayName({
  required String brand,
  required String model,
}) {
  final String normalizedBrand = normalizeVehicleBrand(brand);
  final String normalizedModel = normalizeVehicleModelName(model);
  if (normalizedBrand.isEmpty) {
    return normalizedModel;
  }
  if (normalizedModel.isEmpty) {
    return normalizedBrand;
  }
  return '$normalizedBrand $normalizedModel';
}
