import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../providers/admin_providers.dart';

class ReturnsScreen extends ConsumerStatefulWidget {
  const ReturnsScreen({super.key});

  @override
  ConsumerState<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends ConsumerState<ReturnsScreen> {
  String? _statusFilter;
  Future<List<Map<String, dynamic>>>? _future;

  void _reload() {
    _future = ref.read(returnAdminServiceProvider).listAll(
          status: _statusFilter,
          limit: 100,
        );
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _process(int id, String status) async {
    try {
      await ref.read(returnAdminServiceProvider).process(id, status);
      _reload();
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              DropdownButton<String?>(
                value: _statusFilter,
                hint: const Text('Trạng thái'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Tất cả')),
                  DropdownMenuItem(value: 'PENDING', child: Text('PENDING')),
                  DropdownMenuItem(value: 'APPROVED', child: Text('APPROVED')),
                  DropdownMenuItem(value: 'REJECTED', child: Text('REJECTED')),
                ],
                onChanged: (v) {
                  setState(() => _statusFilter = v);
                  _reload();
                },
              ),
              IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _future,
            builder: (context, snap) {
              if (!snap.hasData) {
                return snap.hasError
                    ? Center(child: Text(dioErrorMessage(snap.error!)))
                    : const Center(child: CircularProgressIndicator());
              }
              final rows = snap.data!;
              if (rows.isEmpty) {
                return const Center(child: Text('Không có yêu cầu'));
              }
              return ListView.builder(
                itemCount: rows.length,
                itemBuilder: (_, i) {
                  final r = rows[i];
                  final id = r['id'] as int;
                  final st = r['status']?.toString() ?? '';
                  return ListTile(
                    title: Text('YC #$id · $st'),
                    subtitle: Text(
                      '${r['book_title']} · Đơn ${r['order_id']} · ${r['buyer_email']}',
                    ),
                    trailing: st == 'PENDING'
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: () => _process(id, 'APPROVED'),
                                child: const Text('Duyệt'),
                              ),
                              TextButton(
                                onPressed: () => _process(id, 'REJECTED'),
                                child: const Text('Từ chối'),
                              ),
                            ],
                          )
                        : null,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
