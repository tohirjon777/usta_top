class SavedVehicleProfile {
  const SavedVehicleProfile({
    required this.id,
    required this.brand,
    required this.model,
    required this.vehicleTypeId,
    this.catalogVehicleId = '',
    this.isCustom = false,
    this.usageCount = 0,
    this.lastUsedAt,
  });

  final String id;
  final String brand;
  final String model;
  final String vehicleTypeId;
  final String catalogVehicleId;
  final bool isCustom;
  final int usageCount;
  final DateTime? lastUsedAt;

  String get displayName => formatVehicleDisplayName(
        brand: brand,
        model: model,
      );

  SavedVehicleProfile copyWith({
    String? id,
    String? brand,
    String? model,
    String? vehicleTypeId,
    String? catalogVehicleId,
    bool? isCustom,
    int? usageCount,
    DateTime? lastUsedAt,
  }) {
    return SavedVehicleProfile(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      vehicleTypeId: vehicleTypeId ?? this.vehicleTypeId,
      catalogVehicleId: catalogVehicleId ?? this.catalogVehicleId,
      isCustom: isCustom ?? this.isCustom,
      usageCount: usageCount ?? this.usageCount,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  factory SavedVehicleProfile.fromJson(Map<String, dynamic> json) {
    return SavedVehicleProfile(
      id: (json['id'] ?? '').toString().trim(),
      brand: normalizeVehicleBrand((json['brand'] ?? '').toString()),
      model: normalizeVehicleModelName((json['model'] ?? '').toString()),
      vehicleTypeId: (json['vehicleTypeId'] ?? '').toString().trim(),
      catalogVehicleId: (json['catalogVehicleId'] ?? '').toString().trim(),
      isCustom: json['isCustom'] == true,
      usageCount: _toInt(json['usageCount']),
      lastUsedAt: DateTime.tryParse((json['lastUsedAt'] ?? '').toString()),
    );
  }

  Map<String, Object> toJson() {
    return <String, Object>{
      'id': id,
      'brand': brand,
      'model': model,
      'vehicleTypeId': vehicleTypeId,
      if (catalogVehicleId.isNotEmpty) 'catalogVehicleId': catalogVehicleId,
      'isCustom': isCustom,
      'usageCount': usageCount,
      if (lastUsedAt != null)
        'lastUsedAt': lastUsedAt!.toUtc().toIso8601String(),
    };
  }

  bool matchesVehicle({
    required String brand,
    required String model,
  }) {
    return normalizeVehicleBrand(this.brand).toLowerCase() ==
            normalizeVehicleBrand(brand).toLowerCase() &&
        normalizeVehicleModelName(this.model).toLowerCase() ==
            normalizeVehicleModelName(model).toLowerCase();
  }

  static List<SavedVehicleProfile> upsert(
    List<SavedVehicleProfile> current, {
    required SavedVehicleProfile vehicle,
    int maxItems = 8,
  }) {
    final DateTime now = vehicle.lastUsedAt ?? DateTime.now();
    final List<SavedVehicleProfile> next = <SavedVehicleProfile>[];
    SavedVehicleProfile? updated;

    for (final SavedVehicleProfile item in current) {
      if (item.matchesVehicle(
        brand: vehicle.brand,
        model: vehicle.model,
      )) {
        updated = item.copyWith(
          brand: normalizeVehicleBrand(vehicle.brand),
          model: normalizeVehicleModelName(vehicle.model),
          vehicleTypeId: vehicle.vehicleTypeId,
          catalogVehicleId: vehicle.catalogVehicleId,
          isCustom: vehicle.isCustom,
          usageCount: item.usageCount + 1,
          lastUsedAt: now,
        );
      } else {
        next.add(item);
      }
    }

    next.insert(
      0,
      updated ??
          vehicle.copyWith(
            usageCount: vehicle.usageCount > 0 ? vehicle.usageCount : 1,
            lastUsedAt: now,
          ),
    );

    next.sort((SavedVehicleProfile a, SavedVehicleProfile b) {
      final int usageOrder = b.usageCount.compareTo(a.usageCount);
      if (usageOrder != 0) {
        return usageOrder;
      }

      final DateTime aTime =
          a.lastUsedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime bTime =
          b.lastUsedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    if (next.length > maxItems) {
      return List<SavedVehicleProfile>.unmodifiable(next.take(maxItems));
    }
    return List<SavedVehicleProfile>.unmodifiable(next);
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

String normalizeVehicleBrand(String raw) {
  return raw.trim().replaceAll(RegExp(r'\s+'), ' ');
}

String normalizeVehicleModelName(String raw) {
  return raw.trim().replaceAll(RegExp(r'\s+'), ' ');
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
