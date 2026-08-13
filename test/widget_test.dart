import 'package:awa_app/api/model.dart';
import 'package:awa_app/api/session_controller.dart';
import 'package:awa_app/main.dart';
import 'package:awa_app/navigation/room_required_route.dart';
import 'package:awa_app/screens/create_join_flat_screen.dart';
import 'package:awa_app/screens/home_screen.dart';
import 'package:awa_app/state/app_flow_controller.dart';
import 'package:awa_app/state/app_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('relaunch with a valid session and no room shows room setup',
      (tester) async {
    final controller = _noRoomController();

    await tester.pumpWidget(MyApp(controller: controller));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(CreateJoinFlatScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    controller.dispose();
  });

  testWidgets('room-required route does not construct its feature without room',
      (tester) async {
    final controller = _noRoomController();
    await controller.bootstrap();
    var featureWasBuilt = false;

    await tester.pumpWidget(
      AppScope(
        controller: controller,
        child: MaterialApp(
          home: RoomRequired(
            builder: (_, __) {
              featureWasBuilt = true;
              return const Scaffold(body: Text('Protected feature'));
            },
          ),
        ),
      ),
    );

    expect(featureWasBuilt, isFalse);
    expect(find.text('Create or join a room to continue.'), findsOneWidget);
    controller.dispose();
  });
}

AppFlowController _noRoomController() {
  return AppFlowController(
    sessionController: SessionController.test(hasStoredSession: true),
    repository: _NoRoomRepository(),
    observeLifecycle: false,
  );
}

class _NoRoomRepository implements AppFlowRepository {
  @override
  Future<UserResponse> getMe() async => UserResponse(
        id: 'user-1',
        firstName: 'Awa',
        email: 'awa@example.com',
        createdAt: '2026-01-01T00:00:00Z',
        role: 'MEMBER',
        avatarId: 'AVA_01',
      );

  @override
  Future<MyRoomResponse> getMyRoom() async =>
      MyRoomResponse(room: null, members: const []);

  @override
  Future<void> signOut() async {}
}
