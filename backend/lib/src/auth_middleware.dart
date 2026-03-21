import 'package:shelf/shelf.dart';

import 'http_helpers.dart';
import 'models.dart';
import 'store.dart';

const String authUserContextKey = 'auth_user';

const Set<String> _publicPaths = <String>{
  'health',
  'auth/login',
  'auth/register',
  'auth/forgot-password',
};

bool _isPublicPath(String path) {
  return _publicPaths.contains(path) ||
      path == 'admin' ||
      path.startsWith('admin/');
}

Middleware authMiddleware(InMemoryStore store) {
  return (Handler innerHandler) {
    return (Request request) {
      if (request.method == 'OPTIONS' || _isPublicPath(request.url.path)) {
        return innerHandler(request);
      }

      final String? token = extractBearerToken(request);
      if (token == null) {
        return Future<Response>.value(
          errorResponse('Authorization token topilmadi', statusCode: 401),
        );
      }

      final UserModel? user = store.userByToken(token);
      if (user == null) {
        return Future<Response>.value(
          errorResponse('Token yaroqsiz', statusCode: 401),
        );
      }

      return innerHandler(
        request.change(
          context: <String, Object>{
            ...request.context,
            authUserContextKey: user,
          },
        ),
      );
    };
  };
}

UserModel? userFromRequest(Request request) {
  return request.context[authUserContextKey] as UserModel?;
}
