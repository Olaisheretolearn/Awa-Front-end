import 'dart:async';

import 'package:flutter/widgets.dart';

import '../api/auth_api.dart';
import '../api/client.dart';
import '../api/model.dart';
import '../api/room_api.dart';
import '../api/session_controller.dart';
import 'app_flow_state.dart';

abstract class AppFlowRepository {
  Future<UserResponse> getMe();
  Future<MyRoomResponse> getMyRoom();
  Future<void> signOut();
}

class ApiAppFlowRepository implements AppFlowRepository {
  ApiAppFlowRepository({AuthApi? authApi, RoomApi? roomApi})
      : _authApi = authApi ?? AuthApi(ApiClient.dev()),
        _roomApi = roomApi ?? RoomApi(ApiClient.dev());

  final AuthApi _authApi;
  final RoomApi _roomApi;

  @override
  Future<UserResponse> getMe() => _authApi.getMe();

  @override
  Future<MyRoomResponse> getMyRoom() => _roomApi.getMyRoom();

  @override
  Future<void> signOut() => _authApi.signOut();
}

/// The single source of truth for authentication and room membership.
///
/// Room-dependent UI may only be built while [status] is [AppFlowStatus.roomReady].
class AppFlowController extends ChangeNotifier with WidgetsBindingObserver {
  AppFlowController({
    SessionController? sessionController,
    AppFlowRepository? repository,
    bool observeLifecycle = true,
  })  : _session = sessionController ?? SessionController.instance,
        _repository = repository ?? ApiAppFlowRepository(),
        _observeLifecycle = observeLifecycle {
    _session.addListener(_handleSessionChange);
    if (_observeLifecycle) {
      WidgetsBinding.instance.addObserver(this);
    }
  }

  final SessionController _session;
  final AppFlowRepository _repository;
  final bool _observeLifecycle;

  AppFlowStatus _status = AppFlowStatus.initializing;
  UserResponse? _currentUser;
  RoomResponse? _currentRoom;
  List<UserResponse> _currentMembers = const [];
  Object? _lastError;
  Future<bool>? _activeResolution;
  int _resolutionVersion = 0;
  bool _disposed = false;

  AppFlowStatus get status => _status;
  UserResponse? get currentUser => _currentUser;
  RoomResponse? get currentRoom => _currentRoom;
  List<UserResponse> get currentMembers => _currentMembers;
  Object? get lastError => _lastError;

  bool get isAuthenticated =>
      _status != AppFlowStatus.initializing &&
      _status != AppFlowStatus.signedOut;

  RoomSession? get roomSession {
    final user = _currentUser;
    final room = _currentRoom;
    if (_status != AppFlowStatus.roomReady || user == null || room == null) {
      return null;
    }
    return RoomSession(
      currentUser: user,
      room: room,
      members: _currentMembers,
    );
  }

  Future<void> bootstrap() async {
    if (_session.hasStoredSession == null) {
      try {
        await _session.restore();
      } catch (_) {
        await _session.markSignedOut();
      }
    }

    if (_session.hasStoredSession != true) {
      _becomeSignedOut();
      return;
    }

    await resolveAuthenticatedState();
  }

  Future<bool> resolveAuthenticatedState({bool showLoading = true}) {
    final active = _activeResolution;
    if (active != null) return active;

    final resolution = _resolveAuthenticatedState(showLoading: showLoading);
    _activeResolution = resolution;
    unawaited(resolution.whenComplete(() {
      if (identical(_activeResolution, resolution)) {
        _activeResolution = null;
      }
    }));
    return resolution;
  }

  Future<bool> _resolveAuthenticatedState({required bool showLoading}) async {
    if (_session.hasStoredSession != true) {
      _becomeSignedOut();
      return false;
    }

    final previousStatus = _status;
    final version = ++_resolutionVersion;
    if (showLoading || previousStatus != AppFlowStatus.roomReady) {
      _setStatus(AppFlowStatus.resolving);
    }

    try {
      final user = await _repository.getMe();
      final myRoom = await _repository.getMyRoom();

      if (_disposed || version != _resolutionVersion) return false;
      if (_session.hasStoredSession != true) {
        _becomeSignedOut();
        return false;
      }

      final room = myRoom.room;
      final hasValidRoom = room != null && room.id.trim().isNotEmpty;

      _currentUser = user;
      _currentRoom = hasValidRoom ? room : null;
      _currentMembers = hasValidRoom
          ? List<UserResponse>.unmodifiable(myRoom.members)
          : const [];
      _lastError = null;

      if (user.avatarId == null || user.avatarId!.trim().isEmpty) {
        _setStatus(AppFlowStatus.profileSetupRequired);
      } else if (!hasValidRoom) {
        _setStatus(AppFlowStatus.roomSetupRequired);
      } else {
        _setStatus(AppFlowStatus.roomReady);
      }
      return true;
    } catch (error) {
      if (_disposed || version != _resolutionVersion) return false;
      if (_session.hasStoredSession != true) {
        _becomeSignedOut();
        return false;
      }

      if (!showLoading && previousStatus == AppFlowStatus.roomReady) {
        return false;
      }

      _currentUser = null;
      _currentRoom = null;
      _currentMembers = const [];
      _lastError = error;
      _setStatus(AppFlowStatus.error);
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _repository.signOut();
    } finally {
      _becomeSignedOut();
    }
  }

  void _handleSessionChange() {
    if (_disposed) return;
    if (_session.hasStoredSession == false) {
      _becomeSignedOut();
    } else if (_session.hasStoredSession == true &&
        _status == AppFlowStatus.signedOut) {
      unawaited(resolveAuthenticatedState());
    }
  }

  void _becomeSignedOut() {
    _resolutionVersion++;
    _activeResolution = null;
    _currentUser = null;
    _currentRoom = null;
    _currentMembers = const [];
    _lastError = null;
    _setStatus(AppFlowStatus.signedOut);
  }

  void _setStatus(AppFlowStatus next) {
    if (_disposed) return;
    if (_status == next) {
      notifyListeners();
      return;
    }
    _status = next;
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _status == AppFlowStatus.roomReady) {
      unawaited(resolveAuthenticatedState(showLoading: false));
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _resolutionVersion++;
    _session.removeListener(_handleSessionChange);
    if (_observeLifecycle) {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }
}
