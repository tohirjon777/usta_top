import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'models.dart';
import 'store.dart';

const String _userContextKey = 'auth_user';

const Map<String, String> _corsHeaders = <String, String>{
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PATCH, OPTIONS',
  'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
};

Handler buildHandler(InMemoryStore store) {
  final Router router = Router()
    ..options('/<ignored|.*>', _optionsHandler)
    ..get('/health', _healthHandler)
    ..post('/auth/login', (Request request) => _loginHandler(request, store))
    ..get('/auth/me', _meHandler)
    ..get('/workshops', (Request request) => _workshopsHandler(request, store))
    ..get(
      '/workshops/<id>',
      (Request request, String id) => _workshopByIdHandler(request, store, id),
    )
    ..get('/bookings', (Request request) => _bookingsHandler(request, store))
    ..post(
        '/bookings', (Request request) => _createBookingHandler(request, store))
    ..patch(
      '/bookings/<id>/cancel',
      (Request request, String id) => _cancelBookingHandler(request, store, id),
    );

  return Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(_corsMiddleware())
      .addMiddleware(_authMiddleware(store))
      .addHandler(router.call);
}

Response _optionsHandler(Request request) {
  return Response.ok('', headers: _corsHeaders);
}

Response _healthHandler(Request request) {
  return _json(<String, Object>{
    'ok': true,
    'timestamp': DateTime.now().toUtc().toIso8601String(),
  });
}

Future<Response> _loginHandler(Request request, InMemoryStore store) async {
  try {
    final Map<String, dynamic> body = await _readJsonMap(request);
    final String phone = (body['phone'] ?? '').toString().trim();
    final String password = (body['password'] ?? '').toString();

    if (phone.isEmpty || password.isEmpty) {
      return _error('Telefon raqam va parol majburiy', statusCode: 400);
    }

    final String? token = store.login(phone: phone, password: password);
    if (token == null) {
      return _error('Telefon yoki parol noto\'g\'ri', statusCode: 401);
    }

    final UserModel user = store.userByToken(token)!;
    return _json(<String, Object>{
      'data': <String, Object>{
        'token': token,
        'user': user.toPublicJson(),
      },
    });
  } on FormatException catch (error) {
    return _error(error.message, statusCode: 400);
  }
}

Response _meHandler(Request request) {
  final UserModel? user = _userFromRequest(request);
  if (user == null) {
    return _error('Unauthorized', statusCode: 401);
  }
  return _json(<String, Object>{'data': user.toPublicJson()});
}

Response _workshopsHandler(Request request, InMemoryStore store) {
  final String? query = request.url.queryParameters['q'];
  final List<Map<String, Object>> data = store
      .workshops(query: query)
      .map((WorkshopModel item) => item.toJson())
      .toList(growable: false);
  return _json(<String, Object>{'data': data});
}

Response _workshopByIdHandler(
  Request request,
  InMemoryStore store,
  String id,
) {
  final WorkshopModel? workshop = store.workshopById(id);
  if (workshop == null) {
    return _error('Servis topilmadi', statusCode: 404);
  }
  return _json(<String, Object>{'data': workshop.toJson()});
}

Response _bookingsHandler(Request request, InMemoryStore store) {
  final UserModel? user = _userFromRequest(request);
  if (user == null) {
    return _error('Unauthorized', statusCode: 401);
  }

  final List<Map<String, Object>> data = store
      .bookingsForUser(user.id)
      .map((BookingModel item) => item.toJson())
      .toList(growable: false);
  return _json(<String, Object>{'data': data});
}

Future<Response> _createBookingHandler(
  Request request,
  InMemoryStore store,
) async {
  final UserModel? user = _userFromRequest(request);
  if (user == null) {
    return _error('Unauthorized', statusCode: 401);
  }

  try {
    final Map<String, dynamic> body = await _readJsonMap(request);
    final String workshopId = (body['workshopId'] ?? '').toString();
    final String serviceId = (body['serviceId'] ?? '').toString();
    final String dateTimeRaw = (body['dateTime'] ?? '').toString();
    final DateTime? dateTime = DateTime.tryParse(dateTimeRaw);

    if (workshopId.isEmpty || serviceId.isEmpty || dateTime == null) {
      return _error(
        'workshopId, serviceId va dateTime (ISO) kerak',
        statusCode: 400,
      );
    }

    final BookingModel booking = store.createBooking(
      userId: user.id,
      workshopId: workshopId,
      serviceId: serviceId,
      dateTime: dateTime,
    );
    return _json(<String, Object>{'data': booking.toJson()}, statusCode: 201);
  } on FormatException catch (error) {
    return _error(error.message, statusCode: 400);
  } on StateError catch (error) {
    return _error(error.message, statusCode: 400);
  }
}

Response _cancelBookingHandler(
  Request request,
  InMemoryStore store,
  String id,
) {
  final UserModel? user = _userFromRequest(request);
  if (user == null) {
    return _error('Unauthorized', statusCode: 401);
  }

  try {
    final BookingModel booking = store.cancelBooking(
      userId: user.id,
      bookingId: id,
    );
    return _json(<String, Object>{'data': booking.toJson()});
  } on StateError catch (error) {
    return _error(error.message, statusCode: 404);
  }
}

Middleware _authMiddleware(InMemoryStore store) {
  return (Handler innerHandler) {
    return (Request request) {
      if (request.method == 'OPTIONS' || _isPublicPath(request.url.path)) {
        return innerHandler(request);
      }

      final String? token = _extractBearerToken(request);
      if (token == null) {
        return Future<Response>.value(
          _error('Authorization token topilmadi', statusCode: 401),
        );
      }

      final UserModel? user = store.userByToken(token);
      if (user == null) {
        return Future<Response>.value(
          _error('Token yaroqsiz', statusCode: 401),
        );
      }

      return innerHandler(
        request.change(
          context: <String, Object>{
            ...request.context,
            _userContextKey: user,
          },
        ),
      );
    };
  };
}

Middleware _corsMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: _corsHeaders);
      }

      final Response response = await innerHandler(request);
      return response.change(
        headers: <String, String>{
          ...response.headers,
          ..._corsHeaders,
        },
      );
    };
  };
}

bool _isPublicPath(String path) {
  return path == 'health' || path == 'auth/login';
}

String? _extractBearerToken(Request request) {
  final String? value = request.headers['authorization'];
  if (value == null) {
    return null;
  }

  const String prefix = 'Bearer ';
  if (!value.startsWith(prefix)) {
    return null;
  }

  final String token = value.substring(prefix.length).trim();
  if (token.isEmpty) {
    return null;
  }
  return token;
}

UserModel? _userFromRequest(Request request) {
  return request.context[_userContextKey] as UserModel?;
}

Future<Map<String, dynamic>> _readJsonMap(Request request) async {
  final String body = await request.readAsString();
  if (body.trim().isEmpty) {
    return <String, dynamic>{};
  }

  final dynamic decoded = jsonDecode(body);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('JSON object kutilgan edi');
  }
  return decoded;
}

Response _json(
  Map<String, Object> body, {
  int statusCode = 200,
}) {
  return Response(
    statusCode,
    body: jsonEncode(body),
    headers: <String, String>{
      'content-type': 'application/json; charset=utf-8',
    },
  );
}

Response _error(
  String message, {
  int statusCode = 400,
}) {
  return _json(
    <String, Object>{
      'error': message,
    },
    statusCode: statusCode,
  );
}
