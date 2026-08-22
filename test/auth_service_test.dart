import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:uei_app/services/auth_service.dart';

void main() {
  setUp(() {
    AuthService.currentToken = null;
    AuthService.currentUser = null;
  });

  test('login accepts the server data envelope and sets static credentials',
      () async {
    final server = await _authServer({
      'data': {
        'token': 'nested-token',
        'user': {
          'id': 'driver-1',
          'email': 'driver@example.com',
          'role': 'customer',
        },
      },
    });

    try {
      final auth = AuthService('http://127.0.0.1:${server.port}');
      final result =
          await auth.emailLogin('driver@example.com', 'password123');

      expect(result['token'], 'nested-token');
      expect(AuthService.currentToken, 'nested-token');
      expect(AuthService.currentUser?['email'], 'driver@example.com');
      expect(auth.authHeaders()['Authorization'], 'Bearer nested-token');
    } finally {
      await server.close(force: true);
    }
  });

  test('login also accepts the live top-level response shape', () async {
    final server = await _authServer({
      'token': 'top-level-token',
      'user': {
        'id': 'operator-1',
        'email': 'operator@example.com',
        'role': 'operator',
      },
    });

    try {
      final result = await AuthService('http://127.0.0.1:${server.port}')
          .emailLogin('operator@example.com', 'password123');

      expect(result['token'], 'top-level-token');
      expect(AuthService.currentUser?['role'], 'operator');
    } finally {
      await server.close(force: true);
    }
  });

  test('logout clears in-memory credentials', () async {
    AuthService.currentToken = 'active-token';
    AuthService.currentUser = {'email': 'test@driver.in'};

    await AuthService.logout();

    expect(AuthService.currentToken, isNull);
    expect(AuthService.currentUser, isNull);
  });
}

Future<HttpServer> _authServer(Map<String, dynamic> responseBody) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) async {
    await utf8.decoder.bind(request).join();
    request.response.statusCode = HttpStatus.ok;
    request.response.headers.contentType = ContentType.json;
    request.response.write(json.encode(responseBody));
    await request.response.close();
  });
  return server;
}

