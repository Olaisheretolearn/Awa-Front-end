// lib/api/model_message.dart
class Reaction {
  final String userId;
  final String emoji;

  Reaction({required this.userId, required this.emoji});

  factory Reaction.fromJson(Map<String, dynamic> j) =>
      Reaction(userId: j['userId'], emoji: j['emoji']);
}

class MessageResponse {
  final String id;
  final String roomId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final List<Reaction> reactions;
  final List<String> attachmentUrls;

  MessageResponse({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    required this.reactions,
    required this.attachmentUrls,
  });

  factory MessageResponse.fromJson(Map<String, dynamic> j) => MessageResponse(
        id: j['id'],
        roomId: j['roomId'],
        senderId: j['senderId'],
        senderName: j['senderName'],
        content: j['content'],
        timestamp: DateTime.parse(j['timestamp']).toLocal(),
        reactions: (j['reactions'] as List? ?? [])
            .map((e) => Reaction.fromJson(e))
            .toList(),
        attachmentUrls:
            (j['attachmentUrls'] as List? ?? []).map((e) => e.toString()).toList(),
      );

      
}


