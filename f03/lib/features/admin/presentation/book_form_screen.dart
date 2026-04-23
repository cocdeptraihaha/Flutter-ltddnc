import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api_client.dart';
import '../../../providers/auth_providers.dart';
import '../providers/admin_providers.dart';

/// Tạo / sửa sách (tối giản MVP).
class BookFormScreen extends ConsumerStatefulWidget {
  const BookFormScreen({super.key, this.existingId});

  final int? existingId;

  @override
  ConsumerState<BookFormScreen> createState() => _BookFormScreenState();
}

class _BookFormScreenState extends ConsumerState<BookFormScreen> {
  final _title = TextEditingController();
  final _author = TextEditingController();
  final _price = TextEditingController();
  final _stock = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get<Map<String, dynamic>>('/books/${widget.existingId}');
      final j = res.data!;
      _title.text = j['title']?.toString() ?? '';
      _author.text = j['author']?.toString() ?? '';
      _price.text = '${j['selling_price'] ?? ''}';
      _stock.text = '${j['stock_quantity'] ?? ''}';
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(dioErrorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      final books = ref.read(bookAdminServiceProvider);
      final body = <String, dynamic>{
        'title': _title.text.trim(),
        'author': _author.text.trim().isEmpty ? null : _author.text.trim(),
        'selling_price': double.tryParse(_price.text.trim()) ?? 0,
        'stock_quantity': int.tryParse(_stock.text.trim()) ?? 0,
      };
      Map<String, dynamic> out;
      if (widget.existingId == null) {
        out = await books.createBook(body);
      } else {
        out = await books.updateBook(widget.existingId!, body);
      }
      int? detailId = out['book_detail_id'] as int?;
      final bd = out['book_detail'];
      if (detailId == null && bd is Map<String, dynamic>) {
        detailId = bd['id'] as int?;
      }
      if (mounted && detailId != null) {
        final picker = ImagePicker();
        final img = await picker.pickImage(source: ImageSource.gallery);
        if (img != null) {
          await books.uploadBookDetailImage(detailId, img.path);
        }
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(dioErrorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _author.dispose();
    _price.dispose();
    _stock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingId == null ? 'Thêm sách' : 'Sửa sách'),
      ),
      body: _loading && widget.existingId != null && _title.text.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _title,
                  decoration: const InputDecoration(labelText: 'Tiêu đề'),
                ),
                TextField(
                  controller: _author,
                  decoration: const InputDecoration(labelText: 'Tác giả'),
                ),
                TextField(
                  controller: _price,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Giá bán'),
                ),
                TextField(
                  controller: _stock,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Tồn kho'),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loading ? null : _save,
                  child: Text(widget.existingId == null ? 'Tạo' : 'Lưu'),
                ),
              ],
            ),
    );
  }
}
