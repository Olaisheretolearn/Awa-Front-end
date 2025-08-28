// lib/api/auth_interceptor.dart
import 'package:dio/dio.dart';
import 'auth_storage.dart';

typedef OnUnauthorized = Future<void> Function();

class AuthInterceptor extends Interceptor {
  final AuthStorage storage;
  final Dio _refreshDio;
  final OnUnauthorized? onUnauthorized;

  bool _refreshing = false;

  AuthInterceptor(this.storage, {this.onUnauthorized})
      : _refreshDio = Dio(BaseOptions(
          baseUrl: "https://awa-pp4u.onrender.com/api", 
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
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
    final isApi = err.requestOptions.path.startsWith('/api');

    if (status == 401 && isApi) {
      if (_refreshing) {
   
        return handler.next(err);
      }

      _refreshing = true;
      final ok = await _tryRefresh();
      _refreshing = false;

      if (ok) {
       
        final newAT = await storage.access;
        err.requestOptions.headers['Authorization'] = 'Bearer $newAT';
        final clone = await _refreshDio.request(
          err.requestOptions.path,
          data: err.requestOptions.data,
          queryParameters: err.requestOptions.queryParameters,
          options: Options(method: err.requestOptions.method),
        );
        return handler.resolve(clone);
      } else {
        await storage.clear();
        if (onUnauthorized != null) await onUnauthorized!();
      }
    }

    return handler.next(err);
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
