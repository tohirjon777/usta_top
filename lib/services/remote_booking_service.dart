import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/config/api_endpoints.dart';
import '../core/storage/auth_token_storage.dart';
import '../models/booking_item.dart';
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
    required String vehicleModel,
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
        'vehicleModel': vehicleModel,
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
