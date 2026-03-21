import 'package:shelf/shelf.dart';

import '../auth_middleware.dart';
import '../http_helpers.dart';
import '../models.dart';
import '../store.dart';

class BookingController {
  const BookingController(this._store);

  final InMemoryStore _store;

  Response list(Request request) {
    final UserModel? user = userFromRequest(request);
    if (user == null) {
      return errorResponse('Unauthorized', statusCode: 401);
    }

    final List<Map<String, Object>> data = _store
        .bookingsForUser(user.id)
        .map((BookingModel item) => item.toJson())
        .toList(growable: false);
    return jsonResponse(<String, Object>{'data': data});
  }

  Future<Response> create(Request request) async {
    final UserModel? user = userFromRequest(request);
    if (user == null) {
      return errorResponse('Unauthorized', statusCode: 401);
    }

    try {
      final Map<String, dynamic> body = await readJsonMap(request);
      final String workshopId = (body['workshopId'] ?? '').toString();
      final String serviceId = (body['serviceId'] ?? '').toString();
      final String dateTimeRaw = (body['dateTime'] ?? '').toString();
      final DateTime? dateTime = DateTime.tryParse(dateTimeRaw);

      if (workshopId.isEmpty || serviceId.isEmpty || dateTime == null) {
        return errorResponse(
          'workshopId, serviceId va dateTime (ISO) kerak',
          statusCode: 400,
        );
      }

      final BookingModel booking = _store.createBooking(
        userId: user.id,
        workshopId: workshopId,
        serviceId: serviceId,
        dateTime: dateTime,
      );
      return jsonResponse(<String, Object>{'data': booking.toJson()},
          statusCode: 201);
    } on FormatException catch (error) {
      return errorResponse(error.message, statusCode: 400);
    } on StateError catch (error) {
      return errorResponse(error.message, statusCode: 400);
    }
  }

  Response cancel(Request request, String id) {
    final UserModel? user = userFromRequest(request);
    if (user == null) {
      return errorResponse('Unauthorized', statusCode: 401);
    }

    try {
      final BookingModel booking = _store.cancelBooking(
        userId: user.id,
        bookingId: id,
      );
      return jsonResponse(<String, Object>{'data': booking.toJson()});
    } on StateError catch (error) {
      return errorResponse(error.message, statusCode: 404);
    }
  }
}
