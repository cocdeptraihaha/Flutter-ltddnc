import 'package:flutter/material.dart';

import '../../../app_theme.dart';
import 'account_screen.dart';
import 'books_list_screen.dart';
import 'dashboard_screen.dart';
import 'orders_list_screen.dart';
import 'notifications_screen.dart';
import 'promotions_screen.dart';
import 'returns_screen.dart';
import 'revenue_screen.dart';
import 'users_list_screen.dart';

/// Shell điều hướng admin:
/// - Mobile: `NavigationBar` 5 tab (4 mục chính + "Thêm" mở bottom sheet).
/// - Tablet/desktop (>=900 px): `NavigationRail` đầy đủ 8 mục.
class AdminShellScreen extends StatefulWidget {
  const AdminShellScreen({super.key});

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  int _index = 0;

  static const List<_NavItem> _items = [
    _NavItem('Tổng quan', Icons.dashboard_outlined, Icons.dashboard_rounded),
    _NavItem('Sách', Icons.menu_book_outlined, Icons.menu_book_rounded),
    _NavItem('Đơn hàng', Icons.receipt_long_outlined, Icons.receipt_long_rounded),
    _NavItem('Khách', Icons.people_outline, Icons.people_rounded),
    _NavItem('Khuyến mãi', Icons.local_offer_outlined, Icons.local_offer_rounded),
    _NavItem('Doanh thu', Icons.trending_up_outlined, Icons.trending_up_rounded),
    _NavItem('Trả hàng', Icons.assignment_return_outlined,
        Icons.assignment_return_rounded),
    _NavItem('Thông báo', Icons.notifications_outlined, Icons.notifications_rounded),
    _NavItem('Tài khoản', Icons.manage_accounts_outlined,
        Icons.manage_accounts_rounded),
  ];

  /// 4 mục đầu hiển thị cố định ở bottom nav; 4 mục còn lại vào "Thêm".
  static const int _primaryCount = 4;

  List<Widget> get _pages => const [
        DashboardScreen(),
        BooksListScreen(),
        OrdersListScreen(),
        UsersListScreen(),
        PromotionsScreen(),
        RevenueScreen(),
        ReturnsScreen(),
        NotificationsScreen(),
        AccountScreen(),
      ];

  Future<void> _openMoreSheet() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(8, 0, 8, 12),
                  child: Text(
                    'Thêm khu vực',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
                for (var i = _primaryCount; i < _items.length; i++)
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: AppColors.primary,
                      child: Icon(_items[i].selected, size: 20),
                    ),
                    title: Text(
                      _items[i].label,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: _index == i
                        ? const Icon(Icons.check, color: AppColors.primary)
                        : const Icon(Icons.chevron_right,
                            color: AppColors.onSurfaceVariant),
                    onTap: () => Navigator.of(ctx).pop(i),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || selected == null) return;
    setState(() => _index = selected);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 900;

    if (wide) {
      return _WideShell(
        items: _items,
        index: _index,
        extended: width > 1100,
        onSelected: (i) => setState(() => _index = i),
        child: IndexedStack(index: _index, children: _pages),
      );
    }

    // Mobile shell.
    final showMoreSelected = _index >= _primaryCount;
    final barIndex = showMoreSelected ? _primaryCount : _index;
    final currentTitle = _items[_index].label;

    return Scaffold(
      appBar: AppBar(title: Text(currentTitle)),
      body: SafeArea(
        top: false,
        bottom: false,
        child: IndexedStack(index: _index, children: _pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: barIndex,
        onDestinationSelected: (i) {
          if (i == _primaryCount) {
            _openMoreSheet();
            return;
          }
          setState(() => _index = i);
        },
        destinations: [
          for (var i = 0; i < _primaryCount; i++)
            NavigationDestination(
              icon: Icon(_items[i].outlined),
              selectedIcon: Icon(_items[i].selected),
              label: _items[i].label,
            ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: showMoreSelected,
              smallSize: 8,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.more_horiz_rounded),
            ),
            selectedIcon: const Icon(Icons.more_horiz_rounded),
            label: 'Thêm',
          ),
        ],
      ),
    );
  }
}

class _WideShell extends StatelessWidget {
  const _WideShell({
    required this.items,
    required this.index,
    required this.extended,
    required this.onSelected,
    required this.child,
  });

  final List<_NavItem> items;
  final int index;
  final bool extended;
  final ValueChanged<int> onSelected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Row(
        children: [
          SafeArea(
            child: NavigationRail(
              extended: extended,
              selectedIndex: index,
              onDestinationSelected: onSelected,
              labelType: extended
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              backgroundColor: AppColors.surface,
              indicatorColor: AppColors.primaryContainer,
              destinations: [
                for (final it in items)
                  NavigationRailDestination(
                    icon: Icon(it.outlined),
                    selectedIcon: Icon(it.selected),
                    label: Text(it.label),
                  ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Material(
                  color: AppColors.surface,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                    child: Text(
                      items[index].label,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.outlined, this.selected);
  final String label;
  final IconData outlined;
  final IconData selected;
}
