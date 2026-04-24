import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app_theme.dart';
import '../../../core/api_client.dart';
import '../providers/admin_providers.dart';

class NotificationCreateScreen extends ConsumerStatefulWidget {
  const NotificationCreateScreen({super.key});

  @override
  ConsumerState<NotificationCreateScreen> createState() =>
      _NotificationCreateScreenState();
}

class _NotificationCreateScreenState
    extends ConsumerState<NotificationCreateScreen> {
  final _title = TextEditingController();
  final _message = TextEditingController();
  final _userIds = TextEditingController();

  String _type = 'INFO';
  bool _broadcast = true;
  bool _onlyActive = true;
  bool _onlyAdmin = false;
  bool _submitting = false;

  @override
  void dispose() {
    _title.dispose();
    _message.dispose();
    _userIds.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _title.text.trim();
    final message = _message.text.trim();
    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tiêu đề và nội dung không được để trống')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final service = ref.read(notificationAdminServiceProvider);
      if (_broadcast) {
        await service.broadcast(
          title: title,
          message: message,
          type: _type,
          isActive: _onlyActive ? true : null,
          isSuperuser: _onlyAdmin ? true : null,
        );
      } else {
        final ids = _userIds.text
            .split(',')
            .map((s) => int.tryParse(s.trim()))
            .whereType<int>()
            .toList();
        if (ids.isEmpty) {
          throw Exception('Nhập user_id hợp lệ, cách nhau bởi dấu phẩy');
        }
        await service.createToUsers(
          userIds: ids,
          title: title,
          message: message,
          type: _type,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã tạo thông báo')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(dioErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tạo thông báo mới'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(
              labelText: 'Tiêu đề',
              prefixIcon: Icon(Icons.title),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _message,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Nội dung',
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.message_outlined),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: const InputDecoration(
              labelText: 'Loại thông báo',
              prefixIcon: Icon(Icons.category_outlined),
            ),
            items: const [
              DropdownMenuItem(value: 'INFO', child: Text('INFO')),
              DropdownMenuItem(value: 'NEW_ORDER', child: Text('NEW_ORDER')),
              DropdownMenuItem(
                  value: 'RETURN_REQUEST', child: Text('RETURN_REQUEST')),
              DropdownMenuItem(value: 'PROMOTION', child: Text('PROMOTION')),
            ],
            onChanged: (v) => setState(() => _type = v ?? 'INFO'),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: _broadcast,
            onChanged: (v) => setState(() => _broadcast = v),
            title: const Text('Gửi hàng loạt (broadcast)'),
            subtitle:
                const Text('Tắt để gửi theo danh sách user_id cụ thể'),
          ),
          if (_broadcast) ...[
            SwitchListTile(
              value: _onlyActive,
              onChanged: (v) => setState(() => _onlyActive = v),
              title: const Text('Chỉ user active'),
            ),
            SwitchListTile(
              value: _onlyAdmin,
              onChanged: (v) => setState(() => _onlyAdmin = v),
              title: const Text('Chỉ admin'),
            ),
          ] else ...[
            TextField(
              controller: _userIds,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Danh sách user_id',
                hintText: 'Ví dụ: 1,2,5',
                prefixIcon: Icon(Icons.group_outlined),
              ),
            ),
          ],
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: const Icon(Icons.send_rounded),
            label: Text(_submitting ? 'Đang gửi...' : 'Tạo thông báo'),
          ),
        ],
      ),
    );
  }
}

