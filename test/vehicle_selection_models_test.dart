import 'package:flutter_test/flutter_test.dart';
import 'package:automaster/models/saved_vehicle_profile.dart';
import 'package:automaster/models/vehicle_catalog.dart';

void main() {
  test('catalog prioritizes Uzbekistan GM models before other cars', () {
    final List<VehicleCatalogEntry> gmVehicles =
        uzbekistanGmVehicleCatalogEntries();
    final List<VehicleCatalogEntry> otherVehicles =
        otherPopularVehicleCatalogEntries();

    expect(gmVehicles, isNotEmpty);
    expect(otherVehicles, isNotEmpty);
    expect(gmVehicles.take(4).map((VehicleCatalogEntry item) => item.model),
        <String>['Cobalt', 'Damas', 'Tracker', 'Gentra']);
    expect(gmVehicles.every((VehicleCatalogEntry item) => item.isUzbekistanGm),
        isTrue);
    expect(
        otherVehicles.every((VehicleCatalogEntry item) => !item.isUzbekistanGm),
        isTrue);
  });

  test('saved vehicle history keeps most used vehicles on top', () {
    final List<SavedVehicleProfile> vehicles = SavedVehicleProfile.upsert(
      const <SavedVehicleProfile>[
        SavedVehicleProfile(
          id: 'veh-1',
          brand: 'Chevrolet',
          model: 'Cobalt',
          vehicleTypeId: 'sedan',
          usageCount: 1,
        ),
        SavedVehicleProfile(
          id: 'veh-2',
          brand: 'Chevrolet',
          model: 'Tracker',
          vehicleTypeId: 'crossover',
          usageCount: 1,
        ),
      ],
      vehicle: const SavedVehicleProfile(
        id: 'veh-2',
        brand: 'Chevrolet',
        model: 'Tracker',
        vehicleTypeId: 'crossover',
      ),
    );

    expect(vehicles.first.displayName, 'Chevrolet Tracker');
    expect(vehicles.first.usageCount, 2);
    expect(vehicles.last.displayName, 'Chevrolet Cobalt');
  });

  test('saved vehicle history is capped and keeps custom entries', () {
    final List<SavedVehicleProfile> current =
        List<SavedVehicleProfile>.generate(
      8,
      (int index) => SavedVehicleProfile(
        id: 'veh-$index',
        brand: 'Brand $index',
        model: 'Model $index',
        vehicleTypeId: 'sedan',
        usageCount: 1,
      ),
      growable: false,
    );

    final List<SavedVehicleProfile> vehicles = SavedVehicleProfile.upsert(
      current,
      vehicle: const SavedVehicleProfile(
        id: '',
        brand: 'Tesla',
        model: 'Model Y',
        vehicleTypeId: 'suv',
        isCustom: true,
      ),
    );

    expect(vehicles, hasLength(8));
    expect(vehicles.first.displayName, 'Tesla Model Y');
    expect(vehicles.first.isCustom, isTrue);
  });
}
