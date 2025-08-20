// lib/api/bills_api.dart
import 'client.dart';
import 'bills_models.dart';

class BillsApi {
  final ApiClient _c;
  BillsApi(this._c);

  Future<List<BillResponse>> listByRoom(String roomId) async {
    final res = await _c.dio.get('/room/$roomId/bill');
    final data = (res.data as List).map((e) => BillResponse.fromJson(e)).toList();
    return data;
  }

  Future<BillResponse> create(String roomId, BillCreateReq req) async {
    final res = await _c.dio.post('/room/$roomId/bill', data: req.toJson());
    return BillResponse.fromJson(res.data);
  }


  Future<BillResponse> markSharePaid(
    String roomId,
    String billId,
    String debtorUserId,
  ) async {
    final res = await _c.dio.patch(
      '/room/$roomId/bill/$billId/shares/$debtorUserId/mark-paid',
    );
    return BillResponse.fromJson(res.data);
  }


  Future<BillResponse> confirmShare({
    required String roomId,
    required String billId,
    required String creatorUserId, 
    required String debtorUserId,
    required bool confirm,
  }) async {
    final res = await _c.dio.patch(
      '/room/$roomId/bill/$billId/shares/$debtorUserId/confirm',
      queryParameters: {
        'creatorUserId': creatorUserId,
        'confirm': confirm, 
      },
    );
    return BillResponse.fromJson(res.data);
  }
}
