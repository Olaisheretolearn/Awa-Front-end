import 'package:dio/dio.dart';
import 'client.dart';
import 'model.dart';

class RoomApi {
  final ApiClient _c;
  RoomApi(this._c);

  // POST /api/rooms
  Future<RoomResponse> createRoom({
    required String name,
    required String ownerId,
    String? city,
  }) async {
    final res = await _c.dio.post(
      '/rooms',
      data: {
        'name': name,
        'ownerID': ownerId,
        'city': city,
      },
    );
    return RoomResponse.fromJson(res.data as Map<String, dynamic>);
  }

  // GET /api/rooms/me  (Authorization header provided by your AuthInterceptor)
  Future<MyRoomResponse> getMyRoom() async {
    final res = await _c.dio.get('/rooms/me');
    return MyRoomResponse.fromJson(res.data as Map<String, dynamic>);
  }

  // POST /api/users/{userId}/join-room
  Future<UserResponse> joinRoom({
    required String userId,
    required String code,
  }) async {
    final res = await _c.dio.post('/users/$userId/join-room', data: {'code': code});
    return UserResponse.fromJson(res.data as Map<String, dynamic>);
  }

  // PATCH /api/users/{userId}/leave-room
  Future<UserResponse> leaveRoom(String userId) async {
    final res = await _c.dio.patch('/users/$userId/leave-room');
    return UserResponse.fromJson(res.data as Map<String, dynamic>);
  }


  // GET /api/rooms/{roomId}/members
Future<List<UserResponse>> getMembers(String roomId) async {

    final res = await _c.dio.get('/rooms/$roomId/members');
    final data = (res.data as List).cast<Map<String, dynamic>>();
    return data.map(UserResponse.fromJson).toList();
  }

  Future<RoomResponse> getRoom(String roomId) async {
  final res = await _c.dio.get('/rooms/$roomId');
  return RoomResponse.fromJson(res.data as Map<String, dynamic>);
}


  // GET /api/rooms/{code}
  Future<RoomResponse> getRoomByCode(String code) async {
    final res = await _c.dio.get('/rooms/$code');
    return RoomResponse.fromJson(res.data as Map<String, dynamic>);
  }

  // PATCH /api/rooms/{roomId}
  Future<RoomResponse> updateRoom(
    String roomId, {
    String? name,
    String? code,
    String? city,
  }) async {
    final res = await _c.dio.patch('/rooms/$roomId', data: {
      if (name != null) 'name': name,
      if (code != null) 'code': code,
      if (city != null) 'city': city,
    });
    return RoomResponse.fromJson(res.data as Map<String, dynamic>);
  }
}
