// lib/api/models.dart
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  AuthResponse({required this.accessToken, required this.refreshToken});
  factory AuthResponse.fromJson(Map<String, dynamic> j) =>
      AuthResponse(accessToken: j['accessToken'], refreshToken: j['refreshToken']);
}

class UserResponse {
  final String id;
  final String firstName;
  final String email;
  final String createdAt;
  final String? roomId;
  final String role;
  final String? avatarId;
  final String? avatarImageUrl;

  UserResponse({
    required this.id,
    required this.firstName,
    required this.email,
    required this.createdAt,
    required this.role,
    this.roomId,
    this.avatarId,
    this.avatarImageUrl,
  });

  factory UserResponse.fromJson(Map<String, dynamic> j) => UserResponse(
        id: j['id'],
        firstName: j['firstName'],
        email: j['email'],
        createdAt: j['createdAt'],
        roomId: j['roomId'],
        role: j['role'],
        avatarId: j['avatarId'],
        avatarImageUrl: j['avatarImageUrl'],
      );

       UserResponse copyWith({
    String? id,
    String? firstName,
    String? email,
    String? createdAt,
    String? role,
    String? roomId,
    String? avatarId,
    String? avatarImageUrl,
  }) {
    return UserResponse(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      role: role ?? this.role,
      roomId: roomId ?? this.roomId,
      avatarId: avatarId ?? this.avatarId,
      avatarImageUrl: avatarImageUrl ?? this.avatarImageUrl,
    );
  }
}


class RoomResponse {
  final String id;
  final String name;
  final String code;
  final String ownerId;
  final String? city;
  final String createdAt;

  RoomResponse({
    required this.id,
    required this.name,
    required this.code,
    required this.ownerId,
    required this.createdAt,
    this.city,
  });

  factory RoomResponse.fromJson(Map<String, dynamic> j) => RoomResponse(
        id: j['id'],
        name: j['name'],
        code: j['code'],
        ownerId: j['ownerId'],
        city: j['city'],
        createdAt: j['createdAt'],
      );
}

class MyRoomResponse {
  final RoomResponse? room;
  final List<UserResponse> members;

  MyRoomResponse({required this.room, required this.members});

  factory MyRoomResponse.fromJson(Map<String, dynamic> j) => MyRoomResponse(
        room: j['room'] == null ? null : RoomResponse.fromJson(j['room']),
        members: (j['members'] as List)
            .map((e) => UserResponse.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}


