import '../models/saved_payment_card.dart';
import '../models/saved_vehicle_profile.dart';
import '../models/cashback_transaction.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.fullName,
    required this.phone,
    this.avatarUrl,
    this.savedVehicles = const <SavedVehicleProfile>[],
    this.savedPaymentCards = const <SavedPaymentCard>[],
    this.cashbackBalance = 0,
    this.cashbackEarnedTotal = 0,
    this.cashbackTransactions = const <CashbackTransaction>[],
  });

  final String id;
  final String fullName;
  final String phone;
  final String? avatarUrl;
  final List<SavedVehicleProfile> savedVehicles;
  final List<SavedPaymentCard> savedPaymentCards;
  final int cashbackBalance;
  final int cashbackEarnedTotal;
  final List<CashbackTransaction> cashbackTransactions;

  AuthUser copyWith({
    String? fullName,
    String? phone,
    String? avatarUrl,
    List<SavedVehicleProfile>? savedVehicles,
    List<SavedPaymentCard>? savedPaymentCards,
    int? cashbackBalance,
    int? cashbackEarnedTotal,
    List<CashbackTransaction>? cashbackTransactions,
  }) {
    return AuthUser(
      id: id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      savedVehicles: savedVehicles ?? this.savedVehicles,
      savedPaymentCards: savedPaymentCards ?? this.savedPaymentCards,
      cashbackBalance: cashbackBalance ?? this.cashbackBalance,
      cashbackEarnedTotal: cashbackEarnedTotal ?? this.cashbackEarnedTotal,
      cashbackTransactions: cashbackTransactions ?? this.cashbackTransactions,
    );
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    // TODO(API): /auth/me javobidagi data object kalitlari:
    // id, fullName, phone
    return AuthUser(
      id: (json['id'] ?? '').toString(),
      fullName: (json['fullName'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      avatarUrl: (json['avatarUrl'] ?? '').toString().trim().isEmpty
          ? null
          : (json['avatarUrl'] ?? '').toString(),
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
      cashbackBalance: _toInt(json['cashbackBalance']),
      cashbackEarnedTotal: _toInt(json['cashbackEarnedTotal']),
      cashbackTransactions: ((json['cashbackTransactions'] as List<dynamic>?) ??
              const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(CashbackTransaction.fromJson)
          .where((CashbackTransaction item) {
        return item.id.isNotEmpty && item.amount != 0;
      }).toList(growable: false),
    );
  }

  static int _toInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse('$value') ?? 0;
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

  Future<AuthUser> uploadCurrentUserAvatar({
    required String accessToken,
    required List<int> bytes,
    required String fileName,
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
