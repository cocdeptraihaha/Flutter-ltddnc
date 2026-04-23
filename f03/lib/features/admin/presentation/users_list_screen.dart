import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../../providers/auth_providers.dart';
import '../data/csv_downloader.dart';
import '../providers/admin_providers.dart';
import 'user_detail_screen.dart';

class UsersListScreen extends ConsumerStatefulWidget {
  const UsersListScreen({super.key});

  @override
  ConsumerState<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends ConsumerState<UsersListScreen> {
  final _q = TextEditingController();

  Future<void> _export() async {
    try {
      await downloadAndShareCsv(
        ref.read(dioProvider),
        path: '/users/admin/export.csv',
        fileName: 'users_export.csv',
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
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final svc = ref.watch(userAdminServiceProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _q,
                  decoration: const InputDecoration(
                    hintText: 'Tìm email / tên',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onSubmitted: (_) => setState(() {}),
                ),
              ),
              IconButton(onPressed: _export, icon: const Icon(Icons.download_outlined)),
              IconButton(onPressed: () => setState(() {}), icon: const Icon(Icons.refresh)),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: svc.listUsers(q: _q.text.trim().isEmpty ? null : _q.text.trim()),
            builder: (context, snap) {
              if (!snap.hasData) {
                return snap.hasError
                    ? Center(child: Text(dioErrorMessage(snap.error!)))
                    : const Center(child: CircularProgressIndicator());
              }
              final rows = snap.data!;
              return ListView.builder(
                itemCount: rows.length,
                itemBuilder: (_, i) {
                  final u = rows[i];
                  final id = u['id'] as int;
                  return ListTile(
                    title: Text(u['email']?.toString() ?? '—'),
                    subtitle: Text('${u['full_name']} · admin=${u['is_superuser']}'),
                    onTap: () async {
                      await Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => UserDetailScreen(userId: id),
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
      ],
    );
  }
}
