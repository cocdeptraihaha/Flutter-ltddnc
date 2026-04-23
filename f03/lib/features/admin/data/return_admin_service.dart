import 'package:dio/dio.dart';

import 'date_range_util.dart';

class ReturnAdminService {
  ReturnAdminService(this._dio);

  final Dio _dio;

  Future<List<Map<String, dynamic>>> listAll({
    int skip = 0,
    int limit = 50,
    String? status,
    DateTime? from,
    DateTime? to,
  }) async {
    final q = <String, dynamic>{'skip': skip, 'limit': limit};
    if (status != null) q['status'] = status;
    if (from != null) q['from'] = formatQueryDate(from);
    if (to != null) q['to'] = formatQueryDate(to);
    final res = await _dio.get<List<dynamic>>(
      '/return-requests/admin/all',
      queryParameters: q,
    );
    return (res.data ?? []).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> process(int id, String status) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      '/return-requests/$id/process',
      data: {'status': status},
    );
    return res.data!;
  }
}
