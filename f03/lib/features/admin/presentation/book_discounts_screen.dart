import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api_client.dart';
import '../providers/admin_providers.dart';

class BookDiscountsScreen extends ConsumerStatefulWidget {
  const BookDiscountsScreen({super.key});

  @override
  ConsumerState<BookDiscountsScreen> createState() =>
      _BookDiscountsScreenState();
}

class _BookDiscountsScreenState extends ConsumerState<BookDiscountsScreen> {
  Future<List<Map<String, dynamic>>>? _future;
  final _displayDate = DateFormat('dd-MM-yyyy');
  final _backendDate = DateFormat('yyyy-MM-dd');

  void _reload() {
    _future = ref.read(bookDiscountAdminServiceProvider).list(limit: 100);
    setState(() {});
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

  String? _validateDiscountInputs({
    required String amt,
    required String pct,
    required String ids,
    required String start,
    required String end,
  }) {
    final amount = amt.trim().isEmpty ? null : double.tryParse(amt.trim());
    final percent = pct.trim().isEmpty ? null : double.tryParse(pct.trim());
    if (amount == null && percent == null) {
      return 'Cần nhập discount_amount hoặc discount_percent';
    }
    if (amount != null && amount < 0) return 'discount_amount phải >= 0';
    if (percent != null && (percent <= 0 || percent > 100)) {
      return 'discount_percent phải > 0 và <= 100';
    }
    final list = ids
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (list.isEmpty) return 'Cần nhập ít nhất 1 book_id';
    if (list.any((s) => int.tryParse(s) == null || int.parse(s) <= 0)) {
      return 'book_ids phải là danh sách số nguyên dương, cách nhau dấu phẩy';
    }
    DateTime? sDate;
    DateTime? eDate;
    if (start.trim().isNotEmpty) {
      sDate = _parseFlexibleDate(start.trim());
      if (sDate == null) {
        return 'start_date không hợp lệ (định dạng dd-MM-yyyy)';
      }
    }
    if (end.trim().isNotEmpty) {
      eDate = _parseFlexibleDate(end.trim());
      if (eDate == null) {
        return 'end_date không hợp lệ (định dạng dd-MM-yyyy)';
      }
    }
    if (sDate != null && eDate != null && sDate.isAfter(eDate)) {
      return 'start_date phải trước hoặc bằng end_date';
    }
    return null;
  }

  Future<void> _openDiscountForm({Map<String, dynamic>? existing}) async {
    final amt = TextEditingController(
      text: existing?['discount_amount']?.toString() ?? '',
    );
    final pct = TextEditingController(
      text: existing?['discount_percent']?.toString() ?? '',
    );
    final ids = TextEditingController(
      text: ((existing?['book_ids'] as List?) ?? const []).join(','),
    );
    final start = TextEditingController(
      text: _displayDateValue(existing?['start_date']),
    );
    final end = TextEditingController(
      text: _displayDateValue(existing?['end_date']),
    );
    final isEdit = existing != null;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Sửa discount' : 'Tạo discount'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amt,
                decoration: const InputDecoration(labelText: 'discount_amount'),
              ),
              TextField(
                controller: pct,
                decoration: const InputDecoration(
                  labelText: 'discount_percent',
                ),
              ),
              TextField(
                controller: ids,
                decoration: const InputDecoration(
                  labelText: 'book_ids (1,2,3)',
                ),
              ),
              TextField(
                controller: start,
                readOnly: true,
                onTap: () => _pickDate(start),
                decoration: InputDecoration(
                  labelText: 'start_date dd-MM-yyyy',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today_outlined),
                    onPressed: () => _pickDate(start),
                  ),
                ),
              ),
              TextField(
                controller: end,
                readOnly: true,
                onTap: () => _pickDate(end),
                decoration: InputDecoration(
                  labelText: 'end_date dd-MM-yyyy',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today_outlined),
                    onPressed: () => _pickDate(end),
                  ),
                ),
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
    );
    if (ok != true) return;
    final validationError = _validateDiscountInputs(
      amt: amt.text,
      pct: pct.text,
      ids: ids.text,
      start: start.text,
      end: end.text,
    );
    if (validationError != null) {
      _showError(validationError);
      return;
    }
    try {
      final parts = ids.text
          .split(',')
          .map((s) => int.tryParse(s.trim()))
          .whereType<int>()
          .toList();
      final body = <String, dynamic>{
        if (amt.text.trim().isNotEmpty)
          'discount_amount': double.tryParse(amt.text.trim()),
        if (pct.text.trim().isNotEmpty)
          'discount_percent': double.tryParse(pct.text.trim()),
        if (ids.text.trim().isNotEmpty) 'book_ids': parts,
        'start_date': _normalizeDateTime(start.text),
        'end_date': _normalizeDateTime(end.text),
      };
      body.removeWhere((_, v) => v == null);
      if (isEdit) {
        await ref
            .read(bookDiscountAdminServiceProvider)
            .update(existing['id'] as int, body);
      } else {
        await ref.read(bookDiscountAdminServiceProvider).create(body);
      }
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(dioErrorMessage(e))));
      }
    }
  }

  Future<void> _deleteDiscount(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa discount'),
        content: const Text('Bạn có chắc muốn xóa discount này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
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
      await ref.read(bookDiscountAdminServiceProvider).delete(id);
      _reload();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giảm giá theo sách'),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'admin_book_discounts_fab',
        onPressed: () => _openDiscountForm(),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
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
              final d = rows[i];
              return ListTile(
                title: Text('ID ${d['id']} · books ${d['book_ids']}'),
                subtitle: Text(
                  '${d['discount_percent'] ?? '-'}% · ${d['discount_amount'] ?? '-'} ₫',
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) {
                    switch (v) {
                      case 'edit':
                        _openDiscountForm(existing: d);
                      case 'delete':
                        _deleteDiscount(d['id'] as int);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Sửa')),
                    PopupMenuItem(value: 'delete', child: Text('Xóa')),
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
