import '../models/saved_payment_card.dart';
import '../models/saved_vehicle_profile.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.fullName,
    required this.phone,
    this.savedVehicles = const <SavedVehicleProfile>[],
    this.savedPaymentCards = const <SavedPaymentCard>[],
  });

  final String id;
  final String fullName;
  final String phone;
  final List<SavedVehicleProfile> savedVehicles;
  final List<SavedPaymentCard> savedPaymentCards;

  AuthUser copyWith({
    String? fullName,
    String? phone,
    List<SavedVehicleProfile>? savedVehicles,
    List<SavedPaymentCard>? savedPaymentCards,
  }) {
    return AuthUser(
      id: id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      savedVehicles: savedVehicles ?? this.savedVehicles,
      savedPaymentCards: savedPaymentCards ?? this.savedPaymentCards,
    );
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    // TODO(API): /auth/me javobidagi data object kalitlari:
    // id, fullName, phone
    return AuthUser(
      id: (json['id'] ?? '').toString(),
      fullName: (json['fullName'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      savedVehicles:
          ((json['savedVehicles'] as List<dynamic>?) ?? const <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .map(SavedVehicleProfile.fromJson)
              .where((SavedVehicleProfile item) {
        return item.brand.isNotEmpty && item.model.isNotEmpty;
      }).toList(growable: false),
      savedPaymentCards:
          ((json['savedPaymentCards'] as List<dynamic>?) ?? const <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .map(SavedPaymentCard.fromJson)
              .where((SavedPaymentCard item) {
        return item.id.isNotEmpty &&
            item.maskedNumber.isNotEmpty &&
            item.expiryMonth > 0 &&
            item.expiryYear > 0;
      }).toList(growable: false),
    );
  }
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    this.refreshToken,
    this.expiresAt,
  });

  final String accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;
}

class AuthOtpChallenge {
  const AuthOtpChallenge({
    required this.expiresAt,
    required this.resendAvailableAt,
    required this.channel,
    this.debugCode,
  });

  final DateTime? expiresAt;
  final DateTime? resendAvailableAt;
  final String channel;
  final String? debugCode;

  factory AuthOtpChallenge.fromJson(Map<String, dynamic> json) {
    return AuthOtpChallenge(
      expiresAt: DateTime.tryParse((json['expiresAt'] ?? '').toString()),
      resendAvailableAt: DateTime.tryParse(
        (json['resendAvailableAt'] ?? '').toString(),
      ),
      channel: (json['channel'] ?? 'sms').toString(),
      debugCode: (json['debugCode'] ?? '').toString().trim().isEmpty
          ? null
          : (json['debugCode'] ?? '').toString(),
    );
  }
}

class AuthException implements Exception {
  const AuthException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'AuthException($statusCode, $message)';
}

abstract interface class AuthService {
  Future<AuthSession> login({
    required String phone,
    required String password,
  });

  Future<AuthSession> signUp({
    required String fullName,
    required String phone,
    required String password,
  });

  Future<AuthOtpChallenge> sendSignUpCode({
    required String phone,
  });

  Future<AuthSession> verifySignUpCode({
    required String fullName,
    required String phone,
    required String password,
    required String code,
  });

  Future<void> resetPassword({
    required String phone,
    required String newPassword,
  });

  Future<AuthOtpChallenge> sendPasswordResetCode({
    required String phone,
  });

  Future<void> verifyPasswordResetCode({
    required String phone,
    required String newPassword,
    required String code,
  });

  Future<AuthUser> getCurrentUser({
    required String accessToken,
  });

  Future<AuthUser> updateCurrentUserProfile({
    required String accessToken,
    required String fullName,
    required String phone,
  });

  Future<AuthUser> addPaymentCard({
    required String accessToken,
    required String holderName,
    required String cardNumber,
    required int expiryMonth,
    required int expiryYear,
    required bool isDefault,
  });

  Future<AuthUser> updatePaymentCard({
    required String accessToken,
    required String cardId,
    required String holderName,
    required String cardNumber,
    required int expiryMonth,
    required int expiryYear,
    required bool isDefault,
  });

  Future<AuthUser> deletePaymentCard({
    required String accessToken,
    required String cardId,
  });

  Future<void> changePassword({
    required String accessToken,
    required String currentPassword,
    required String newPassword,
  });

  Future<void> registerPushToken({
    required String accessToken,
    required String token,
    required String platform,
  });

  Future<void> unregisterPushToken({
    required String accessToken,
    required String token,
  });

  Future<void> sendTestPush({
    required String accessToken,
  });
}
