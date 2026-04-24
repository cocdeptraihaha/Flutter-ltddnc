import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app_theme.dart';
import '../../../core/api_client.dart';
import '../providers/admin_providers.dart';
import 'notification_create_screen.dart';
import 'widgets/section_card.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  Future<List<Map<String, dynamic>>>? _future;
  String _filter = 'ALL';

  Future<void> _reload() async {
    _future = ref.read(notificationAdminServiceProvider).list(limit: 100);
    setState(() {});
    await _future;
  }

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _openCreateScreen() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const NotificationCreateScreen(),
      ),
    );
    if (ok == true) {
      await _reload();
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
            final all = snap.data ?? const [];
            final rows = all.where((r) {
              if (_filter == 'ALL') return true;
              return (r['type']?.toString() ?? '').toUpperCase() == _filter;
            }).toList();

            if (all.isEmpty) {
              return const EmptyState(
                message: 'Chưa có thông báo admin',
                icon: Icons.notifications_none_rounded,
              );
            }

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
              children: [
                HorizontalChips(
                  children: [
                    ChoiceChip(
                      label: const Text('Tất cả'),
                      selected: _filter == 'ALL',
                      onSelected: (_) => setState(() => _filter = 'ALL'),
                    ),
                    ChoiceChip(
                      label: const Text('Đơn mới'),
                      selected: _filter == 'NEW_ORDER',
                      onSelected: (_) => setState(() => _filter = 'NEW_ORDER'),
                    ),
                    ChoiceChip(
                      label: const Text('Yêu cầu trả hàng'),
                      selected: _filter == 'RETURN_REQUEST',
                      onSelected: (_) => setState(() => _filter = 'RETURN_REQUEST'),
                    ),
                    ChoiceChip(
                      label: const Text('Khác'),
                      selected: _filter == 'INFO',
                      onSelected: (_) => setState(() => _filter = 'INFO'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (rows.isEmpty)
                  const EmptyState(
                    message: 'Không có thông báo theo bộ lọc hiện tại',
                    icon: Icons.filter_alt_off_outlined,
                  )
                else
                  ...rows.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _NotificationTile(data: r),
                      )),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'admin_notifications_fab',
        onPressed: _openCreateScreen,
        icon: const Icon(Icons.add_alert_outlined),
        label: const Text('Tạo thông báo'),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.data});

  final Map<String, dynamic> data;

  Color _badgeColor(String type) {
    switch (type) {
      case 'NEW_ORDER':
        return const Color(0xFF1D4ED8);
      case 'RETURN_REQUEST':
        return const Color(0xFFB45309);
      case 'PROMOTION':
        return const Color(0xFF7C3AED);
      default:
        return const Color(0xFF475467);
    }
  }

  IconData _icon(String type) {
    switch (type) {
      case 'NEW_ORDER':
        return Icons.receipt_long_outlined;
      case 'RETURN_REQUEST':
        return Icons.assignment_return_outlined;
      case 'PROMOTION':
        return Icons.local_offer_outlined;
      default:
        return Icons.notifications_none_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = (data['type']?.toString() ?? 'INFO').toUpperCase();
    final title = data['title']?.toString() ?? '(Không tiêu đề)';
    final message = data['message']?.toString() ?? '';
    final sendDate = data['send_date']?.toString() ?? '';
    final c = _badgeColor(type);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outline),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon(type), color: c),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: c.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        type,
                        style: TextStyle(
                          color: c,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  message.isEmpty ? '(Không có nội dung)' : message,
                  style: const TextStyle(color: AppColors.onSurfaceVariant),
                ),
                if (sendDate.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    sendDate.replaceFirst('T', ' ').split('.').first,
                    style: const TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

