import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../providers/admin_providers.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  Future<List<Map<String, dynamic>>>? _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = ref.read(categoryAdminServiceProvider).list(limit: 200);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thể loại'),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final nameCtl = TextEditingController();
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Thêm thể loại'),
              content: TextField(
                controller: nameCtl,
                decoration: const InputDecoration(labelText: 'Tên'),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Tạo')),
              ],
            ),
          );
          if (ok == true && nameCtl.text.trim().isNotEmpty) {
            try {
              await ref.read(categoryAdminServiceProvider).create({'name': nameCtl.text.trim()});
              _reload();
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(dioErrorMessage(e))));
              }
            }
          }
        },
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text(dioErrorMessage(snap.error!)));
          }
          final rows = snap.data ?? [];
          return ListView.builder(
            itemCount: rows.length,
            itemBuilder: (_, i) {
              final c = rows[i];
              return ListTile(
                title: Text(c['name']?.toString() ?? '—'),
                subtitle: Text('id: ${c['id']} · parent: ${c['parent_id']}'),
                onTap: () async {
                  final ctl = TextEditingController(text: c['name']?.toString());
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Sửa thể loại'),
                      content: TextField(controller: ctl, decoration: const InputDecoration(labelText: 'Tên')),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
                        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lưu')),
                      ],
                    ),
                  );
                  if (ok == true) {
                    try {
                      await ref.read(categoryAdminServiceProvider).update(c['id'] as int, {'name': ctl.text.trim()});
                      _reload();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(dioErrorMessage(e))));
                      }
                    }
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
