import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';

class AuthStorage {
  final _s = const FlutterSecureStorage();

  Future<void> saveTokens(String access, String refresh) async {
    // Persist the refresh token first. If the app is interrupted between these
    // writes, a new access token can still be obtained from the new refresh
    // token. The opposite order can leave a rotated (and therefore unusable)
    // refresh token behind.
    await _s.write(key: 'refresh', value: refresh);
    await _s.write(key: 'access', value: access);
  }

  Future<String?> get access => _readToken('access');
  Future<String?> get refresh => _readToken('refresh');

  /// A token encrypted with a previous Android keystore key cannot be read
  /// (for example, after reinstalling a differently signed build). Treat it
  /// as an expired session rather than allowing the request interceptor to
  /// crash the app.
  Future<String?> _readToken(String key) async {
    try {
      return await _s.read(key: key);
    } on PlatformException {
      await _clearCorruptTokens();
      return null;
    }
  }

  Future<void> clear() async {
    await _s.delete(key: 'access');
    await _s.delete(key: 'refresh');
  }

  Future<void> _clearCorruptTokens() async {
    try {
      await clear();
    } on PlatformException {
      // There is no usable session to preserve; subsequent reads can proceed.
    }
  }
}
