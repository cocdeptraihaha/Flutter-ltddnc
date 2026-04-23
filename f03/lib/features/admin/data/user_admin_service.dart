import 'package:dio/dio.dart';

class UserAdminService {
  UserAdminService(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> getUser(int id) async {
    final res = await _dio.get<Map<String, dynamic>>('/users/$id');
    return res.data!;
  }

  Future<List<Map<String, dynamic>>> listUsers({
    int skip = 0,
    int limit = 50,
    String? q,
    bool? isActive,
    bool? isSuperuser,
  }) async {
    final qm = <String, dynamic>{'skip': skip, 'limit': limit};
    if (q != null && q.isNotEmpty) qm['q'] = q;
    if (isActive != null) qm['is_active'] = isActive;
    if (isSuperuser != null) qm['is_superuser'] = isSuperuser;
    final res = await _dio.get<List<dynamic>>(
      '/users/admin/all',
      queryParameters: qm,
    );
    return (res.data ?? []).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> setActive(int id, bool isActive) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      '/users/admin/$id/status',
      data: {'is_active': isActive},
    );
    return res.data!;
  }

  Future<Map<String, dynamic>> setRole(int id, bool isSuperuser) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      '/users/admin/$id/role',
      data: {'is_superuser': isSuperuser},
    );
    return res.data!;
  }

  Future<Map<String, dynamic>> adjustPoints(
    int id, {
    required int delta,
    required String reason,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/users/admin/$id/points-adjust',
      data: {'delta': delta, 'reason': reason},
    );
    return res.data!;
  }

  Future<List<Map<String, dynamic>>> userOrders(int userId) async {
    final res = await _dio.get<List<dynamic>>('/users/admin/$userId/orders');
    return (res.data ?? []).cast<Map<String, dynamic>>();
  }
}
