import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'auth_storage.dart';
import 'auth_interceptor.dart';
import 'session_controller.dart';

class ApiClient {
  static const _defaultOrigin = 'https://awa-pp4u.onrender.com';

  final Dio dio;
  final AuthStorage storage;
  final AuthInterceptor authInterceptor;

  static ApiClient? _shared;

  ApiClient._(this.dio, this.storage, this.authInterceptor);

  factory ApiClient.dev() {
    final existing = _shared;
    if (existing != null) return existing;
    const envBase = String.fromEnvironment('API_BASE');

    final base = envBase.isNotEmpty ? envBase : _defaultOrigin;

    final storage = AuthStorage();
    final dio = Dio(
      BaseOptions(
        baseUrl: '$base/api',
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Content-Type': 'application/json'},
        receiveDataWhenStatusError: true,
      ),
    );

    final authInterceptor = AuthInterceptor(
      storage,
      baseUrl: '$base/api',
      onUnauthorized: SessionController.instance.markSignedOut,
    );
    dio.interceptors.add(authInterceptor);

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
        ),
      );
    }

    return _shared = ApiClient._(dio, storage, authInterceptor);
  }

  static String get origin {
    const envBase = String.fromEnvironment('API_BASE');
    if (envBase.isNotEmpty) return envBase;
    return _defaultOrigin;
  }
}
