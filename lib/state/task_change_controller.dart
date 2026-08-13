import 'package:flutter/foundation.dart';

enum TaskMutation { completed, created, deleted }

@immutable
class TaskChange {
  const TaskChange({
    required this.roomId,
    required this.taskId,
    required this.mutation,
  });

  final String roomId;
  final String taskId;
  final TaskMutation mutation;
}

/// A lightweight invalidation signal for screens that cache room tasks.
class TaskChangeController extends ChangeNotifier {
  TaskChangeController._();

  static final TaskChangeController instance = TaskChangeController._();

  TaskChange? _lastChange;
  TaskChange? get lastChange => _lastChange;

  void record({
    required String roomId,
    required String taskId,
    required TaskMutation mutation,
  }) {
    _lastChange = TaskChange(
      roomId: roomId,
      taskId: taskId,
      mutation: mutation,
    );
    notifyListeners();
  }
}
