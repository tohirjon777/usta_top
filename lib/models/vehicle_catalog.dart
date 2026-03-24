import 'saved_vehicle_profile.dart';

class VehicleCatalogEntry {
  const VehicleCatalogEntry({
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

const List<VehicleCatalogEntry> vehicleCatalogEntries = <VehicleCatalogEntry>[
  VehicleCatalogEntry(
    id: 'chevrolet-cobalt',
    brand: 'Chevrolet',
    model: 'Cobalt',
    vehicleTypeId: 'sedan',
    popularityRank: 1,
    isUzbekistanGm: true,
  ),
  VehicleCatalogEntry(
    id: 'chevrolet-damas',
    brand: 'Chevrolet',
    model: 'Damas',
    vehicleTypeId: 'minivan',
    popularityRank: 2,
    isUzbekistanGm: true,
  ),
  VehicleCatalogEntry(
    id: 'chevrolet-tracker',
    brand: 'Chevrolet',
    model: 'Tracker',
    vehicleTypeId: 'crossover',
    popularityRank: 3,
    isUzbekistanGm: true,
  ),
  VehicleCatalogEntry(
    id: 'chevrolet-gentra',
    brand: 'Chevrolet',
    model: 'Gentra',
    vehicleTypeId: 'sedan',
    popularityRank: 4,
    isUzbekistanGm: true,
  ),
  VehicleCatalogEntry(
    id: 'chevrolet-lacetti',
    brand: 'Chevrolet',
    model: 'Lacetti',
    vehicleTypeId: 'sedan',
    popularityRank: 5,
    isUzbekistanGm: true,
  ),
  VehicleCatalogEntry(
    id: 'chevrolet-onix',
    brand: 'Chevrolet',
    model: 'Onix',
    vehicleTypeId: 'sedan',
    popularityRank: 6,
    isUzbekistanGm: true,
  ),
  VehicleCatalogEntry(
    id: 'chevrolet-spark',
    brand: 'Chevrolet',
    model: 'Spark',
    vehicleTypeId: 'compact',
    popularityRank: 7,
    isUzbekistanGm: true,
  ),
  VehicleCatalogEntry(
    id: 'chevrolet-malibu',
    brand: 'Chevrolet',
    model: 'Malibu',
    vehicleTypeId: 'sedan',
    popularityRank: 8,
    isUzbekistanGm: true,
  ),
  VehicleCatalogEntry(
    id: 'chevrolet-nexia-3',
    brand: 'Chevrolet',
    model: 'Nexia 3',
    vehicleTypeId: 'sedan',
    popularityRank: 9,
    isUzbekistanGm: true,
  ),
  VehicleCatalogEntry(
    id: 'chevrolet-labo',
    brand: 'Chevrolet',
    model: 'Labo',
    vehicleTypeId: 'pickup',
    popularityRank: 10,
    isUzbekistanGm: true,
  ),
  VehicleCatalogEntry(
    id: 'daewoo-matiz',
    brand: 'Daewoo',
    model: 'Matiz',
    vehicleTypeId: 'compact',
    popularityRank: 11,
    isUzbekistanGm: true,
  ),
  VehicleCatalogEntry(
    id: 'daewoo-nexia',
    brand: 'Daewoo',
    model: 'Nexia',
    vehicleTypeId: 'sedan',
    popularityRank: 12,
    isUzbekistanGm: true,
  ),
  VehicleCatalogEntry(
    id: 'chevrolet-captiva',
    brand: 'Chevrolet',
    model: 'Captiva',
    vehicleTypeId: 'suv',
    popularityRank: 13,
    isUzbekistanGm: false,
  ),
  VehicleCatalogEntry(
    id: 'kia-k5',
    brand: 'Kia',
    model: 'K5',
    vehicleTypeId: 'sedan',
    popularityRank: 14,
    isUzbekistanGm: false,
  ),
  VehicleCatalogEntry(
    id: 'kia-sportage',
    brand: 'Kia',
    model: 'Sportage',
    vehicleTypeId: 'suv',
    popularityRank: 15,
    isUzbekistanGm: false,
  ),
  VehicleCatalogEntry(
    id: 'hyundai-tucson',
    brand: 'Hyundai',
    model: 'Tucson',
    vehicleTypeId: 'suv',
    popularityRank: 16,
    isUzbekistanGm: false,
  ),
  VehicleCatalogEntry(
    id: 'hyundai-elantra',
    brand: 'Hyundai',
    model: 'Elantra',
    vehicleTypeId: 'sedan',
    popularityRank: 17,
    isUzbekistanGm: false,
  ),
  VehicleCatalogEntry(
    id: 'toyota-camry',
    brand: 'Toyota',
    model: 'Camry',
    vehicleTypeId: 'sedan',
    popularityRank: 18,
    isUzbekistanGm: false,
  ),
  VehicleCatalogEntry(
    id: 'byd-song-plus',
    brand: 'BYD',
    model: 'Song Plus',
    vehicleTypeId: 'suv',
    popularityRank: 19,
    isUzbekistanGm: false,
  ),
  VehicleCatalogEntry(
    id: 'chery-tiggo-7-pro',
    brand: 'Chery',
    model: 'Tiggo 7 Pro',
    vehicleTypeId: 'crossover',
    popularityRank: 20,
    isUzbekistanGm: false,
  ),
  VehicleCatalogEntry(
    id: 'haval-jolion',
    brand: 'Haval',
    model: 'Jolion',
    vehicleTypeId: 'crossover',
    popularityRank: 21,
    isUzbekistanGm: false,
  ),
];

List<VehicleCatalogEntry> popularVehicleCatalogEntries({int limit = 8}) {
  final List<VehicleCatalogEntry> items = vehicleCatalogEntries.toList()
    ..sort((VehicleCatalogEntry a, VehicleCatalogEntry b) {
      return a.popularityRank.compareTo(b.popularityRank);
    });
  if (items.length <= limit) {
    return items;
  }
  return items.take(limit).toList(growable: false);
}

List<VehicleCatalogEntry> uzbekistanGmVehicleCatalogEntries({int? limit}) {
  final List<VehicleCatalogEntry> items = vehicleCatalogEntries
      .where((VehicleCatalogEntry item) => item.isUzbekistanGm)
      .toList(growable: false)
    ..sort((VehicleCatalogEntry a, VehicleCatalogEntry b) {
      return a.popularityRank.compareTo(b.popularityRank);
    });
  if (limit == null || items.length <= limit) {
    return List<VehicleCatalogEntry>.unmodifiable(items);
  }
  return List<VehicleCatalogEntry>.unmodifiable(items.take(limit));
}

List<VehicleCatalogEntry> otherPopularVehicleCatalogEntries({int limit = 8}) {
  final List<VehicleCatalogEntry> items = vehicleCatalogEntries
      .where((VehicleCatalogEntry item) => !item.isUzbekistanGm)
      .toList(growable: false)
    ..sort((VehicleCatalogEntry a, VehicleCatalogEntry b) {
      return a.popularityRank.compareTo(b.popularityRank);
    });
  if (items.length <= limit) {
    return List<VehicleCatalogEntry>.unmodifiable(items);
  }
  return List<VehicleCatalogEntry>.unmodifiable(items.take(limit));
}

List<String> vehicleCatalogBrands() {
  final List<String> brands = <String>[];
  for (final VehicleCatalogEntry item in vehicleCatalogEntries) {
    if (!brands.contains(item.brand)) {
      brands.add(item.brand);
    }
  }
  return List<String>.unmodifiable(brands);
}

List<VehicleCatalogEntry> vehicleCatalogByBrand(String brand) {
  final String normalizedBrand = normalizeVehicleBrand(brand);
  final List<VehicleCatalogEntry> items = vehicleCatalogEntries
      .where((VehicleCatalogEntry item) => item.brand == normalizedBrand)
      .toList(growable: false)
    ..sort((VehicleCatalogEntry a, VehicleCatalogEntry b) {
      return a.popularityRank.compareTo(b.popularityRank);
    });
  return List<VehicleCatalogEntry>.unmodifiable(items);
}

VehicleCatalogEntry? vehicleCatalogEntryById(String id) {
  final String normalizedId = id.trim();
  for (final VehicleCatalogEntry item in vehicleCatalogEntries) {
    if (item.id == normalizedId) {
      return item;
    }
  }
  return null;
}

VehicleCatalogEntry? vehicleCatalogEntryByBrandAndModel({
  required String brand,
  required String model,
}) {
  final String normalizedBrand = normalizeVehicleBrand(brand).toLowerCase();
  final String normalizedModel = normalizeVehicleModelName(model).toLowerCase();
  for (final VehicleCatalogEntry item in vehicleCatalogEntries) {
    if (item.brand.toLowerCase() == normalizedBrand &&
        item.model.toLowerCase() == normalizedModel) {
      return item;
    }
  }
  return null;
}
