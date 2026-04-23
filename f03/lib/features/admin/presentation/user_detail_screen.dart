import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../providers/admin_providers.dart';

class UserDetailScreen extends ConsumerStatefulWidget {
  const UserDetailScreen({super.key, required this.userId});

  final int userId;

  @override
  ConsumerState<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends ConsumerState<UserDetailScreen> {
  Map<String, dynamic>? _u;
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _u = await ref.read(userAdminServiceProvider).getUser(widget.userId);
      _orders = await ref.read(userAdminServiceProvider).userOrders(widget.userId);
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

  Future<void> _ban(bool active) async {
    try {
      await ref.read(userAdminServiceProvider).setActive(widget.userId, active);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(dioErrorMessage(e))),
        );
      }
    }
  }

  Future<void> _role(bool superuser) async {
    try {
      await ref.read(userAdminServiceProvider).setRole(widget.userId, superuser);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(dioErrorMessage(e))),
        );
      }
    }
  }

  Future<void> _points() async {
    final delta = TextEditingController();
    final reason = TextEditingController(text: 'Admin điều chỉnh');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Điều chỉnh điểm'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: delta,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Delta (+/-)'),
            ),
            TextField(
              controller: reason,
              decoration: const InputDecoration(labelText: 'Lý do'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Gửi')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ref.read(userAdminServiceProvider).adjustPoints(
              widget.userId,
              delta: int.parse(delta.text.trim()),
              reason: reason.text.trim(),
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã cập nhật điểm')),
          );
        }
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('User #${widget.userId}'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Thông tin'),
            Tab(text: 'Đơn hàng'),
          ]),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text('Email: ${_u?['email']}'),
                      Text('Tên: ${_u?['full_name']}'),
                      Text('Active: ${_u?['is_active']} · Superuser: ${_u?['is_superuser']}'),
                      const Divider(),
                      OutlinedButton(
                        onPressed: () => _ban(!(_u?['is_active'] == true)),
                        child: Text(_u?['is_active'] == true ? 'Ban' : 'Mở khoá'),
                      ),
                      OutlinedButton(
                        onPressed: () => _role(!(_u?['is_superuser'] == true)),
                        child: Text(_u?['is_superuser'] == true ? 'Hạ admin' : 'Nâng admin'),
                      ),
                      OutlinedButton(onPressed: _points, child: const Text('Điểm thưởng')),
                    ],
                  ),
                  ListView.builder(
                    itemCount: _orders.length,
                    itemBuilder: (_, i) {
                      final o = _orders[i];
                      return ListTile(
                        title: Text('Đơn #${o['id']} · ${o['status']}'),
                        subtitle: Text('${o['total_price']} ₫'),
                      );
                    },
                  ),
                ],
              ),
      ),
    );
  }
}
