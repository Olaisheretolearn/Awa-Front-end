import 'package:dio/dio.dart';
import 'client.dart';

class ShoppingItemDto {
  final String id;
  final String roomId;
  final String listName;
  final String itemName;
  final String addedByUserId;
  final String addedByName;
  final bool isBought;
  final String? boughtByUserId;
  final String? boughtByName;

  ShoppingItemDto({
    required this.id,
    required this.roomId,
    required this.listName,
    required this.itemName,
    required this.addedByUserId,
    required this.addedByName,
    required this.isBought,
    this.boughtByUserId,
    this.boughtByName,
  });

  factory ShoppingItemDto.fromJson(Map<String, dynamic> j) => ShoppingItemDto(
        id: j['id'],
        roomId: j['roomId'],
        listName: j['listName'],
        itemName: j['itemName'],
        addedByUserId: j['addedByUserId'],
        addedByName: j['addedByName'],
        isBought: j['isBought'] ?? false,
        boughtByUserId: j['boughtByUserId'],
        boughtByName: j['boughtByName'],
      );
}

class ShoppingApi {
  final ApiClient _c;
  ShoppingApi(this._c);

  Future<List<ShoppingItemDto>> list(String roomId) async {
    final res = await _c.dio.get('/room/$roomId/shopping');
    final data = res.data as List;
    return data.map((x) => ShoppingItemDto.fromJson(x)).toList();
  }

  Future<ShoppingItemDto> create({
    required String roomId,
    required String listName,
    required String itemName,
    required String addedByUserId,
    required String addedByName,
  }) async {
    try {
      final body = {
        "listName": listName,
        "itemName": itemName,
        "addedByUserId": addedByUserId,
        "addedByName": addedByName,
        // Kotlin/Java backends often require a non-null createdAt; ISO 8601 with Z:
        "createdAt": DateTime.now().toUtc().toIso8601String(),
        "isBought": false,
      };

      final res = await _c.dio.post(
        '/room/$roomId/shopping',
        data: body,
        options: Options(headers: {
          'Content-Type': 'application/json',
          // Include your auth header if needed:
          // 'Authorization': 'Bearer ${_c.token}',
        }),
      );

      return ShoppingItemDto.fromJson(res.data);
    } on DioException catch (e) {
      // Log everything helpful
      final code = e.response?.statusCode;
      final text = e.response?.data;
      // This print helps you see the actual server message in the console
      // (leave it in while debugging)
      // ignore: avoid_print
      print('Create failed ($code): $text');
      rethrow;
    }
  }

  Future<ShoppingItemDto> markBought({
    required String roomId,
    required String itemId,
    required String boughtByUserId,
    required String boughtByName,
  }) async {
    final res = await _c.dio.patch(
      '/room/$roomId/shopping/$itemId/bought',
      data: {
        'boughtByUserId': boughtByUserId,
        'boughtByName': boughtByName,
      },
    );
    return ShoppingItemDto.fromJson(res.data);
  }

  Future<void> delete(String itemId, String roomId) async {
    await _c.dio.delete('/room/$roomId/shopping/$itemId');
  }
}
