import '../models/saved_vehicle_profile.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.fullName,
    required this.phone,
    this.savedVehicles = const <SavedVehicleProfile>[],
  });

  final String id;
  final String fullName;
  final String phone;
  final List<SavedVehicleProfile> savedVehicles;

  AuthUser copyWith({
    String? fullName,
    String? phone,
    List<SavedVehicleProfile>? savedVehicles,
  }) {
    return AuthUser(
      id: id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      savedVehicles: savedVehicles ?? this.savedVehicles,
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

  Future<void> resetPassword({
    required String phone,
    required String newPassword,
  });

  Future<AuthUser> getCurrentUser({
    required String accessToken,
  });

  Future<AuthUser> updateCurrentUserProfile({
    required String accessToken,
    required String fullName,
    required String phone,
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
}
