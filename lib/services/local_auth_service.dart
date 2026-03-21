import 'auth_service.dart';

class LocalAuthService implements AuthService {
  const LocalAuthService();

  @override
  Future<AuthSession> login({
    required String phone,
    required String password,
  }) async {
    final String cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');

    if (cleanPhone.length < 7 || password.length < 6) {
      throw const AuthException('Telefon raqam yoki parol noto\'g\'ri');
    }

    final DateTime expiresAt = DateTime.now().add(const Duration(days: 30));
    return AuthSession(
      accessToken: 'local-${DateTime.now().microsecondsSinceEpoch}',
      expiresAt: expiresAt,
    );
  }

  @override
  Future<AuthUser> getCurrentUser({
    required String accessToken,
  }) async {
    return const AuthUser(
      id: 'u-local',
      fullName: 'Tokhirjon',
      phone: '+998 90 123 45 67',
    );
  }
}
