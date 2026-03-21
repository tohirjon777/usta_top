import 'package:shelf/shelf.dart';

import '../auth_middleware.dart';
import '../http_helpers.dart';
import '../models.dart';
import '../store.dart';

class AuthController {
  const AuthController(this._store);

  final InMemoryStore _store;

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

  Response me(Request request) {
    final UserModel? user = userFromRequest(request);
    if (user == null) {
      return errorResponse('Unauthorized', statusCode: 401);
    }
    return jsonResponse(<String, Object>{'data': user.toPublicJson()});
  }
}
