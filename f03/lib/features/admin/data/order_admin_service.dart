import 'package:dio/dio.dart';

import 'date_range_util.dart';

/// Admin orders API.
class OrderAdminService {
  OrderAdminService(this._dio);

  final Dio _dio;

  Future<List<Map<String, dynamic>>> listOrders({
    int skip = 0,
    int limit = 30,
    List<String>? statusIn,
    DateTime? from,
    DateTime? to,
    String? q,
  }) async {
    final query = <String, dynamic>{'skip': skip, 'limit': limit};
    if (statusIn != null && statusIn.isNotEmpty) {
      query['status_in'] = statusIn.join(',');
    }
    if (from != null) query['from'] = formatQueryDate(from);
    if (to != null) query['to'] = formatQueryDate(to);
    if (q != null && q.isNotEmpty) query['q'] = q;
    final res = await _dio.get<List<dynamic>>(
      '/orders/admin/all',
      queryParameters: query,
    );
    return (res.data ?? []).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getOrder(int id) async {
    final res = await _dio.get<Map<String, dynamic>>('/orders/admin/$id');
    return res.data!;
  }

  Future<void> updateStatus(int id, String status, {String? description}) async {
    await _dio.patch<Map<String, dynamic>>(
      '/orders/admin/$id/status',
      data: {
        'status': status,
        if (description != null) 'description': description,
      },
    );
  }

  Future<void> updateShipment(
    int id, {
    String? trackingNumber,
    String? shippingProvider,
  }) async {
    await _dio.patch<Map<String, dynamic>>(
      '/orders/admin/$id/shipment',
      data: {
        if (trackingNumber != null) 'tracking_number': trackingNumber,
        if (shippingProvider != null) 'shipping_provider': shippingProvider,
      },
    );
  }

  Future<void> cancelDecision(int id, bool approve, {String? description}) async {
    await _dio.post<Map<String, dynamic>>(
      '/orders/admin/$id/cancel-decision',
      data: {
        'approve': approve,
        if (description != null) 'description': description,
      },
    );
  }
}
