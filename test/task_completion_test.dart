import 'dart:async';
import 'dart:convert';

import 'package:awa_app/api/model.dart';
import 'package:awa_app/api/tasks_api.dart';
import 'package:awa_app/api/tasks_models.dart';
import 'package:awa_app/screens/task_screen.dart';
import 'package:awa_app/state/app_flow_state.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('active task request uses the status endpoint and filters defensively',
      () async {
    late RequestOptions capturedRequest;
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.httpClientAdapter = _MockHttpClientAdapter((options) async {
      capturedRequest = options;
      return ResponseBody.fromString(
        jsonEncode([
          _taskJson(id: 'active', complete: false),
          _taskJson(id: 'completed', complete: true),
        ]),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    });

    final tasks = await TasksApi.withDio(dio).listActiveByRoom('room-1');

    expect(capturedRequest.path, '/room/room-1/task/status');
    expect(capturedRequest.queryParameters, {'isComplete': false});
    expect(tasks.map((task) => task.id), ['active']);
  });

  test('completion uses PATCH and returns the persisted completion state',
      () async {
    late RequestOptions capturedRequest;
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.httpClientAdapter = _MockHttpClientAdapter((options) async {
      capturedRequest = options;
      return ResponseBody.fromString(
        jsonEncode(_taskJson(id: 'task-1', complete: true)),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    });

    final task = await TasksApi.withDio(dio).markComplete('room-1', 'task-1');

    expect(capturedRequest.method, 'PATCH');
    expect(capturedRequest.path, '/room/room-1/task/task-1/complete');
    expect(capturedRequest.queryParameters, isEmpty);
    expect(task.isComplete, isTrue);
  });

  testWidgets(
      'completion is sent once and removes the task after server confirmation',
      (tester) async {
    final completion = Completer<TaskDto>();
    final repository = _FakeTasksRepository(
      initialTasks: [
        _task(id: 'active', name: 'Wash dishes'),
        _task(id: 'completed', name: 'Old chore', isComplete: true),
      ],
      completion: completion,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TasksScreen(
          roomSession: _roomSession(),
          tasksRepository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Wash dishes'), findsOneWidget);
    expect(find.text('Old chore'), findsNothing);

    await tester.tap(find.text('Wash dishes'));
    await tester.pump();
    final completeButton = find.widgetWithText(
      ElevatedButton,
      'Mark Complete',
    );
    expect(completeButton, findsOneWidget);

    await tester.tap(completeButton);
    await tester.tap(completeButton);
    await tester.pump();

    expect(repository.completeCalls, 1);
    expect(find.text('Wash dishes'), findsOneWidget);

    completion.complete(
      _task(id: 'active', name: 'Wash dishes', isComplete: true),
    );
    await tester.pumpAndSettle();

    expect(repository.completeCalls, 1);
    expect(find.text('Wash dishes'), findsNothing);
    expect(find.text('Yayyyyyyy Task done!'), findsOneWidget);
  });

  testWidgets('task remains active when server does not confirm completion',
      (tester) async {
    final completion = Completer<TaskDto>();
    final repository = _FakeTasksRepository(
      initialTasks: [_task(id: 'active', name: 'Wash dishes')],
      completion: completion,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TasksScreen(
          roomSession: _roomSession(),
          tasksRepository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wash dishes'));
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Mark Complete'));

    completion.complete(_task(id: 'active', name: 'Wash dishes'));
    await tester.pumpAndSettle();

    expect(find.text('Wash dishes'), findsOneWidget);
    expect(find.text('Yayyyyyyy Task done!'), findsNothing);
  });
}

class _FakeTasksRepository implements TasksRepository {
  _FakeTasksRepository({
    required this.initialTasks,
    required this.completion,
  });

  final List<TaskDto> initialTasks;
  final Completer<TaskDto> completion;
  int completeCalls = 0;

  @override
  Future<List<TaskDto>> listActiveByRoom(String roomId) async => initialTasks;

  @override
  Future<TaskDto> markComplete(
    String roomId,
    String taskId,
  ) {
    completeCalls++;
    return completion.future;
  }

  @override
  Future<TaskDto> create(String roomId, TaskCreateReq req) =>
      throw UnimplementedError();

  @override
  Future<void> delete(String roomId, String taskId) =>
      throw UnimplementedError();
}

class _MockHttpClientAdapter implements HttpClientAdapter {
  _MockHttpClientAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

RoomSession _roomSession() {
  final user = UserResponse(
    id: 'user-1',
    firstName: 'Awa',
    email: 'awa@example.com',
    createdAt: '2026-01-01T00:00:00Z',
    role: 'MEMBER',
    avatarId: 'AVA_01',
  );
  return RoomSession(
    currentUser: user,
    room: RoomResponse(
      id: 'room-1',
      name: 'Our room',
      code: 'ABC123',
      ownerId: user.id,
      createdAt: '2026-01-01T00:00:00Z',
    ),
    members: [user],
  );
}

TaskDto _task({
  required String id,
  required String name,
  bool isComplete = false,
}) {
  return TaskDto(
    id: id,
    name: name,
    description: null,
    roomId: 'room-1',
    assignedTo: 'user-1',
    recurrence: Recurrence.NONE,
    nextDueDateUtc: DateTime.utc(2026, 8, 13),
    createdDateUtc: DateTime.utc(2026, 8, 12),
    isComplete: isComplete,
    iconId: null,
    iconImageUrl: null,
  );
}

Map<String, dynamic> _taskJson({
  required String id,
  required bool complete,
}) {
  return {
    'id': id,
    'name': id,
    'description': null,
    'roomId': 'room-1',
    'assignedTo': 'user-1',
    'recurrence': 'NONE',
    'nextDueDateUtc': '2026-08-13T00:00:00Z',
    'createdDateUtc': '2026-08-12T00:00:00Z',
    'complete': complete,
    'iconId': null,
    'iconImageUrl': null,
  };
}
