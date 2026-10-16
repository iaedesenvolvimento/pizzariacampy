import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pizzaria_mobile/core/config/app_config.dart';
import 'package:pizzaria_mobile/core/network/api_client.dart';
import 'package:pizzaria_mobile/core/storage/app_storage.dart';
import 'package:pizzaria_mobile/features/admin/admin_api_client.dart';

void main() {
  test('compartilha um único refresh entre requisições 401 concorrentes', () async {
    SharedPreferences.setMockInitialValues({
      'auth.access_token': 'expired-access',
      'auth.refresh_token': 'refresh-token',
    });
    final storage = AppStorage(await SharedPreferences.getInstance());
    var refreshCalls = 0;
    var protectedCalls = 0;
    final refreshGate = Completer<void>();
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/auth/refresh')) {
        refreshCalls++;
        await refreshGate.future;
        return http.Response(jsonEncode({
          'access_token': 'fresh-access',
          'refresh_token': 'fresh-refresh',
        }), 200);
      }
      protectedCalls++;
      if (request.headers['authorization'] == 'Bearer expired-access') {
        return http.Response(jsonEncode({'detail': 'expired'}), 401);
      }
      return http.Response('{}', 200);
    });
    final api = AdminApiClient(
      ApiClient(config: const AppConfig(apiBaseUrl: 'https://example.test'), client: client),
      storage,
    );

    final first = api.get('/admin/dashboard');
    final second = api.get('/admin/orders');
    await Future<void>.delayed(Duration.zero);
    expect(refreshCalls, 1);
    refreshGate.complete();
    await Future.wait([first, second]);

    expect(refreshCalls, 1);
    expect(protectedCalls, 4);
    expect(storage.accessToken, 'fresh-access');
    expect(storage.refreshToken, 'fresh-refresh');
  });
}
