import 'package:dio/dio.dart';

class NotificationAdminService {
  NotificationAdminService(this._dio);

  final Dio _dio;

  Future<List<Map<String, dynamic>>> list({
    int skip = 0,
    int limit = 100,
  }) async {
    final res = await _dio.get<List<dynamic>>(
      '/notifications/',
      queryParameters: {'skip': skip, 'limit': limit},
    );
    return (res.data ?? []).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createToUsers({
    required List<int> userIds,
    required String title,
    required String message,
    String type = 'INFO',
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/notifications/',
      data: {
        'user_ids': userIds,
        'title': title,
        'message': message,
        'type': type,
      },
    );
    return res.data!;
  }

  Future<Map<String, dynamic>> broadcast({
    required String title,
    required String message,
    String type = 'INFO',
    bool? isActive,
    bool? isSuperuser,
  }) async {
    final data = <String, dynamic>{
      'title': title,
      'message': message,
      'type': type,
    };
    final userFilter = <String, dynamic>{
      'is_active': isActive,
      'is_superuser': isSuperuser,
    }..removeWhere((_, v) => v == null);
    if (userFilter.isNotEmpty) {
      data['user_filter'] = userFilter;
    }
    final res = await _dio.post<Map<String, dynamic>>(
      '/notifications/broadcast',
      data: data,
    );
    return res.data!;
  }
}

