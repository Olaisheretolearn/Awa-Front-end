// lib/api/tasks_api.dart
import 'package:dio/dio.dart';
import 'client.dart';
import 'tasks_models.dart';

abstract class TasksRepository {
  Future<List<TaskDto>> listActiveByRoom(String roomId);
  Future<TaskDto> create(String roomId, TaskCreateReq req);
  Future<TaskDto> markComplete(String roomId, String taskId);
  Future<void> delete(String roomId, String taskId);
}

class TasksApi implements TasksRepository {
  TasksApi(ApiClient client) : _dio = client.dio;

  /// Allows the HTTP contract to be tested without using the shared client.
  TasksApi.withDio(Dio dio) : _dio = dio;

  final Dio _dio;

  @override
  Future<List<TaskDto>> listActiveByRoom(String roomId) async {
    final res = await _dio.get(
      '/room/$roomId/task/status',
      queryParameters: {'isComplete': false},
    );
    final data = (res.data as List).cast<Map<String, dynamic>>();
    // Keep this filter as a defensive boundary if a server ever returns a
    // mixed-status response from the active endpoint.
    return data
        .map(TaskDto.fromJson)
        .where((task) => !task.isComplete)
        .toList();
  }

  @override
  Future<TaskDto> create(String roomId, TaskCreateReq req) async {
    final res = await _dio.post('/room/$roomId/task', data: req.toJson());
    return TaskDto.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<TaskDto> markComplete(String roomId, String taskId) async {
    final res = await _dio.patch('/room/$roomId/task/$taskId/complete');
    return TaskDto.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<void> delete(String roomId, String taskId) async {
    await _dio.delete('/room/$roomId/task/$taskId');
  }
}
