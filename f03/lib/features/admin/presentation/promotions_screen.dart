import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app_theme.dart';
import '../../../core/api_client.dart';
import '../providers/admin_providers.dart';
import 'widgets/section_card.dart';

class PromotionsScreen extends ConsumerStatefulWidget {
  const PromotionsScreen({super.key});

  @override
  ConsumerState<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends ConsumerState<PromotionsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.outline),
                ),
                child: TabBar(
                  controller: _tab,
                  indicator: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: const EdgeInsets.all(4),
                  dividerColor: Colors.transparent,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.onSurfaceVariant,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                  tabs: const [
                    Tab(text: 'Khuyến mãi'),
                    Tab(text: 'Đổi điểm'),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: const [_PromotionsTab(), _PointRewardsTab()],
              ),
            ),
          ],
        ),
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
  final _dateRe = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  Future<void> _reload() async {
    _future = ref
        .read(promotionAdminServiceProvider)
        .listPromotions(limit: 100);
    setState(() {});
    await _future;
  }

  String? _normalizeDateTime(String input) {
    final t = input.trim();
    if (t.isEmpty) return null;
    if (t.contains('T')) return t;
    return '${t}T00:00:00';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String? _validatePromotionInputs({
    required String code,
    required String discount,
    required String maxDiscount,
    required String start,
    required String end,
  }) {
    if (code.trim().isEmpty) return 'Code khuyến mãi không được để trống';
    final pct = double.tryParse(discount.trim());
    if (pct == null || pct <= 0 || pct > 100) {
      return 'Discount % phải là số > 0 và <= 100';
    }
    if (maxDiscount.trim().isNotEmpty) {
      final md = double.tryParse(maxDiscount.trim());
      if (md == null || md < 0) return 'Giảm tối đa phải là số >= 0';
    }
    DateTime? s;
    DateTime? e;
    if (start.trim().isNotEmpty) {
      if (!_dateRe.hasMatch(start.trim())) {
        return 'Ngày bắt đầu sai định dạng YYYY-MM-DD';
      }
      s = DateTime.tryParse(start.trim());
      if (s == null) {
        return 'Ngày bắt đầu không hợp lệ';
      }
    }
    if (end.trim().isNotEmpty) {
      if (!_dateRe.hasMatch(end.trim())) {
        return 'Ngày kết thúc sai định dạng YYYY-MM-DD';
      }
      e = DateTime.tryParse(end.trim());
      if (e == null) {
        return 'Ngày kết thúc không hợp lệ';
      }
    }
    if (s != null && e != null && s.isAfter(e)) {
      return 'Ngày bắt đầu phải trước hoặc bằng ngày kết thúc';
    }
    return null;
  }

  Future<void> _openPromotionForm({Map<String, dynamic>? existing}) async {
    final code = TextEditingController(
      text: existing?['code']?.toString() ?? '',
    );
    final name = TextEditingController(
      text: existing?['name']?.toString() ?? '',
    );
    final discount = TextEditingController(
      text: existing?['discount_percent']?.toString() ?? '',
    );
    final maxDiscount = TextEditingController(
      text: existing?['max_discount']?.toString() ?? '',
    );
    final start = TextEditingController(
      text: existing?['start_date']?.toString().split('T').first ?? '',
    );
    final end = TextEditingController(
      text: existing?['end_date']?.toString().split('T').first ?? '',
    );
    final isEdit = existing != null;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            4,
            20,
            20 + MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEdit ? 'Sửa mã khuyến mãi' : 'Tạo mã khuyến mãi',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: code,
                decoration: const InputDecoration(labelText: 'Code'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Tên hiển thị'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: discount,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Discount %',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: maxDiscount,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Giảm tối đa',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: start,
                      decoration: const InputDecoration(
                        labelText: 'Bắt đầu (YYYY-MM-DD)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: end,
                      decoration: const InputDecoration(
                        labelText: 'Kết thúc (YYYY-MM-DD)',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.pop(ctx, true),
                icon: const Icon(Icons.save_outlined),
                label: Text(isEdit ? 'Lưu thay đổi' : 'Tạo mã'),
              ),
            ],
          ),
        );
      },
    );
    if (ok != true) return;
    final validationError = _validatePromotionInputs(
      code: code.text,
      discount: discount.text,
      maxDiscount: maxDiscount.text,
      start: start.text,
      end: end.text,
    );
    if (validationError != null) {
      _showError(validationError);
      return;
    }
    try {
      final body = <String, dynamic>{
        'code': code.text.trim().isEmpty ? null : code.text.trim(),
        'name': name.text.trim().isEmpty ? null : name.text.trim(),
        'discount_percent': double.tryParse(discount.text.trim()),
        'max_discount': double.tryParse(maxDiscount.text.trim()),
        'start_date': _normalizeDateTime(start.text),
        'end_date': _normalizeDateTime(end.text),
      };
      body.removeWhere((_, v) => v == null);
      if (isEdit) {
        await ref
            .read(promotionAdminServiceProvider)
            .updatePromotion(existing['id'] as int, body);
      } else {
        await ref.read(promotionAdminServiceProvider).createPromotion(body);
      }
      await _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(dioErrorMessage(e))));
      }
    }
  }

  Future<void> _deletePromotion(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa mã giảm giá'),
        content: const Text('Bạn có chắc muốn xóa mã này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(promotionAdminServiceProvider).deletePromotion(id);
      await _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(dioErrorMessage(e))));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _issue() async {
    final uid = TextEditingController();
    final pid = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            4,
            20,
            20 + MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Cấp mã cho user',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              TextField(
                controller: uid,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'User ID',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pid,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Promotion ID',
                  prefixIcon: Icon(Icons.local_offer_outlined),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Huỷ'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(ctx, true),
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('Gửi'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    if (ok == true) {
      final userId = int.tryParse(uid.text.trim());
      final promotionId = int.tryParse(pid.text.trim());
      if (userId == null || userId <= 0) {
        _showError('User ID phải là số nguyên dương');
        return;
      }
      if (promotionId == null || promotionId <= 0) {
        _showError('Promotion ID phải là số nguyên dương');
        return;
      }
      try {
        await ref
            .read(promotionAdminServiceProvider)
            .issueToUser(userId: userId, promotionId: promotionId);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Đã cấp mã')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(dioErrorMessage(e))));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
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
                message: 'Chưa có khuyến mãi',
                icon: Icons.local_offer_outlined,
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              itemCount: rows.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _PromotionTile(
                data: rows[i],
                onEdit: () => _openPromotionForm(existing: rows[i]),
                onDelete: () => _deletePromotion(rows[i]['id'] as int),
                onStats: () async {
                  try {
                    final s = await ref
                        .read(promotionAdminServiceProvider)
                        .stats(rows[i]['id'] as int);
                    if (!context.mounted) return;
                    showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Thống kê'),
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
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final action = await showModalBottomSheet<String>(
            context: context,
            backgroundColor: AppColors.surface,
            showDragHandle: true,
            builder: (ctx) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.add_card_outlined),
                    title: const Text('Tạo mã giảm giá'),
                    onTap: () => Navigator.pop(ctx, 'create'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.card_giftcard_rounded),
                    title: const Text('Cấp mã cho user'),
                    onTap: () => Navigator.pop(ctx, 'issue'),
                  ),
                ],
              ),
            ),
          );
          if (action == 'create') {
            await _openPromotionForm();
          } else if (action == 'issue') {
            await _issue();
          }
        },
        icon: const Icon(Icons.local_offer_outlined),
        label: const Text('Khuyến mãi'),
      ),
    );
  }
}

class _PromotionTile extends StatelessWidget {
  const _PromotionTile({
    required this.data,
    required this.onStats,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> data;
  final VoidCallback onStats;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final name = data['name']?.toString() ?? data['code']?.toString() ?? '—';
    final discount = data['discount_percent'];
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outline),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.local_offer_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID ${data['id']} · giảm $discount%',
                  style: const TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              switch (v) {
                case 'stats':
                  onStats();
                case 'edit':
                  onEdit();
                case 'delete':
                  onDelete();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'stats', child: Text('Thống kê')),
              PopupMenuItem(value: 'edit', child: Text('Sửa')),
              PopupMenuItem(value: 'delete', child: Text('Xóa')),
            ],
          ),
        ],
      ),
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

  Future<void> _reload() async {
    _future = ref.read(pointRewardAdminServiceProvider).list(limit: 100);
    setState(() {});
    await _future;
  }

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _reload,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
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
              message: 'Chưa có phần thưởng điểm',
              icon: Icons.stars_outlined,
            );
          }
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: rows.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final r = rows[i];
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.outline),
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.stars_rounded,
                        color: Color(0xFFB45309),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r['name']?.toString() ?? '—',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${r['cost_points']} điểm · ${r['discount_percent']}%',
                            style: const TextStyle(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
