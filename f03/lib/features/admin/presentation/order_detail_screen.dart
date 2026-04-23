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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final o = await ref.read(orderAdminServiceProvider).getOrder(widget.orderId);
      setState(() => _order = o);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(dioErrorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setStatus(String s) async {
    try {
      await ref.read(orderAdminServiceProvider).updateStatus(widget.orderId, s);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(dioErrorMessage(e))),
        );
      }
    }
  }

  Future<void> _shipment() async {
    final track = TextEditingController(text: _order?['tracking_number']?.toString());
    final prov = TextEditingController(text: _order?['shipping_provider']?.toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Giao vận'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: track, decoration: const InputDecoration(labelText: 'Tracking')),
            TextField(controller: prov, decoration: const InputDecoration(labelText: 'Đơn vị')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lưu')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ref.read(orderAdminServiceProvider).updateShipment(
              widget.orderId,
              trackingNumber: track.text.trim().isEmpty ? null : track.text.trim(),
              shippingProvider: prov.text.trim().isEmpty ? null : prov.text.trim(),
            );
        await _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(dioErrorMessage(e))),
          );
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
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
        await ref.read(orderAdminServiceProvider).cancelDecision(
              widget.orderId,
              ok == 'approve',
            );
        await _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(dioErrorMessage(e))),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                Text('Trạng thái: ${_order!['status']}'),
                Text('Khách: ${_order!['full_name']} · ${_order!['phone_number']}'),
                Text('Địa chỉ: ${_order!['shipping_address']}'),
                Text('Tổng: ${_order!['total_price']} ₫'),
                const Divider(),
                const Text('Items', style: TextStyle(fontWeight: FontWeight.bold)),
                ...((_order!['order_items'] as List?) ?? []).map<Widget>((it) {
                  final m = it as Map<String, dynamic>;
                  return ListTile(
                    dense: true,
                    title: Text(m['book_title']?.toString() ?? '—'),
                    subtitle: Text('SL ${m['quantity']} × ${m['price']}'),
                  );
                }),
                const Divider(),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () => _setStatus('CONFIRMED'),
                      child: const Text('CONFIRMED'),
                    ),
                    OutlinedButton(
                      onPressed: () => _setStatus('SHIPPED'),
                      child: const Text('SHIPPED'),
                    ),
                    OutlinedButton(
                      onPressed: () => _setStatus('DELIVERED'),
                      child: const Text('DELIVERED'),
                    ),
                    OutlinedButton(onPressed: _shipment, child: const Text('Shipment')),
                    if ((_order!['status']?.toString().contains('CANCEL_REQUESTED') ?? false))
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
