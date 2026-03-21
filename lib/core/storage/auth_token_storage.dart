import 'package:shared_preferences/shared_preferences.dart';

class AuthTokenStorage {
  const AuthTokenStorage();

  // TODO(API): Backend token lifecycle shu kalitlarda saqlanadi.
  static const String _accessTokenKey = 'auth_access_token';
  static const String _refreshTokenKey = 'auth_refresh_token';
  static const String _expiresAtKey = 'auth_expires_at';

  Future<void> saveSession({
    required String accessToken,
    String? refreshToken,
    DateTime? expiresAt,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString(_accessTokenKey, accessToken);

    if (refreshToken == null || refreshToken.isEmpty) {
      await prefs.remove(_refreshTokenKey);
    } else {
      await prefs.setString(_refreshTokenKey, refreshToken);
    }

    if (expiresAt == null) {
      await prefs.remove(_expiresAtKey);
    } else {
      await prefs.setString(_expiresAtKey, expiresAt.toUtc().toIso8601String());
    }
  }

  Future<String?> getAccessToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  Future<DateTime?> getExpiresAt() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_expiresAtKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw)?.toLocal();
  }

  Future<bool> hasValidSession() async {
    final String? token = await getAccessToken();
    if (token == null || token.isEmpty) {
      return false;
    }

    final DateTime? expiresAt = await getExpiresAt();
    if (expiresAt == null) {
      return true;
    }

    return DateTime.now().isBefore(expiresAt);
  }

  Future<void> clearSession() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_expiresAtKey);
  }
}
