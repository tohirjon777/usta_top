import 'dart:io';

import 'package:shelf/shelf_io.dart' as io;
import 'package:usta_top_backend/src/router.dart';
import 'package:usta_top_backend/src/store.dart';

Future<void> main() async {
  final String host = Platform.environment['HOST'] ?? '0.0.0.0';
  final int port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final String workshopLocationsFilePath =
      Platform.environment['WORKSHOP_LOCATIONS_FILE'] ??
          'data/workshop_locations.json';

  final InMemoryStore store = InMemoryStore.withSeedData();
  await store.loadWorkshopLocations(workshopLocationsFilePath);

  final server = await io.serve(
    buildHandler(
      store,
      workshopLocationsFilePath: workshopLocationsFilePath,
    ),
    host,
    port,
  );

  stdout.writeln(
    'Usta Top backend ishga tushdi: http://${server.address.host}:${server.port}',
  );
  stdout.writeln(
    'Admin sahifa: http://${server.address.host}:${server.port}/admin/workshops',
  );
}
