import 'dart:typed_data';

import 'package:excel/excel.dart';

import 'money.dart';
import 'models.dart';
import 'vehicle_catalog.dart';
import 'vehicle_types.dart';

const String vehiclePricingSheetName = 'pricing_matrix';
const String vehiclePricingInstructionsSheetName = 'instructions';

Uint8List buildWorkshopVehiclePricingWorkbook(WorkshopModel workshop) {
  final Excel excel = Excel.createExcel();
  final String defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
  if (defaultSheet != vehiclePricingSheetName) {
    excel.rename(defaultSheet, vehiclePricingSheetName);
  }
  excel.setDefaultSheet(vehiclePricingSheetName);

  excel.appendRow(vehiclePricingSheetName, <CellValue?>[
    TextCellValue('service_id'),
    TextCellValue('service_name'),
    TextCellValue('catalog_vehicle_id'),
    TextCellValue('brand'),
    TextCellValue('model'),
    TextCellValue('vehicle_type_id'),
    TextCellValue('price_uzs'),
  ]);

  final List<VehicleCatalogEntryModel> catalogEntries =
      sortedVehicleCatalogEntries();
  for (final ServiceModel service in workshop.services) {
    for (final VehicleCatalogEntryModel vehicle in catalogEntries) {
      final VehiclePriceRuleModel? rule = workshop.resolveVehiclePriceRule(
        serviceId: service.id,
        catalogVehicleId: vehicle.id,
        vehicleBrand: vehicle.brand,
        vehicleModel: vehicle.model,
      );
      excel.appendRow(vehiclePricingSheetName, <CellValue?>[
        TextCellValue(service.id),
        TextCellValue(service.name),
        TextCellValue(vehicle.id),
        TextCellValue(vehicle.brand),
        TextCellValue(vehicle.model),
        TextCellValue(vehicle.vehicleTypeId),
        IntCellValue(moneyDisplayAmount(rule?.price ?? service.price)),
      ]);
    }
  }

  final List<VehiclePriceRuleModel> customRules = workshop.vehiclePricingRules
      .where((VehiclePriceRuleModel item) => !item.hasCatalogVehicle)
      .toList(growable: false);
  for (final VehiclePriceRuleModel rule in customRules) {
      final ServiceModel? service = workshop.getServiceById(rule.serviceId);
      if (service == null) {
        continue;
      }
      excel.appendRow(vehiclePricingSheetName, <CellValue?>[
        TextCellValue(service.id),
        TextCellValue(service.name),
        TextCellValue(''),
        TextCellValue(rule.normalizedVehicleBrand),
        TextCellValue(rule.normalizedVehicleModel),
        TextCellValue(rule.vehicleTypeId),
        IntCellValue(moneyDisplayAmount(rule.price)),
      ]);
  }

  excel[vehiclePricingInstructionsSheetName];
  excel.appendRow(vehiclePricingInstructionsSheetName, <CellValue?>[
    TextCellValue('Usta Top vehicle pricing template'),
  ]);
  excel.appendRow(vehiclePricingInstructionsSheetName, <CellValue?>[
    TextCellValue(
      '1. pricing_matrix sheet ichida price_uzs ustunini to‘liq UZS qiymatida o‘zgartiring.',
    ),
  ]);
  excel.appendRow(vehiclePricingInstructionsSheetName, <CellValue?>[
    TextCellValue(
      '2. catalog_vehicle_id bo‘sh bo‘lsa, brand + model + vehicle_type_id ni to‘ldirib custom model qo‘shishingiz mumkin.',
    ),
  ]);
  excel.appendRow(vehiclePricingInstructionsSheetName, <CellValue?>[
    TextCellValue(
      '3. service_id va price_uzs majburiy. Masalan: 100000 yoki 150000 UZS.',
    ),
  ]);

  final List<int>? encoded = excel.encode();
  if (encoded == null || encoded.isEmpty) {
    return Uint8List(0);
  }
  return Uint8List.fromList(encoded);
}

List<VehiclePriceRuleModel> parseWorkshopVehiclePricingWorkbook({
  required Uint8List bytes,
  required WorkshopModel workshop,
}) {
  final Excel excel = Excel.decodeBytes(bytes);
  final Sheet? sheet = excel.tables[vehiclePricingSheetName] ??
      (excel.tables.isEmpty ? null : excel.tables.values.first);
  if (sheet == null || sheet.maxRows == 0) {
    throw const FormatException('Excel ichida pricing_matrix sheet topilmadi');
  }

  final List<Data?> headerRow = sheet.row(0);
  final Map<String, int> headerIndex = <String, int>{};
  for (int index = 0; index < headerRow.length; index++) {
    final String key = _cellString(headerRow[index]).toLowerCase();
    if (key.isNotEmpty) {
      headerIndex[key] = index;
    }
  }

  final int? serviceIdColumn = headerIndex['service_id'];
  final int? catalogVehicleIdColumn = headerIndex['catalog_vehicle_id'];
  final int? brandColumn = headerIndex['brand'];
  final int? modelColumn = headerIndex['model'];
  final int? vehicleTypeColumn = headerIndex['vehicle_type_id'];
  final int? priceColumn = headerIndex['price_uzs'] ??
      headerIndex['price'] ??
      headerIndex['price_k'];

  if (serviceIdColumn == null || priceColumn == null) {
    throw const FormatException(
      'Excel sarlavhasi noto‘g‘ri. service_id va price_uzs ustunlari kerak.',
    );
  }

  final Map<String, VehiclePriceRuleModel> deduped =
      <String, VehiclePriceRuleModel>{};
  for (int rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
    final List<Data?> row = sheet.row(rowIndex);
    final String serviceId = _readRowValue(row, serviceIdColumn).trim();
    final String catalogVehicleId = catalogVehicleIdColumn == null
        ? ''
        : _readRowValue(row, catalogVehicleIdColumn).trim();
    final String brand = brandColumn == null
        ? ''
        : _readRowValue(row, brandColumn).trim();
    final String model =
        modelColumn == null ? '' : _readRowValue(row, modelColumn).trim();
    final String vehicleTypeId = vehicleTypeColumn == null
        ? ''
        : _readRowValue(row, vehicleTypeColumn).trim();
    final String priceRaw = _readRowValue(row, priceColumn).trim();

    if (serviceId.isEmpty &&
        catalogVehicleId.isEmpty &&
        brand.isEmpty &&
        model.isEmpty &&
        priceRaw.isEmpty) {
      continue;
    }

    final ServiceModel? service = workshop.getServiceById(serviceId);
    if (service == null) {
      throw FormatException('Noma’lum service_id: $serviceId');
    }

    final int? price = tryParseStoredMoneyAmount(priceRaw);
    if (price == null || price < 0) {
      throw FormatException('Narx noto‘g‘ri: $priceRaw');
    }

    final VehicleCatalogEntryModel? catalogVehicle =
        vehicleCatalogEntryById(catalogVehicleId);
    final String resolvedBrand = catalogVehicle?.brand ??
        normalizeVehicleBrand(brand);
    final String resolvedModel = catalogVehicle?.model ??
        normalizeVehicleModelName(model);
    final String resolvedVehicleTypeId = catalogVehicle?.vehicleTypeId ??
        vehicleTypePricingById(vehicleTypeId).id;

    if (catalogVehicle == null &&
        (resolvedBrand.isEmpty || resolvedModel.isEmpty)) {
      throw FormatException(
        'Custom model uchun brand va model majburiy (service_id: $serviceId).',
      );
    }

    final VehiclePriceRuleModel rule = VehiclePriceRuleModel(
      serviceId: service.id,
      catalogVehicleId: catalogVehicle?.id ?? '',
      vehicleBrand: resolvedBrand,
      vehicleModel: resolvedModel,
      vehicleTypeId: resolvedVehicleTypeId,
      price: price,
    );
    final String key = '${rule.serviceId}|'
        '${rule.hasCatalogVehicle ? rule.normalizedCatalogVehicleId : '${rule.normalizedVehicleBrand.toLowerCase()}|${rule.normalizedVehicleModel.toLowerCase()}'}';
    deduped[key] = rule;
  }

  return List<VehiclePriceRuleModel>.unmodifiable(deduped.values);
}

String _readRowValue(List<Data?> row, int index) {
  if (index < 0 || index >= row.length) {
    return '';
  }
  return _cellString(row[index]);
}

String _cellString(Data? cell) {
  final CellValue? value = cell?.value;
  if (value == null) {
    return '';
  }
  if (value is TextCellValue) {
    return value.value.toString().trim();
  }
  if (value is IntCellValue) {
    return value.value.toString();
  }
  if (value is DoubleCellValue) {
    final double raw = value.value;
    if (raw == raw.roundToDouble()) {
      return raw.toInt().toString();
    }
    return raw.toString();
  }
  if (value is BoolCellValue) {
    return value.value.toString();
  }
  return value.toString().trim();
}
