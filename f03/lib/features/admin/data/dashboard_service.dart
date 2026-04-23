import 'package:dio/dio.dart';

import 'date_range_util.dart';
import 'models/admin_models.dart';

/// Gọi API `/admin/dashboard/*`.
class DashboardService {
  DashboardService(this._dio);

  final Dio _dio;

  Future<DashboardSummary> summary({DateTime? from, DateTime? to}) async {
    final q = <String, dynamic>{};
    if (from != null) q['from'] = formatQueryDate(from);
    if (to != null) q['to'] = formatQueryDate(to);
    final res = await _dio.get<Map<String, dynamic>>(
      '/admin/dashboard/summary',
      queryParameters: q.isEmpty ? null : q,
    );
    return DashboardSummary.fromJson(res.data!);
  }

  Future<List<TopBookRow>> topBooks({
    DateTime? from,
    DateTime? to,
    int limit = 10,
    String metric = 'revenue',
  }) async {
    final q = <String, dynamic>{'limit': limit, 'metric': metric};
    if (from != null) q['from'] = formatQueryDate(from);
    if (to != null) q['to'] = formatQueryDate(to);
    final res = await _dio.get<List<dynamic>>(
      '/admin/dashboard/top-books',
      queryParameters: q,
    );
    return (res.data ?? [])
        .map((e) => TopBookRow.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CategoryRevenueRow>> byCategory({
    DateTime? from,
    DateTime? to,
  }) async {
    final q = <String, dynamic>{};
    if (from != null) q['from'] = formatQueryDate(from);
    if (to != null) q['to'] = formatQueryDate(to);
    final res = await _dio.get<List<dynamic>>(
      '/admin/dashboard/by-category',
      queryParameters: q.isEmpty ? null : q,
    );
    return (res.data ?? [])
        .map((e) => CategoryRevenueRow.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<OrderStatusBreakdownRow>> orderStatusBreakdown({
    DateTime? from,
    DateTime? to,
  }) async {
    final q = <String, dynamic>{};
    if (from != null) q['from'] = formatQueryDate(from);
    if (to != null) q['to'] = formatQueryDate(to);
    final res = await _dio.get<List<dynamic>>(
      '/admin/dashboard/order-status-breakdown',
      queryParameters: q.isEmpty ? null : q,
    );
    return (res.data ?? [])
        .map((e) =>
            OrderStatusBreakdownRow.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TopCustomerRow>> topCustomers({
    DateTime? from,
    DateTime? to,
    int limit = 10,
  }) async {
    final q = <String, dynamic>{'limit': limit};
    if (from != null) q['from'] = formatQueryDate(from);
    if (to != null) q['to'] = formatQueryDate(to);
    final res = await _dio.get<List<dynamic>>(
      '/admin/dashboard/top-customers',
      queryParameters: q,
    );
    return (res.data ?? [])
        .map((e) => TopCustomerRow.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CancelRatePoint>> cancellationTimeseries({
    DateTime? from,
    DateTime? to,
    String groupBy = 'day',
  }) async {
    final q = <String, dynamic>{'group_by': groupBy};
    if (from != null) q['from'] = formatQueryDate(from);
    if (to != null) q['to'] = formatQueryDate(to);
    final res = await _dio.get<List<dynamic>>(
      '/admin/dashboard/cancellation-timeseries',
      queryParameters: q,
    );
    return (res.data ?? [])
        .map((e) => CancelRatePoint.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TimeseriesPoint>> revenueTimeseries({
    DateTime? from,
    DateTime? to,
    String groupBy = 'day',
  }) async {
    final q = <String, dynamic>{'group_by': groupBy};
    if (from != null) q['from'] = formatQueryDate(from);
    if (to != null) q['to'] = formatQueryDate(to);
    final res = await _dio.get<List<dynamic>>(
      '/orders/admin/revenue-timeseries',
      queryParameters: q,
    );
    return (res.data ?? [])
        .map((e) => TimeseriesPoint.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<OrderRevenueStats> orderStats({
    DateTime? from,
    DateTime? to,
  }) async {
    final q = <String, dynamic>{};
    if (from != null) q['from'] = formatQueryDate(from);
    if (to != null) q['to'] = formatQueryDate(to);
    final res = await _dio.get<Map<String, dynamic>>(
      '/orders/admin/stats',
      queryParameters: q.isEmpty ? null : q,
    );
    return OrderRevenueStats.fromJson(res.data!);
  }
}
