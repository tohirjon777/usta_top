import 'dart:convert';
import 'dart:io';

import 'package:usta_top_backend/src/models.dart';
import 'package:usta_top_backend/src/vehicle_pricing_excel.dart';

Future<void> main(List<String> args) async {
  final String workshopId = args.isNotEmpty ? args.first.trim() : 'w-1';
  final File workshopsFile = File('data/workshops.json');
  if (!await workshopsFile.exists()) {
    stderr.writeln('workshops.json topilmadi: ${workshopsFile.path}');
    exitCode = 1;
    return;
  }

  final Object? decoded = jsonDecode(await workshopsFile.readAsString());
  if (decoded is! List) {
    stderr.writeln('workshops.json formati noto‘g‘ri.');
    exitCode = 1;
    return;
  }

  final List<WorkshopModel> workshops = decoded
      .whereType<Map<String, dynamic>>()
      .map(WorkshopModel.fromJson)
      .toList(growable: false);
  if (workshops.isEmpty) {
    stderr.writeln('Hech qanday workshop topilmadi.');
    exitCode = 1;
    return;
  }

  final WorkshopModel workshop = workshops.firstWhere(
    (WorkshopModel item) => item.id == workshopId,
    orElse: () => workshops.first,
  );

  final File outputFile = File('data/vehicle_pricing_sample.xlsx');
  await outputFile.parent.create(recursive: true);
  await outputFile.writeAsBytes(
    buildWorkshopVehiclePricingWorkbook(workshop),
    flush: true,
  );

  stdout.writeln(
    'Sample pricing workbook yaratildi: ${outputFile.path} (${workshop.id} / ${workshop.name})',
  );
}
