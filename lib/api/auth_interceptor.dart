// lib/api/auth_interceptor.dart
import 'package:dio/dio.dart';
import 'auth_storage.dart';

typedef OnUnauthorized = Future<void> Function();

class AuthInterceptor extends Interceptor {
  final AuthStorage storage;
  final Dio _refreshDio;
  final OnUnauthorized? onUnauthorized;

  bool _refreshing = false;
  Future<bool>? _refreshFuture;

  AuthInterceptor(
    this.storage, {
    required String baseUrl,
    this.onUnauthorized,
    Dio? refreshDio,
  }) : _refreshDio = refreshDio ??
            Dio(BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              headers: {'Content-Type': 'application/json'},
              receiveDataWhenStatusError: true,
            ));

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await storage.access;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;

    if ((status == 401 || status == 403) &&
        err.requestOptions.path != '/auth/refresh') {
      final ok = await _refreshSession();

      if (ok) {
        final retryOptions = err.requestOptions.copyWith();
        final newAT = await storage.access;
        if (newAT != null && newAT.isNotEmpty) {
          retryOptions.headers['Authorization'] = 'Bearer $newAT';
        }

        try {
          final clone = await _refreshDio.fetch(retryOptions);
          return handler.resolve(clone);
        } catch (_) {
          return handler.next(err);
        }
      }

      await storage.clear();
      if (onUnauthorized != null) await onUnauthorized!();
    }

    return handler.next(err);
  }

  Future<bool> _refreshSession() async {
    if (_refreshFuture != null) {
      return _refreshFuture!;
    }

    _refreshing = true;
    _refreshFuture = _tryRefresh();

    final ok = await _refreshFuture!;
    _refreshing = false;
    _refreshFuture = null;
    return ok;
  }

  Future<bool> _tryRefresh() async {
    final rt = await storage.refresh;
    if (rt == null || rt.isEmpty) return false;

    try {
      final res = await _refreshDio.post('/auth/refresh', data: {
        'refreshToken': rt,
      });

      final access = res.data['accessToken'] as String?;
      final refresh = res.data['refreshToken'] as String? ?? rt;

      if (access == null) return false;
      await storage.saveTokens(access, refresh);
      return true;
    } catch (_) {
      return false;
    }
  }
}
