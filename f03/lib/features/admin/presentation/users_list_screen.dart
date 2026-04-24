import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app_theme.dart';
import '../../../core/api_client.dart';
import '../../../providers/auth_providers.dart';
import '../data/csv_downloader.dart';
import '../providers/admin_providers.dart';
import 'user_detail_screen.dart';
import 'widgets/section_card.dart';

class UsersListScreen extends ConsumerStatefulWidget {
  const UsersListScreen({super.key});

  @override
  ConsumerState<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends ConsumerState<UsersListScreen> {
  final _q = TextEditingController();
  int _version = 0;

  Future<void> _reload() async {
    setState(() => _version++);
  }

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
                        hintText: 'Tìm email / tên',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: q.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () {
                                  _q.clear();
                                  _reload();
                                },
                              ),
                      ),
                      onSubmitted: (_) => _reload(),
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
                          _export();
                        case 'reload':
                          _reload();
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
            Expanded(
              child: RefreshIndicator(
                onRefresh: _reload,
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  key: ValueKey('users-$_version-$q'),
                  future: svc.listUsers(q: q.isEmpty ? null : q),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return Center(child: Text(dioErrorMessage(snap.error!)));
                    }
                    final rows = snap.data ?? const [];
                    if (rows.isEmpty) {
                      return const EmptyState(
                        message: 'Không có người dùng phù hợp',
                        icon: Icons.people_outline,
                      );
                    }
                    return ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                      itemCount: rows.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final u = rows[i];
                        return _UserTile(
                          user: u,
                          onTap: () async {
                            await Navigator.of(context).push<void>(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    UserDetailScreen(userId: u['id'] as int),
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

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user, required this.onTap});

  final Map<String, dynamic> user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final email = user['email']?.toString() ?? '—';
    final name = user['full_name']?.toString() ?? '';
    final isAdmin = user['is_superuser'] == true;
    final initial = (name.isNotEmpty ? name : email).characters.first.toUpperCase();

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
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: AppColors.primary,
                child: Text(
                  initial,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? email : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    if (name.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    if (isAdmin)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: StatusPill(label: 'ADMIN'),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
