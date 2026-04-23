import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../providers/admin_providers.dart';

class PromotionsScreen extends ConsumerStatefulWidget {
  const PromotionsScreen({super.key});

  @override
  ConsumerState<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends ConsumerState<PromotionsScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Khuyến mãi'),
              Tab(text: 'Đổi điểm'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                const _PromotionsTab(),
                const _PointRewardsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PromotionsTab extends ConsumerStatefulWidget {
  const _PromotionsTab();

  @override
  ConsumerState<_PromotionsTab> createState() => _PromotionsTabState();
}

class _PromotionsTabState extends ConsumerState<_PromotionsTab> {
  Future<List<Map<String, dynamic>>>? _future;

  void _reload() {
    _future = ref.read(promotionAdminServiceProvider).listPromotions(limit: 100);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _issue() async {
    final uid = TextEditingController();
    final pid = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cấp mã cho user'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: uid,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'user_id'),
            ),
            TextField(
              controller: pid,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'promotion_id'),
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
        await ref.read(promotionAdminServiceProvider).issueToUser(
              userId: int.parse(uid.text.trim()),
              promotionId: int.parse(pid.text.trim()),
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã cấp')),
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              FilledButton(onPressed: _issue, child: const Text('Issue to user')),
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
              return ListView.builder(
                itemCount: rows.length,
                itemBuilder: (_, i) {
                  final p = rows[i];
                  return ListTile(
                    title: Text(p['name']?.toString() ?? p['code']?.toString() ?? '—'),
                    subtitle: Text('id ${p['id']} · ${p['discount_percent']}%'),
                    trailing: IconButton(
                      icon: const Icon(Icons.analytics_outlined),
                      onPressed: () async {
                        try {
                          final s =
                              await ref.read(promotionAdminServiceProvider).stats(p['id'] as int);
                          if (!context.mounted) return;
                          showDialog<void>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Stats'),
                              content: Text(s.toString()),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(dioErrorMessage(e))),
                            );
                          }
                        }
                      },
                    ),
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

class _PointRewardsTab extends ConsumerStatefulWidget {
  const _PointRewardsTab();

  @override
  ConsumerState<_PointRewardsTab> createState() => _PointRewardsTabState();
}

class _PointRewardsTabState extends ConsumerState<_PointRewardsTab> {
  Future<List<Map<String, dynamic>>>? _future;

  void _reload() {
    _future = ref.read(pointRewardAdminServiceProvider).list(limit: 100);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
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
            final r = rows[i];
            return ListTile(
              title: Text(r['name']?.toString() ?? '—'),
              subtitle: Text('cost ${r['cost_points']} · ${r['discount_percent']}%'),
            );
          },
        );
      },
    );
  }
}
