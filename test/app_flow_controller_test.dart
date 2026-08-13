import 'package:awa_app/api/model.dart';
import 'package:awa_app/api/session_controller.dart';
import 'package:awa_app/state/app_flow_controller.dart';
import 'package:awa_app/state/app_flow_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppFlowController', () {
    test('does not call account APIs when there is no stored session',
        () async {
      final repository = _FakeAppFlowRepository(room: null);
      final controller = _controller(
        hasStoredSession: false,
        repository: repository,
      );

      await controller.bootstrap();

      expect(controller.status, AppFlowStatus.signedOut);
      expect(repository.getMeCalls, 0);
      expect(repository.getMyRoomCalls, 0);
      controller.dispose();
    });

    test('valid session without a room requires room setup', () async {
      final repository = _FakeAppFlowRepository(room: null);
      final controller = _controller(repository: repository);

      await controller.bootstrap();

      expect(controller.status, AppFlowStatus.roomSetupRequired);
      expect(controller.currentUser?.id, 'user-1');
      expect(controller.currentRoom, isNull);
      expect(controller.roomSession, isNull);
      expect(repository.getMeCalls, 1);
      expect(repository.getMyRoomCalls, 1);
      controller.dispose();
    });

    test('valid session with a room becomes room ready', () async {
      final room = _room();
      final repository = _FakeAppFlowRepository(room: room);
      final controller = _controller(repository: repository);

      await controller.bootstrap();

      expect(controller.status, AppFlowStatus.roomReady);
      expect(controller.roomSession?.roomId, room.id);
      expect(controller.roomSession?.userId, 'user-1');
      controller.dispose();
    });

    test('room lookup failure is an error, not a no-room state', () async {
      final repository = _FakeAppFlowRepository(
        room: null,
        roomError: StateError('network unavailable'),
      );
      final controller = _controller(repository: repository);

      await controller.bootstrap();

      expect(controller.status, AppFlowStatus.error);
      expect(controller.currentRoom, isNull);
      controller.dispose();
    });

    test('losing room membership removes the room session', () async {
      final repository = _FakeAppFlowRepository(room: _room());
      final controller = _controller(repository: repository);
      await controller.bootstrap();
      expect(controller.status, AppFlowStatus.roomReady);

      repository.room = null;
      await controller.resolveAuthenticatedState();

      expect(controller.status, AppFlowStatus.roomSetupRequired);
      expect(controller.roomSession, isNull);
      controller.dispose();
    });

    test('session invalidation clears user and room state', () async {
      final session = SessionController.test(hasStoredSession: true);
      final repository = _FakeAppFlowRepository(room: _room());
      final controller = AppFlowController(
        sessionController: session,
        repository: repository,
        observeLifecycle: false,
      );
      await controller.bootstrap();

      await session.markSignedOut();

      expect(controller.status, AppFlowStatus.signedOut);
      expect(controller.currentUser, isNull);
      expect(controller.currentRoom, isNull);
      controller.dispose();
    });
  });
}

AppFlowController _controller({
  bool hasStoredSession = true,
  required _FakeAppFlowRepository repository,
}) {
  return AppFlowController(
    sessionController:
        SessionController.test(hasStoredSession: hasStoredSession),
    repository: repository,
    observeLifecycle: false,
  );
}

UserResponse _user() => UserResponse(
      id: 'user-1',
      firstName: 'Awa',
      email: 'awa@example.com',
      createdAt: '2026-01-01T00:00:00Z',
      role: 'MEMBER',
      avatarId: 'AVA_01',
    );

RoomResponse _room() => RoomResponse(
      id: 'room-1',
      name: 'Our room',
      code: 'ABC123',
      ownerId: 'user-1',
      createdAt: '2026-01-01T00:00:00Z',
    );

class _FakeAppFlowRepository implements AppFlowRepository {
  _FakeAppFlowRepository({required this.room, this.roomError});

  RoomResponse? room;
  Object? roomError;
  int getMeCalls = 0;
  int getMyRoomCalls = 0;

  @override
  Future<UserResponse> getMe() async {
    getMeCalls++;
    return _user();
  }

  @override
  Future<MyRoomResponse> getMyRoom() async {
    getMyRoomCalls++;
    final error = roomError;
    if (error != null) throw error;
    return MyRoomResponse(
      room: room,
      members: room == null ? const [] : [_user()],
    );
  }

  @override
  Future<void> signOut() async {}
}
