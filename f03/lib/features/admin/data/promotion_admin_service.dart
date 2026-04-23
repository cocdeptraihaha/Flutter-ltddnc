import 'package:dio/dio.dart';

class PromotionAdminService {
  PromotionAdminService(this._dio);

  final Dio _dio;

  Future<List<Map<String, dynamic>>> listPromotions({
    int skip = 0,
    int limit = 100,
  }) async {
    final res = await _dio.get<List<dynamic>>(
      '/promotions/',
      queryParameters: {'skip': skip, 'limit': limit},
    );
    return (res.data ?? []).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createPromotion(Map<String, dynamic> body) async {
    final res = await _dio.post<Map<String, dynamic>>('/promotions/', data: body);
    return res.data!;
  }

  Future<Map<String, dynamic>> updatePromotion(int id, Map<String, dynamic> body) async {
    final res =
        await _dio.patch<Map<String, dynamic>>('/promotions/$id', data: body);
    return res.data!;
  }

  Future<Map<String, dynamic>> stats(int promoId) async {
    final res =
        await _dio.get<Map<String, dynamic>>('/promotions/$promoId/stats');
    return res.data!;
  }

  Future<Map<String, dynamic>> issueToUser({
    required int userId,
    required int promotionId,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/promotions/admin/issue',
      data: {'user_id': userId, 'promotion_id': promotionId},
    );
    return res.data!;
  }

  Future<void> deletePromotion(int id) async {
    await _dio.delete<void>('/promotions/$id');
  }
}
