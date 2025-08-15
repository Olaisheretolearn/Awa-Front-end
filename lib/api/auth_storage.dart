import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorage {
  final _s = const FlutterSecureStorage();

  Future<void> saveTokens(String access, String refresh) async {
    await _s.write(key: 'access', value: access);
    await _s.write(key: 'refresh', value: refresh);
  }

  Future<String?> get access async => _s.read(key: 'access');
  Future<String?> get refresh async => _s.read(key: 'refresh');

  Future<void> clear() async {
    await _s.delete(key: 'access');
    await _s.delete(key: 'refresh');
  }
}