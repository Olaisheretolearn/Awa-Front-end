import 'package:dio/dio.dart';
import 'auth_storage.dart';


typedef OnUnauthorized = Future<void> Function();

class AuthInterceptor extends Interceptor {
  final AuthStorage storage;
  final OnUnauthorized? onUnauthorized;

  AuthInterceptor(this.storage, {this.onUnauthorized});

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
    final path = err.requestOptions.path;

    
    final isApi = path.startsWith('/api/');
    final isUnauthorized = status == 401;

    if (isApi && isUnauthorized) {
      // Clear creds
      await storage.clear();

      
      if (onUnauthorized != null) {
        await onUnauthorized!();
      }

      // We’re done; still pass the error along
      return handler.next(err);
    }


    return handler.next(err);
  }
}
