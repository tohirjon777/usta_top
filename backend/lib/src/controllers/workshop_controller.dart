import 'package:shelf/shelf.dart';

import '../auth_middleware.dart';
import '../http_helpers.dart';
import '../models.dart';
import '../store.dart';
import '../workshop_notifications.dart';

class WorkshopController {
  const WorkshopController(
    this._store, {
    required this.workshopsFilePath,
    required this.reviewsFilePath,
    required this.notificationsService,
  });

  final InMemoryStore _store;
  final String workshopsFilePath;
  final String reviewsFilePath;
  final WorkshopNotificationsService notificationsService;

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
    return jsonResponse(<String, Object>{'data': _workshopDetailJson(workshop)});
  }

  Future<Response> createReview(Request request, String id) async {
    final UserModel? user = userFromRequest(request);
    if (user == null) {
      return errorResponse('Unauthorized', statusCode: 401);
    }

    final WorkshopModel? workshop = _store.workshopById(id);
    if (workshop == null) {
      return errorResponse('Servis topilmadi', statusCode: 404);
    }

    try {
      final Map<String, dynamic> body = await readJsonMap(request);
      final String serviceId = (body['serviceId'] ?? '').toString().trim();
      final String bookingId = (body['bookingId'] ?? '').toString().trim();
      final int rating = _toInt(body['rating']);
      final String comment = (body['comment'] ?? '').toString();
      if (serviceId.isEmpty) {
        return errorResponse('Xizmat tanlanishi kerak', statusCode: 400);
      }

      final WorkshopReviewModel review = _store.createWorkshopReview(
        userId: user.id,
        workshopId: workshop.id,
        serviceId: serviceId,
        rating: rating,
        comment: comment,
        bookingId: bookingId,
      );
      await _store.saveReviews(reviewsFilePath);
      await _store.saveWorkshops(workshopsFilePath);

      final WorkshopModel? refreshedWorkshop = _store.workshopById(workshop.id);
      if (refreshedWorkshop != null) {
        try {
          await notificationsService.sendNewReviewNotification(
            workshop: refreshedWorkshop,
            review: review,
          );
        } on Exception {
          // Telegram sozlanmagan bo'lsa sharh oqimini to'xtatmaymiz.
        }
        return jsonResponse(
          <String, Object>{'data': _workshopDetailJson(refreshedWorkshop)},
          statusCode: 201,
        );
      }

      return jsonResponse(
        <String, Object>{'data': review.toPublicJson()},
        statusCode: 201,
      );
    } on StateError catch (error) {
      return errorResponse(error.message, statusCode: 400);
    } on FormatException catch (error) {
      return errorResponse(error.message, statusCode: 400);
    }
  }

  Map<String, Object> _workshopDetailJson(WorkshopModel workshop) {
    final List<Map<String, Object>> reviews = _store
        .reviewsForWorkshop(workshopId: workshop.id)
        .map((WorkshopReviewModel item) => item.toPublicJson())
        .toList(growable: false);
    return <String, Object>{
      ...workshop.toJson(),
      'reviews': reviews,
    };
  }

  int _toInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse('$value') ?? 0;
  }
}
