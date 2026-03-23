import 'package:shelf/shelf.dart';
import 'dart:io';

import '../auth_middleware.dart';
import '../http_helpers.dart';
import '../models.dart';
import '../store.dart';
import '../workshop_notifications.dart';

class BookingController {
  const BookingController(
    this._store, {
    required this.bookingsFilePath,
    required this.notificationsService,
  });

  final InMemoryStore _store;
  final String bookingsFilePath;
  final WorkshopNotificationsService notificationsService;

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
      final String vehicleModel = (body['vehicleModel'] ?? '').toString();
      final String vehicleTypeId = (body['vehicleTypeId'] ?? '').toString();
      final String dateTimeRaw = (body['dateTime'] ?? '').toString();
      final DateTime? dateTime = DateTime.tryParse(dateTimeRaw);

      if (workshopId.isEmpty ||
          serviceId.isEmpty ||
          vehicleModel.trim().isEmpty ||
          vehicleTypeId.trim().isEmpty ||
          dateTime == null) {
        return errorResponse(
          'workshopId, serviceId, vehicleModel, vehicleTypeId va dateTime (ISO) kerak',
          statusCode: 400,
        );
      }

      final BookingModel booking = _store.createBooking(
        userId: user.id,
        workshopId: workshopId,
        serviceId: serviceId,
        vehicleModel: vehicleModel,
        vehicleTypeId: vehicleTypeId,
        dateTime: dateTime,
      );
      await _store.saveBookings(bookingsFilePath);
      await _notifyWorkshopAboutNewBooking(booking);
      return jsonResponse(<String, Object>{'data': booking.toJson()},
          statusCode: 201);
    } on FormatException catch (error) {
      return errorResponse(error.message, statusCode: 400);
    } on StateError catch (error) {
      return errorResponse(error.message, statusCode: 400);
    }
  }

  Future<Response> cancel(Request request, String id) async {
    final UserModel? user = userFromRequest(request);
    if (user == null) {
      return errorResponse('Unauthorized', statusCode: 401);
    }

    try {
      final BookingModel booking = _store.cancelBooking(
        userId: user.id,
        bookingId: id,
      );
      await _store.saveBookings(bookingsFilePath);
      await _notifyWorkshopAboutStatusChange(
        booking,
        actor: 'Mijoz',
      );
      return jsonResponse(<String, Object>{'data': booking.toJson()});
    } on StateError catch (error) {
      return errorResponse(error.message, statusCode: 404);
    }
  }

  Future<void> _notifyWorkshopAboutNewBooking(BookingModel booking) async {
    final WorkshopModel? workshop = _store.workshopById(booking.workshopId);
    if (workshop == null) {
      return;
    }

    try {
      await notificationsService.sendNewBookingNotification(
        workshop: workshop,
        booking: booking,
      );
    } on Exception catch (error) {
      stderr.writeln('Telegram yangi zakaz xabari yuborilmadi: $error');
    }
  }

  Future<void> _notifyWorkshopAboutStatusChange(
    BookingModel booking, {
    required String actor,
  }) async {
    final WorkshopModel? workshop = _store.workshopById(booking.workshopId);
    if (workshop == null) {
      return;
    }

    try {
      await notificationsService.sendBookingStatusNotification(
        workshop: workshop,
        booking: booking,
        actor: actor,
      );
    } on Exception catch (error) {
      stderr.writeln('Telegram status xabari yuborilmadi: $error');
    }
  }
}
