// lib/api/tasks_models.dart
enum Recurrence { NONE, DAILY, WEEKLY, MONTHLY }

class TaskDto {
  final String id;
  final String name;
  final String? description;
  final String roomId;
  final String? assignedTo;
  final Recurrence recurrence;
  final DateTime? nextDueDateUtc;
  final DateTime createdDateUtc;
  final bool isComplete;
  final String? iconId;        // enum name from server
  final String? iconImageUrl;  // server-hosted image if you want

  TaskDto({
    required this.id,
    required this.name,
    required this.description,
    required this.roomId,
    required this.assignedTo,
    required this.recurrence,
    required this.nextDueDateUtc,
    required this.createdDateUtc,
    required this.isComplete,
    required this.iconId,
    required this.iconImageUrl,
  });


  factory TaskDto.fromJson(Map<String, dynamic> j) {
  
    final nd = (j['nextDueDateUtc'] ?? j['nextDueDate']) as String?;
    return TaskDto(
      id: j['id'] as String,
      name: j['name'] as String,
      description: j['description'] as String?,
      roomId: j['roomId'] as String,
      assignedTo: j['assignedTo'] as String?,
      recurrence: Recurrence.values.firstWhere(
        (e) => e.name == (j['recurrence'] as String? ?? 'NONE'),
        orElse: () => Recurrence.NONE,
      ),
      nextDueDateUtc: nd != null ? DateTime.parse(nd).toUtc() : null,
      createdDateUtc: DateTime.parse(j['createdDateUtc'] as String).toUtc(),
      // server uses "complete", not "isComplete"
      isComplete: (j['complete'] as bool?) ?? false,
      iconId: j['iconId'] as String?,
      iconImageUrl: j['iconImageUrl'] as String?,
    );
  }
}

class TaskCreateReq {
  final String name;
  final String? description;
  final String? assignedTo; // userId
  final Recurrence recurrence;
  final DateTime? nextDueDateUtc; // Ola  UTC!
  final String? icon; // enum name

  TaskCreateReq({
    required this.name,
    this.description,
    this.assignedTo,
    this.recurrence = Recurrence.NONE,
    this.nextDueDateUtc,
    this.icon,
  });

  Map<String,dynamic> toJson() => {
    'name': name,
    'description': description,
    'assignedTo': assignedTo,
    'recurrence': recurrence.name,
    'nextDueDate': nextDueDateUtc?.toIso8601String(),
    'icon': icon,
  }..removeWhere((k,v) => v == null);
}
