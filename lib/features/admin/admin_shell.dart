import 'package:flutter/material.dart';

import '../../services/shop_repository.dart';
import '../../theme/app_theme.dart';
import 'admin_view_mode.dart';
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

class _AdminShellState extends State<AdminShell> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng điều khiển'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: GestureDetector(
                onTap: () => AdminViewMode.openShop(),
                child: Tooltip(
                  message: 'Về giao diện mua sắm',
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shopping_bag, size: 18),
                        const SizedBox(width: 6),
                        const Text(
                          'Shop',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Tổng quan'),
            Tab(text: 'Sản phẩm'),
            Tab(text: 'Danh mục'),
            Tab(text: 'Banner'),
            Tab(text: 'Flash Sale'),
            Tab(text: 'Đơn hàng'),
            Tab(text: 'Người dùng'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          AdminHomePage(repository: widget.repository, userId: widget.userId),
          AdminProductsPage(
              repository: widget.repository, userId: widget.userId),
          AdminCategoriesPage(
              repository: widget.repository, userId: widget.userId),
          AdminBannersPage(repository: widget.repository, userId: widget.userId),
          AdminSalesPage(repository: widget.repository, userId: widget.userId),
          AdminOrdersPage(repository: widget.repository, userId: widget.userId),
          AdminUsersPage(repository: widget.repository, userId: widget.userId),
        ],
      ),
    );
  }
}
