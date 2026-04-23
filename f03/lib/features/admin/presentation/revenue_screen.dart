import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api_client.dart';
import '../../../providers/auth_providers.dart';
import '../data/csv_downloader.dart';
import '../data/date_range_util.dart';
import '../data/models/admin_models.dart';
import '../providers/admin_providers.dart';

class RevenueScreen extends ConsumerStatefulWidget {
  const RevenueScreen({super.key});

  @override
  ConsumerState<RevenueScreen> createState() => _RevenueScreenState();
}

class _RevenueScreenState extends ConsumerState<RevenueScreen> {
  String _groupBy = 'day';

  Future<void> _csv() async {
    final range = ref.read(adminDateRangeProvider);
    try {
      await downloadAndShareCsv(
        ref.read(dioProvider),
        path: '/admin/dashboard/revenue.csv',
        queryParameters: {
          'from': formatQueryDate(range.start),
          'to': formatQueryDate(range.end),
          'group_by': _groupBy,
        },
        fileName: 'revenue_timeseries.csv',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(dioErrorMessage(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final revAsync = ref.watch(
      revenueTimeseriesGroupProvider(_groupBy),
    );
    final statsAsync = ref.watch(orderMoneyStatsProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Text('Nhóm:'),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: _groupBy,
              items: const [
                DropdownMenuItem(value: 'day', child: Text('Ngày')),
                DropdownMenuItem(value: 'week', child: Text('Tuần')),
                DropdownMenuItem(value: 'month', child: Text('Tháng')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _groupBy = v);
              },
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: _csv,
              icon: const Icon(Icons.download),
              label: const Text('CSV doanh thu'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: revAsync.when(
            data: (pts) => pts.isEmpty
                ? const Center(child: Text('Không có dữ liệu'))
                : LineChart(
                    LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            for (var i = 0; i < pts.length; i++)
                              FlSpot(i.toDouble(), pts[i].revenue),
                          ],
                          isCurved: true,
                          color: Colors.deepPurple,
                          barWidth: 3,
                        ),
                      ],
                      titlesData: const FlTitlesData(show: true),
                      gridData: const FlGridData(show: true),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text(dioErrorMessage(e)),
          ),
        ),
        const SizedBox(height: 16),
        Text('Thống kê gộp', style: Theme.of(context).textTheme.titleMedium),
        statsAsync.when(
          data: (s) => Column(
            children: [
              ListTile(
                title: const Text('Chờ xác nhận'),
                trailing: Text(
                  '${s.pendingConfirm.count} · ${fmt.format(s.pendingConfirm.total)}',
                ),
              ),
              ListTile(
                title: const Text('Đang giao'),
                trailing: Text(
                  '${s.shipping.count} · ${fmt.format(s.shipping.total)}',
                ),
              ),
              ListTile(
                title: const Text('Đã giao'),
                trailing: Text(
                  '${s.delivered.count} · ${fmt.format(s.delivered.total)}',
                ),
              ),
              ListTile(
                title: const Text('Huỷ / trả'),
                trailing: Text(
                  '${s.cancelled.count} · ${fmt.format(s.cancelled.total)}',
                ),
              ),
              ListTile(
                title: const Text('Doanh thu đã giao'),
                trailing: Text(fmt.format(s.totalSpent)),
              ),
            ],
          ),
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text(dioErrorMessage(e)),
        ),
        const SizedBox(height: 16),
        Text('Tỉ lệ huỷ (chuỗi)', style: Theme.of(context).textTheme.titleMedium),
        SizedBox(
          height: 180,
          child: ref.watch(cancelRateSeriesProvider).when(
                data: (pts) => pts.isEmpty
                    ? const Center(child: Text('Không có dữ liệu'))
                    : LineChart(
                        LineChartData(
                          lineBarsData: [
                            LineChartBarData(
                              spots: [
                                for (var i = 0; i < pts.length; i++)
                                  FlSpot(i.toDouble(), pts[i].cancelRate * 100),
                              ],
                              color: Colors.orange,
                              barWidth: 2,
                            ),
                          ],
                          titlesData: const FlTitlesData(show: true),
                          gridData: const FlGridData(show: true),
                          borderData: FlBorderData(show: false),
                        ),
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text(dioErrorMessage(e)),
              ),
        ),
      ],
    );
  }
}

final revenueTimeseriesGroupProvider =
    FutureProvider.autoDispose.family<List<TimeseriesPoint>, String>((ref, groupBy) async {
  final range = ref.watch(adminDateRangeProvider);
  return ref.watch(dashboardServiceProvider).revenueTimeseries(
        from: range.start,
        to: range.end,
        groupBy: groupBy,
      );
});
