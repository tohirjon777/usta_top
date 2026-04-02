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
    this.timeout = const Duration(seconds: 20),
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
  Future<AuthSession> signUp({
    required String fullName,
    required String phone,
    required String password,
  }) async {
    final Uri uri = Uri.parse('$baseUrl${ApiEndpoints.authRegister}');
    final http.Client httpClient = client ?? http.Client();
    final bool shouldCloseClient = client == null;

    try {
      final http.Response response = await httpClient
          .post(
            uri,
            headers: const <String, String>{
              'content-type': 'application/json; charset=utf-8',
            },
            body: jsonEncode(<String, String>{
              'fullName': fullName,
              'phone': phone,
              'password': password,
            }),
          )
          .timeout(timeout);

      final Map<String, dynamic> body = _decodeObject(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _parseSession(body);
      }

      final String message = _errorMessage(
        body,
        fallback: 'Ro\'yxatdan o\'tib bo\'lmadi',
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
  Future<AuthOtpChallenge> sendSignUpCode({
    required String phone,
  }) async {
    final Uri uri = Uri.parse('$baseUrl${ApiEndpoints.authRegisterSendCode}');
    final http.Client httpClient = client ?? http.Client();
    final bool shouldCloseClient = client == null;

    try {
      final http.Response response = await httpClient
          .post(
            uri,
            headers: const <String, String>{
              'content-type': 'application/json; charset=utf-8',
            },
            body: jsonEncode(<String, String>{
              'phone': phone,
            }),
          )
          .timeout(timeout);

      final Map<String, dynamic> body = _decodeObject(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _parseOtpChallenge(body);
      }

      final String message = _errorMessage(
        body,
        fallback: 'Tasdiqlash kodini yuborib bo\'lmadi',
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
  Future<AuthSession> verifySignUpCode({
    required String fullName,
    required String phone,
    required String password,
    required String code,
  }) async {
    final Uri uri = Uri.parse('$baseUrl${ApiEndpoints.authRegisterVerifyCode}');
    final http.Client httpClient = client ?? http.Client();
    final bool shouldCloseClient = client == null;

    try {
      final http.Response response = await httpClient
          .post(
            uri,
            headers: const <String, String>{
              'content-type': 'application/json; charset=utf-8',
            },
            body: jsonEncode(<String, String>{
              'fullName': fullName,
              'phone': phone,
              'password': password,
              'code': code,
            }),
          )
          .timeout(timeout);

      final Map<String, dynamic> body = _decodeObject(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _parseSession(body);
      }

      final String message = _errorMessage(
        body,
        fallback: 'Akkauntni tasdiqlab bo\'lmadi',
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
  Future<void> resetPassword({
    required String phone,
    required String newPassword,
  }) async {
    final Uri uri = Uri.parse('$baseUrl${ApiEndpoints.authForgotPassword}');
    final http.Client httpClient = client ?? http.Client();
    final bool shouldCloseClient = client == null;

    try {
      final http.Response response = await httpClient
          .post(
            uri,
            headers: const <String, String>{
              'content-type': 'application/json; charset=utf-8',
            },
            body: jsonEncode(<String, String>{
              'phone': phone,
              'newPassword': newPassword,
            }),
          )
          .timeout(timeout);

      final Map<String, dynamic> body = _decodeObject(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      }

      final String message = _errorMessage(
        body,
        fallback: 'Parolni tiklab bo\'lmadi',
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
  Future<AuthOtpChallenge> sendPasswordResetCode({
    required String phone,
  }) async {
    final Uri uri = Uri.parse('$baseUrl${ApiEndpoints.authPasswordSendCode}');
    final http.Client httpClient = client ?? http.Client();
    final bool shouldCloseClient = client == null;

    try {
      final http.Response response = await httpClient
          .post(
            uri,
            headers: const <String, String>{
              'content-type': 'application/json; charset=utf-8',
            },
            body: jsonEncode(<String, String>{
              'phone': phone,
            }),
          )
          .timeout(timeout);

      final Map<String, dynamic> body = _decodeObject(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _parseOtpChallenge(body);
      }

      final String message = _errorMessage(
        body,
        fallback: 'Tasdiqlash kodini yuborib bo\'lmadi',
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
  Future<void> verifyPasswordResetCode({
    required String phone,
    required String newPassword,
    required String code,
  }) async {
    final Uri uri = Uri.parse('$baseUrl${ApiEndpoints.authPasswordVerifyCode}');
    final http.Client httpClient = client ?? http.Client();
    final bool shouldCloseClient = client == null;

    try {
      final http.Response response = await httpClient
          .post(
            uri,
            headers: const <String, String>{
              'content-type': 'application/json; charset=utf-8',
            },
            body: jsonEncode(<String, String>{
              'phone': phone,
              'newPassword': newPassword,
              'code': code,
            }),
          )
          .timeout(timeout);

      final Map<String, dynamic> body = _decodeObject(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      }

      final String message = _errorMessage(
        body,
        fallback: 'Parolni tasdiqlab bo\'lmadi',
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

  @override
  Future<AuthUser> updateCurrentUserProfile({
    required String accessToken,
    required String fullName,
    required String phone,
  }) async {
    final Uri uri = Uri.parse('$baseUrl${ApiEndpoints.authMe}');
    final http.Client httpClient = client ?? http.Client();
    final bool shouldCloseClient = client == null;

    try {
      final http.Response response = await httpClient
          .patch(
            uri,
            headers: <String, String>{
              'authorization': 'Bearer $accessToken',
              'content-type': 'application/json; charset=utf-8',
            },
            body: jsonEncode(<String, String>{
              'fullName': fullName,
              'phone': phone,
            }),
          )
          .timeout(timeout);

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
        fallback: 'Profil ma\'lumotini yangilab bo\'lmadi',
      );
      throw AuthException(message, statusCode: response.statusCode);
    } on TimeoutException {
      throw const AuthException(
        'Profilni saqlash vaqti tugadi. Qayta urinib ko\'ring.',
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
  Future<AuthUser> uploadCurrentUserAvatar({
    required String accessToken,
    required List<int> bytes,
    required String fileName,
  }) async {
    final Uri uri = Uri.parse('$baseUrl${ApiEndpoints.authMeAvatar}');
    final http.Client httpClient = client ?? http.Client();
    final bool shouldCloseClient = client == null;

    try {
      final http.MultipartRequest request = http.MultipartRequest('POST', uri)
        ..headers['authorization'] = 'Bearer $accessToken'
        ..files.add(
          http.MultipartFile.fromBytes(
            'avatar',
            bytes,
            filename: fileName,
          ),
        );

      final http.StreamedResponse streamedResponse =
          await httpClient.send(request).timeout(timeout);
      final http.Response response =
          await http.Response.fromStream(streamedResponse);
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
        fallback: 'Avatarni yuklab bo\'lmadi',
      );
      throw AuthException(message, statusCode: response.statusCode);
    } on TimeoutException {
      throw const AuthException(
        'Avatarni yuklash vaqti tugadi. Qayta urinib ko\'ring.',
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
  Future<AuthUser> addPaymentCard({
    required String accessToken,
    required String holderName,
    required String cardNumber,
    required int expiryMonth,
    required int expiryYear,
    required bool isDefault,
  }) async {
    final Uri uri = Uri.parse('$baseUrl${ApiEndpoints.authMeCards}');
    final http.Client httpClient = client ?? http.Client();
    final bool shouldCloseClient = client == null;

    try {
      final http.Response response = await httpClient
          .post(
            uri,
            headers: <String, String>{
              'authorization': 'Bearer $accessToken',
              'content-type': 'application/json; charset=utf-8',
            },
            body: jsonEncode(<String, Object>{
              'holderName': holderName,
              'cardNumber': cardNumber,
              'expiryMonth': expiryMonth,
              'expiryYear': expiryYear,
              'isDefault': isDefault,
            }),
          )
          .timeout(timeout);

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
        fallback: 'Kartani saqlab bo\'lmadi',
      );
      throw AuthException(message, statusCode: response.statusCode);
    } on TimeoutException {
      throw const AuthException(
        'Kartani saqlash vaqti tugadi. Qayta urinib ko\'ring.',
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
  Future<AuthUser> updatePaymentCard({
    required String accessToken,
    required String cardId,
    required String holderName,
    required String cardNumber,
    required int expiryMonth,
    required int expiryYear,
    required bool isDefault,
  }) async {
    final Uri uri = Uri.parse('$baseUrl${ApiEndpoints.authMeCard(cardId)}');
    final http.Client httpClient = client ?? http.Client();
    final bool shouldCloseClient = client == null;

    try {
      final http.Response response = await httpClient
          .patch(
            uri,
            headers: <String, String>{
              'authorization': 'Bearer $accessToken',
              'content-type': 'application/json; charset=utf-8',
            },
            body: jsonEncode(<String, Object>{
              'holderName': holderName,
              'cardNumber': cardNumber,
              'expiryMonth': expiryMonth,
              'expiryYear': expiryYear,
              'isDefault': isDefault,
            }),
          )
          .timeout(timeout);

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
        fallback: 'Kartani yangilab bo\'lmadi',
      );
      throw AuthException(message, statusCode: response.statusCode);
    } on TimeoutException {
      throw const AuthException(
        'Kartani saqlash vaqti tugadi. Qayta urinib ko\'ring.',
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
  Future<AuthUser> deletePaymentCard({
    required String accessToken,
    required String cardId,
  }) async {
    final Uri uri = Uri.parse('$baseUrl${ApiEndpoints.authMeCard(cardId)}');
    final http.Client httpClient = client ?? http.Client();
    final bool shouldCloseClient = client == null;

    try {
      final http.Response response = await httpClient.delete(
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
        fallback: 'Kartani o\'chirib bo\'lmadi',
      );
      throw AuthException(message, statusCode: response.statusCode);
    } on TimeoutException {
      throw const AuthException(
        'Kartani o\'chirish vaqti tugadi. Qayta urinib ko\'ring.',
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
  Future<void> changePassword({
    required String accessToken,
    required String currentPassword,
    required String newPassword,
  }) async {
    final Uri uri = Uri.parse('$baseUrl${ApiEndpoints.authMePassword}');
    final http.Client httpClient = client ?? http.Client();
    final bool shouldCloseClient = client == null;

    try {
      final http.Response response = await httpClient
          .patch(
            uri,
            headers: <String, String>{
              'authorization': 'Bearer $accessToken',
              'content-type': 'application/json; charset=utf-8',
            },
            body: jsonEncode(<String, String>{
              'currentPassword': currentPassword,
              'newPassword': newPassword,
            }),
          )
          .timeout(timeout);

      final Map<String, dynamic> body = _decodeObject(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      }

      final String message = _errorMessage(
        body,
        fallback: 'Parolni yangilab bo\'lmadi',
      );
      throw AuthException(message, statusCode: response.statusCode);
    } on TimeoutException {
      throw const AuthException(
        'Parolni saqlash vaqti tugadi. Qayta urinib ko\'ring.',
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
  Future<void> registerPushToken({
    required String accessToken,
    required String token,
    required String platform,
  }) async {
    final Uri uri = Uri.parse('$baseUrl${ApiEndpoints.authPushToken}');
    final http.Client httpClient = client ?? http.Client();
    final bool shouldCloseClient = client == null;

    try {
      final http.Response response = await httpClient
          .post(
            uri,
            headers: <String, String>{
              'authorization': 'Bearer $accessToken',
              'content-type': 'application/json; charset=utf-8',
            },
            body: jsonEncode(<String, String>{
              'token': token,
              'platform': platform,
            }),
          )
          .timeout(timeout);

      final Map<String, dynamic> body = _decodeObject(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      }

      final String message = _errorMessage(
        body,
        fallback: 'Push tokenni saqlab bo\'lmadi',
      );
      throw AuthException(message, statusCode: response.statusCode);
    } on TimeoutException {
      throw const AuthException(
        'Push tokenni yuborish vaqti tugadi. Qayta urinib ko\'ring.',
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
  Future<void> unregisterPushToken({
    required String accessToken,
    required String token,
  }) async {
    final Uri uri = Uri.parse('$baseUrl${ApiEndpoints.authPushTokenRemove}');
    final http.Client httpClient = client ?? http.Client();
    final bool shouldCloseClient = client == null;

    try {
      final http.Response response = await httpClient
          .post(
            uri,
            headers: <String, String>{
              'authorization': 'Bearer $accessToken',
              'content-type': 'application/json; charset=utf-8',
            },
            body: jsonEncode(<String, String>{
              'token': token,
            }),
          )
          .timeout(timeout);

      final Map<String, dynamic> body = _decodeObject(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      }

      final String message = _errorMessage(
        body,
        fallback: 'Push tokenni o\'chirib bo\'lmadi',
      );
      throw AuthException(message, statusCode: response.statusCode);
    } on TimeoutException {
      throw const AuthException(
        'Push tokenni o\'chirish vaqti tugadi. Qayta urinib ko\'ring.',
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
  Future<void> sendTestPush({
    required String accessToken,
  }) async {
    final Uri uri = Uri.parse('$baseUrl${ApiEndpoints.authPushTokenTest}');
    final http.Client httpClient = client ?? http.Client();
    final bool shouldCloseClient = client == null;

    try {
      final http.Response response = await httpClient
          .post(
            uri,
            headers: <String, String>{
              'authorization': 'Bearer $accessToken',
              'content-type': 'application/json; charset=utf-8',
            },
            body: '{}',
          )
          .timeout(timeout);

      final Map<String, dynamic> body = _decodeObject(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      }

      final String message = _errorMessage(
        body,
        fallback: 'Test push yuborib bo\'lmadi',
      );
      throw AuthException(message, statusCode: response.statusCode);
    } on TimeoutException {
      throw const AuthException(
        'Test push yuborish vaqti tugadi. Qayta urinib ko\'ring.',
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

  AuthSession _parseSession(Map<String, dynamic> body) {
    final dynamic data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw const AuthException('Server javobi noto\'g\'ri formatda');
    }

    final String token = (data['token'] ?? data['accessToken'] ?? '').toString();
    if (token.isEmpty) {
      throw const AuthException('Server token qaytarmadi');
    }

    final String refreshToken = (data['refreshToken'] ?? '').toString();
    final DateTime? expiresAt = DateTime.tryParse((data['expiresAt'] ?? '').toString());
    return AuthSession(
      accessToken: token,
      refreshToken: refreshToken.isEmpty ? null : refreshToken,
      expiresAt: expiresAt ?? DateTime.now().add(const Duration(days: 30)),
    );
  }

  AuthOtpChallenge _parseOtpChallenge(Map<String, dynamic> body) {
    final dynamic data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw const AuthException('Server javobi noto\'g\'ri formatda');
    }

    return AuthOtpChallenge.fromJson(data);
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
