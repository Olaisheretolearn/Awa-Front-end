import 'package:flutter/foundation.dart';

import 'auth_storage.dart';

/// Holds the app-wide authentication state. Network clients use this to tell
/// the root navigator that a refresh token was rejected.
class SessionController extends ChangeNotifier {
  SessionController._();

  static final SessionController instance = SessionController._();

  bool? _hasStoredSession;
  bool _wasInvalidated = false;

  bool? get hasStoredSession => _hasStoredSession;

  Future<void> restore() async {
    final storage = AuthStorage();
    final access = await storage.access;
    final refresh = await storage.refresh;
    _hasStoredSession = (access?.isNotEmpty ?? false) ||
        (refresh?.isNotEmpty ?? false);
    _wasInvalidated = false;
    notifyListeners();
  }

  void markSignedIn() {
    _hasStoredSession = true;
    _wasInvalidated = false;
    notifyListeners();
  }

  Future<void> markSignedOut() async {
    _hasStoredSession = false;
    _wasInvalidated = true;
    notifyListeners();
  }

  /// Returns true only once for a server-driven invalid session event.
  bool takeInvalidation() {
    if (!_wasInvalidated) return false;
    _wasInvalidated = false;
    return true;
  }
}
