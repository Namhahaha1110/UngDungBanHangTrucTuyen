import 'package:flutter/material.dart';

import '../../services/shop_repository.dart';
import 'admin_view_mode.dart';
import 'widgets/admin_top_bar.dart';
import 'screens/admin_banners_page.dart';
import 'screens/admin_categories_page.dart';
import 'screens/admin_home_page.dart';
import 'screens/admin_orders_page.dart';
import 'screens/admin_products_page.dart';
import 'screens/admin_sales_page.dart';
import 'screens/admin_users_page.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({required this.repository, required this.userId, super.key});

  final ShopRepository repository;
  final String userId;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  late PageController _pageController;
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<String> _titles = [
    'Tổng quan',
    'Sản phẩm',
    'Danh mục',
    'Banner',
    'Flash Sale',
    'Đơn hàng',
    'Người dùng',
  ];

  final List<String> _navIcons = ['◦', '☐', '▥', '⬚', '⚡', '📋', '👤'];
  final List<String> _navLabels = [
    'Tổng quan',
    'Sản phẩm',
    'Danh mục',
    'Banner',
    'Flash Sale',
    'Đơn hàng',
    'Người dùng',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: Container(
          color: Colors.white,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                height: 60,
                color: const Color(0xFFea580c),
                child: const Center(
                  child: Text(
                    'Menu',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              ..._buildDrawerItems(),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          const AdminStatusBar(),
          AdminTopBar(
            title: _titles[_currentIndex],
            actionIcon: '＋',
            showBack: false,
            onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
            onActionTap: _showCreateMenu,
          ),
          Expanded(
            child: Stack(
              children: [
                PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  children: [
                    AdminHomePage(
                      repository: widget.repository,
                      userId: widget.userId,
                      onOpenModule: _openModule,
                      onGoHome: AdminViewMode.openShop,
                    ),
                    AdminProductsPage(
                      repository: widget.repository,
                      userId: widget.userId,
                    ),
                    AdminCategoriesPage(
                      repository: widget.repository,
                      userId: widget.userId,
                    ),
                    AdminBannersPage(
                      repository: widget.repository,
                      userId: widget.userId,
                    ),
                    AdminSalesPage(
                      repository: widget.repository,
                      userId: widget.userId,
                    ),
                    AdminOrdersPage(
                      repository: widget.repository,
                      userId: widget.userId,
                    ),
                    AdminUsersPage(
                      repository: widget.repository,
                      userId: widget.userId,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDrawerItems() {
    return List.generate(7, (index) {
      final isActive = _currentIndex == index;
      return ListTile(
        leading: Text(
          _navIcons[index],
          style: TextStyle(
            fontSize: 18,
            color: isActive ? const Color(0xFFea580c) : const Color(0xFF999999),
          ),
        ),
        title: Text(
          _navLabels[index],
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? const Color(0xFFea580c) : const Color(0xFF171717),
          ),
        ),
        tileColor: isActive ? const Color(0xFFfff2e8) : Colors.transparent,
        onTap: () {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          Navigator.pop(context);
        },
      );
    });
  }

  void _openModule(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _showCreateMenu() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              const Text(
                'Tạo mới nhanh',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              _CreateActionTile(
                label: 'Sản phẩm',
                onTap: () {
                  Navigator.of(context).pop();
                  _openModule(1);
                },
              ),
              _CreateActionTile(
                label: 'Danh mục',
                onTap: () {
                  Navigator.of(context).pop();
                  _openModule(2);
                },
              ),
              _CreateActionTile(
                label: 'Banner',
                onTap: () {
                  Navigator.of(context).pop();
                  _openModule(3);
                },
              ),
              _CreateActionTile(
                label: 'Flash Sale',
                onTap: () {
                  Navigator.of(context).pop();
                  _openModule(4);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _CreateActionTile extends StatelessWidget {
  const _CreateActionTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
