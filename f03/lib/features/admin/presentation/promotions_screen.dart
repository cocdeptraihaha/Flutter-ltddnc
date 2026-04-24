import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
  final _displayDate = DateFormat('dd-MM-yyyy');
  final _backendDate = DateFormat('yyyy-MM-dd');

  Future<void> _reload() async {
    _future = ref
        .read(promotionAdminServiceProvider)
        .listPromotions(limit: 100);
    setState(() {});
    await _future;
  }

  DateTime? _parseFlexibleDate(String input) {
    final t = input.trim();
    if (t.isEmpty) {
      return null;
    }
    try {
      return _displayDate.parseStrict(t);
    } catch (_) {}
    try {
      return _backendDate.parseStrict(t);
    } catch (_) {}
    return DateTime.tryParse(t);
  }

  String _displayDateValue(dynamic value) {
    final raw = value?.toString() ?? '';
    if (raw.trim().isEmpty) return '';
    final parsed = _parseFlexibleDate(raw.split('T').first);
    if (parsed == null) return raw.split('T').first;
    return _displayDate.format(parsed);
  }

  String? _normalizeDateTime(String input) {
    final parsed = _parseFlexibleDate(input);
    if (parsed == null) return null;
    return '${_backendDate.format(parsed)}T00:00:00';
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final now = DateTime.now();
    final initial = _parseFlexibleDate(controller.text) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Chọn ngày',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );
    if (picked != null) {
      controller.text = _displayDate.format(picked);
    }
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
      s = _parseFlexibleDate(start.trim());
      if (s == null) {
        return 'Ngày bắt đầu không hợp lệ (định dạng dd-MM-yyyy)';
      }
    }
    if (end.trim().isNotEmpty) {
      e = _parseFlexibleDate(end.trim());
      if (e == null) {
        return 'Ngày kết thúc không hợp lệ (định dạng dd-MM-yyyy)';
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
      text: _displayDateValue(existing?['start_date']),
    );
    final end = TextEditingController(
      text: _displayDateValue(existing?['end_date']),
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
                      readOnly: true,
                      onTap: () => _pickDate(start),
                      decoration: InputDecoration(
                        labelText: 'Bắt đầu (dd-MM-yyyy)',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today_outlined),
                          onPressed: () => _pickDate(start),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: end,
                      readOnly: true,
                      onTap: () => _pickDate(end),
                      decoration: InputDecoration(
                        labelText: 'Kết thúc (dd-MM-yyyy)',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today_outlined),
                          onPressed: () => _pickDate(end),
                        ),
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
        heroTag: 'admin_promotions_fab',
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

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

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

  Future<void> _openRewardForm({Map<String, dynamic>? existing}) async {
    final name = TextEditingController(text: existing?['name']?.toString() ?? '');
    final cost = TextEditingController(text: existing?['cost_points']?.toString() ?? '');
    final percent = TextEditingController(text: existing?['discount_percent']?.toString() ?? '');
    final maxDiscount = TextEditingController(text: existing?['max_discount']?.toString() ?? '');
    final validDays = TextEditingController(text: existing?['valid_days']?.toString() ?? '30');
    bool active = (existing?['active'] as bool?) ?? true;
    final isEdit = existing != null;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: Text(isEdit ? 'Sửa phần thưởng điểm' : 'Tạo phần thưởng điểm'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Tên phần thưởng'),
                ),
                TextField(
                  controller: cost,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Điểm cần đổi'),
                ),
                TextField(
                  controller: percent,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Discount %'),
                ),
                TextField(
                  controller: maxDiscount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Giảm tối đa (tuỳ chọn)'),
                ),
                TextField(
                  controller: validDays,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Số ngày hiệu lực'),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: active,
                  onChanged: (v) => setModalState(() => active = v),
                  title: const Text('Kích hoạt'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Huỷ'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(isEdit ? 'Lưu' : 'Tạo'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;

    final n = name.text.trim();
    final c = int.tryParse(cost.text.trim());
    final p = double.tryParse(percent.text.trim());
    final md = maxDiscount.text.trim().isEmpty
        ? null
        : double.tryParse(maxDiscount.text.trim());
    final vd = int.tryParse(validDays.text.trim());

    if (n.isEmpty) {
      _showError('Tên phần thưởng không được để trống');
      return;
    }
    if (c == null || c <= 0) {
      _showError('Điểm cần đổi phải là số nguyên > 0');
      return;
    }
    if (p == null || p <= 0 || p > 100) {
      _showError('Discount % phải > 0 và <= 100');
      return;
    }
    if (md != null && md < 0) {
      _showError('Giảm tối đa phải >= 0');
      return;
    }
    if (vd == null || vd <= 0) {
      _showError('Số ngày hiệu lực phải là số nguyên > 0');
      return;
    }

    final body = <String, dynamic>{
      'name': n,
      'cost_points': c,
      'discount_percent': p,
      'max_discount': md,
      'valid_days': vd,
      'active': active,
    }..removeWhere((_, v) => v == null);

    try {
      final svc = ref.read(pointRewardAdminServiceProvider);
      if (isEdit) {
        await svc.update(existing['id'] as int, body);
      } else {
        await svc.create(body);
      }
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(dioErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
                message: 'Chưa có phần thưởng điểm',
                icon: Icons.stars_outlined,
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              itemCount: rows.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final r = rows[i];
                final active = (r['active'] as bool?) ?? false;
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
                              '${r['cost_points']} điểm · ${r['discount_percent']}% · ${active ? 'Đang bật' : 'Đang tắt'}',
                              style: const TextStyle(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _openRewardForm(existing: r),
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Sửa',
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'admin_point_rewards_fab',
        onPressed: () => _openRewardForm(),
        icon: const Icon(Icons.add),
        label: const Text('Thêm phần thưởng'),
      ),
    );
  }
}
