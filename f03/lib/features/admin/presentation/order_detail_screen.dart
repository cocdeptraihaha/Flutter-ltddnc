import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../providers/admin_providers.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final int orderId;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  Map<String, dynamic>? _order;
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final o = await ref
          .read(orderAdminServiceProvider)
          .getOrder(widget.orderId);
      setState(() => _order = o);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(dioErrorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setStatus(String s) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await ref.read(orderAdminServiceProvider).updateStatus(widget.orderId, s);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(dioErrorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _shipment() async {
    final track = TextEditingController(
      text: _order?['tracking_number']?.toString(),
    );
    final prov = TextEditingController(
      text: _order?['shipping_provider']?.toString(),
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Giao vận'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: track,
              decoration: const InputDecoration(labelText: 'Tracking'),
            ),
            TextField(
              controller: prov,
              decoration: const InputDecoration(labelText: 'Đơn vị'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ref
            .read(orderAdminServiceProvider)
            .updateShipment(
              widget.orderId,
              trackingNumber: track.text.trim().isEmpty
                  ? null
                  : track.text.trim(),
              shippingProvider: prov.text.trim().isEmpty
                  ? null
                  : prov.text.trim(),
            );
        await _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(dioErrorMessage(e))));
        }
      }
    }
  }

  Future<void> _cancelDecision() async {
    final ok = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quyết định huỷ đơn'),
        content: const Text('Duyệt hay từ chối yêu cầu huỷ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'deny'),
            child: const Text('Từ chối'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'approve'),
            child: const Text('Duyệt'),
          ),
        ],
      ),
    );
    if (ok != null && ok.isNotEmpty) {
      try {
        await ref
            .read(orderAdminServiceProvider)
            .cancelDecision(widget.orderId, ok == 'approve');
        await _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(dioErrorMessage(e))));
        }
      }
    }
  }

  String? _nextStatusFor(String current) {
    switch (current) {
      case 'PENDING':
        return 'CONFIRMED';
      case 'CONFIRMED':
        return 'INPROGRESS';
      case 'INPROGRESS':
        return 'SHIPPED';
      case 'SHIPPED':
        return 'DELIVERED';
      case 'DELIVERED':
        return 'COMPLETED';
      default:
        return null;
    }
  }

  bool _canCancelOrder(String current) {
    const cancellable = {'PENDING', 'CONFIRMED', 'INPROGRESS', 'SHIPPED'};
    return cancellable.contains(current);
  }

  Future<void> _cancelOrder() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy đơn hàng'),
        content: const Text(
          'Bạn có chắc muốn hủy đơn này? Hành động này sẽ cập nhật trạng thái sang CANCELLED.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Đóng'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hủy đơn'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _setStatus('CANCELLED');
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _order?['status']?.toString() ?? '';
    final nextStatus = _nextStatusFor(status);
    final canCancel = _canCancelOrder(status);
    final hasCancelRequest = status.contains('CANCEL_REQUESTED');

    return Scaffold(
      appBar: AppBar(
        title: Text('Đơn #${widget.orderId}'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading || _order == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: Text('Trạng thái: $status'),
                    subtitle: Text('Tổng: ${_order!['total_price']} ₫'),
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.person_outline_rounded),
                    title: Text('${_order!['full_name']}'),
                    subtitle: Text(
                      '${_order!['phone_number']} \n${_order!['shipping_address']}',
                    ),
                    isThreeLine: true,
                  ),
                ),
                const Divider(),
                const Text(
                  'Items',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...((_order!['order_items'] as List?) ?? []).map<Widget>((it) {
                  final m = it as Map<String, dynamic>;
                  return ListTile(
                    dense: true,
                    title: Text(m['book_title']?.toString() ?? '—'),
                    subtitle: Text('SL ${m['quantity']} × ${m['price']}'),
                  );
                }),
                const Divider(),
                const Text(
                  'Thao tác đơn hàng',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: nextStatus == null || _submitting
                          ? null
                          : () => _setStatus(nextStatus),
                      icon: const Icon(Icons.trending_up_rounded),
                      label: Text(
                        nextStatus == null
                            ? 'Đơn đã ở trạng thái cuối'
                            : 'Xúc tiến: $nextStatus',
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: canCancel && !_submitting
                          ? _cancelOrder
                          : null,
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Hủy đơn'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _submitting ? null : _shipment,
                      icon: const Icon(Icons.local_shipping_outlined),
                      label: const Text('Cập nhật vận chuyển'),
                    ),
                    if (hasCancelRequest)
                      OutlinedButton(
                        onPressed: _cancelDecision,
                        child: const Text('Huỷ đơn — quyết định'),
                      ),
                  ],
                ),
              ],
            ),
    );
  }
}
