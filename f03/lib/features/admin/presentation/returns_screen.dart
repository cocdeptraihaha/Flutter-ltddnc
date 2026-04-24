import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app_theme.dart';
import '../../../core/api_client.dart';
import '../providers/admin_providers.dart';
import 'widgets/section_card.dart';

class ReturnsScreen extends ConsumerStatefulWidget {
  const ReturnsScreen({super.key});

  @override
  ConsumerState<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends ConsumerState<ReturnsScreen> {
  String? _statusFilter;
  Future<List<Map<String, dynamic>>>? _future;

  Future<void> _reload() async {
    _future = ref.read(returnAdminServiceProvider).listAll(
          status: _statusFilter,
          limit: 100,
        );
    setState(() {});
    await _future;
  }

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _process(int id, String status) async {
    try {
      await ref.read(returnAdminServiceProvider).process(id, status);
      await _reload();
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
    const options = <MapEntry<String?, String>>[
      MapEntry(null, 'Tất cả'),
      MapEntry('PENDING', 'PENDING'),
      MapEntry('APPROVED', 'APPROVED'),
      MapEntry('REJECTED', 'REJECTED'),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            HorizontalChips(
              children: [
                for (final o in options)
                  ChoiceChip(
                    label: Text(o.value),
                    selected: _statusFilter == o.key,
                    onSelected: (v) {
                      if (!v) return;
                      setState(() => _statusFilter = o.key);
                      _reload();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: RefreshIndicator(
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
                        message: 'Không có yêu cầu trả hàng',
                        icon: Icons.assignment_return_outlined,
                      );
                    }
                    return ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                      itemCount: rows.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final r = rows[i];
                        return _ReturnTile(
                          data: r,
                          onApprove: () =>
                              _process(r['id'] as int, 'APPROVED'),
                          onReject: () =>
                              _process(r['id'] as int, 'REJECTED'),
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

class _ReturnTile extends StatelessWidget {
  const _ReturnTile({
    required this.data,
    required this.onApprove,
    required this.onReject,
  });

  final Map<String, dynamic> data;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final id = data['id'];
    final status = data['status']?.toString() ?? '';
    final bookTitle = data['book_title']?.toString() ?? '—';
    final orderId = data['order_id'];
    final buyer = data['buyer_email']?.toString() ?? '';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outline),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Yêu cầu #$id',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                    fontSize: 15,
                  ),
                ),
              ),
              StatusPill(label: status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            bookTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Đơn #$orderId · $buyer',
            style: const TextStyle(
              color: AppColors.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          if (status == 'PENDING') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Từ chối'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFFEE2E2)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Duyệt'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
