import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/config/api_endpoints.dart';
import '../core/storage/auth_token_storage.dart';
import '../models/salon.dart';
import 'api_exception.dart';
import 'workshop_service.dart';

class RemoteWorkshopService implements WorkshopService {
  const RemoteWorkshopService({
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
  Future<List<Salon>> fetchFeaturedWorkshops() async {
    // JSON namunalari: core/config/api_endpoints.dart ichida.
    final Map<String, dynamic> body = await _request(
      method: _HttpMethod.get,
      path: ApiEndpoints.workshops,
    );
    final dynamic data = body['data'];
    if (data is! List) {
      return <Salon>[];
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(Salon.fromJson)
        .toList(growable: false);
  }

  @override
  Future<Salon> fetchWorkshopById(String id) async {
    // JSON namunalari: core/config/api_endpoints.dart ichida.
    final Map<String, dynamic> body = await _request(
      method: _HttpMethod.get,
      path: ApiEndpoints.workshopById(id),
    );
    final dynamic data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Servis ma\'lumoti topilmadi');
    }
    return Salon.fromJson(data);
  }

  @override
  Future<Salon> submitReview({
    required String workshopId,
    required String serviceId,
    required int rating,
    required String comment,
  }) async {
    final Map<String, dynamic> body = await _request(
      method: _HttpMethod.post,
      path: ApiEndpoints.workshopReviews(workshopId),
      payload: <String, Object>{
        'serviceId': serviceId,
        'rating': rating,
        'comment': comment.trim(),
      },
    );
    final dynamic data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Sharh yuborilgandan keyin servis qaytmadi');
    }
    return Salon.fromJson(data);
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
    final http.Client httpClient = client ?? http.Client();
    final bool shouldCloseClient = client == null;

    try {
      late final http.Response response;
      switch (method) {
        case _HttpMethod.get:
          response = await httpClient.get(
            uri,
            headers: <String, String>{
              'authorization': 'Bearer $token',
              'content-type': 'application/json; charset=utf-8',
            },
          ).timeout(timeout);
        case _HttpMethod.post:
          response = await httpClient
              .post(
                uri,
                headers: <String, String>{
                  'authorization': 'Bearer $token',
                  'content-type': 'application/json; charset=utf-8',
                },
                body: jsonEncode(payload ?? <String, Object>{}),
              )
              .timeout(timeout);
      }

      final Map<String, dynamic> body = _decodeObject(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return body;
      }

      final String message = _errorMessage(
        body,
        fallback: 'Servislarni yuklab bo\'lmadi (${response.statusCode})',
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

enum _HttpMethod { get, post }
