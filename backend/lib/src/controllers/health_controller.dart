import 'package:shelf/shelf.dart';

import '../http_helpers.dart';

class HealthController {
  const HealthController();

  Response health(Request request) {
    return jsonResponse(<String, Object>{
      'ok': true,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
