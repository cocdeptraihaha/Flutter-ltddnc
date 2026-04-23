import 'package:dio/dio.dart';

class BookDiscountAdminService {
  BookDiscountAdminService(this._dio);

  final Dio _dio;

  Future<List<Map<String, dynamic>>> list({
    int skip = 0,
    int limit = 100,
    bool activeOnly = false,
  }) async {
    final res = await _dio.get<List<dynamic>>(
      '/book-discounts/',
      queryParameters: {
        'skip': skip,
        'limit': limit,
        'active_only': activeOnly,
      },
    );
    return (res.data ?? []).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
    final res =
        await _dio.post<Map<String, dynamic>>('/book-discounts/', data: body);
    return res.data!;
  }

  Future<Map<String, dynamic>> update(int id, Map<String, dynamic> body) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      '/book-discounts/$id',
      data: body,
    );
    return res.data!;
  }
}
