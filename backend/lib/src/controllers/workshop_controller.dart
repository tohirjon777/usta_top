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
        .map((WorkshopModel item) => item.toPublicJson())
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

  Response availability(Request request, String id) {
    final WorkshopModel? workshop = _store.workshopById(id);
    if (workshop == null) {
      return errorResponse('Servis topilmadi', statusCode: 404);
    }

    final String serviceId =
        (request.url.queryParameters['serviceId'] ?? '').trim();
    final String dateRaw = (request.url.queryParameters['date'] ?? '').trim();
    final DateTime? date = DateTime.tryParse(dateRaw);
    if (serviceId.isEmpty || date == null) {
      return errorResponse(
        'serviceId va date (YYYY-MM-DD) query paramlari kerak',
        statusCode: 400,
      );
    }

    try {
      final ({
        List<String> slotTimes,
        bool isClosedDay,
        WorkshopScheduleModel schedule,
        int serviceDurationMinutes,
      }) availability = _store.bookingAvailability(
        workshopId: workshop.id,
        serviceId: serviceId,
        date: date,
      );
      return jsonResponse(
        <String, Object>{
          'data': <String, Object>{
            'date':
                '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
            'slots': availability.slotTimes,
            'isClosedDay': availability.isClosedDay,
            'serviceDurationMinutes': availability.serviceDurationMinutes,
            'openingTime': availability.schedule.openingTime,
            'closingTime': availability.schedule.closingTime,
            'breakStartTime': availability.schedule.breakStartTime,
            'breakEndTime': availability.schedule.breakEndTime,
          },
        },
      );
    } on StateError catch (error) {
      return errorResponse(error.message, statusCode: 400);
    }
  }

  Response availabilityCalendar(Request request, String id) {
    final WorkshopModel? workshop = _store.workshopById(id);
    if (workshop == null) {
      return errorResponse('Servis topilmadi', statusCode: 404);
    }

    final String serviceId =
        (request.url.queryParameters['serviceId'] ?? '').trim();
    final String fromRaw =
        (request.url.queryParameters['from'] ?? '').trim();
    final DateTime? fromDate = DateTime.tryParse(fromRaw);
    final int days = _toInt(request.url.queryParameters['days']);
    if (serviceId.isEmpty || fromDate == null) {
      return errorResponse(
        'serviceId va from (YYYY-MM-DD) query paramlari kerak',
        statusCode: 400,
      );
    }

    try {
      final BookingAvailabilityCalendarModel calendar =
          _store.bookingAvailabilityCalendar(
        workshopId: workshop.id,
        serviceId: serviceId,
        fromDate: fromDate,
        days: days <= 0 ? 45 : days,
      );
      return jsonResponse(<String, Object>{'data': calendar.toJson()});
    } on StateError catch (error) {
      return errorResponse(error.message, statusCode: 400);
    }
  }

  Response priceQuote(Request request, String id) {
    final WorkshopModel? workshop = _store.workshopById(id);
    if (workshop == null) {
      return errorResponse('Servis topilmadi', statusCode: 404);
    }

    final String serviceId =
        (request.url.queryParameters['serviceId'] ?? '').trim();
    if (serviceId.isEmpty) {
      return errorResponse('serviceId query parami kerak', statusCode: 400);
    }

    try {
      final quote = _store.quoteWorkshopServicePrice(
        workshopId: workshop.id,
        serviceId: serviceId,
        catalogVehicleId:
            (request.url.queryParameters['catalogVehicleId'] ?? '').trim(),
        vehicleBrand:
            (request.url.queryParameters['vehicleBrand'] ?? '').trim(),
        vehicleModelName:
            (request.url.queryParameters['vehicleModelName'] ?? '').trim(),
        vehicleTypeId:
            (request.url.queryParameters['vehicleTypeId'] ?? '').trim(),
      );
      return jsonResponse(
        <String, Object>{
          'data': <String, Object>{
            'serviceId': serviceId,
            'basePrice': quote.basePrice,
            'price': quote.price,
            'matchedRule': quote.matchedRule != null,
            if (quote.matchedRule != null)
              'matchedVehicleLabel': quote.matchedRule!.vehicleLabel,
          },
        },
      );
    } on StateError catch (error) {
      return errorResponse(error.message, statusCode: 400);
    }
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
      ...workshop.toPublicJson(),
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
