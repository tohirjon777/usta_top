import 'dart:math';

import 'package:shelf/shelf.dart';

class AdminAuthService {
  AdminAuthService({
    required this.username,
    required this.password,
  });

  static const String cookieName = 'usta_top_admin_session';

  final String username;
  final String password;
  final Random _random = Random.secure();
  final Map<String, DateTime> _sessions = <String, DateTime>{};

  bool isAuthenticated(Request request) {
    final String? token = readSessionToken(request);
    return token != null && _sessions.containsKey(token);
  }

  bool validateCredentials({
    required String username,
    required String password,
  }) {
    return username == this.username && password == this.password;
  }

  String createSession() {
    final String token =
        '${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(1 << 32)}';
    _sessions[token] = DateTime.now().toUtc();
    return token;
  }

  String? readSessionToken(Request request) {
    final String? rawCookie = request.headers['cookie'];
    if (rawCookie == null || rawCookie.trim().isEmpty) {
      return null;
    }

    for (final String part in rawCookie.split(';')) {
      final List<String> pair = part.trim().split('=');
      if (pair.length < 2) {
        continue;
      }
      final String name = pair.first.trim();
      if (name != cookieName) {
        continue;
      }
      return pair.sublist(1).join('=').trim();
    }
    return null;
  }

  void revokeSession(String? token) {
    if (token == null || token.isEmpty) {
      return;
    }
    _sessions.remove(token);
  }

  String buildSessionCookie(String token) {
    return '$cookieName=$token; Path=/; HttpOnly; SameSite=Lax';
  }

  String buildClearedSessionCookie() {
    return '$cookieName=; Path=/; Max-Age=0; HttpOnly; SameSite=Lax';
  }
}
