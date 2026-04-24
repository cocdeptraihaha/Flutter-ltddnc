import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

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
  final _code = TextEditingController();
  final _edition = TextEditingController();
  final _pubDate = TextEditingController();
  final _price = TextEditingController();
  final _stock = TextEditingController();
  final _description = TextEditingController();
  final _pages = TextEditingController();
  final _publisher = TextEditingController();
  final _supplier = TextEditingController();
  final _height = TextEditingController();
  final _width = TextEditingController();
  final _length = TextEditingController();
  final _weight = TextEditingController();

  String? _imageUrl;
  int? _bookDetailId;
  bool _loading = false;
  final _displayDate = DateFormat('dd-MM-yyyy');
  final _backendDate = DateFormat('yyyy-MM-dd');

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  DateTime? _parseFlexibleDate(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;
    try {
      return _displayDate.parseStrict(text);
    } catch (_) {}
    try {
      return _backendDate.parseStrict(text);
    } catch (_) {}
    return DateTime.tryParse(text);
  }

  String? _normalizePublicationDate(String value) {
    final parsed = _parseFlexibleDate(value);
    if (parsed == null) return null;
    return _backendDate.format(parsed);
  }

  Future<void> _pickPublicationDate() async {
    final now = DateTime.now();
    final initial = _parseFlexibleDate(_pubDate.text) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      helpText: 'Chọn ngày xuất bản',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );
    if (picked != null) {
      _pubDate.text = _displayDate.format(picked);
    }
  }

  bool _validateInputs() {
    final title = _title.text.trim();
    if (title.isEmpty) {
      _showError('Tên sách không được để trống');
      return false;
    }
    final price = double.tryParse(_price.text.trim());
    if (price == null || price < 0) {
      _showError('Giá bán phải là số >= 0');
      return false;
    }
    final stock = int.tryParse(_stock.text.trim());
    if (stock == null || stock < 0) {
      _showError('Tồn kho phải là số nguyên >= 0');
      return false;
    }
    if (_pubDate.text.trim().isNotEmpty &&
        _parseFlexibleDate(_pubDate.text.trim()) == null) {
      _showError('Ngày xuất bản không hợp lệ (dd-MM-yyyy)');
      return false;
    }
    final pagesText = _pages.text.trim();
    if (pagesText.isNotEmpty) {
      final pages = int.tryParse(pagesText);
      if (pages == null || pages <= 0) {
        _showError('Số trang phải là số nguyên > 0');
        return false;
      }
    }
    final numericFields = <String, TextEditingController>{
      'Phiên bản': _edition,
      'Chiều dài': _length,
      'Chiều rộng': _width,
      'Chiều cao': _height,
      'Trọng lượng': _weight,
    };
    for (final entry in numericFields.entries) {
      final v = entry.value.text.trim();
      if (v.isEmpty) continue;
      final n = double.tryParse(v);
      if (n == null || n < 0) {
        _showError('${entry.key} phải là số >= 0');
        return false;
      }
    }
    return true;
  }

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
      final res = await dio.get<Map<String, dynamic>>(
        '/books/${widget.existingId}',
      );
      final j = res.data!;
      _title.text = j['title']?.toString() ?? '';
      _author.text = j['author']?.toString() ?? '';
      _code.text = j['code']?.toString() ?? '';
      _edition.text = '${j['edition'] ?? ''}';
      final rawPub = j['publication_date']?.toString() ?? '';
      final parsedPub = _parseFlexibleDate(rawPub.split('T').first);
      _pubDate.text = parsedPub == null ? '' : _displayDate.format(parsedPub);
      _price.text = '${j['selling_price'] ?? ''}';
      _stock.text = '${j['stock_quantity'] ?? ''}';
      final d = j['book_detail'] as Map<String, dynamic>?;
      _bookDetailId = d?['id'] as int?;
      _description.text = d?['description']?.toString() ?? '';
      _pages.text = '${d?['pages'] ?? ''}';
      _publisher.text = d?['publisher']?.toString() ?? '';
      _supplier.text = d?['supplier']?.toString() ?? '';
      _height.text = '${d?['height'] ?? ''}';
      _width.text = '${d?['width'] ?? ''}';
      _length.text = '${d?['length'] ?? ''}';
      _weight.text = '${d?['weight'] ?? ''}';
      _imageUrl = d?['image_url']?.toString();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(dioErrorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_validateInputs()) return;
    setState(() => _loading = true);
    try {
      await _upsertBookAndDetail();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(dioErrorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<int?> _upsertBookAndDetail() async {
    final books = ref.read(bookAdminServiceProvider);
    final detailBody = <String, dynamic>{
      'description': _description.text.trim().isEmpty
          ? null
          : _description.text.trim(),
      'pages': int.tryParse(_pages.text.trim()),
      'publisher': _publisher.text.trim().isEmpty ? null : _publisher.text.trim(),
      'supplier': _supplier.text.trim().isEmpty ? null : _supplier.text.trim(),
      'height': double.tryParse(_height.text.trim()),
      'width': double.tryParse(_width.text.trim()),
      'length': double.tryParse(_length.text.trim()),
      'weight': double.tryParse(_weight.text.trim()),
    };
    detailBody.removeWhere((_, v) => v == null);

    if (_bookDetailId == null &&
        (widget.existingId == null || detailBody.isNotEmpty)) {
      final createdDetail = await books.createBookDetail(detailBody);
      _bookDetailId = createdDetail['id'] as int?;
    } else if (_bookDetailId != null && detailBody.isNotEmpty) {
      await books.updateBookDetail(_bookDetailId!, detailBody);
    }

    final body = <String, dynamic>{
      'title': _title.text.trim(),
      'author': _author.text.trim().isEmpty ? null : _author.text.trim(),
      'code': _code.text.trim().isEmpty ? null : _code.text.trim(),
      'edition': int.tryParse(_edition.text.trim()),
      'publication_date': _pubDate.text.trim().isEmpty
          ? null
          : _normalizePublicationDate(_pubDate.text),
      'selling_price': double.tryParse(_price.text.trim()) ?? 0,
      'stock_quantity': int.tryParse(_stock.text.trim()) ?? 0,
      'book_detail_id': _bookDetailId,
    };
    body.removeWhere((_, v) => v == null);
    final out = widget.existingId == null
        ? await books.createBook(body)
        : await books.updateBook(widget.existingId!, body);

    int? detailId = out['book_detail_id'] as int?;
    final bd = out['book_detail'];
    if (detailId == null && bd is Map<String, dynamic>) {
      detailId = bd['id'] as int?;
    }
    return detailId ?? _bookDetailId;
  }

  Future<void> _uploadCoverImage() async {
    if (!_validateInputs()) return;
    setState(() => _loading = true);
    try {
      // New books do not have IDs yet, so we save first.
      final detailId = await _upsertBookAndDetail();
      if (detailId == null) {
        _showError('Không tìm thấy thông tin chi tiết sách để upload ảnh');
        return;
      }
      final picker = ImagePicker();
      final img = await picker.pickImage(source: ImageSource.gallery);
      if (img == null) return;

      await ref.read(bookAdminServiceProvider).uploadBookDetailImage(
            detailId,
            img.path,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload ảnh bìa thành công')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(dioErrorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _author.dispose();
    _code.dispose();
    _edition.dispose();
    _pubDate.dispose();
    _price.dispose();
    _stock.dispose();
    _description.dispose();
    _pages.dispose();
    _publisher.dispose();
    _supplier.dispose();
    _height.dispose();
    _width.dispose();
    _length.dispose();
    _weight.dispose();
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
                _SectionCard(
                  title: 'Thông tin cơ bản',
                  child: Column(
                    children: [
                      TextField(
                        controller: _title,
                        decoration: const InputDecoration(
                          labelText: 'Tên sách *',
                        ),
                      ),
                      TextField(
                        controller: _author,
                        decoration: const InputDecoration(labelText: 'Tác giả'),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _code,
                              decoration: const InputDecoration(
                                labelText: 'Mã sách',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _edition,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Phiên bản',
                              ),
                            ),
                          ),
                        ],
                      ),
                      TextField(
                        controller: _pubDate,
                        readOnly: true,
                        onTap: _pickPublicationDate,
                        decoration: InputDecoration(
                          labelText: 'Ngày xuất bản (dd-MM-yyyy)',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today_outlined),
                            onPressed: _pickPublicationDate,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _price,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Giá bán',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _stock,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Tồn kho',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Chi tiết sách',
                  child: Column(
                    children: [
                      TextField(
                        controller: _description,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Mô tả'),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _pages,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Số trang',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _publisher,
                              decoration: const InputDecoration(
                                labelText: 'NXB',
                              ),
                            ),
                          ),
                        ],
                      ),
                      TextField(
                        controller: _supplier,
                        decoration: const InputDecoration(
                          labelText: 'Nhà cung cấp',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Kích thước & trọng lượng',
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _length,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Dài (cm)',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _width,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Rộng (cm)',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _height,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Cao (cm)',
                              ),
                            ),
                          ),
                        ],
                      ),
                      TextField(
                        controller: _weight,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Trọng lượng (kg)',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Ảnh bìa',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: 72,
                              height: 96,
                              color: const Color(0xFFF1F5F9),
                              child: (_imageUrl != null && _imageUrl!.isNotEmpty)
                                  ? Image.network(
                                      _imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) =>
                                          const Icon(Icons.image_outlined),
                                    )
                                  : const Icon(Icons.image_outlined),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Nhấn Upload ảnh để chọn ảnh bìa. Nếu là sách mới, hệ thống sẽ tự lưu rồi upload.',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _loading ? null : _uploadCoverImage,
                        icon: const Icon(Icons.upload_file_outlined),
                        label: const Text('Upload ảnh bìa'),
                      ),
                    ],
                  ),
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
