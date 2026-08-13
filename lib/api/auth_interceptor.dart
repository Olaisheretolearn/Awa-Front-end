// lib/api/auth_interceptor.dart
import 'dart:convert';

import 'package:dio/dio.dart';
import 'auth_storage.dart';

typedef OnUnauthorized = Future<void> Function();

enum _RefreshResult { succeeded, invalidSession, unavailable }

class AuthInterceptor extends Interceptor {
  static const _retriedKey = 'awa.auth.retried';
  static const _refreshWindow = Duration(seconds: 30);

  final AuthStorage storage;
  final Dio _refreshDio;
  final OnUnauthorized? onUnauthorized;

  Future<_RefreshResult>? _refreshFuture;
  bool _sessionInvalidated = false;

  AuthInterceptor(
    this.storage, {
    required String baseUrl,
    this.onUnauthorized,
    Dio? refreshDio,
  }) : _refreshDio = refreshDio ??
            Dio(BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 20),
              headers: {'Content-Type': 'application/json'},
              receiveDataWhenStatusError: true,
            ));

  /// Allows a successful interactive login to start a fresh refresh cycle.
  void markSignedIn() {
    _sessionInvalidated = false;
  }

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    var token = await storage.access;

    // Refresh before a protected request when the JWT is about to expire. The
    // 401 handler remains as a fallback for opaque tokens and clock skew.
    if (!_sessionInvalidated &&
        !_isPublicAuthRequest(options.path) &&
        token != null &&
        token.isNotEmpty &&
        _expiresSoon(token)) {
      final result = await _refreshSession(staleAccessToken: token);
      if (result == _RefreshResult.succeeded) {
        token = await storage.access;
      }
    }

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    final request = err.requestOptions;

    if (status == 401 &&
        !_sessionInvalidated &&
        !_isPublicAuthRequest(request.path) &&
        request.extra[_retriedKey] != true) {
      final sentAccess = _bearerToken(request.headers['Authorization']);
      final currentAccess = await storage.access;

      // This response may belong to a request sent just before another request
      // completed a refresh. Retry with the already-refreshed access token
      // instead of rotating the refresh token a second time.
      if (sentAccess != null &&
          currentAccess != null &&
          currentAccess.isNotEmpty &&
          sentAccess != currentAccess) {
        return _retry(request, currentAccess, err, handler);
      }

      final refreshResult = await _refreshSession(staleAccessToken: sentAccess);

      if (refreshResult == _RefreshResult.succeeded) {
        final newAT = await storage.access;
        if (newAT != null && newAT.isNotEmpty) {
          return _retry(request, newAT, err, handler);
        }
      }
    }

    handler.next(err);
  }

  Future<_RefreshResult> _refreshSession({String? staleAccessToken}) async {
    if (_sessionInvalidated) return _RefreshResult.invalidSession;

    var existing = _refreshFuture;
    if (existing != null) return existing;

    if (staleAccessToken != null) {
      final latestAccess = await storage.access;
      if (latestAccess != null &&
          latestAccess.isNotEmpty &&
          latestAccess != staleAccessToken) {
        return _RefreshResult.succeeded;
      }

      // A refresh may have started while secure storage was being read.
      existing = _refreshFuture;
      if (existing != null) return existing;
      if (_sessionInvalidated) return _RefreshResult.invalidSession;
    }

    final refresh = _refreshAndHandleInvalidSession();
    _refreshFuture = refresh;

    try {
      return await refresh;
    } finally {
      if (identical(_refreshFuture, refresh)) {
        _refreshFuture = null;
      }
    }
  }

  Future<_RefreshResult> _refreshAndHandleInvalidSession() async {
    final result = await _tryRefresh();
    if (result == _RefreshResult.invalidSession && !_sessionInvalidated) {
      // This method is shared by every request waiting for the same refresh,
      // so clearing state and navigating to sign-in happen only once.
      _sessionInvalidated = true;
      await storage.clear();
      if (onUnauthorized != null) await onUnauthorized!();
    }
    return result;
  }

  Future<_RefreshResult> _tryRefresh() async {
    final rt = await storage.refresh;
    if (rt == null || rt.isEmpty) return _RefreshResult.invalidSession;

    try {
      final res = await _refreshDio.post('/auth/refresh', data: {
        'refreshToken': rt,
      });

      final body = _responseBody(res.data);
      final access = _tokenValue(body, const ['accessToken', 'access_token']);
      final refresh =
          _tokenValue(body, const ['refreshToken', 'refresh_token']) ?? rt;

      if (access == null || access.isEmpty) return _RefreshResult.unavailable;
      await storage.saveTokens(access, refresh);
      return _RefreshResult.succeeded;
    } on DioException catch (err) {
      final status = err.response?.statusCode;
      return status == 400 ||
              status == 401 ||
              status == 403 ||
              status == 404 ||
              status == 405 ||
              _isMissingRefreshEndpoint(err.response?.data)
          ? _RefreshResult.invalidSession
          : _RefreshResult.unavailable;
    } catch (_) {
      return _RefreshResult.unavailable;
    }
  }

  Future<void> _retry(
    RequestOptions request,
    String accessToken,
    DioException originalError,
    ErrorInterceptorHandler handler,
  ) async {
    final retryOptions = request.copyWith(
      extra: <String, dynamic>{...request.extra, _retriedKey: true},
      headers: <String, dynamic>{
        ...request.headers,
        'Authorization': 'Bearer $accessToken',
      },
    );

    try {
      final response = await _refreshDio.fetch(retryOptions);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    } catch (_) {
      handler.next(originalError);
    }
  }

  bool _expiresSoon(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;

      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (payload is! Map) return false;

      final rawExpiry = payload['exp'];
      final expiry = rawExpiry is num
          ? rawExpiry.toInt()
          : int.tryParse(rawExpiry?.toString() ?? '');
      if (expiry == null) return false;

      final refreshAt = DateTime.now().toUtc().add(_refreshWindow);
      return DateTime.fromMillisecondsSinceEpoch(
        expiry * 1000,
        isUtc: true,
      ).isBefore(refreshAt);
    } catch (_) {
      // Some backends use opaque access tokens. Those are refreshed on 401.
      return false;
    }
  }

  bool _isPublicAuthRequest(String path) {
    return path.endsWith('/auth/login') ||
        path.endsWith('/auth/refresh') ||
        path.endsWith('/users/register');
  }

  String? _bearerToken(dynamic authorization) {
    if (authorization is! String) return null;
    final match = RegExp(r'^Bearer\s+(.+)$', caseSensitive: false)
        .firstMatch(authorization.trim());
    return match?.group(1);
  }

  Map<dynamic, dynamic> _responseBody(dynamic responseData) {
    dynamic decoded = responseData;
    if (decoded is String) {
      try {
        decoded = jsonDecode(decoded);
      } catch (_) {
        return const <dynamic, dynamic>{};
      }
    }
    if (decoded is! Map) return const <dynamic, dynamic>{};
    final nested = decoded['data'];
    return nested is Map ? nested : decoded;
  }

  String? _tokenValue(Map<dynamic, dynamic> body, List<String> keys) {
    for (final key in keys) {
      final value = body[key];
      if (value is String && value.isNotEmpty) return value;
    }
    return null;
  }

  bool _isMissingRefreshEndpoint(dynamic responseData) {
    final body = _responseBody(responseData);
    final message = body['message']?.toString().toLowerCase() ?? '';
    return message.contains('no static resource') &&
        message.contains('auth/refresh');
  }
}
