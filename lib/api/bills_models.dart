// lib/api/bills_models.dart
class BillShare {
  final String userId;
  final double amount;
  final String status; // PENDING | MARKED_PAID | CONFIRMED
  final DateTime? markedPaidAt;
  final DateTime? confirmedPaidAt;

  BillShare({
    required this.userId,
    required this.amount,
    required this.status,
    this.markedPaidAt,
    this.confirmedPaidAt,
  });

  factory BillShare.fromJson(Map<String, dynamic> j) => BillShare(
    userId: j['userId'],
    amount: (j['amount'] as num).toDouble(),
    status: j['status'],
    markedPaidAt: j['markedPaidAt'] == null ? null : DateTime.parse(j['markedPaidAt']).toLocal(),
    confirmedPaidAt: j['confirmedPaidAt'] == null ? null : DateTime.parse(j['confirmedPaidAt']).toLocal(),
  );
}


// lib/api/bills_models.dart

// --- BillResponse ---
class BillResponse {
  final String id, roomId, name, description, paidByUserId;
  final double amount, totalOwedToCreator;
  final DateTime dueDate;
  final bool isPaid;
  final bool isContract; 
  final List<String> splitAmongUserIds;
  final List<BillShare> shares;

  BillResponse({
    required this.id,
    required this.roomId,
    required this.name,
    required this.description,
    required this.amount,
    required this.dueDate,
    required this.paidByUserId,
    required this.isPaid,
    required this.isContract,
    required this.splitAmongUserIds,
    required this.shares,
    required this.totalOwedToCreator,
  });

  factory BillResponse.fromJson(Map<String, dynamic> j) => BillResponse(
    id: j['id'],
    roomId: j['roomId'],
    name: j['name'] ?? '',
    description: j['description'] ?? '',
    amount: (j['amount'] as num).toDouble(),
    dueDate: DateTime.parse(j['dueDate']).toLocal(),
    paidByUserId: j['paidByUserId'],
    isPaid: (j['isPaid'] ?? j['paid'] ?? false) as bool,
    isContract: (j['isContract'] as bool?) ?? false, // <— NEW (defaults false)
    splitAmongUserIds: ((j['splitAmongUserIds'] as List?) ?? const []).cast<String>(),
    shares: ((j['shares'] as List?) ?? const [])
        .map((e) => BillShare.fromJson(e as Map<String, dynamic>))
        .toList(),
    totalOwedToCreator: ((j['totalOwedToCreator'] as num?) ?? 0).toDouble(),
  );
}

// --- BillCreateReq ---
class BillCreateReq {
  final String roomId, name, description, paidByUserId;
  final double amount;
  final DateTime dueDate;
  final List<String> splitAmongUserIds;
  final bool isContract; 

  BillCreateReq({
    required this.roomId,
    required this.name,
    required this.description,
    required this.amount,
    required this.dueDate,
    required this.paidByUserId,
    required this.splitAmongUserIds,
    this.isContract = false, 
  });

  Map<String, dynamic> toJson() => {
    'roomId': roomId,
    'name': name,
    'description': description,
    'amount': amount,
    'dueDate': dueDate.toUtc().toIso8601String(),
    'paidByUserId': paidByUserId,
    'splitAmongUserIds': splitAmongUserIds,
    'isContract': isContract, 
  };
}

