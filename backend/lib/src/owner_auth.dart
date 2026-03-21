import 'dart:math';

import 'package:shelf/shelf.dart';

class OwnerAuthService {
  OwnerAuthService();

  static const String cookieName = 'usta_top_owner_session';

  final Random _random = Random.secure();
  final Map<String, String> _sessionToWorkshopId = <String, String>{};

  String? workshopIdFromRequest(Request request) {
    final String? token = readSessionToken(request);
    if (token == null) {
      return null;
    }
    return _sessionToWorkshopId[token];
  }

  bool isAuthenticated(Request request) {
    return workshopIdFromRequest(request) != null;
  }

  String createSession(String workshopId) {
    final String token =
        '${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(1 << 32)}';
    _sessionToWorkshopId[token] = workshopId;
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
      if (pair.first.trim() != cookieName) {
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
    _sessionToWorkshopId.remove(token);
  }

  String buildSessionCookie(String token) {
    return '$cookieName=$token; Path=/; HttpOnly; SameSite=Lax';
  }

  String buildClearedSessionCookie() {
    return '$cookieName=; Path=/; Max-Age=0; HttpOnly; SameSite=Lax';
  }
}
