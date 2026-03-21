import 'dart:convert';

import 'package:shelf/shelf.dart';

const Map<String, String> corsHeaders = <String, String>{
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PATCH, OPTIONS',
  'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
};

Response optionsHandler(Request request) {
  return Response.ok('', headers: corsHeaders);
}

Middleware corsMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: corsHeaders);
      }

      final Response response = await innerHandler(request);
      return response.change(
        headers: <String, String>{
          ...response.headers,
          ...corsHeaders,
        },
      );
    };
  };
}

Future<Map<String, dynamic>> readJsonMap(Request request) async {
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

Response jsonResponse(
  Map<String, Object?> body, {
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

Response errorResponse(
  String message, {
  int statusCode = 400,
}) {
  return jsonResponse(
    <String, Object>{
      'error': message,
    },
    statusCode: statusCode,
  );
}

String? extractBearerToken(Request request) {
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
