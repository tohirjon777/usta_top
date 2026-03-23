import 'dart:convert';
import 'dart:io';

import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;

class FirebasePushService {
  FirebasePushService({
    required this.serviceAccountFilePath,
  });

  final String serviceAccountFilePath;

  auth.AccessCredentials? _cachedCredentials;
  Map<String, dynamic>? _serviceAccountJson;

  bool get isConfigured {
    final String path = serviceAccountFilePath.trim();
    return path.isNotEmpty && File(path).existsSync();
  }

  Future<void> sendToTokens({
    required Iterable<String> tokens,
    required String title,
    required String body,
    Map<String, String> data = const <String, String>{},
  }) async {
    final List<String> normalizedTokens = tokens
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (normalizedTokens.isEmpty) {
      return;
    }
    if (!isConfigured) {
      throw const FirebasePushException(
        'Firebase service account sozlanmagan',
      );
    }

    final String projectId = await _loadProjectId();
    final String accessToken = await _loadAccessToken();
    final Uri uri = Uri.parse(
      'https://fcm.googleapis.com/v1/projects/$projectId/messages:send',
    );
    final http.Client client = http.Client();

    try {
      for (final String token in normalizedTokens) {
        final http.Response response = await client.post(
          uri,
          headers: <String, String>{
            'authorization': 'Bearer $accessToken',
            'content-type': 'application/json; charset=utf-8',
          },
          body: jsonEncode(
            <String, Object>{
              'message': <String, Object>{
                'token': token,
                'notification': <String, String>{
                  'title': title,
                  'body': body,
                },
                'data': data,
                'android': <String, Object>{
                  'priority': 'high',
                  'notification': <String, String>{
                    'channel_id': 'booking_updates',
                  },
                },
                'apns': <String, Object>{
                  'headers': <String, String>{
                    'apns-priority': '10',
                  },
                  'payload': <String, Object>{
                    'aps': <String, Object>{
                      'sound': 'default',
                    },
                  },
                },
              },
            },
          ),
        );

        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw FirebasePushException(
            _firebaseErrorMessage(
              response.body,
              fallback: 'FCM xabari yuborilmadi (HTTP ${response.statusCode})',
            ),
          );
        }
      }
    } on SocketException {
      throw const FirebasePushException('FCMga ulanib bo‘lmadi');
    } on HandshakeException {
      throw const FirebasePushException('FCM bilan xavfsiz ulanishda xato');
    } finally {
      client.close();
    }
  }

  Future<String> _loadProjectId() async {
    final Map<String, dynamic> json = await _loadServiceAccountJson();
    final String projectId = (json['project_id'] ?? '').toString().trim();
    if (projectId.isEmpty) {
      throw const FirebasePushException(
        'Firebase service account ichida project_id topilmadi',
      );
    }
    return projectId;
  }

  Future<String> _loadAccessToken() async {
    final auth.AccessCredentials? cached = _cachedCredentials;
    if (cached != null &&
        !cached.accessToken.hasExpired &&
        cached.accessToken.expiry
            .isAfter(DateTime.now().toUtc().add(const Duration(minutes: 1)))) {
      return cached.accessToken.data;
    }

    final Map<String, dynamic> json = await _loadServiceAccountJson();
    final auth.ServiceAccountCredentials credentials =
        auth.ServiceAccountCredentials.fromJson(json);
    final http.Client client = http.Client();
    try {
      final auth.AccessCredentials fresh =
          await auth.obtainAccessCredentialsViaServiceAccount(
        credentials,
        const <String>['https://www.googleapis.com/auth/firebase.messaging'],
        client,
      );
      _cachedCredentials = fresh;
      return fresh.accessToken.data;
    } on auth.AccessDeniedException catch (error) {
      throw FirebasePushException('Firebase access rad etildi: $error');
    } finally {
      client.close();
    }
  }

  Future<Map<String, dynamic>> _loadServiceAccountJson() async {
    final Map<String, dynamic>? cached = _serviceAccountJson;
    if (cached != null) {
      return cached;
    }

    final String path = serviceAccountFilePath.trim();
    if (path.isEmpty) {
      throw const FirebasePushException(
        'Firebase service account fayli ko‘rsatilmagan',
      );
    }

    final File file = File(path);
    if (!await file.exists()) {
      throw FirebasePushException(
        'Firebase service account fayli topilmadi: $path',
      );
    }

    final dynamic decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, dynamic>) {
      throw const FirebasePushException(
        'Firebase service account JSON object bo‘lishi kerak',
      );
    }
    _serviceAccountJson = decoded;
    return decoded;
  }

  String _firebaseErrorMessage(
    String rawBody, {
    required String fallback,
  }) {
    if (rawBody.trim().isEmpty) {
      return fallback;
    }

    try {
      final dynamic decoded = jsonDecode(rawBody);
      if (decoded is Map<String, dynamic>) {
        final dynamic error = decoded['error'];
        if (error is Map<String, dynamic>) {
          final String message = (error['message'] ?? '').toString().trim();
          if (message.isNotEmpty) {
            return message;
          }
        }
      }
    } on FormatException {
      return fallback;
    }

    return fallback;
  }
}

class FirebasePushException implements Exception {
  const FirebasePushException(this.message);

  final String message;

  @override
  String toString() => 'FirebasePushException($message)';
}
