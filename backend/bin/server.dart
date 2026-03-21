import 'dart:io';

import 'package:shelf/shelf_io.dart' as io;
import 'package:usta_top_backend/src/router.dart';
import 'package:usta_top_backend/src/store.dart';

Future<void> main() async {
  final String host = Platform.environment['HOST'] ?? '0.0.0.0';
  final int port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;

  final InMemoryStore store = InMemoryStore.withSeedData();
  final server = await io.serve(buildHandler(store), host, port);

  stdout.writeln(
    'Usta Top backend ishga tushdi: http://${server.address.host}:${server.port}',
  );
}
