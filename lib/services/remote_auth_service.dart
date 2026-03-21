import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/config/api_endpoints.dart';
import 'auth_service.dart';

class RemoteAuthService implements AuthService {
  const RemoteAuthService({
    required this.baseUrl,
    this.client,
    this.timeout = const Duration(seconds: 8),
  });

  final String baseUrl;
  final http.Client? client;
  final Duration timeout;

  @override
  Future<AuthSession> login({
    required String phone,
    required String password,
  }) async {
    final Uri uri = Uri.parse('$baseUrl${ApiEndpoints.authLogin}');
    final http.Client httpClient = client ?? http.Client();
    final bool shouldCloseClient = client == null;

    try {
      // TODO(API): Backend login endpoint below should accept phone/password.
      // JSON namunalari: core/config/api_endpoints.dart ichida.
      final http.Response response = await httpClient
          .post(
            uri,
            headers: const <String, String>{
              'content-type': 'application/json; charset=utf-8',
            },
            body: jsonEncode(<String, String>{
              'phone': phone,
              'password': password,
            }),
          )
          .timeout(timeout);

      final Map<String, dynamic> body = _decodeObject(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic data = body['data'];
        if (data is! Map<String, dynamic>) {
          throw const AuthException('Server javobi noto\'g\'ri formatda');
        }

        final String token =
            (data['token'] ?? data['accessToken'] ?? '').toString();
        if (token.isEmpty) {
          throw const AuthException('Server token qaytarmadi');
        }

        final String refreshToken = (data['refreshToken'] ?? '').toString();
        final DateTime? expiresAt =
            DateTime.tryParse((data['expiresAt'] ?? '').toString());
        return AuthSession(
          accessToken: token,
          refreshToken: refreshToken.isEmpty ? null : refreshToken,
          expiresAt: expiresAt ?? DateTime.now().add(const Duration(days: 30)),
        );
      }

      final String message = _errorMessage(
        body,
        fallback: 'Kirish amalga oshmadi',
      );
      throw AuthException(message, statusCode: response.statusCode);
    } on TimeoutException {
      throw const AuthException(
        'Serverga ulanish vaqti tugadi. Qayta urinib ko\'ring.',
      );
    } on SocketException {
      throw const AuthException(
        'Backendga ulanib bo\'lmadi. Backend serverni ishga tushiring.',
      );
    } on http.ClientException {
      throw const AuthException('Tarmoq xatoligi yuz berdi');
    } on FormatException {
      throw const AuthException('Server javobini o\'qib bo\'lmadi');
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
    }
  }

  @override
  Future<AuthUser> getCurrentUser({
    required String accessToken,
  }) async {
    final Uri uri = Uri.parse('$baseUrl${ApiEndpoints.authMe}');
    final http.Client httpClient = client ?? http.Client();
    final bool shouldCloseClient = client == null;

    try {
      // JSON namunalari: core/config/api_endpoints.dart ichida.
      final http.Response response = await httpClient.get(
        uri,
        headers: <String, String>{
          'authorization': 'Bearer $accessToken',
          'content-type': 'application/json; charset=utf-8',
        },
      ).timeout(timeout);

      final Map<String, dynamic> body = _decodeObject(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic data = body['data'];
        if (data is! Map<String, dynamic>) {
          throw const AuthException('Foydalanuvchi ma\'lumoti formatida xato');
        }
        return AuthUser.fromJson(data);
      }

      final String message = _errorMessage(
        body,
        fallback: 'Profil ma\'lumotini olib bo\'lmadi',
      );
      throw AuthException(message, statusCode: response.statusCode);
    } on TimeoutException {
      throw const AuthException(
        'Profilni yuklash vaqti tugadi. Qayta urinib ko\'ring.',
      );
    } on SocketException {
      throw const AuthException(
        'Backendga ulanib bo\'lmadi. Backend serverni ishga tushiring.',
      );
    } on http.ClientException {
      throw const AuthException('Tarmoq xatoligi yuz berdi');
    } on FormatException {
      throw const AuthException('Server javobini o\'qib bo\'lmadi');
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
