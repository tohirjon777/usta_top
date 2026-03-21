import 'package:shelf/shelf.dart';

import '../http_helpers.dart';
import '../models.dart';
import '../store.dart';

class WorkshopController {
  const WorkshopController(this._store);

  final InMemoryStore _store;

  Response list(Request request) {
    final String? query = request.url.queryParameters['q'];
    final List<Map<String, Object>> data = _store
        .workshops(query: query)
        .map((WorkshopModel item) => item.toJson())
        .toList(growable: false);
    return jsonResponse(<String, Object>{'data': data});
  }

  Response byId(Request request, String id) {
    final WorkshopModel? workshop = _store.workshopById(id);
    if (workshop == null) {
      return errorResponse('Servis topilmadi', statusCode: 404);
    }
    return jsonResponse(<String, Object>{'data': workshop.toJson()});
  }
}
