
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'auth_storage.dart';
import 'auth_interceptor.dart';

class ApiClient {
  final Dio dio;
  final AuthStorage storage;

  ApiClient._(this.dio, this.storage);

  factory ApiClient.dev() {
    const envBase = String.fromEnvironment('API_BASE');
    final base = (envBase.isNotEmpty ? envBase : 'http://127.0.0.1:8080');

    final storage = AuthStorage();
    final dio = Dio(
      BaseOptions(
        baseUrl: '$base/api',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
        receiveDataWhenStatusError: true,
      ),
    );

    dio.interceptors.add(AuthInterceptor(storage));



    


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


    return ApiClient._(dio, storage);
    }

    static String get origin {
    const envBase = String.fromEnvironment('API_BASE');
    return (envBase.isNotEmpty ? envBase : 'http://127.0.0.1:8080');
  }


}
