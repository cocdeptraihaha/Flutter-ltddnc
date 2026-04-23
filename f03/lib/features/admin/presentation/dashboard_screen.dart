import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app_theme.dart';
import '../data/date_range_util.dart';
import '../data/models/admin_models.dart';
import '../providers/admin_providers.dart';

/// Dashboard KPI + biểu đồ (MVP).
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final fmtMoney = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _DateRangeChips(),
          const SizedBox(height: 16),
          ref.watch(dashboardSummaryProvider).when(
                data: (s) => _KpiGrid(summary: s, fmtMoney: fmtMoney),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _RetryCard(
                  message: e.toString(),
                  onRetry: () =>
                      ref.invalidate(dashboardSummaryProvider),
                ),
              ),
          const SizedBox(height: 24),
          Text('Doanh thu theo ngày', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 220,
            child: ref.watch(revenueTimeseriesProvider).when(
                  data: (pts) => _LineChartWidget(
                    spots: [
                      for (var i = 0; i < pts.length; i++)
                        FlSpot(i.toDouble(), pts[i].revenue),
                    ],
                    labels: pts.map((p) => p.period).toList(),
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => _RetryCard(
                    message: e.toString(),
                    onRetry: () =>
                        ref.invalidate(revenueTimeseriesProvider),
                  ),
                ),
          ),
          const SizedBox(height: 24),
          Text('Trạng thái đơn', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 220,
            child: ref.watch(orderStatusBreakdownProvider).when(
                  data: (rows) =>
                      rows.where((r) => r.count > 0).isEmpty
                          ? const Center(child: Text('Không có dữ liệu'))
                          : PieChart(
                              PieChartData(
                                sections: [
                                  for (final r in rows.where((x) => x.count > 0))
                                    PieChartSectionData(
                                      color: _colorForStatus(r.status),
                                      value: r.count.toDouble(),
                                      title: '${r.status}\n${r.count}',
                                      radius: 56,
                                      titleStyle: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => _RetryCard(
                    message: e.toString(),
                    onRetry: () =>
                        ref.invalidate(orderStatusBreakdownProvider),
                  ),
                ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text('Top sách', style: theme.textTheme.titleMedium),
              ),
              ToggleButtons(
                isSelected: [
                  ref.watch(_topMetricProvider) == 'revenue',
                  ref.watch(_topMetricProvider) == 'quantity',
                ],
                onPressed: (i) {
                  ref.read(_topMetricProvider.notifier).state =
                      i == 0 ? 'revenue' : 'quantity';
                },
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('Doanh thu'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('SL'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 240,
            child: ref
                .watch(topBooksProvider(ref.watch(_topMetricProvider)))
                .when(
                  data: (books) => books.isEmpty
                      ? const Center(child: Text('Không có dữ liệu'))
                      : BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: books
                                    .map((b) => ref.read(_topMetricProvider) ==
                                            'revenue'
                                        ? b.revenue
                                        : b.quantitySold.toDouble())
                                    .fold<double>(
                                      0,
                                      (a, b) => a > b ? a : b,
                                    ) *
                                1.2,
                            barGroups: [
                              for (var i = 0; i < books.length; i++)
                                BarChartGroupData(
                                  x: i,
                                  barRods: [
                                    BarChartRodData(
                                      toY: ref.read(_topMetricProvider) ==
                                              'revenue'
                                          ? books[i].revenue
                                          : books[i].quantitySold.toDouble(),
                                      color: AppColors.primary,
                                      width: 14,
                                    ),
                                  ],
                                ),
                            ],
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (v, _) {
                                    final idx = v.toInt();
                                    if (idx < 0 || idx >= books.length) {
                                      return const SizedBox.shrink();
                                    }
                                    final t = books[idx].title ?? '#${books[idx].bookId}';
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        t.length > 8 ? '${t.substring(0, 8)}…' : t,
                                        style: const TextStyle(fontSize: 9),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: true),
                              ),
                              topTitles: const AxisTitles(),
                              rightTitles: const AxisTitles(),
                            ),
                            gridData: const FlGridData(show: true),
                            borderData: FlBorderData(show: false),
                          ),
                        ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => _RetryCard(
                    message: e.toString(),
                    onRetry: () => ref.invalidate(
                      topBooksProvider(ref.read(_topMetricProvider)),
                    ),
                  ),
                ),
          ),
          const SizedBox(height: 24),
          Text('Doanh thu theo thể loại', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 220,
            child: ref.watch(categoryRevenueProvider).when(
                  data: (cats) => cats.isEmpty
                      ? const Center(child: Text('Không có dữ liệu'))
                      : PieChart(
                          PieChartData(
                            sections: [
                              for (var i = 0; i < cats.length; i++)
                                PieChartSectionData(
                                  color: _pieColor(i),
                                  value: cats[i].revenue,
                                  title:
                                      '${cats[i].categoryName ?? "${cats[i].categoryId}"}\n${fmtMoney.format(cats[i].revenue)}',
                                  radius: 52,
                                  titleStyle: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                            ],
                          ),
                        ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => _RetryCard(
                    message: e.toString(),
                    onRetry: () =>
                        ref.invalidate(categoryRevenueProvider),
                  ),
                ),
          ),
          const SizedBox(height: 24),
          Text('Top khách hàng', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 240,
            child: ref.watch(topCustomersProvider).when(
                  data: (rows) => rows.isEmpty
                      ? const Center(child: Text('Không có dữ liệu'))
                      : BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: rows
                                    .map((r) => r.totalSpent)
                                    .fold<double>(0, (a, b) => a > b ? a : b) *
                                1.15,
                            barGroups: [
                              for (var i = 0; i < rows.length; i++)
                                BarChartGroupData(
                                  x: i,
                                  barRods: [
                                    BarChartRodData(
                                      toY: rows[i].totalSpent,
                                      color: AppColors.primary,
                                      width: 16,
                                    ),
                                  ],
                                ),
                            ],
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (v, _) {
                                    final idx = v.toInt();
                                    if (idx < 0 || idx >= rows.length) {
                                      return const SizedBox.shrink();
                                    }
                                    final n =
                                        rows[idx].fullName ?? rows[idx].email ?? '';
                                    return Text(
                                      n.length > 6 ? '${n.substring(0, 6)}…' : n,
                                      style: const TextStyle(fontSize: 9),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: true),
                              ),
                              topTitles: const AxisTitles(),
                              rightTitles: const AxisTitles(),
                            ),
                            gridData: const FlGridData(show: true),
                            borderData: FlBorderData(show: false),
                          ),
                        ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => _RetryCard(
                    message: e.toString(),
                    onRetry: () =>
                        ref.invalidate(topCustomersProvider),
                  ),
                ),
          ),
          const SizedBox(height: 24),
          Text('Tỉ lệ huỷ đơn', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
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
                                isCurved: true,
                                color: Colors.deepOrange,
                                barWidth: 3,
                                dotData: const FlDotData(show: true),
                              ),
                            ],
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (v, _) {
                                    final idx = v.toInt();
                                    if (idx < 0 || idx >= pts.length) {
                                      return const SizedBox.shrink();
                                    }
                                    return Text(
                                      pts[idx].period,
                                      style: const TextStyle(fontSize: 9),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: true),
                              ),
                              topTitles: const AxisTitles(),
                              rightTitles: const AxisTitles(),
                            ),
                            gridData: const FlGridData(show: true),
                            borderData: FlBorderData(show: false),
                          ),
                        ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => _RetryCard(
                    message: e.toString(),
                    onRetry: () =>
                        ref.invalidate(cancelRateSeriesProvider),
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

final _topMetricProvider = StateProvider<String>((_) => 'revenue');

class _DateRangeChips extends ConsumerWidget {
  const _DateRangeChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void setRange(DateTimeRange range) {
      ref.read(adminDateRangeProvider.notifier).state = range;
      _invalidateDash(ref);
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ActionChip(
          label: const Text('Hôm nay'),
          onPressed: () {
            final n = DateTime.now();
            setRange(DateTimeRange(start: startOfDay(n), end: endOfDay(n)));
          },
        ),
        ActionChip(
          label: const Text('7 ngày'),
          onPressed: () => setRange(defaultLast7Days()),
        ),
        ActionChip(
          label: const Text('30 ngày'),
          onPressed: () {
            final to = DateTime.now();
            final from = to.subtract(const Duration(days: 29));
            setRange(DateTimeRange(
              start: startOfDay(from),
              end: endOfDay(to),
            ));
          },
        ),
        ActionChip(
          label: const Text('Tuỳ chọn'),
          onPressed: () async {
            final now = DateTime.now();
            final picked = await showDateRangePicker(
              context: context,
              firstDate: now.subtract(const Duration(days: 365 * 2)),
              lastDate: now.add(const Duration(days: 1)),
              initialDateRange: ref.read(adminDateRangeProvider),
            );
            if (picked != null) {
              setRange(DateTimeRange(
                start: startOfDay(picked.start),
                end: endOfDay(picked.end),
              ));
            }
          },
        ),
      ],
    );
  }
}

void _invalidateDash(WidgetRef ref) {
  ref.invalidate(dashboardSummaryProvider);
  ref.invalidate(revenueTimeseriesProvider);
  ref.invalidate(orderStatusBreakdownProvider);
  ref.invalidate(topBooksProvider('revenue'));
  ref.invalidate(topBooksProvider('quantity'));
  ref.invalidate(categoryRevenueProvider);
  ref.invalidate(topCustomersProvider);
  ref.invalidate(cancelRateSeriesProvider);
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.summary, required this.fmtMoney});

  final DashboardSummary summary;
  final NumberFormat fmtMoney;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    return LayoutBuilder(
      builder: (context, c) {
        final cross = c.maxWidth > 700 ? 4 : 2;
        return GridView.count(
          crossAxisCount: cross,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            _KpiCard(
              title: 'Doanh thu',
              value: fmtMoney.format(s.revenue),
              icon: Icons.payments_outlined,
            ),
            _KpiCard(
              title: 'Số đơn',
              value: '${s.orderCount}',
              icon: Icons.shopping_bag_outlined,
            ),
            _KpiCard(
              title: 'AOV',
              value: fmtMoney.format(s.aov),
              icon: Icons.analytics_outlined,
            ),
            _KpiCard(
              title: 'Khách mới',
              value: '${s.newUserCount}',
              icon: Icons.person_add_alt_1_outlined,
            ),
            _KpiCard(
              title: 'Low stock',
              value: '${s.lowStockCount}',
              icon: Icons.inventory_2_outlined,
              badge: s.lowStockCount > 0,
            ),
            _KpiCard(
              title: 'Đơn chờ',
              value: '${s.pendingOrderCount}',
              icon: Icons.hourglass_empty_rounded,
              badge: s.pendingOrderCount > 0,
            ),
          ],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    this.badge = false,
  });

  final String title;
  final String value;
  final IconData icon;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 22),
                if (badge) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '!',
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _LineChartWidget extends StatelessWidget {
  const _LineChartWidget({required this.spots, required this.labels});

  final List<FlSpot> spots;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    if (spots.isEmpty) {
      return const Center(child: Text('Không có dữ liệu'));
    }
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                return Text(
                  labels[i],
                  style: const TextStyle(fontSize: 9),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true),
          ),
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
        ),
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

class _RetryCard extends StatelessWidget {
  const _RetryCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(message, style: TextStyle(color: Colors.red.shade900)),
            TextButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}

Color _colorForStatus(String s) {
  final i = s.hashCode.abs() % 8;
  return [
    Colors.purple,
    Colors.blue,
    Colors.teal,
    Colors.amber.shade700,
    Colors.green,
    Colors.deepOrange,
    Colors.pink,
    Colors.indigo,
  ][i];
}

Color _pieColor(int i) {
  return [
    AppColors.primary,
    Colors.teal,
    Colors.orange,
    Colors.pink,
    Colors.blueGrey,
    Colors.green,
    Colors.amber,
  ][i % 7];
}
