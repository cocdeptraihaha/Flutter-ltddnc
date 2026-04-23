import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../../providers/auth_providers.dart';
import '../data/csv_downloader.dart';
import '../providers/admin_providers.dart';
import 'order_detail_screen.dart';

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
  static const _limit = 30;

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in _statuses)
                FilterChip(
                  label: Text(s),
                  selected: _selected.contains(s),
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        _selected.add(s);
                      } else {
                        _selected.remove(s);
                      }
                      _skip = 0;
                    });
                  },
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _q,
                  decoration: const InputDecoration(
                    hintText: 'Tìm / ghi chú / tracking',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onSubmitted: (_) => setState(() => _skip = 0),
                ),
              ),
              IconButton(
                tooltip: 'Export CSV',
                onPressed: _exportCsv,
                icon: const Icon(Icons.download_outlined),
              ),
              IconButton(
                onPressed: () => setState(() {}),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: svc.listOrders(
              skip: _skip,
              limit: _limit,
              statusIn: _selected.isEmpty ? null : _selected.toList(),
              from: range.start,
              to: range.end,
              q: _q.text.trim().isEmpty ? null : _q.text.trim(),
            ),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(child: Text(dioErrorMessage(snap.error!)));
              }
              final rows = snap.data ?? [];
              if (rows.isEmpty) {
                return const Center(child: Text('Không có đơn'));
              }
              return ListView.builder(
                itemCount: rows.length,
                itemBuilder: (_, i) {
                  final o = rows[i];
                  final id = o['id'] as int;
                  return ListTile(
                    title: Text('Đơn #$id · ${o['status']}'),
                    subtitle: Text(
                      '${o['full_name'] ?? ''} · ${o['total_price'] ?? 0} ₫',
                    ),
                    onTap: () async {
                      await Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => OrderDetailScreen(orderId: id),
                        ),
                      );
                      setState(() {});
                    },
                  );
                },
              );
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: _skip > 0
                  ? () => setState(() => _skip -= _limit)
                  : null,
              child: const Text('Trước'),
            ),
            TextButton(
              onPressed: () => setState(() => _skip += _limit),
              child: const Text('Sau'),
            ),
          ],
        ),
      ],
    );
  }
}
