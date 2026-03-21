class AuthUser {
  const AuthUser({
    required this.id,
    required this.fullName,
    required this.phone,
  });

  final String id;
  final String fullName;
  final String phone;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    // TODO(API): /auth/me javobidagi data object kalitlari:
    // id, fullName, phone
    return AuthUser(
      id: (json['id'] ?? '').toString(),
      fullName: (json['fullName'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
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

  Future<AuthUser> getCurrentUser({
    required String accessToken,
  });
}
