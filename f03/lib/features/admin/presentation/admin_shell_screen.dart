import 'package:flutter/material.dart';

import '../../../app_theme.dart';
import 'books_list_screen.dart';
import 'dashboard_screen.dart';
import 'orders_list_screen.dart';
import 'promotions_screen.dart';
import 'returns_screen.dart';
import 'revenue_screen.dart';
import 'users_list_screen.dart';
import 'account_screen.dart';

/// Shell điều hướng admin: Drawer (mobile) / NavigationRail (desktop).
class AdminShellScreen extends StatefulWidget {
  const AdminShellScreen({super.key});

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  int _index = 0;

  static const _titles = [
    'Tổng quan',
    'Sách',
    'Đơn hàng',
    'Khách hàng',
    'Khuyến mãi',
    'Doanh thu',
    'Trả hàng',
    'Tài khoản',
  ];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width > 900;

    final pages = [
      const DashboardScreen(),
      const BooksListScreen(),
      const OrdersListScreen(),
      const UsersListScreen(),
      const PromotionsScreen(),
      const RevenueScreen(),
      const ReturnsScreen(),
      const AccountScreen(),
    ];

    final rail = NavigationRail(
      extended: wide && MediaQuery.sizeOf(context).width > 1100,
      selectedIndex: _index,
      onDestinationSelected: (i) => setState(() => _index = i),
      labelType: NavigationRailLabelType.all,
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primaryContainer,
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded),
          label: Text('Tổng quan'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.menu_book_outlined),
          selectedIcon: Icon(Icons.menu_book_rounded),
          label: Text('Sách'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long_rounded),
          label: Text('Đơn hàng'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people_rounded),
          label: Text('Khách'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.local_offer_outlined),
          selectedIcon: Icon(Icons.local_offer_rounded),
          label: Text('KM'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.trending_up_outlined),
          selectedIcon: Icon(Icons.trending_up_rounded),
          label: Text('Doanh thu'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.assignment_return_outlined),
          selectedIcon: Icon(Icons.assignment_return_rounded),
          label: Text('Trả hàng'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.manage_accounts_outlined),
          selectedIcon: Icon(Icons.manage_accounts_rounded),
          label: Text('TK'),
        ),
      ],
    );

    final body = IndexedStack(index: _index, children: pages);

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(child: rail),
            const VerticalDivider(width: 1),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Material(
                    elevation: 0,
                    color: AppColors.surface,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                      child: Text(
                        _titles[_index],
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                      ),
                    ),
                  ),
                  Expanded(child: body),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: AppColors.primary),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'KeBook Admin',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),
            for (var i = 0; i < _titles.length; i++)
              ListTile(
                leading: Icon(_iconFor(i)),
                title: Text(_titles[i]),
                selected: _index == i,
                onTap: () {
                  setState(() => _index = i);
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
      body: body,
    );
  }

  IconData _iconFor(int i) {
    const icons = [
      Icons.dashboard_rounded,
      Icons.menu_book_rounded,
      Icons.receipt_long_rounded,
      Icons.people_rounded,
      Icons.local_offer_rounded,
      Icons.trending_up_rounded,
      Icons.assignment_return_rounded,
      Icons.manage_accounts_rounded,
    ];
    return icons[i];
  }
}
