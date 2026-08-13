import 'package:flutter/foundation.dart';

import '../api/model.dart';

enum AppFlowStatus {
  initializing,
  resolving,
  signedOut,
  profileSetupRequired,
  roomSetupRequired,
  roomReady,
  error,
}

@immutable
class RoomSession {
  RoomSession({
    required this.currentUser,
    required this.room,
    required List<UserResponse> members,
  })  : assert(room.id.trim().isNotEmpty),
        members = List<UserResponse>.unmodifiable(members);

  final UserResponse currentUser;
  final RoomResponse room;
  final List<UserResponse> members;

  String get roomId => room.id;
  String get userId => currentUser.id;
}
