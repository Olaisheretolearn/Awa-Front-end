// lib/api/messages_api.dart
import 'package:dio/dio.dart';
import 'client.dart';
import 'model_message.dart';

class MessagesApi {
  final ApiClient _c;
  MessagesApi(this._c);

  Future<List<MessageResponse>> list(String roomId, {DateTime? after}) async {
    final q = <String, dynamic>{};
    if (after != null) q['after'] = after.toUtc().toIso8601String();

    final res = await _c.dio.get('/room/$roomId/message', queryParameters: q);
    final data = (res.data as List).cast<Map<String, dynamic>>();
    return data.map((j) => MessageResponse.fromJson(j)).toList();
  }

  Future<MessageResponse> send({
    required String roomId,
    required String senderId,
    required String senderName,
    required String content,
    List<String> attachmentUrls = const [],
  }) async {
    final body = {
      'content': content,
      'senderId': senderId,
      'senderName': senderName,
      'roomId': 'ignored', 
      'attachmentUrls': attachmentUrls,
    };
    final res = await _c.dio.post('/room/$roomId/message', data: body);
    return MessageResponse.fromJson(res.data);
  }

  Future<MessageResponse> react({
    required String roomId,
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    final res = await _c.dio.post(
      '/room/$roomId/message/$messageId/react',
      queryParameters: {'userId': userId, 'emoji': emoji},
    );
    return MessageResponse.fromJson(res.data);
  }
}
