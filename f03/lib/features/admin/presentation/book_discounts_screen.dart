import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../providers/admin_providers.dart';

class BookDiscountsScreen extends ConsumerStatefulWidget {
  const BookDiscountsScreen({super.key});

  @override
  ConsumerState<BookDiscountsScreen> createState() => _BookDiscountsScreenState();
}

class _BookDiscountsScreenState extends ConsumerState<BookDiscountsScreen> {
  Future<List<Map<String, dynamic>>>? _future;

  void _reload() {
    _future = ref.read(bookDiscountAdminServiceProvider).list(limit: 100);
    setState(() {});
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
        actions: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh))],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final amt = TextEditingController();
          final pct = TextEditingController();
          final ids = TextEditingController();
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Tạo discount'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: amt, decoration: const InputDecoration(labelText: 'discount_amount')),
                  TextField(controller: pct, decoration: const InputDecoration(labelText: 'discount_percent')),
                  TextField(controller: ids, decoration: const InputDecoration(labelText: 'book_ids (1,2,3)')),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Tạo')),
              ],
            ),
          );
          if (ok == true) {
            try {
              final parts = ids.text.split(',').map((s) => int.tryParse(s.trim())).whereType<int>().toList();
              await ref.read(bookDiscountAdminServiceProvider).create({
                if (amt.text.trim().isNotEmpty) 'discount_amount': double.tryParse(amt.text.trim()),
                if (pct.text.trim().isNotEmpty) 'discount_percent': double.tryParse(pct.text.trim()),
                'book_ids': parts,
              });
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
              );
            },
          );
        },
      ),
    );
  }
}
