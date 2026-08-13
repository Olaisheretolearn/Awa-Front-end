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
    var refreshCalls = 0;
    final adapter = MockHttpClientAdapter((options) async {
      if (options.path == '/auth/refresh') {
        refreshCalls += 1;
        return ResponseBody.fromString(
          jsonEncode(
              {'accessToken': 'fresh-access', 'refreshToken': 'fresh-refresh'}),
          200,
          headers: <String, List<String>>{},
        );
      }

      if (options.path == '/users/me') {
        userCalls += 1;
        if (options.headers['Authorization'] == 'Bearer stale-access') {
          return ResponseBody.fromString('', 401,
              headers: <String, List<String>>{});
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

      return ResponseBody.fromString('not found', 404,
          headers: <String, List<String>>{});
    });

    final refreshDio = Dio(BaseOptions());
    refreshDio.httpClientAdapter = adapter;

    final dio = Dio(BaseOptions(baseUrl: 'http://example.com'));
    dio.httpClientAdapter = adapter;
    dio.interceptors.add(
      AuthInterceptor(storage,
          baseUrl: 'http://example.com', refreshDio: refreshDio),
    );

    final futures = [dio.get('/users/me'), dio.get('/users/me')];
    final responses = await Future.wait(futures);

    expect(responses[0].statusCode, 200);
    expect(responses[1].statusCode, 200);
    expect(userCalls, 4);
    expect(refreshCalls, 1);
    expect(await storage.access, 'fresh-access');
    expect(await storage.refresh, 'fresh-refresh');
  });

  test('refreshes an expired JWT before sending a protected request', () async {
    final storage = FakeAuthStorage();
    await storage.saveTokens(_jwt(exp: 1), 'stale-refresh');

    var refreshCalls = 0;
    var userCalls = 0;
    final adapter = MockHttpClientAdapter((options) async {
      if (options.path == '/auth/refresh') {
        refreshCalls += 1;
        return ResponseBody.fromString(
          jsonEncode({
            'data': {
              'access_token': 'fresh-access',
              'refresh_token': 'fresh-refresh',
            },
          }),
          200,
          headers: <String, List<String>>{},
        );
      }

      if (options.path == '/users/me') {
        userCalls += 1;
        final status = options.headers['Authorization'] == 'Bearer fresh-access'
            ? 200
            : 401;
        return ResponseBody.fromString('{}', status,
            headers: <String, List<String>>{});
      }

      return ResponseBody.fromString('not found', 404,
          headers: <String, List<String>>{});
    });

    final refreshDio = Dio(BaseOptions())..httpClientAdapter = adapter;
    final dio = Dio(BaseOptions(baseUrl: 'http://example.com'))
      ..httpClientAdapter = adapter;
    dio.interceptors.add(
      AuthInterceptor(storage,
          baseUrl: 'http://example.com', refreshDio: refreshDio),
    );

    final response = await dio.get('/users/me');

    expect(response.statusCode, 200);
    expect(userCalls, 1);
    expect(refreshCalls, 1);
  });

  test('a late stale 401 reuses the token refreshed by another request',
      () async {
    final storage = FakeAuthStorage();
    await storage.saveTokens('stale-access', 'stale-refresh');

    final slowRequestStarted = Completer<void>();
    final releaseSlowResponse = Completer<void>();
    var refreshCalls = 0;

    final adapter = MockHttpClientAdapter((options) async {
      if (options.path == '/auth/refresh') {
        refreshCalls += 1;
        return ResponseBody.fromString(
          jsonEncode(
              {'accessToken': 'fresh-access', 'refreshToken': 'fresh-refresh'}),
          200,
          headers: <String, List<String>>{},
        );
      }

      final isStale = options.headers['Authorization'] == 'Bearer stale-access';
      if (options.path == '/slow' && isStale) {
        slowRequestStarted.complete();
        await releaseSlowResponse.future;
        return ResponseBody.fromString('', 401,
            headers: <String, List<String>>{});
      }
      if (options.path == '/fast' && isStale) {
        return ResponseBody.fromString('', 401,
            headers: <String, List<String>>{});
      }
      if ((options.path == '/slow' || options.path == '/fast') && !isStale) {
        return ResponseBody.fromString('{}', 200,
            headers: <String, List<String>>{});
      }

      return ResponseBody.fromString('not found', 404,
          headers: <String, List<String>>{});
    });

    final refreshDio = Dio(BaseOptions())..httpClientAdapter = adapter;
    final dio = Dio(BaseOptions(baseUrl: 'http://example.com'))
      ..httpClientAdapter = adapter;
    dio.interceptors.add(
      AuthInterceptor(storage,
          baseUrl: 'http://example.com', refreshDio: refreshDio),
    );

    final slowResponse = dio.get('/slow');
    await slowRequestStarted.future;
    final fastResponse = await dio.get('/fast');
    releaseSlowResponse.complete();

    expect(fastResponse.statusCode, 200);
    expect((await slowResponse).statusCode, 200);
    expect(refreshCalls, 1);
  });

  test('a transient refresh failure preserves the stored session', () async {
    final storage = FakeAuthStorage();
    await storage.saveTokens('stale-access', 'stale-refresh');

    var unauthorizedCalls = 0;
    final adapter = MockHttpClientAdapter((options) async {
      if (options.path == '/auth/refresh') {
        return ResponseBody.fromString('', 503,
            headers: <String, List<String>>{});
      }
      return ResponseBody.fromString('', 401,
          headers: <String, List<String>>{});
    });

    final refreshDio = Dio(BaseOptions())..httpClientAdapter = adapter;
    final dio = Dio(BaseOptions(baseUrl: 'http://example.com'))
      ..httpClientAdapter = adapter;
    dio.interceptors.add(
      AuthInterceptor(
        storage,
        baseUrl: 'http://example.com',
        refreshDio: refreshDio,
        onUnauthorized: () async => unauthorizedCalls += 1,
      ),
    );

    await expectLater(dio.get('/users/me'), throwsA(isA<DioException>()));
    expect(await storage.access, 'stale-access');
    expect(await storage.refresh, 'stale-refresh');
    expect(unauthorizedCalls, 0);
  });

  test('an invalid refresh token invalidates concurrent requests once',
      () async {
    final storage = FakeAuthStorage();
    await storage.saveTokens('stale-access', 'invalid-refresh');

    final slowRequestStarted = Completer<void>();
    final releaseSlowResponse = Completer<void>();
    var refreshCalls = 0;
    var unauthorizedCalls = 0;

    final adapter = MockHttpClientAdapter((options) async {
      if (options.path == '/auth/refresh') {
        refreshCalls += 1;
        return ResponseBody.fromString('', 401,
            headers: <String, List<String>>{});
      }
      if (options.path == '/slow') {
        slowRequestStarted.complete();
        await releaseSlowResponse.future;
      }
      return ResponseBody.fromString('', 401,
          headers: <String, List<String>>{});
    });

    final refreshDio = Dio(BaseOptions())..httpClientAdapter = adapter;
    final dio = Dio(BaseOptions(baseUrl: 'http://example.com'))
      ..httpClientAdapter = adapter;
    dio.interceptors.add(
      AuthInterceptor(
        storage,
        baseUrl: 'http://example.com',
        refreshDio: refreshDio,
        onUnauthorized: () async => unauthorizedCalls += 1,
      ),
    );

    final slowRequest = dio.get('/slow');
    await slowRequestStarted.future;
    await expectLater(dio.get('/fast'), throwsA(isA<DioException>()));
    releaseSlowResponse.complete();
    await expectLater(slowRequest, throwsA(isA<DioException>()));

    expect(refreshCalls, 1);
    expect(unauthorizedCalls, 1);
    expect(await storage.access, isNull);
    expect(await storage.refresh, isNull);
  });

  test('a deployed server missing the refresh route clears the stale session',
      () async {
    final storage = FakeAuthStorage();
    await storage.saveTokens('stale-access', 'stale-refresh');

    var unauthorizedCalls = 0;
    final adapter = MockHttpClientAdapter((options) async {
      if (options.path == '/auth/refresh') {
        return ResponseBody.fromString(
          jsonEncode({
            'code': 'SERVER_ERROR',
            'message': 'No static resource api/auth/refresh.',
          }),
          500,
          headers: <String, List<String>>{},
        );
      }
      return ResponseBody.fromString('', 401,
          headers: <String, List<String>>{});
    });

    final refreshDio = Dio(BaseOptions())..httpClientAdapter = adapter;
    final dio = Dio(BaseOptions(baseUrl: 'http://example.com'))
      ..httpClientAdapter = adapter;
    dio.interceptors.add(
      AuthInterceptor(
        storage,
        baseUrl: 'http://example.com',
        refreshDio: refreshDio,
        onUnauthorized: () async => unauthorizedCalls += 1,
      ),
    );

    await expectLater(dio.get('/users/me'), throwsA(isA<DioException>()));
    expect(unauthorizedCalls, 1);
    expect(await storage.access, isNull);
    expect(await storage.refresh, isNull);
  });
}

String _jwt({required int exp}) {
  String encode(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');

  return '${encode({'alg': 'none'})}.${encode({'exp': exp})}.';
}
