import 'dart:convert';

import 'package:automaster/core/storage/auth_token_storage.dart';
import 'package:automaster/services/remote_workshop_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('workshop list requests bypass stale HTTP caches', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'auth_access_token': 'test-token',
    });

    final List<http.Request> requests = <http.Request>[];
    final RemoteWorkshopService service = RemoteWorkshopService(
      baseUrl: 'http://example.test',
      tokenStorage: const AuthTokenStorage(),
      client: MockClient((http.Request request) async {
        requests.add(request);
        return http.Response(
          jsonEncode(<String, Object>{'data': <Object>[]}),
          200,
          headers: <String, String>{
            'content-type': 'application/json; charset=utf-8',
          },
        );
      }),
    );

    await service.fetchFeaturedWorkshops();

    expect(requests, hasLength(1));
    final http.Request request = requests.single;
    expect(request.url.path, '/workshops');
    expect(request.url.queryParameters['refresh'], isNotEmpty);
    expect(request.headers['cache-control'], 'no-cache');
    expect(request.headers['pragma'], 'no-cache');
  });
}
