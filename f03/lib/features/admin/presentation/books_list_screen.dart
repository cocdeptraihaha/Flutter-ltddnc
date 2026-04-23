import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../data/models/admin_models.dart';
import '../providers/admin_providers.dart';
import 'book_discounts_screen.dart';
import 'book_form_screen.dart';
import 'categories_screen.dart';

class BooksListScreen extends ConsumerStatefulWidget {
  const BooksListScreen({super.key});

  @override
  ConsumerState<BooksListScreen> createState() => _BooksListScreenState();
}

class _BooksListScreenState extends ConsumerState<BooksListScreen> {
  int _page = 1;
  bool _lowStockTab = false;
  final _search = TextEditingController();

  Future<void> _reload() async {
    setState(() {});
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final svc = ref.watch(bookAdminServiceProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                    hintText: 'Tìm tiêu đề / tác giả',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onSubmitted: (_) => setState(() => _page = 1),
                ),
              ),
              IconButton(
                tooltip: 'Làm mới',
                onPressed: () => setState(() {}),
                icon: const Icon(Icons.refresh),
              ),
              TextButton(
                onPressed: () async {
                  await Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const CategoriesScreen(),
                    ),
                  );
                },
                child: const Text('Thể loại'),
              ),
              TextButton(
                onPressed: () async {
                  await Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const BookDiscountsScreen(),
                    ),
                  );
                },
                child: const Text('Giảm giá'),
              ),
              FilledButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push<bool>(
                    MaterialPageRoute<bool>(
                      builder: (_) => const BookFormScreen(),
                    ),
                  );
                  await _reload();
                },
                icon: const Icon(Icons.add),
                label: const Text('Thêm sách'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              FilterChip(
                label: const Text('Tất cả'),
                selected: !_lowStockTab,
                onSelected: (v) {
                  if (v) setState(() => _lowStockTab = false);
                },
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Low stock'),
                selected: _lowStockTab,
                onSelected: (v) {
                  if (v) setState(() => _lowStockTab = true);
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<Object>(
            future: _lowStockTab
                ? svc.lowStock()
                : svc.listBooks(
                    page: _page,
                    q: _search.text.trim().isEmpty ? null : _search.text.trim(),
                  ),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(child: Text(dioErrorMessage(snap.error!)));
              }
              if (_lowStockTab) {
                final books = snap.data! as List;
                if (books.isEmpty) {
                  return const Center(child: Text('Không có sách sắp hết'));
                }
                return ListView.builder(
                  itemCount: books.length,
                  itemBuilder: (_, i) {
                    final b = books[i];
                    return ListTile(
                      leading: b.imageUrl != null
                          ? Image.network(b.imageUrl!, width: 48, height: 64, fit: BoxFit.cover)
                          : const Icon(Icons.book),
                      title: Text(b.title ?? '—'),
                      subtitle: Text(
                        'Tồn: ${b.stockQuantity ?? 0} · ${b.sellingPrice ?? 0} ₫',
                      ),
                      onTap: () async {
                        await Navigator.of(context).push<bool>(
                          MaterialPageRoute<bool>(
                            builder: (_) => BookFormScreen(existingId: b.id),
                          ),
                        );
                        await _reload();
                      },
                    );
                  },
                );
              }
              final pg = snap.data as PageResult<BookListItem>;
              final items = pg.items;
              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final b = items[i];
                        return ListTile(
                          leading: b.imageUrl != null
                              ? Image.network(
                                  b.imageUrl!,
                                  width: 48,
                                  height: 64,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.book),
                                )
                              : const Icon(Icons.book),
                          title: Text(b.title ?? '—'),
                          subtitle: Text(
                            '${b.sellingPrice ?? 0} ₫ · tồn ${b.stockQuantity ?? 0}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () async {
                              await Navigator.of(context).push<bool>(
                                MaterialPageRoute<bool>(
                                  builder: (_) =>
                                      BookFormScreen(existingId: b.id),
                                ),
                              );
                              await _reload();
                            },
                          ),
                          onTap: () async {
                            await Navigator.of(context).push<bool>(
                              MaterialPageRoute<bool>(
                                builder: (_) =>
                                    BookFormScreen(existingId: b.id),
                              ),
                            );
                            await _reload();
                          },
                        );
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: _page > 1
                            ? () => setState(() => _page--)
                            : null,
                        child: const Text('Trước'),
                      ),
                      Text('Trang $_page'),
                      TextButton(
                        onPressed: items.length >= 20
                            ? () => setState(() => _page++)
                            : null,
                        child: const Text('Sau'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
