import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app_theme.dart';
import '../../../core/api_client.dart';
import '../data/models/admin_models.dart';
import '../providers/admin_providers.dart';
import 'book_discounts_screen.dart';
import 'book_form_screen.dart';
import 'categories_screen.dart';
import 'widgets/section_card.dart';

class BooksListScreen extends ConsumerStatefulWidget {
  const BooksListScreen({super.key});

  @override
  ConsumerState<BooksListScreen> createState() => _BooksListScreenState();
}

class _BooksListScreenState extends ConsumerState<BooksListScreen> {
  int _page = 1;
  bool _lowStockTab = false;
  int _version = 0;
  String _statusFilter = 'all';
  final _search = TextEditingController();

  Future<void> _reload() async {
    setState(() => _version++);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _openForm({int? id}) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => BookFormScreen(existingId: id)),
    );
    await _reload();
  }

  Future<void> _toggleActive(BookListItem book) async {
    final books = ref.read(bookAdminServiceProvider);
    final isHidden = book.deletedAt != null;
    final title = isHidden ? 'Hiện sách' : 'Ẩn sách';
    final message = isHidden
        ? 'Sách sẽ hiển thị lại trên danh sách khách hàng.'
        : 'Sách sẽ bị ẩn khỏi danh sách khách hàng.';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Đóng'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(title),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      if (isHidden) {
        await books.restoreBook(book.id);
      } else {
        await books.softDeleteBook(book.id);
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

  @override
  Widget build(BuildContext context) {
    final svc = ref.watch(bookAdminServiceProvider);
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final q = _search.text.trim();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _search,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Tìm tiêu đề / tác giả',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: q.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () {
                                  _search.clear();
                                  setState(() {
                                    _page = 1;
                                    _version++;
                                  });
                                },
                              ),
                      ),
                      onSubmitted: (_) => setState(() {
                        _page = 1;
                        _version++;
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _OverflowMenu(
                    onCategories: () async {
                      await Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => const CategoriesScreen(),
                        ),
                      );
                    },
                    onDiscounts: () async {
                      await Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => const BookDiscountsScreen(),
                        ),
                      );
                    },
                    onReload: _reload,
                  ),
                ],
              ),
            ),
            HorizontalChips(
              children: [
                ChoiceChip(
                  label: const Text('Tất cả'),
                  selected: !_lowStockTab && _statusFilter == 'all',
                  onSelected: (v) {
                    if (v) {
                      setState(() {
                        _lowStockTab = false;
                        _statusFilter = 'all';
                        _page = 1;
                        _version++;
                      });
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('Đang hiển thị'),
                  selected: !_lowStockTab && _statusFilter == 'active',
                  onSelected: (v) {
                    if (v) {
                      setState(() {
                        _lowStockTab = false;
                        _statusFilter = 'active';
                        _page = 1;
                        _version++;
                      });
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('Đã ẩn'),
                  selected: !_lowStockTab && _statusFilter == 'deleted',
                  onSelected: (v) {
                    if (v) {
                      setState(() {
                        _lowStockTab = false;
                        _statusFilter = 'deleted';
                        _page = 1;
                        _version++;
                      });
                    }
                  },
                ),
                ChoiceChip(
                  avatar: const Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: Color(0xFFF59E0B),
                  ),
                  label: const Text('Sắp hết hàng'),
                  selected: _lowStockTab,
                  onSelected: (v) {
                    if (v) {
                      setState(() {
                        _lowStockTab = true;
                        _page = 1;
                        _version++;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _reload,
                child: FutureBuilder<Object>(
                  key: ValueKey('books-$_lowStockTab-$_page-$_version-$q'),
                  future: _lowStockTab
                      ? svc.lowStock()
                      : svc.listBooks(
                          page: _page,
                          q: q.isEmpty ? null : q,
                          includeDeleted: _statusFilter != 'active',
                          status: _statusFilter == 'all' ? null : _statusFilter,
                        ),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return _ErrorView(
                        message: dioErrorMessage(snap.error!),
                        onRetry: _reload,
                      );
                    }
                    if (_lowStockTab) {
                      final books = (snap.data! as List).cast<BookListItem>();
                      if (books.isEmpty) {
                        return const EmptyState(
                          message: 'Không có sách sắp hết',
                          icon: Icons.inventory_2_outlined,
                        );
                      }
                      return ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                        itemCount: books.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _BookTile(
                          book: books[i],
                          fmt: fmt,
                          lowStockHighlight: true,
                          onTap: () => _openForm(id: books[i].id),
                          onToggleActive: () => _toggleActive(books[i]),
                        ),
                      );
                    }
                    final pg = snap.data as PageResult<BookListItem>;
                    final items = pg.items;
                    if (items.isEmpty) {
                      return const EmptyState(
                        message: 'Không có sách phù hợp',
                        icon: Icons.menu_book_outlined,
                      );
                    }
                    return ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      itemCount: items.length + 1,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        if (i == items.length) {
                          return _Pager(
                            page: _page,
                            canPrev: _page > 1,
                            canNext: items.length >= 20,
                            onPrev: () => setState(() {
                              _page--;
                              _version++;
                            }),
                            onNext: () => setState(() {
                              _page++;
                              _version++;
                            }),
                          );
                        }
                        return _BookTile(
                          book: items[i],
                          fmt: fmt,
                          onTap: () => _openForm(id: items[i].id),
                          onToggleActive: () => _toggleActive(items[i]),
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
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'admin_books_list_fab',
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm sách'),
      ),
    );
  }
}

class _BookTile extends StatelessWidget {
  const _BookTile({
    required this.book,
    required this.fmt,
    required this.onTap,
    required this.onToggleActive,
    this.lowStockHighlight = false,
  });

  final BookListItem book;
  final NumberFormat fmt;
  final bool lowStockHighlight;
  final VoidCallback onTap;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    final stock = book.stockQuantity ?? 0;
    final price = book.sellingPrice ?? 0;
    final lowStock = stock <= 5;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.outline),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 56,
                  height: 76,
                  color: AppColors.surfaceMuted,
                  child: book.imageUrl != null
                      ? Image.network(
                          book.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.menu_book_rounded,
                            color: AppColors.primary,
                          ),
                        )
                      : const Icon(
                          Icons.menu_book_rounded,
                          color: AppColors.primary,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title ?? '—',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fmt.format(price),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 14,
                          color: (lowStock || lowStockHighlight)
                              ? const Color(0xFFF59E0B)
                              : AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Tồn $stock',
                          style: TextStyle(
                            color: (lowStock || lowStockHighlight)
                                ? const Color(0xFFB45309)
                                : AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        if (book.deletedAt != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Đã ẩn',
                              style: TextStyle(
                                color: Color(0xFFB91C1C),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.onSurfaceVariant,
                ),
                onSelected: (v) {
                  switch (v) {
                    case 'edit':
                      onTap();
                    case 'toggle':
                      onToggleActive();
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Sửa sách')),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(
                      book.deletedAt == null ? 'Ẩn sách' : 'Hiện sách',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverflowMenu extends StatelessWidget {
  const _OverflowMenu({
    required this.onCategories,
    required this.onDiscounts,
    required this.onReload,
  });

  final VoidCallback onCategories;
  final VoidCallback onDiscounts;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded),
      tooltip: 'Thao tác',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (v) {
        switch (v) {
          case 'categories':
            onCategories();
          case 'discounts':
            onDiscounts();
          case 'reload':
            onReload();
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'categories',
          child: ListTile(
            dense: true,
            leading: Icon(Icons.category_outlined),
            title: Text('Thể loại'),
          ),
        ),
        PopupMenuItem(
          value: 'discounts',
          child: ListTile(
            dense: true,
            leading: Icon(Icons.percent_rounded),
            title: Text('Giảm giá'),
          ),
        ),
        PopupMenuItem(
          value: 'reload',
          child: ListTile(
            dense: true,
            leading: Icon(Icons.refresh_rounded),
            title: Text('Làm mới'),
          ),
        ),
      ],
    );
  }
}

class _Pager extends StatelessWidget {
  const _Pager({
    required this.page,
    required this.canPrev,
    required this.canNext,
    required this.onPrev,
    required this.onNext,
  });

  final int page;
  final bool canPrev;
  final bool canNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OutlinedButton.icon(
            onPressed: canPrev ? onPrev : null,
            icon: const Icon(Icons.chevron_left_rounded),
            label: const Text('Trước'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Trang $page',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: canNext ? onNext : null,
            icon: const Icon(Icons.chevron_right_rounded),
            label: const Text('Sau'),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 42,
              color: Color(0xFFDC2626),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
