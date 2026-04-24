import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app_theme.dart';
import '../../../core/api_client.dart';
import '../../../providers/auth_providers.dart';
import '../data/csv_downloader.dart';
import '../providers/admin_providers.dart';
import 'order_detail_screen.dart';
import 'widgets/section_card.dart';

const _statuses = [
  'PENDING',
  'CONFIRMED',
  'INPROGRESS',
  'SHIPPED',
  'DELIVERED',
  'COMPLETED',
  'CANCELLED',
  'CANCEL_REQUESTED',
  'RETURNED',
];

class OrdersListScreen extends ConsumerStatefulWidget {
  const OrdersListScreen({super.key});

  @override
  ConsumerState<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends ConsumerState<OrdersListScreen> {
  final Set<String> _selected = {};
  final _q = TextEditingController();
  int _skip = 0;
  int _version = 0;
  static const _limit = 30;

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() => _version++);
  }

  Future<void> _exportCsv() async {
    try {
      await downloadAndShareCsv(
        ref.read(dioProvider),
        path: '/orders/admin/export.csv',
        queryParameters: {
          if (_selected.isNotEmpty) 'status_in': _selected.join(','),
        },
        fileName: 'orders_export.csv',
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
    final range = ref.watch(adminDateRangeProvider);
    final svc = ref.watch(orderAdminServiceProvider);
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final q = _q.text.trim();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _q,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Tìm theo ghi chú / tracking',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: q.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () {
                                  _q.clear();
                                  setState(() {
                                    _skip = 0;
                                    _version++;
                                  });
                                },
                              ),
                      ),
                      onSubmitted: (_) => setState(() {
                        _skip = 0;
                        _version++;
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded),
                    tooltip: 'Thao tác',
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    onSelected: (v) {
                      switch (v) {
                        case 'export':
                          _exportCsv();
                        case 'reload':
                          _reload();
                        case 'clear':
                          setState(() {
                            _selected.clear();
                            _skip = 0;
                            _version++;
                          });
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'export',
                        child: ListTile(
                          dense: true,
                          leading: Icon(Icons.download_outlined),
                          title: Text('Xuất CSV'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'clear',
                        child: ListTile(
                          dense: true,
                          leading: Icon(Icons.filter_alt_off_outlined),
                          title: Text('Bỏ lọc'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'reload',
                        child: ListTile(
                          dense: true,
                          leading: Icon(Icons.refresh_rounded),
                          title: Text('Làm mới'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            HorizontalChips(
              children: [
                for (final s in _statuses)
                  FilterChip(
                    label: Text(s),
                    selected: _selected.contains(s),
                    avatar: CircleAvatar(
                      radius: 5,
                      backgroundColor: StatusPill.colorOf(s),
                    ),
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _selected.add(s);
                        } else {
                          _selected.remove(s);
                        }
                        _skip = 0;
                        _version++;
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _reload,
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  key: ValueKey(
                      'orders-$_skip-$_version-${_selected.join(",")}-$q'),
                  future: svc.listOrders(
                    skip: _skip,
                    limit: _limit,
                    statusIn: _selected.isEmpty ? null : _selected.toList(),
                    from: range.start,
                    to: range.end,
                    q: q.isEmpty ? null : q,
                  ),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return _OrderErrorView(
                        message: dioErrorMessage(snap.error!),
                        onRetry: _reload,
                      );
                    }
                    final rows = snap.data ?? const [];
                    if (rows.isEmpty) {
                      return const EmptyState(
                        message: 'Không có đơn hàng phù hợp',
                        icon: Icons.receipt_long_outlined,
                      );
                    }
                    return ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: rows.length + 1,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        if (i == rows.length) {
                          return _OrderPager(
                            skip: _skip,
                            canPrev: _skip > 0,
                            canNext: rows.length >= _limit,
                            onPrev: () => setState(() {
                              _skip -= _limit;
                              _version++;
                            }),
                            onNext: () => setState(() {
                              _skip += _limit;
                              _version++;
                            }),
                          );
                        }
                        final o = rows[i];
                        return _OrderTile(
                          order: o,
                          fmt: fmt,
                          onTap: () async {
                            await Navigator.of(context).push<void>(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    OrderDetailScreen(orderId: o['id'] as int),
                              ),
                            );
                            await _reload();
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({
    required this.order,
    required this.fmt,
    required this.onTap,
  });

  final Map<String, dynamic> order;
  final NumberFormat fmt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final id = order['id'];
    final status = order['status']?.toString() ?? '—';
    final total = (order['total_price'] as num?)?.toDouble() ?? 0;
    final name = order['full_name']?.toString() ?? '—';
    final phone = order['phone_number']?.toString();
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.outline),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Đơn #$id',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  StatusPill(label: status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                name,
                style: const TextStyle(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (phone != null && phone.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    phone,
                    style: const TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.payments_outlined,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    fmt.format(total),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.onSurfaceVariant),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderPager extends StatelessWidget {
  const _OrderPager({
    required this.skip,
    required this.canPrev,
    required this.canNext,
    required this.onPrev,
    required this.onNext,
  });

  final int skip;
  final bool canPrev;
  final bool canNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OutlinedButton.icon(
            onPressed: canPrev ? onPrev : null,
            icon: const Icon(Icons.chevron_left_rounded),
            label: const Text('Trước'),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: canNext ? onNext : null,
            icon: const Icon(Icons.chevron_right_rounded),
            label: const Text('Sau'),
          ),
        ],
      ),
    );
  }
}

class _OrderErrorView extends StatelessWidget {
  const _OrderErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 42, color: Color(0xFFDC2626)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
