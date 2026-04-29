import 'dart:convert';

import '../models/saved_payment_card.dart';
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
  final Map<String, String> _otpByPhoneAndPurpose = <String, String>{};
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
  Future<AuthOtpChallenge> sendSignUpCode({
    required String phone,
  }) async {
    final String normalizedPhone = _normalizePhone(phone);
    if (_userIdByPhone.containsKey(normalizedPhone)) {
      throw const AuthException('Bu telefon raqam allaqachon ishlatilgan');
    }

    const String code = '123456';
    _otpByPhoneAndPurpose['register:$normalizedPhone'] = code;

    return AuthOtpChallenge(
      expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      resendAvailableAt: DateTime.now().add(const Duration(seconds: 60)),
      channel: 'sms',
      debugCode: code,
    );
  }

  @override
  Future<AuthSession> verifySignUpCode({
    required String fullName,
    required String phone,
    required String password,
    required String code,
  }) async {
    final String normalizedPhone = _normalizePhone(phone);
    if (_otpByPhoneAndPurpose['register:$normalizedPhone'] != code.trim()) {
      throw const AuthException('Tasdiqlash kodi noto\'g\'ri');
    }
    _otpByPhoneAndPurpose.remove('register:$normalizedPhone');
    return signUp(
      fullName: fullName,
      phone: phone,
      password: password,
    );
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
  Future<AuthOtpChallenge> sendPasswordResetCode({
    required String phone,
  }) async {
    final String normalizedPhone = _normalizePhone(phone);
    if (!_userIdByPhone.containsKey(normalizedPhone)) {
      throw const AuthException('Bunday telefon raqam bilan akkaunt topilmadi');
    }

    const String code = '123456';
    _otpByPhoneAndPurpose['password_reset:$normalizedPhone'] = code;

    return AuthOtpChallenge(
      expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      resendAvailableAt: DateTime.now().add(const Duration(seconds: 60)),
      channel: 'sms',
      debugCode: code,
    );
  }

  @override
  Future<void> verifyPasswordResetCode({
    required String phone,
    required String newPassword,
    required String code,
  }) async {
    final String normalizedPhone = _normalizePhone(phone);
    if (_otpByPhoneAndPurpose['password_reset:$normalizedPhone'] !=
        code.trim()) {
      throw const AuthException('Tasdiqlash kodi noto\'g\'ri');
    }
    _otpByPhoneAndPurpose.remove('password_reset:$normalizedPhone');
    await resetPassword(phone: phone, newPassword: newPassword);
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
  Future<AuthUser> uploadCurrentUserAvatar({
    required String accessToken,
    required List<int> bytes,
    required String fileName,
  }) async {
    final AuthUser current = _requireUserByToken(accessToken);
    final String extension =
        fileName.contains('.') ? fileName.split('.').last.toLowerCase() : 'png';
    final String mimeType = switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => 'image/png',
    };

    final AuthUser updated = current.copyWith(
      avatarUrl: 'data:$mimeType;base64,${base64Encode(bytes)}',
    );
    _usersById[current.id] = updated;
    return updated;
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
    final AuthUser current = _requireUserByToken(accessToken);
    final String normalizedHolderName = holderName.trim();
    final String digits = SavedPaymentCard.normalizeDigits(cardNumber);

    _validateCardHolderName(normalizedHolderName);
    _validateCardDigits(digits);
    _validateCardExpiry(expiryMonth, expiryYear);

    final SavedPaymentCard nextCard = SavedPaymentCard(
      id: 'card-${DateTime.now().microsecondsSinceEpoch}',
      holderName: normalizedHolderName,
      brand: SavedPaymentCard.detectBrand(digits),
      maskedNumber: SavedPaymentCard.maskDigits(digits),
      last4: digits.substring(digits.length - 4),
      expiryMonth: expiryMonth,
      expiryYear: expiryYear,
      isDefault: isDefault || current.savedPaymentCards.isEmpty,
      updatedAt: DateTime.now(),
    );

    final List<SavedPaymentCard> nextCards = _normalizePaymentCards(
      <SavedPaymentCard>[
        ...current.savedPaymentCards,
        nextCard,
      ],
    );

    final AuthUser updated = current.copyWith(savedPaymentCards: nextCards);
    _usersById[current.id] = updated;
    return updated;
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
    final AuthUser current = _requireUserByToken(accessToken);
    final int cardIndex = current.savedPaymentCards.indexWhere(
      (SavedPaymentCard card) => card.id == cardId,
    );
    if (cardIndex < 0) {
      throw const AuthException('Karta topilmadi');
    }

    final SavedPaymentCard existing = current.savedPaymentCards[cardIndex];
    final String normalizedHolderName = holderName.trim();
    final String digits = SavedPaymentCard.normalizeDigits(cardNumber);

    _validateCardHolderName(normalizedHolderName);
    if (digits.isNotEmpty) {
      _validateCardDigits(digits);
    }
    _validateCardExpiry(expiryMonth, expiryYear);

    final SavedPaymentCard updatedCard = existing.copyWith(
      holderName: normalizedHolderName,
      brand: digits.isEmpty
          ? existing.brand
          : SavedPaymentCard.detectBrand(digits),
      maskedNumber: digits.isEmpty
          ? existing.maskedNumber
          : SavedPaymentCard.maskDigits(digits),
      last4:
          digits.isEmpty ? existing.last4 : digits.substring(digits.length - 4),
      expiryMonth: expiryMonth,
      expiryYear: expiryYear,
      isDefault: isDefault,
      updatedAt: DateTime.now(),
    );

    final List<SavedPaymentCard> nextCards = current.savedPaymentCards
        .map((SavedPaymentCard card) => card.id == cardId ? updatedCard : card)
        .toList(growable: false);

    final AuthUser updated = current.copyWith(
      savedPaymentCards: _normalizePaymentCards(nextCards),
    );
    _usersById[current.id] = updated;
    return updated;
  }

  @override
  Future<AuthUser> deletePaymentCard({
    required String accessToken,
    required String cardId,
  }) async {
    final AuthUser current = _requireUserByToken(accessToken);
    final List<SavedPaymentCard> nextCards = current.savedPaymentCards
        .where((SavedPaymentCard card) => card.id != cardId)
        .toList(growable: false);

    if (nextCards.length == current.savedPaymentCards.length) {
      throw const AuthException('Karta topilmadi');
    }

    final AuthUser updated = current.copyWith(
      savedPaymentCards: _normalizePaymentCards(nextCards),
    );
    _usersById[current.id] = updated;
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

  @override
  Future<void> sendTestPush({
    required String accessToken,
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

  void _validateCardHolderName(String value) {
    if (value.length < 2) {
      throw const AuthException(
          'Karta egasi ismi kamida 2 ta harfdan iborat bo\'lsin');
    }
  }

  void _validateCardDigits(String digits) {
    if (digits.length < 12 || digits.length > 19) {
      throw const AuthException('Karta raqami noto\'g\'ri');
    }
  }

  void _validateCardExpiry(int month, int year) {
    if (month < 1 || month > 12) {
      throw const AuthException('Karta amal qilish muddati noto\'g\'ri');
    }
    if (year < 2000) {
      throw const AuthException('Karta amal qilish muddati noto\'g\'ri');
    }

    final DateTime now = DateTime.now();
    if (year < now.year || (year == now.year && month < now.month)) {
      throw const AuthException('Karta muddati allaqachon tugagan');
    }
  }

  List<SavedPaymentCard> _normalizePaymentCards(List<SavedPaymentCard> cards) {
    if (cards.isEmpty) {
      return const <SavedPaymentCard>[];
    }

    final bool hasDefault =
        cards.any((SavedPaymentCard card) => card.isDefault);
    final String defaultId = hasDefault
        ? cards.firstWhere((SavedPaymentCard card) => card.isDefault).id
        : cards.first.id;

    return List<SavedPaymentCard>.unmodifiable(
      cards.map((SavedPaymentCard card) {
        return card.copyWith(isDefault: card.id == defaultId);
      }),
    );
  }
}
