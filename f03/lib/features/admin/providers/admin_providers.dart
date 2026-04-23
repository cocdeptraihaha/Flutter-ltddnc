import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/auth_providers.dart';
import '../data/book_admin_service.dart';
import '../data/book_discount_admin_service.dart';
import '../data/category_admin_service.dart';
import '../data/dashboard_service.dart';
import '../data/date_range_util.dart';
import '../data/order_admin_service.dart';
import '../data/point_reward_service.dart';
import '../data/promotion_admin_service.dart';
import '../data/return_admin_service.dart';
import '../data/user_admin_service.dart';
import '../data/models/admin_models.dart';

final adminDateRangeProvider =
    StateProvider<DateTimeRange>((_) => defaultLast7Days());

final dashboardServiceProvider =
    Provider<DashboardService>((ref) => DashboardService(ref.watch(dioProvider)));

final orderAdminServiceProvider =
    Provider<OrderAdminService>((ref) => OrderAdminService(ref.watch(dioProvider)));

final bookAdminServiceProvider =
    Provider<BookAdminService>((ref) => BookAdminService(ref.watch(dioProvider)));

final userAdminServiceProvider =
    Provider<UserAdminService>((ref) => UserAdminService(ref.watch(dioProvider)));

final promotionAdminServiceProvider =
    Provider<PromotionAdminService>(
        (ref) => PromotionAdminService(ref.watch(dioProvider)));

final bookDiscountAdminServiceProvider =
    Provider<BookDiscountAdminService>(
        (ref) => BookDiscountAdminService(ref.watch(dioProvider)));

final returnAdminServiceProvider =
    Provider<ReturnAdminService>((ref) => ReturnAdminService(ref.watch(dioProvider)));

final categoryAdminServiceProvider =
    Provider<CategoryAdminService>((ref) => CategoryAdminService(ref.watch(dioProvider)));

final pointRewardAdminServiceProvider =
    Provider<PointRewardAdminService>(
        (ref) => PointRewardAdminService(ref.watch(dioProvider)));

// --- Dashboard async ---

final dashboardSummaryProvider =
    FutureProvider.autoDispose<DashboardSummary>((ref) async {
  final range = ref.watch(adminDateRangeProvider);
  return ref.watch(dashboardServiceProvider).summary(
        from: range.start,
        to: range.end,
      );
});

final revenueTimeseriesProvider =
    FutureProvider.autoDispose<List<TimeseriesPoint>>((ref) async {
  final range = ref.watch(adminDateRangeProvider);
  return ref.watch(dashboardServiceProvider).revenueTimeseries(
        from: range.start,
        to: range.end,
        groupBy: 'day',
      );
});

final orderStatusBreakdownProvider =
    FutureProvider.autoDispose<List<OrderStatusBreakdownRow>>((ref) async {
  final range = ref.watch(adminDateRangeProvider);
  return ref.watch(dashboardServiceProvider).orderStatusBreakdown(
        from: range.start,
        to: range.end,
      );
});

final topBooksProvider =
    FutureProvider.autoDispose.family<List<TopBookRow>, String>((ref, metric) async {
  final range = ref.watch(adminDateRangeProvider);
  return ref.watch(dashboardServiceProvider).topBooks(
        from: range.start,
        to: range.end,
        metric: metric,
      );
});

final categoryRevenueProvider =
    FutureProvider.autoDispose<List<CategoryRevenueRow>>((ref) async {
  final range = ref.watch(adminDateRangeProvider);
  return ref.watch(dashboardServiceProvider).byCategory(
        from: range.start,
        to: range.end,
      );
});

final topCustomersProvider =
    FutureProvider.autoDispose<List<TopCustomerRow>>((ref) async {
  final range = ref.watch(adminDateRangeProvider);
  return ref.watch(dashboardServiceProvider).topCustomers(
        from: range.start,
        to: range.end,
      );
});

final cancelRateSeriesProvider =
    FutureProvider.autoDispose<List<CancelRatePoint>>((ref) async {
  final range = ref.watch(adminDateRangeProvider);
  return ref.watch(dashboardServiceProvider).cancellationTimeseries(
        from: range.start,
        to: range.end,
        groupBy: 'day',
      );
});

final orderMoneyStatsProvider =
    FutureProvider.autoDispose<OrderRevenueStats>((ref) async {
  final range = ref.watch(adminDateRangeProvider);
  return ref.watch(dashboardServiceProvider).orderStats(
        from: range.start,
        to: range.end,
      );
});
