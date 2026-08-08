import 'dart:convert';
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:awa_app/api/auth_interceptor.dart';
import 'package:awa_app/api/auth_storage.dart';

class FakeAuthStorage extends AuthStorage {
  String? _access;
  String? _refresh;

  @override
  Future<void> saveTokens(String access, String refresh) async {
    _access = access;
    _refresh = refresh;
  }

  @override
  Future<String?> get access async => _access;

  @override
  Future<String?> get refresh async => _refresh;

  @override
  Future<void> clear() async {
    _access = null;
    _refresh = null;
  }
}

class MockHttpClientAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;

  MockHttpClientAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('retries concurrent requests after a refresh succeeds', () async {
    final storage = FakeAuthStorage();
    await storage.saveTokens('stale-access', 'stale-refresh');

    var userCalls = 0;
    final adapter = MockHttpClientAdapter((options) async {
      if (options.path == '/auth/refresh') {
        return ResponseBody.fromString(
          jsonEncode({'accessToken': 'fresh-access', 'refreshToken': 'fresh-refresh'}),
          200,
          headers: <String, List<String>>{},
        );
      }

      if (options.path == '/users/me') {
        userCalls += 1;
        if (userCalls == 1 || userCalls == 3) {
          return ResponseBody.fromString('', 401, headers: <String, List<String>>{});
        }

        return ResponseBody.fromString(
          jsonEncode({
            'id': 'u1',
            'firstName': 'Ada',
            'email': 'ada@example.com',
            'createdAt': '2024-01-01',
            'role': 'user',
          }),
          200,
          headers: <String, List<String>>{},
        );
      }

      return ResponseBody.fromString('not found', 404, headers: <String, List<String>>{});
    });

    final refreshDio = Dio(BaseOptions());
    refreshDio.httpClientAdapter = adapter;

    final dio = Dio(BaseOptions(baseUrl: 'http://example.com'));
    dio.httpClientAdapter = adapter;
    dio.interceptors.add(
      AuthInterceptor(storage, baseUrl: 'http://example.com', refreshDio: refreshDio),
    );

    final futures = [dio.get('/users/me'), dio.get('/users/me')];
    final responses = await Future.wait(futures);

    expect(responses[0].statusCode, 200);
    expect(responses[1].statusCode, 200);
    expect(userCalls, 4);
  });
}
