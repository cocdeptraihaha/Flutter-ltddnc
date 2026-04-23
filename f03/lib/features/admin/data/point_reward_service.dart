import 'package:dio/dio.dart';

class PointRewardAdminService {
  PointRewardAdminService(this._dio);

  final Dio _dio;

  Future<List<Map<String, dynamic>>> list({
    int skip = 0,
    int limit = 200,
  }) async {
    final res = await _dio.get<List<dynamic>>(
      '/points/admin/rewards',
      queryParameters: {'skip': skip, 'limit': limit},
    );
    return (res.data ?? []).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/points/admin/rewards',
      data: body,
    );
    return res.data!;
  }

  Future<Map<String, dynamic>> update(int id, Map<String, dynamic> body) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      '/points/admin/rewards/$id',
      data: body,
    );
    return res.data!;
  }
}
