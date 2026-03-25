import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/config/api_endpoints.dart';
import '../core/storage/auth_token_storage.dart';
import '../models/booking_availability.dart';
import '../models/booking_availability_calendar.dart';
import '../models/booking_chat_message.dart';
import '../models/booking_item.dart';
import '../models/saved_vehicle_profile.dart';
import '../models/service_price_quote.dart';
import 'api_exception.dart';
import 'booking_service.dart';

class RemoteBookingService implements BookingService {
  const RemoteBookingService({
    required this.baseUrl,
    required AuthTokenStorage tokenStorage,
    this.client,
    this.timeout = const Duration(seconds: 8),
  }) : _tokenStorage = tokenStorage;

  final String baseUrl;
  final AuthTokenStorage _tokenStorage;
  final http.Client? client;
  final Duration timeout;

  @override
  Future<List<BookingItem>> fetchBookings() async {
    // JSON namunalari: core/config/api_endpoints.dart ichida.
    final Map<String, dynamic> body = await _request(
      method: _HttpMethod.get,
      path: ApiEndpoints.bookings,
    );

    final dynamic data = body['data'];
    if (data is! List) {
      return <BookingItem>[];
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(BookingItem.fromJson)
        .toList(growable: false);
  }

  @override
  Future<BookingItem> createBooking({
    required String workshopId,
    required String serviceId,
    required String vehicleBrand,
    required String vehicleModelName,
    required String vehicleDisplayName,
    required String catalogVehicleId,
    required bool isCustomVehicle,
    required String vehicleTypeId,
    required DateTime dateTime,
  }) async {
    // TODO(API): dateTime UTC ISO8601 formatda yuboriladi.
    // JSON namunalari: core/config/api_endpoints.dart ichida.
    final Map<String, dynamic> body = await _request(
      method: _HttpMethod.post,
      path: ApiEndpoints.bookings,
      payload: <String, Object>{
        'workshopId': workshopId,
        'serviceId': serviceId,
        'vehicleBrand': normalizeVehicleBrand(vehicleBrand),
        'vehicleModelName': normalizeVehicleModelName(vehicleModelName),
        'vehicleModel': vehicleDisplayName.isEmpty
            ? formatVehicleDisplayName(
                brand: vehicleBrand,
                model: vehicleModelName,
              )
            : vehicleDisplayName,
        'catalogVehicleId': catalogVehicleId,
        'isCustomVehicle': isCustomVehicle,
        'vehicleTypeId': vehicleTypeId,
        'dateTime': dateTime.toUtc().toIso8601String(),
      },
    );

    final dynamic data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Server buyurtma ma\'lumotini qaytarmadi');
    }

    return BookingItem.fromJson(data);
  }

  @override
  Future<BookingAvailability> fetchAvailability({
    required String workshopId,
    required String serviceId,
    required DateTime date,
  }) async {
    final String normalizedDate =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final Map<String, dynamic> body = await _request(
      method: _HttpMethod.get,
      path: ApiEndpoints.workshopAvailability(
        workshopId,
        serviceId: serviceId,
        date: normalizedDate,
      ),
    );

    final dynamic data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Server bo‘sh vaqtlarni qaytarmadi');
    }
    return BookingAvailability.fromJson(data);
  }

  @override
  Future<BookingAvailabilityCalendar> fetchAvailabilityCalendar({
    required String workshopId,
    required String serviceId,
    required DateTime fromDate,
    int days = 45,
  }) async {
    final String normalizedFrom =
        '${fromDate.year.toString().padLeft(4, '0')}-${fromDate.month.toString().padLeft(2, '0')}-${fromDate.day.toString().padLeft(2, '0')}';
    final Map<String, dynamic> body = await _request(
      method: _HttpMethod.get,
      path: ApiEndpoints.workshopAvailabilityCalendar(
        workshopId,
        serviceId: serviceId,
        from: normalizedFrom,
        days: days,
      ),
    );

    final dynamic data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Server kalendar bo‘sh vaqtlarini qaytarmadi');
    }
    return BookingAvailabilityCalendar.fromJson(data);
  }

  @override
  Future<ServicePriceQuote> fetchPriceQuote({
    required String workshopId,
    required String serviceId,
    required String catalogVehicleId,
    required String vehicleBrand,
    required String vehicleModelName,
    required String vehicleTypeId,
  }) async {
    final Map<String, dynamic> body = await _request(
      method: _HttpMethod.get,
      path: ApiEndpoints.workshopPriceQuote(
        workshopId,
        serviceId: serviceId,
        catalogVehicleId: catalogVehicleId,
        vehicleBrand: normalizeVehicleBrand(vehicleBrand),
        vehicleModelName: normalizeVehicleModelName(vehicleModelName),
        vehicleTypeId: vehicleTypeId,
      ),
    );

    final dynamic data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Server narx hisobini qaytarmadi');
    }
    return ServicePriceQuote.fromJson(data);
  }

  @override
  Future<BookingItem> cancelBooking({required String bookingId}) async {
    // JSON namunalari: core/config/api_endpoints.dart ichida.
    final Map<String, dynamic> body = await _request(
      method: _HttpMethod.patch,
      path: ApiEndpoints.cancelBooking(bookingId),
    );

    final dynamic data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Server bekor qilingan buyurtmani qaytarmadi');
    }

    return BookingItem.fromJson(data);
  }

  @override
  Future<List<BookingChatMessage>> fetchBookingMessages({
    required String bookingId,
  }) async {
    final Map<String, dynamic> body = await _request(
      method: _HttpMethod.get,
      path: ApiEndpoints.bookingMessages(bookingId),
    );

    final dynamic data = body['data'];
    if (data is! List) {
      return <BookingChatMessage>[];
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(BookingChatMessage.fromJson)
        .toList(growable: false);
  }

  @override
  Future<BookingChatMessage> sendBookingMessage({
    required String bookingId,
    required String text,
  }) async {
    final Map<String, dynamic> body = await _request(
      method: _HttpMethod.post,
      path: ApiEndpoints.bookingMessages(bookingId),
      payload: <String, Object>{
        'text': normalizeBookingChatText(text),
      },
    );

    final dynamic data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Server chat xabarini qaytarmadi');
    }

    return BookingChatMessage.fromJson(data);
  }

  @override
  Future<void> markBookingMessagesRead({
    required String bookingId,
  }) async {
    await _request(
      method: _HttpMethod.patch,
      path: ApiEndpoints.markBookingMessagesRead(bookingId),
    );
  }

  Future<Map<String, dynamic>> _request({
    required _HttpMethod method,
    required String path,
    Map<String, Object>? payload,
  }) async {
    final String? token = await _tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      throw const ApiException('Token topilmadi. Qayta tizimga kiring.');
    }

    final Uri uri = Uri.parse('$baseUrl$path');
    final Map<String, String> headers = <String, String>{
      'authorization': 'Bearer $token',
      'content-type': 'application/json; charset=utf-8',
    };

    final http.Client httpClient = client ?? http.Client();
    final bool shouldCloseClient = client == null;

    try {
      late final http.Response response;
      switch (method) {
        case _HttpMethod.get:
          response =
              await httpClient.get(uri, headers: headers).timeout(timeout);
        case _HttpMethod.post:
          response = await httpClient
              .post(
                uri,
                headers: headers,
                body: jsonEncode(payload ?? <String, Object>{}),
              )
              .timeout(timeout);
        case _HttpMethod.patch:
          response = await httpClient
              .patch(uri, headers: headers, body: '{}')
              .timeout(timeout);
      }

      final Map<String, dynamic> body = _decodeObject(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return body;
      }

      final String message = _errorMessage(
        body,
        fallback: 'So\'rov bajarilmadi (${response.statusCode})',
      );
      throw ApiException(message, statusCode: response.statusCode);
    } on TimeoutException {
      throw const ApiException(
          'Server javobi kechikdi. Qayta urinib ko\'ring.');
    } on SocketException {
      throw const ApiException(
        'Backendga ulanib bo\'lmadi. Serverni ishga tushiring.',
      );
    } on http.ClientException {
      throw const ApiException('Tarmoq xatoligi yuz berdi');
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
    }
  }

  Map<String, dynamic> _decodeObject(String raw) {
    if (raw.trim().isEmpty) {
      return <String, dynamic>{};
    }

    final dynamic decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('JSON object expected');
    }
    return decoded;
  }

  String _errorMessage(
    Map<String, dynamic> body, {
    required String fallback,
  }) {
    final dynamic value = body['error'];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    return fallback;
  }
}

enum _HttpMethod { get, post, patch }
