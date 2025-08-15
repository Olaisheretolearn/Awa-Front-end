// lib/api/auth_api.dart
import 'package:dio/dio.dart';
import 'client.dart';
import 'model.dart';

class AuthApi {
  final ApiClient _c;
  AuthApi(this._c);

  Future<UserResponse> signUp({
    required String firstName,
    required String email,
    required String password,
  }) async {
    final res = await _c.dio.post('/users/register', data: {
      'firstName': firstName,
      'email': email,
      'password': password,
    });
    return UserResponse.fromJson(res.data);
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final res = await _c.dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final auth = AuthResponse.fromJson(res.data);
    await _c.storage.saveTokens(auth.accessToken, auth.refreshToken);
    return auth;
  }

  Future<UserResponse> getUserById(String id) async {
    final res = await _c.dio.get('/users/$id');
    return UserResponse.fromJson(res.data);
  }

  Future<UserResponse> getMe() async {
    final res = await _c.dio.get('/users/me');
    return UserResponse.fromJson(res.data);
  }

  Future<UserResponse> setAvatar({
    required String userId,
    required String avatarId,
  }) async {
    final res = await _c.dio.patch('/users/$userId', data: {'avatarId': avatarId});
    return UserResponse.fromJson(res.data);
  }

  Future<void> signOut() => _c.storage.clear();
}
