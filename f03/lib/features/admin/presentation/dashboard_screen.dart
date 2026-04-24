import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app_theme.dart';
import '../data/date_range_util.dart';
import '../data/models/admin_models.dart';
import '../providers/admin_providers.dart';
import 'widgets/section_card.dart';

/// Dashboard KPI + biểu đồ (mobile-first, pull-to-refresh).
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmtMoney = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    Future<void> refresh() async {
      _invalidateDash(ref);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              const _DateRangeCard(),
              const SizedBox(height: 14),
              ref
                  .watch(dashboardSummaryProvider)
                  .when(
                    data: (s) => _KpiGrid(summary: s, fmtMoney: fmtMoney),
                    loading: () => const _SectionLoader(height: 220),
                    error: (e, _) => _RetryCard(
                      message: e.toString(),
                      onRetry: () => ref.invalidate(dashboardSummaryProvider),
                    ),
                  ),
              const SizedBox(height: 14),
              SectionCard(
                title: 'Doanh thu theo ngày',
                child: SizedBox(
                  height: 200,
                  child: ref
                      .watch(revenueTimeseriesProvider)
                      .when(
                        data: (pts) => pts.isEmpty
                            ? const _ChartStateHint(
                                icon: Icons.bar_chart_outlined,
                                title: 'Chua co du lieu doanh thu',
                                subtitle:
                                    'Hay mo rong khoang thoi gian de xem xu huong.',
                              )
                            : _LineChartWidget(
                                spots: [
                                  for (var i = 0; i < pts.length; i++)
                                    FlSpot(i.toDouble(), pts[i].revenue),
                                ],
                                labels: pts.map((p) => p.period).toList(),
                              ),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => _RetryCard(
                          message: e.toString(),
                          onRetry: () =>
                              ref.invalidate(revenueTimeseriesProvider),
                        ),
                      ),
                ),
              ),
              const SizedBox(height: 14),
              SectionCard(
                title: 'Trạng thái đơn',
                child: SizedBox(
                  height: 220,
                  child: ref
                      .watch(orderStatusBreakdownProvider)
                      .when(
                        data: (rows) {
                          final filtered = rows
                              .where((r) => r.count > 0)
                              .toList();
                          if (filtered.isEmpty) return const EmptyState();
                          return PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                              sections: [
                                for (final r in filtered)
                                  PieChartSectionData(
                                    color: StatusPill.colorOf(r.status),
                                    value: r.count.toDouble(),
                                    title: '${r.count}',
                                    radius: 56,
                                    titleStyle: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => _RetryCard(
                          message: e.toString(),
                          onRetry: () =>
                              ref.invalidate(orderStatusBreakdownProvider),
                        ),
                      ),
                ),
              ),
              const SizedBox(height: 14),
              _TopBooksCard(fmtMoney: fmtMoney),
              const SizedBox(height: 14),
              SectionCard(
                title: 'Doanh thu theo thể loại',
                child: SizedBox(
                  height: 220,
                  child: ref
                      .watch(categoryRevenueProvider)
                      .when(
                        data: (cats) => cats.isEmpty
                            ? const EmptyState()
                            : PieChart(
                                PieChartData(
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 36,
                                  sections: [
                                    for (var i = 0; i < cats.length; i++)
                                      PieChartSectionData(
                                        color: _pieColor(i),
                                        value: cats[i].revenue,
                                        title:
                                            cats[i].categoryName ??
                                            '#${cats[i].categoryId}',
                                        radius: 52,
                                        titleStyle: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => _RetryCard(
                          message: e.toString(),
                          onRetry: () =>
                              ref.invalidate(categoryRevenueProvider),
                        ),
                      ),
                ),
              ),
              const SizedBox(height: 14),
              SectionCard(
                title: 'Top khách hàng',
                child: SizedBox(
                  height: 260,
                  child: ref
                      .watch(topCustomersProvider)
                      .when(
                        data: (rows) => rows.isEmpty
                            ? const EmptyState()
                            : _TopCustomersHorizontalChart(rows: rows),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => _RetryCard(
                          message: e.toString(),
                          onRetry: () => ref.invalidate(topCustomersProvider),
                        ),
                      ),
                ),
              ),
              const SizedBox(height: 14),
              SectionCard(
                title: 'Tỉ lệ huỷ đơn',
                subtitle: '%',
                child: SizedBox(
                  height: 200,
                  child: ref
                      .watch(cancelRateSeriesProvider)
                      .when(
                        data: (pts) => pts.isEmpty
                            ? const _ChartStateHint(
                                icon: Icons.timeline_outlined,
                                title: 'Chua co du lieu ti le huy',
                                subtitle:
                                    'Chua du don hang trong khoang thoi gian da chon.',
                              )
                            : pts.length == 1
                            ? _ChartStateHint(
                                icon: Icons.show_chart_rounded,
                                title: 'Du lieu chua du de ve xu huong',
                                subtitle:
                                    'Hien co 1 moc (${pts.first.period}) - ti le ${((pts.first.cancelRate) * 100).toStringAsFixed(1)}%',
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
                                        interval: pts.length > 6
                                            ? (pts.length / 3).ceilToDouble()
                                            : 1,
                                        getTitlesWidget: (v, _) {
                                          final i = v.toInt();
                                          if (i < 0 || i >= pts.length) {
                                            return const SizedBox.shrink();
                                          }
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            child: Text(
                                              _shortPeriod(pts[i].period),
                                              style: const TextStyle(
                                                fontSize: 9,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    leftTitles: const AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 36,
                                      ),
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
                          onRetry: () =>
                              ref.invalidate(cancelRateSeriesProvider),
                        ),
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

final _topMetricProvider = StateProvider<String>((_) => 'revenue');

class _TopBooksCard extends ConsumerWidget {
  const _TopBooksCard({required this.fmtMoney});

  final NumberFormat fmtMoney;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metric = ref.watch(_topMetricProvider);
    return SectionCard(
      title: 'Top sách',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'revenue', label: Text('Doanh thu')),
              ButtonSegment(value: 'quantity', label: Text('Số lượng')),
            ],
            selected: {metric},
            showSelectedIcon: false,
            onSelectionChanged: (s) =>
                ref.read(_topMetricProvider.notifier).state = s.first,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: ref
                .watch(topBooksProvider(metric))
                .when(
                  data: (books) {
                    final topBooks = books.take(5).toList();
                    if (topBooks.isEmpty) {
                      return const _ChartStateHint(
                        icon: Icons.menu_book_outlined,
                        title: 'Chua co du lieu top sach',
                        subtitle: 'Can them don hang de xep hang top.',
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY:
                                  topBooks
                                      .map(
                                        (b) => metric == 'revenue'
                                            ? b.revenue
                                            : b.quantitySold.toDouble(),
                                      )
                                      .fold<double>(
                                        0,
                                        (a, b) => a > b ? a : b,
                                      ) *
                                  1.35,
                              barGroups: [
                                for (var i = 0; i < topBooks.length; i++)
                                  BarChartGroupData(
                                    x: i,
                                    barRods: [
                                      BarChartRodData(
                                        toY: metric == 'revenue'
                                            ? topBooks[i].revenue
                                            : topBooks[i].quantitySold
                                                  .toDouble(),
                                        color: AppColors.primary,
                                        width: 14,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ],
                                  ),
                              ],
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (v, _) {
                                      final i = v.toInt();
                                      if (i < 0 || i >= topBooks.length) {
                                        return const SizedBox.shrink();
                                      }
                                      final t =
                                          topBooks[i].title ??
                                          '#${topBooks[i].bookId}';
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          t.length > 12
                                              ? '${t.substring(0, 12)}…'
                                              : t,
                                          style: const TextStyle(fontSize: 9),
                                          textAlign: TextAlign.center,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 76,
                                    getTitlesWidget: (value, _) => Text(
                                      _formatAxisValueNTr(value),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ),
                                topTitles: const AxisTitles(),
                                rightTitles: const AxisTitles(),
                              ),
                              barTouchData: BarTouchData(
                                enabled: true,
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipItem:
                                      (group, groupIndex, rod, rodIndex) {
                                        final b = topBooks[group.x.toInt()];
                                        final title = b.title ?? '#${b.bookId}';
                                        final value = metric == 'revenue'
                                            ? fmtMoney.format(rod.toY)
                                            : '${rod.toY.toInt()} cuon';
                                        return BarTooltipItem(
                                          '$title\n$value',
                                          const TextStyle(
                                            color: AppColors.onSurface,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        );
                                      },
                                ),
                              ),
                              gridData: const FlGridData(show: true),
                              borderData: FlBorderData(show: false),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => _RetryCard(
                    message: e.toString(),
                    onRetry: () => ref.invalidate(topBooksProvider(metric)),
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

class _DateRangeCard extends ConsumerWidget {
  const _DateRangeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(adminDateRangeProvider);
    final fmt = DateFormat('dd/MM');

    void setRange(DateTimeRange r) {
      ref.read(adminDateRangeProvider.notifier).state = r;
      _invalidateDash(ref);
    }

    String keyFor(DateTimeRange r) {
      final now = DateTime.now();
      final today = startOfDay(now);
      final end = endOfDay(now);
      if (r.start == today && r.end == end) return 'today';
      final last7 = defaultLast7Days();
      if (r.start == last7.start && r.end == last7.end) return 'last7';
      final d30 = DateTimeRange(
        start: startOfDay(now.subtract(const Duration(days: 29))),
        end: end,
      );
      if (r.start == d30.start && r.end == d30.end) return 'last30';
      return 'custom';
    }

    final active = keyFor(range);

    return SectionCard(
      title: 'Khoảng thời gian',
      subtitle: '${fmt.format(range.start)} - ${fmt.format(range.end)}',
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.calendar_today_rounded,
          size: 18,
          color: AppColors.primary,
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ChoiceChip(
            label: const Text('Hôm nay'),
            selected: active == 'today',
            onSelected: (_) {
              final n = DateTime.now();
              setRange(DateTimeRange(start: startOfDay(n), end: endOfDay(n)));
            },
          ),
          ChoiceChip(
            label: const Text('7 ngày'),
            selected: active == 'last7',
            onSelected: (_) => setRange(defaultLast7Days()),
          ),
          ChoiceChip(
            label: const Text('30 ngày'),
            selected: active == 'last30',
            onSelected: (_) {
              final to = DateTime.now();
              final from = to.subtract(const Duration(days: 29));
              setRange(
                DateTimeRange(start: startOfDay(from), end: endOfDay(to)),
              );
            },
          ),
          ActionChip(
            avatar: const Icon(Icons.event_rounded, size: 16),
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
                setRange(
                  DateTimeRange(
                    start: startOfDay(picked.start),
                    end: endOfDay(picked.end),
                  ),
                );
              }
            },
          ),
        ],
      ),
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
        final aspect = c.maxWidth < 360 ? 1.25 : 1.55;
        return GridView.count(
          crossAxisCount: cross,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: aspect,
          children: [
            _KpiCard(
              title: 'Doanh thu',
              value: fmtMoney.format(s.revenue),
              icon: Icons.payments_outlined,
              iconColor: AppColors.primary,
            ),
            _KpiCard(
              title: 'Số đơn',
              value: '${s.orderCount}',
              icon: Icons.shopping_bag_outlined,
              iconColor: const Color(0xFF2563EB),
            ),
            _KpiCard(
              title: 'AOV',
              value: fmtMoney.format(s.aov),
              icon: Icons.analytics_outlined,
              iconColor: const Color(0xFF16A34A),
            ),
            _KpiCard(
              title: 'Khách mới',
              value: '${s.newUserCount}',
              icon: Icons.person_add_alt_1_outlined,
              iconColor: const Color(0xFF7C3AED),
            ),
            _KpiCard(
              title: 'Sắp hết',
              value: '${s.lowStockCount}',
              icon: Icons.inventory_2_outlined,
              iconColor: const Color(0xFFF59E0B),
              badge: s.lowStockCount > 0,
            ),
            _KpiCard(
              title: 'Đơn chờ',
              value: '${s.pendingOrderCount}',
              icon: Icons.hourglass_empty_rounded,
              iconColor: const Color(0xFFDC2626),
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
    required this.iconColor,
    this.badge = false,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outline),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const Spacer(),
              if (badge)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '!',
                    style: TextStyle(
                      color: iconColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
    if (spots.isEmpty) return const EmptyState();
    if (spots.length == 1) {
      return const _ChartStateHint(
        icon: Icons.insights_outlined,
        title: 'Chi co 1 moc du lieu',
        subtitle: 'Can it nhat 2 moc de hien thi duong xu huong.',
      );
    }
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (labels.length - 1).toDouble(),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: labels.length > 8
                  ? (labels.length / 4).ceilToDouble()
                  : 1,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _shortPeriod(labels[i]),
                    style: const TextStyle(fontSize: 9),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 76,
              getTitlesWidget: (value, _) => Text(
                _formatAxisValueNTr(value),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
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

class _TopCustomersHorizontalChart extends StatelessWidget {
  const _TopCustomersHorizontalChart({required this.rows});

  final List<TopCustomerRow> rows;

  @override
  Widget build(BuildContext context) {
    final topRows = rows.take(6).toList();
    final maxValue = topRows
        .map((e) => e.totalSpent)
        .fold<double>(0, (a, b) => a > b ? a : b);
    final fmt = NumberFormat.compactCurrency(locale: 'vi_VN', symbol: '₫');

    return ListView.separated(
      itemCount: topRows.length,
      physics: const BouncingScrollPhysics(),
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final r = topRows[i];
        final name = (r.fullName?.trim().isNotEmpty ?? false)
            ? r.fullName!.trim()
            : (r.email ?? 'User #${r.userId}');
        final ratio = maxValue > 0 ? (r.totalSpent / maxValue) : 0.0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  fmt.format(r.totalSpent),
                  style: const TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: ratio,
                color: AppColors.primary,
                backgroundColor: AppColors.primary.withValues(alpha: 0.16),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ChartStateHint extends StatelessWidget {
  const _ChartStateHint({
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

class _SectionLoader extends StatelessWidget {
  const _SectionLoader({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _RetryCard extends StatelessWidget {
  const _RetryCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF991B1B)),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
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

String _shortPeriod(String raw) {
  if (raw.length >= 10 && raw.contains('-')) return raw.substring(5, 10);
  if (raw.length >= 7 && raw.contains('-')) return raw.substring(0, 7);
  return raw;
}

String _formatAxisValueNTr(double value) {
  final abs = value.abs();
  if (abs >= 1000000) {
    final tr = value / 1000000;
    final text = tr.abs() >= 10 ? tr.toStringAsFixed(0) : tr.toStringAsFixed(1);
    return '${text}TR';
  }
  if (abs >= 1000) {
    final n = value / 1000;
    final text = n.abs() >= 10 ? n.toStringAsFixed(0) : n.toStringAsFixed(1);
    return '${text}N';
  }
  return value.toStringAsFixed(0);
}
