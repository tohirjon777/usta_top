import 'auth_service.dart';

class LocalAuthService implements AuthService {
  LocalAuthService() {
    _createSeedUser(
      const AuthUser(
        id: 'u-local',
        fullName: 'Tokhirjon',
        phone: '+998 90 123 45 67',
      ),
      password: '123456',
    );
  }

  final Map<String, AuthUser> _usersById = <String, AuthUser>{};
  final Map<String, String> _userIdByPhone = <String, String>{};
  final Map<String, String> _passwordByUserId = <String, String>{};
  final Map<String, String> _sessionToUserId = <String, String>{};
  String? _activeUserId;

  @override
  Future<AuthSession> login({
    required String phone,
    required String password,
  }) async {
    final String normalizedPhone = _normalizePhone(phone);
    final String? userId = _userIdByPhone[normalizedPhone];
    if (userId == null || _passwordByUserId[userId] != password) {
      throw const AuthException('Telefon raqam yoki parol noto\'g\'ri');
    }

    _activeUserId = userId;
    return _createSession(userId);
  }

  @override
  Future<AuthSession> signUp({
    required String fullName,
    required String phone,
    required String password,
  }) async {
    final String normalizedName = fullName.trim();
    final String normalizedPhone = phone.trim();
    _validateFullName(normalizedName);
    _validatePhone(normalizedPhone);
    _validatePassword(password);

    final String phoneKey = _normalizePhone(normalizedPhone);
    if (_userIdByPhone.containsKey(phoneKey)) {
      throw const AuthException('Bu telefon raqam allaqachon ishlatilgan');
    }

    final String userId = 'u-local-${DateTime.now().microsecondsSinceEpoch}';
    final AuthUser user = AuthUser(
      id: userId,
      fullName: normalizedName,
      phone: normalizedPhone,
    );
    _saveUser(user, password: password);
    _activeUserId = userId;
    return _createSession(userId);
  }

  @override
  Future<void> resetPassword({
    required String phone,
    required String newPassword,
  }) async {
    final String normalizedPhone = _normalizePhone(phone);
    _validatePhone(phone);
    _validatePassword(newPassword, label: 'Yangi parol');

    final String? userId = _userIdByPhone[normalizedPhone];
    if (userId == null) {
      throw const AuthException('Bunday telefon raqam bilan akkaunt topilmadi');
    }
    _passwordByUserId[userId] = newPassword;
  }

  @override
  Future<AuthUser> getCurrentUser({
    required String accessToken,
  }) async {
    return _requireUserByToken(accessToken);
  }

  @override
  Future<AuthUser> updateCurrentUserProfile({
    required String accessToken,
    required String fullName,
    required String phone,
  }) async {
    final String normalized = fullName.trim();
    final String normalizedPhone = phone.trim();
    _validateFullName(normalized);
    _validatePhone(normalizedPhone);

    final AuthUser current = _requireUserByToken(accessToken);
    final String normalizedPhoneKey = _normalizePhone(normalizedPhone);
    final String? existingUserId = _userIdByPhone[normalizedPhoneKey];
    if (existingUserId != null && existingUserId != current.id) {
      throw const AuthException('Bu telefon raqam allaqachon ishlatilgan');
    }

    final AuthUser updated = current.copyWith(
      fullName: normalized,
      phone: normalizedPhone,
    );

    _userIdByPhone.remove(_normalizePhone(current.phone));
    _usersById[current.id] = updated;
    _userIdByPhone[normalizedPhoneKey] = current.id;
    return updated;
  }

  @override
  Future<void> changePassword({
    required String accessToken,
    required String currentPassword,
    required String newPassword,
  }) async {
    final AuthUser current = _requireUserByToken(accessToken);
    if (_passwordByUserId[current.id] != currentPassword) {
      throw const AuthException('Joriy parol noto\'g\'ri');
    }
    _validatePassword(newPassword, label: 'Yangi parol');
    _passwordByUserId[current.id] = newPassword;
  }

  @override
  Future<void> registerPushToken({
    required String accessToken,
    required String token,
    required String platform,
  }) async {}

  @override
  Future<void> unregisterPushToken({
    required String accessToken,
    required String token,
  }) async {}

  void _createSeedUser(
    AuthUser user, {
    required String password,
  }) {
    _saveUser(user, password: password);
  }

  void _saveUser(
    AuthUser user, {
    required String password,
  }) {
    _usersById[user.id] = user;
    _userIdByPhone[_normalizePhone(user.phone)] = user.id;
    _passwordByUserId[user.id] = password;
    _activeUserId ??= user.id;
  }

  AuthUser _requireUserByToken(String accessToken) {
    final String? userId = _sessionToUserId[accessToken] ?? _activeUserId;
    if (userId == null) {
      throw const AuthException('Sessiya topilmadi', statusCode: 401);
    }
    final AuthUser? user = _usersById[userId];
    if (user == null) {
      throw const AuthException('Foydalanuvchi topilmadi', statusCode: 401);
    }
    return user;
  }

  AuthSession _createSession(String userId) {
    final String token = 'local-${DateTime.now().microsecondsSinceEpoch}';
    _sessionToUserId[token] = userId;
    _activeUserId = userId;
    final DateTime expiresAt = DateTime.now().add(const Duration(days: 30));
    return AuthSession(
      accessToken: token,
      expiresAt: expiresAt,
    );
  }

  String _normalizePhone(String raw) {
    return raw.replaceAll(RegExp(r'\s+'), '');
  }

  void _validateFullName(String value) {
    if (value.length < 2) {
      throw const AuthException('Ism kamida 2 ta belgidan iborat bo\'lsin');
    }
  }

  void _validatePhone(String value) {
    if (_normalizePhone(value).length < 7) {
      throw const AuthException('Telefon raqam noto\'g\'ri');
    }
  }

  void _validatePassword(
    String value, {
    String label = 'Parol',
  }) {
    if (value.length < 6) {
      throw AuthException('$label kamida 6 ta belgidan iborat bo\'lsin');
    }
  }
}
