import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app_theme.dart';
import '../../../core/api_client.dart';
import '../../../providers/auth_providers.dart';
import '../data/csv_downloader.dart';
import '../data/date_range_util.dart';
import '../data/models/admin_models.dart';
import '../providers/admin_providers.dart';
import 'widgets/section_card.dart';

class RevenueScreen extends ConsumerStatefulWidget {
  const RevenueScreen({super.key});

  @override
  ConsumerState<RevenueScreen> createState() => _RevenueScreenState();
}

class _RevenueScreenState extends ConsumerState<RevenueScreen> {
  String _groupBy = 'day';

  String _xLabel(String period) {
    if (_groupBy == 'day' && period.length >= 10) {
      return period.substring(5, 10); // MM-DD
    }
    if (_groupBy == 'month' && period.length >= 7) {
      return period.substring(0, 7); // YYYY-MM
    }
    return period;
  }

  String _compactMoney(num value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}B';
    }
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(dioErrorMessage(e))));
      }
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(revenueTimeseriesGroupProvider(_groupBy));
    ref.invalidate(orderMoneyStatsProvider);
    ref.invalidate(cancelRateSeriesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final revAsync = ref.watch(revenueTimeseriesGroupProvider(_groupBy));
    final statsAsync = ref.watch(orderMoneyStatsProvider);
    final cancelAsync = ref.watch(cancelRateSeriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              SectionCard(
                title: 'Doanh thu theo thời gian',
                subtitle: 'Nhóm dữ liệu biểu đồ',
                trailing: IconButton(
                  tooltip: 'Xuất CSV',
                  onPressed: _csv,
                  icon: const Icon(Icons.download_rounded),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'day', label: Text('Ngày')),
                        ButtonSegment(value: 'week', label: Text('Tuần')),
                        ButtonSegment(value: 'month', label: Text('Tháng')),
                      ],
                      selected: {_groupBy},
                      showSelectedIcon: false,
                      onSelectionChanged: (s) =>
                          setState(() => _groupBy = s.first),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 220,
                      child: revAsync.when(
                        data: (pts) => pts.isEmpty
                            ? const _StateHint(
                                icon: Icons.bar_chart_outlined,
                                title: 'Chua co du lieu doanh thu',
                                subtitle:
                                    'Thu mo rong khoang thoi gian de xem bieu do.',
                              )
                            : pts.length == 1
                            ? _StateHint(
                                icon: Icons.show_chart_rounded,
                                title: 'Du lieu chua du de ve xu huong',
                                subtitle:
                                    'Hien co 1 moc ${pts.first.period} voi doanh thu ${fmt.format(pts.first.revenue)}',
                              )
                            : LineChart(
                                LineChartData(
                                  minX: 0,
                                  maxX: (pts.length - 1).toDouble(),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: [
                                        for (var i = 0; i < pts.length; i++)
                                          FlSpot(i.toDouble(), pts[i].revenue),
                                      ],
                                      isCurved: true,
                                      color: AppColors.primary,
                                      barWidth: 3,
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: AppColors.primary.withValues(
                                          alpha: 0.12,
                                        ),
                                      ),
                                      dotData: FlDotData(
                                        show: pts.length <= 14,
                                      ),
                                    ),
                                  ],
                                  lineTouchData: LineTouchData(
                                    touchTooltipData: LineTouchTooltipData(
                                      getTooltipItems: (items) => items.map((
                                        it,
                                      ) {
                                        final idx = it.x.toInt();
                                        if (idx < 0 || idx >= pts.length)
                                          return null;
                                        final p = pts[idx];
                                        return LineTooltipItem(
                                          '${p.period}\n${fmt.format(p.revenue)}',
                                          const TextStyle(
                                            color: AppColors.onSurface,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    topTitles: const AxisTitles(),
                                    rightTitles: const AxisTitles(),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 44,
                                        getTitlesWidget: (value, _) => Text(
                                          _compactMoney(value),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: AppColors.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 28,
                                        interval: pts.length > 8
                                            ? (pts.length / 4).ceilToDouble()
                                            : 1,
                                        getTitlesWidget: (value, _) {
                                          final i = value.toInt();
                                          if (i < 0 || i >= pts.length) {
                                            return const SizedBox.shrink();
                                          }
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            child: Text(
                                              _xLabel(pts[i].period),
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color:
                                                    AppColors.onSurfaceVariant,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  gridData: const FlGridData(show: true),
                                  borderData: FlBorderData(show: false),
                                ),
                              ),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) =>
                            _InlineErrorCard(message: dioErrorMessage(e)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SectionCard(
                title: 'Thống kê gộp',
                subtitle: 'Theo trạng thái đơn',
                child: statsAsync.when(
                  data: (s) => Column(
                    children: [
                      _StatRow(
                        icon: Icons.hourglass_empty_rounded,
                        label: 'Chờ xác nhận',
                        color: StatusPill.colorOf('PENDING'),
                        count: s.pendingConfirm.count,
                        total: fmt.format(s.pendingConfirm.total),
                      ),
                      _StatRow(
                        icon: Icons.local_shipping_outlined,
                        label: 'Đang giao',
                        color: StatusPill.colorOf('SHIPPED'),
                        count: s.shipping.count,
                        total: fmt.format(s.shipping.total),
                      ),
                      _StatRow(
                        icon: Icons.check_circle_outline_rounded,
                        label: 'Đã giao',
                        color: StatusPill.colorOf('DELIVERED'),
                        count: s.delivered.count,
                        total: fmt.format(s.delivered.total),
                      ),
                      _StatRow(
                        icon: Icons.cancel_outlined,
                        label: 'Huỷ / trả',
                        color: StatusPill.colorOf('CANCELLED'),
                        count: s.cancelled.count,
                        total: fmt.format(s.cancelled.total),
                      ),
                      const Divider(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.payments_rounded,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Doanh thu đã giao',
                                style: TextStyle(
                                  color: AppColors.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              fmt.format(s.totalSpent),
                              style: const TextStyle(
                                color: AppColors.onPrimaryContainer,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) =>
                      _InlineErrorCard(message: dioErrorMessage(e)),
                ),
              ),
              const SizedBox(height: 14),
              SectionCard(
                title: 'Tỉ lệ huỷ đơn',
                subtitle: '%',
                child: SizedBox(
                  height: 170,
                  child: cancelAsync.when(
                    data: (pts) => pts.isEmpty
                        ? const _StateHint(
                            icon: Icons.timeline_outlined,
                            title: 'Chua co du lieu ti le huy',
                            subtitle:
                                'Khong co don de tinh toan trong khoang nay.',
                          )
                        : pts.length == 1
                        ? _StateHint(
                            icon: Icons.insights_outlined,
                            title: 'Chi co 1 moc du lieu',
                            subtitle:
                                'Ti le huy ${((pts.first.cancelRate) * 100).toStringAsFixed(1)}% tai ${pts.first.period}',
                          )
                        : LineChart(
                            LineChartData(
                              minX: 0,
                              maxX: (pts.length - 1).toDouble(),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: [
                                    for (var i = 0; i < pts.length; i++)
                                      FlSpot(
                                        i.toDouble(),
                                        pts[i].cancelRate * 100,
                                      ),
                                  ],
                                  color: Colors.deepOrange,
                                  barWidth: 2,
                                  dotData: const FlDotData(show: true),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: Colors.deepOrange.withValues(
                                      alpha: 0.1,
                                    ),
                                  ),
                                ),
                              ],
                              titlesData: FlTitlesData(
                                show: true,
                                topTitles: const AxisTitles(),
                                rightTitles: const AxisTitles(),
                                leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 34,
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: pts.length > 6
                                        ? (pts.length / 3).ceilToDouble()
                                        : 1,
                                    getTitlesWidget: (value, _) {
                                      final i = value.toInt();
                                      if (i < 0 || i >= pts.length) {
                                        return const SizedBox.shrink();
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          _xLabel(pts[i].period),
                                          style: const TextStyle(
                                            fontSize: 9,
                                            color: AppColors.onSurfaceVariant,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              gridData: const FlGridData(show: true),
                              borderData: FlBorderData(show: false),
                            ),
                          ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) =>
                        _InlineErrorCard(message: dioErrorMessage(e)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.count,
    required this.total,
  });

  final IconData icon;
  final String label;
  final Color color;
  final int count;
  final String total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '$count',
            style: const TextStyle(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            total,
            style: const TextStyle(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _InlineErrorCard extends StatelessWidget {
  const _InlineErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF991B1B)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StateHint extends StatelessWidget {
  const _StateHint({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.onSurfaceVariant),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final revenueTimeseriesGroupProvider = FutureProvider.autoDispose
    .family<List<TimeseriesPoint>, String>((ref, groupBy) async {
      final range = ref.watch(adminDateRangeProvider);
      return ref
          .watch(dashboardServiceProvider)
          .revenueTimeseries(
            from: range.start,
            to: range.end,
            groupBy: groupBy,
          );
    });
