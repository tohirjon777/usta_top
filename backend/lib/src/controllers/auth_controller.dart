import 'package:shelf/shelf.dart';

import '../auth_middleware.dart';
import '../http_helpers.dart';
import '../models.dart';
import '../store.dart';

class AuthController {
  const AuthController(
    this._store, {
    required this.usersFilePath,
  });

  final InMemoryStore _store;
  final String usersFilePath;

  Future<Response> login(Request request) async {
    try {
      final Map<String, dynamic> body = await readJsonMap(request);
      final String phone = (body['phone'] ?? '').toString().trim();
      final String password = (body['password'] ?? '').toString();

      if (phone.isEmpty || password.isEmpty) {
        return errorResponse('Telefon raqam va parol majburiy',
            statusCode: 400);
      }

      final String? token = _store.login(phone: phone, password: password);
      if (token == null) {
        return errorResponse('Telefon yoki parol noto\'g\'ri', statusCode: 401);
      }

      final UserModel user = _store.userByToken(token)!;
      final DateTime expiresAt = DateTime.now().add(const Duration(days: 30));

      // TODO(BACKEND): Productionda refresh tokenni DB/Redisda saqlang.
      return jsonResponse(<String, Object>{
        'data': <String, Object>{
          'token': token,
          'refreshToken': 'refresh-$token',
          'expiresAt': expiresAt.toUtc().toIso8601String(),
          'user': user.toPublicJson(),
        },
      });
    } on FormatException catch (error) {
      return errorResponse(error.message, statusCode: 400);
    }
  }

  Future<Response> register(Request request) async {
    try {
      final Map<String, dynamic> body = await readJsonMap(request);
      final String fullName = (body['fullName'] ?? '').toString().trim();
      final String phone = (body['phone'] ?? '').toString().trim();
      final String password = (body['password'] ?? '').toString();

      _validateFullName(fullName);
      _validatePhone(phone);
      _validatePassword(password, label: 'Parol');

      final UserModel user = _store.createUser(
        fullName: fullName,
        phone: phone,
        password: password,
      );
      await _store.saveUsers(usersFilePath);

      final String? token = _store.login(phone: phone, password: password);
      if (token == null) {
        return errorResponse('Ro\'yxatdan o\'tib bo\'lmadi', statusCode: 500);
      }

      final DateTime expiresAt = DateTime.now().add(const Duration(days: 30));
      return jsonResponse(<String, Object>{
        'data': <String, Object>{
          'token': token,
          'refreshToken': 'refresh-$token',
          'expiresAt': expiresAt.toUtc().toIso8601String(),
          'user': user.toPublicJson(),
        },
      });
    } on StateError catch (error) {
      return errorResponse(error.message, statusCode: 400);
    } on FormatException catch (error) {
      return errorResponse(error.message, statusCode: 400);
    }
  }

  Future<Response> forgotPassword(Request request) async {
    try {
      final Map<String, dynamic> body = await readJsonMap(request);
      final String phone = (body['phone'] ?? '').toString().trim();
      final String newPassword = (body['newPassword'] ?? '').toString();

      _validatePhone(phone);
      _validatePassword(newPassword, label: 'Yangi parol');

      final UserModel? user = _store.resetUserPasswordByPhone(
        phone: phone,
        newPassword: newPassword,
      );
      if (user == null) {
        return errorResponse(
          'Bunday telefon raqam bilan akkaunt topilmadi',
          statusCode: 404,
        );
      }

      await _store.saveUsers(usersFilePath);
      return jsonResponse(<String, Object>{
        'data': <String, Object>{
          'success': true,
        },
      });
    } on StateError catch (error) {
      return errorResponse(error.message, statusCode: 400);
    } on FormatException catch (error) {
      return errorResponse(error.message, statusCode: 400);
    }
  }

  Response me(Request request) {
    final UserModel? user = userFromRequest(request);
    if (user == null) {
      return errorResponse('Unauthorized', statusCode: 401);
    }
    return jsonResponse(<String, Object>{'data': user.toPublicJson()});
  }

  Future<Response> updateMe(Request request) async {
    final UserModel? user = userFromRequest(request);
    if (user == null) {
      return errorResponse('Unauthorized', statusCode: 401);
    }

    try {
      final Map<String, dynamic> body = await readJsonMap(request);
      final String fullName = (body['fullName'] ?? '').toString().trim();
      final String phone = (body['phone'] ?? '').toString().trim();
      _validateFullName(fullName);
      _validatePhone(phone);

      final UserModel? updated = _store.updateUserProfile(
        userId: user.id,
        fullName: fullName,
        phone: phone,
      );
      if (updated == null) {
        return errorResponse('Foydalanuvchi topilmadi', statusCode: 404);
      }

      await _store.saveUsers(usersFilePath);
      return jsonResponse(<String, Object>{'data': updated.toPublicJson()});
    } on StateError catch (error) {
      return errorResponse(error.message, statusCode: 400);
    } on FormatException catch (error) {
      return errorResponse(error.message, statusCode: 400);
    }
  }

  Future<Response> updatePassword(Request request) async {
    final UserModel? user = userFromRequest(request);
    if (user == null) {
      return errorResponse('Unauthorized', statusCode: 401);
    }

    try {
      final Map<String, dynamic> body = await readJsonMap(request);
      final String currentPassword = (body['currentPassword'] ?? '').toString();
      final String newPassword = (body['newPassword'] ?? '').toString();
      if (currentPassword.isEmpty || newPassword.isEmpty) {
        return errorResponse('Joriy va yangi parol majburiy', statusCode: 400);
      }
      _validatePassword(newPassword, label: 'Yangi parol');

      final UserModel? updated = _store.updateUserPassword(
        userId: user.id,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      if (updated == null) {
        return errorResponse('Foydalanuvchi topilmadi', statusCode: 404);
      }

      await _store.saveUsers(usersFilePath);
      return jsonResponse(<String, Object>{
        'data': <String, Object>{
          'success': true,
        },
      });
    } on StateError catch (error) {
      return errorResponse(error.message, statusCode: 400);
    } on FormatException catch (error) {
      return errorResponse(error.message, statusCode: 400);
    }
  }

  void _validateFullName(String value) {
    if (value.isEmpty) {
      throw const FormatException('Ism majburiy');
    }
    if (value.length < 2) {
      throw const FormatException('Ism kamida 2 ta belgidan iborat bo\'lsin');
    }
  }

  void _validatePhone(String value) {
    if (value.isEmpty) {
      throw const FormatException('Telefon raqam majburiy');
    }
    if (value.replaceAll(RegExp(r'\s+'), '').length < 7) {
      throw const FormatException('Telefon raqam noto\'g\'ri');
    }
  }

  void _validatePassword(
    String value, {
    required String label,
  }) {
    if (value.isEmpty) {
      throw FormatException('$label majburiy');
    }
    if (value.length < 6) {
      throw FormatException('$label kamida 6 ta belgidan iborat bo\'lsin');
    }
  }
}
