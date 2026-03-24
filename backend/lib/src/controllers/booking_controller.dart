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
    required this.usersFilePath,
    required this.messagesFilePath,
    required this.notificationsService,
  });

  final InMemoryStore _store;
  final String bookingsFilePath;
  final String usersFilePath;
  final String messagesFilePath;
  final WorkshopNotificationsService notificationsService;

  Response list(Request request) {
    final UserModel? user = userFromRequest(request);
    if (user == null) {
      return errorResponse('Unauthorized', statusCode: 401);
    }

    final List<Map<String, Object>> data = _store
        .bookingsForUser(user.id)
        .map((BookingModel item) => _bookingJson(item))
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
      final String vehicleBrand = (body['vehicleBrand'] ?? '').toString();
      final String vehicleModelName =
          (body['vehicleModelName'] ?? '').toString();
      final String catalogVehicleId =
          (body['catalogVehicleId'] ?? '').toString();
      final bool isCustomVehicle = body['isCustomVehicle'] == true;
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
        vehicleBrand: vehicleBrand,
        vehicleModelName: vehicleModelName,
        catalogVehicleId: catalogVehicleId,
        isCustomVehicle: isCustomVehicle,
        vehicleTypeId: vehicleTypeId,
        dateTime: dateTime,
      );
      await _store.saveBookings(bookingsFilePath);
      await _store.saveUsers(usersFilePath);
      await _notifyWorkshopAboutNewBooking(booking);
      return jsonResponse(<String, Object>{'data': _bookingJson(booking)},
          statusCode: 201);
    } on FormatException catch (error) {
      return errorResponse(error.message, statusCode: 400);
    } on StateError catch (error) {
      return errorResponse(error.message, statusCode: 400);
    }
  }

  Future<Response> listMessages(Request request, String bookingId) async {
    final UserModel? user = userFromRequest(request);
    if (user == null) {
      return errorResponse('Unauthorized', statusCode: 401);
    }

    try {
      final List<Map<String, Object>> data = _store
          .bookingMessagesForUser(
            userId: user.id,
            bookingId: bookingId,
          )
          .map((BookingChatMessageModel item) => item.toJson())
          .toList(growable: false);
      return jsonResponse(<String, Object>{'data': data});
    } on StateError catch (error) {
      return errorResponse(error.message, statusCode: 404);
    }
  }

  Future<Response> sendMessage(Request request, String bookingId) async {
    final UserModel? user = userFromRequest(request);
    if (user == null) {
      return errorResponse('Unauthorized', statusCode: 401);
    }

    try {
      final Map<String, dynamic> body = await readJsonMap(request);
      final String text = (body['text'] ?? '').toString();
      final BookingChatMessageModel message =
          _store.createCustomerBookingMessage(
        userId: user.id,
        bookingId: bookingId,
        text: text,
      );
      await _store.saveBookingMessages(messagesFilePath);
      await _notifyWorkshopAboutChatMessage(
        bookingId: bookingId,
        message: message,
      );
      return jsonResponse(
        <String, Object>{'data': message.toJson()},
        statusCode: 201,
      );
    } on FormatException catch (error) {
      return errorResponse(error.message, statusCode: 400);
    } on StateError catch (error) {
      return errorResponse(error.message, statusCode: 400);
    }
  }

  Future<Response> markMessagesRead(Request request, String bookingId) async {
    final UserModel? user = userFromRequest(request);
    if (user == null) {
      return errorResponse('Unauthorized', statusCode: 401);
    }

    try {
      final int updated = _store.markBookingMessagesReadForCustomer(
        userId: user.id,
        bookingId: bookingId,
      );
      if (updated > 0) {
        await _store.saveBookingMessages(messagesFilePath);
      }
      return jsonResponse(
        <String, Object>{
          'data': <String, Object>{'success': true},
        },
      );
    } on StateError catch (error) {
      return errorResponse(error.message, statusCode: 404);
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
      return jsonResponse(<String, Object>{'data': _bookingJson(booking)});
    } on StateError catch (error) {
      return errorResponse(error.message, statusCode: 404);
    }
  }

  Map<String, Object> _bookingJson(BookingModel booking) {
    final BookingChatSummaryModel summary = _store.chatSummaryForBooking(
      booking.id,
    );
    return <String, Object>{
      ...booking.toJson(),
      'messageCount': summary.messageCount,
      'unreadForCustomerCount': summary.unreadForCustomerCount,
      'lastMessagePreview': summary.lastMessagePreview,
      'lastMessageSenderRole': summary.lastMessageSenderRole,
      if (summary.lastMessageAt != null)
        'lastMessageAt': summary.lastMessageAt!.toUtc().toIso8601String(),
    };
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

  Future<void> _notifyWorkshopAboutChatMessage({
    required String bookingId,
    required BookingChatMessageModel message,
  }) async {
    final BookingModel? booking = _store.bookingById(bookingId);
    if (booking == null) {
      return;
    }

    final WorkshopModel? workshop = _store.workshopById(booking.workshopId);
    if (workshop == null) {
      return;
    }

    try {
      await notificationsService.sendChatMessageNotification(
        workshop: workshop,
        booking: booking,
        message: message,
      );
    } on Exception catch (error) {
      stderr.writeln('Telegram chat xabari yuborilmadi: $error');
    }
  }
}
