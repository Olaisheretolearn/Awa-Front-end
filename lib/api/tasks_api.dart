// lib/api/tasks_api.dart
import 'package:dio/dio.dart';
import 'client.dart';
import 'tasks_models.dart';

class TasksApi {
  final ApiClient _client;
  TasksApi(this._client);

  Dio get _dio => _client.dio;

  Future<List<TaskDto>> listByRoom(String roomId) async {
    final res = await _dio.get('/room/$roomId/task');
    final data = (res.data as List).cast<Map<String,dynamic>>();
    return data.map(TaskDto.fromJson).toList();
  }

  Future<TaskDto> create(String roomId, TaskCreateReq req) async {
    final res = await _dio.post('/room/$roomId/task', data: req.toJson());
    return TaskDto.fromJson(res.data as Map<String,dynamic>);
  }

  Future<TaskDto> markComplete(String roomId, String taskId, String userId) async {
    final res = await _dio.patch('/room/$roomId/task/$taskId/complete', queryParameters: {'userId': userId});
    return TaskDto.fromJson(res.data as Map<String,dynamic>);
  }

  Future<void> delete(String roomId, String taskId) async {
    await _dio.delete('/room/$roomId/task/$taskId');
  }
}
