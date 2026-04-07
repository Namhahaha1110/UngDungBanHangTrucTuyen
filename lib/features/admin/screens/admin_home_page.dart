import 'package:flutter/material.dart';

import '../../../services/shop_repository.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({
    required this.repository,
    required this.userId,
    required this.onOpenModule,
    required this.onGoHome,
    super.key,
  });

  final ShopRepository repository;
  final String userId;
  final ValueChanged<int> onOpenModule;
  final VoidCallback onGoHome;

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AdminDashboardStats>(
      future: _loadStats(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? _AdminDashboardStats.empty();
        final modules = [
          _AdminModuleItem(
            name: 'Sản phẩm',
            desc: '${stats.productCount} record',
            badge: 'CRUD',
            keywords: 'san pham products',
            moduleIndex: 1,
          ),
          _AdminModuleItem(
            name: 'Danh mục',
            desc: '${stats.categoryCount} nhóm',
            badge: 'Sort',
            keywords: 'danh muc category categories',
            moduleIndex: 2,
          ),
          _AdminModuleItem(
            name: 'Banner',
            desc: '${stats.bannerCount} asset',
            badge: 'Active',
            keywords: 'banner marketing',
            moduleIndex: 3,
          ),
          _AdminModuleItem(
            name: 'Flash sale',
            desc: '${stats.flashSaleCount} record',
            badge: 'Timer',
            keywords: 'flash sale giam gia',
            moduleIndex: 4,
          ),
          _AdminModuleItem(
            name: 'Voucher',
            desc: '${stats.voucherCount} mã',
            badge: 'Coupon',
            keywords: 'voucher giam gia shipping code',
            moduleIndex: 5,
          ),
          _AdminModuleItem(
            name: 'Đơn hàng',
            desc: '${stats.orderCount} đơn',
            badge: 'Theo dõi',
            keywords: 'don hang order orders',
            moduleIndex: 6,
          ),
          _AdminModuleItem(
            name: 'Người dùng',
            desc: '${stats.userCount} tài khoản',
            badge: 'Cẩn thận',
            keywords: 'nguoi dung user users role',
            moduleIndex: 7,
          ),
        ];
        final quickActions = [
          _AdminQuickActionItem(
            title: 'Thêm sản phẩm mới',
            desc: 'Tạo record mới cho bảng products',
            keywords: 'them san pham products add',
            moduleIndex: 1,
          ),
          _AdminQuickActionItem(
            title: 'Tạo banner chiến dịch',
            desc: 'Thêm asset mới cho homepage',
            keywords: 'tao banner asset home',
            moduleIndex: 3,
          ),
          _AdminQuickActionItem(
            title: 'Sửa flash sale',
            desc: 'Điều chỉnh off %, thời gian, trạng thái',
            keywords: 'flash sale sua discount',
            moduleIndex: 4,
          ),
          _AdminQuickActionItem(
            title: 'Tạo voucher',
            desc: 'Thiết lập mã giảm cho shop/vận chuyển',
            keywords: 'voucher code giam gia shipping',
            moduleIndex: 5,
          ),
          _AdminQuickActionItem(
            title: 'Rà soát người dùng',
            desc: 'Kiểm tra favorites, cart, orders theo uid',
            keywords: 'nguoi dung users review role',
            moduleIndex: 7,
          ),
        ];
        final query = _normalize(_searchQuery);
        final filteredModules = query.isEmpty
            ? modules
            : modules
                  .where(
                    (m) => _normalize(
                      '${m.name} ${m.desc} ${m.keywords}',
                    ).contains(query),
                  )
                  .toList();
        final filteredQuickActions = query.isEmpty
            ? quickActions
            : quickActions
                  .where(
                    (a) => _normalize(
                      '${a.title} ${a.desc} ${a.keywords}',
                    ).contains(query),
                  )
                  .toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFECECEC)),
                ),
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Tìm bảng, record hoặc mã đơn hàng',
                    hintStyle: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF7a7a7a),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 18,
                      color: Color(0xFF7a7a7a),
                    ),
                    suffixIcon: _searchQuery.trim().isEmpty
                        ? null
                        : IconButton(
                            onPressed: () => setState(() => _searchQuery = ''),
                            icon: const Icon(
                              Icons.close,
                              size: 18,
                              color: Color(0xFF7a7a7a),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (query.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Kết quả cho "$_searchQuery"',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF7a7a7a),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              // Summary row
              Row(
                children: [
                  Expanded(
                    child: _StatChip(
                      label: 'mục quản lý chính',
                      value: '${stats.moduleCount}',
                      bgColor: const Color(0xFFfff2e8),
                      textColor: const Color(0xFFea580c),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatChip(
                      label: 'mục chờ xử lý',
                      value: '${stats.pendingItems}',
                      bgColor: const Color(0xFFeafaf0),
                      textColor: const Color(0xFF12824a),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatChip(
                      label: 'cảnh báo dữ liệu',
                      value: '${stats.dataAlerts}',
                      bgColor: const Color(0xFFeff5ff),
                      textColor: const Color(0xFF2563eb),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: widget.onGoHome,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFea580c)),
                    foregroundColor: const Color(0xFFea580c),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  icon: const Icon(Icons.home_outlined, size: 16),
                  label: const Text(
                    'Về trang chủ',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Management modules
              _AdminSection(
                title: 'Chức năng quản lý',
                subtitle: 'Toàn bộ app',
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.2,
                  children: filteredModules
                      .map(
                        (module) => _ModuleCard(
                          name: module.name,
                          desc: module.desc,
                          badge: module.badge,
                          onTap: () => widget.onOpenModule(module.moduleIndex),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 10),

              // Quick actions
              _AdminSection(
                title: 'Thao tác nhanh',
                subtitle: 'CRUD',
                bgColor: const Color(0xFFF7F7F7),
                child: Column(
                  children: List.generate(filteredQuickActions.length, (index) {
                    final action = filteredQuickActions[index];
                    return _QuickAction(
                      title: action.title,
                      desc: action.desc,
                      onTap: () => widget.onOpenModule(action.moduleIndex),
                      isLast: index == filteredQuickActions.length - 1,
                    );
                  }),
                ),
              ),
              if (query.isNotEmpty &&
                  filteredModules.isEmpty &&
                  filteredQuickActions.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Center(
                    child: Text(
                      'Không tìm thấy mục phù hợp',
                      style: TextStyle(fontSize: 12, color: Color(0xFF7a7a7a)),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _normalize(String value) {
    return value.toLowerCase().trim();
  }

  Future<_AdminDashboardStats> _loadStats() async {
    final results = await Future.wait([
      widget.repository.getProducts(),
      widget.repository.getCategories(),
      widget.repository.getBanners(),
      widget.repository.getFlashSales(),
      widget.repository.getVouchers(),
      widget.repository.getOrders(requesterUserId: widget.userId),
      widget.repository.getUsers(),
    ]);
    final products = results[0] as List;
    final categories = results[1] as List;
    final banners = results[2] as List;
    final sales = results[3] as List;
    final vouchers = results[4] as List;
    final orders = results[5] as List;
    final users = results[6] as List;

    final pendingStatuses = {'pending', 'review', 'shipping'};
    final pendingOrderCount = orders.where((order) {
      final status = (order.status as String?)?.toLowerCase().trim() ?? '';
      return pendingStatuses.contains(status);
    }).length;
    final outOfStock = products
        .where((product) => (product.stock as int? ?? 0) <= 0)
        .length;
    final inactiveSales = sales
        .where((sale) => (sale.status as String?) == 'inactive')
        .length;

    return _AdminDashboardStats(
      moduleCount: 7,
      pendingItems: pendingOrderCount,
      dataAlerts: outOfStock + inactiveSales,
      productCount: products.length,
      categoryCount: categories.length,
      bannerCount: banners.length,
      flashSaleCount: sales.length,
      voucherCount: vouchers.length,
      orderCount: orders.length,
      userCount: users.length,
    );
  }
}

class _AdminModuleItem {
  const _AdminModuleItem({
    required this.name,
    required this.desc,
    required this.badge,
    required this.keywords,
    required this.moduleIndex,
  });

  final String name;
  final String desc;
  final String badge;
  final String keywords;
  final int moduleIndex;
}

class _AdminQuickActionItem {
  const _AdminQuickActionItem({
    required this.title,
    required this.desc,
    required this.keywords,
    required this.moduleIndex,
  });

  final String title;
  final String desc;
  final String keywords;
  final int moduleIndex;
}

class _AdminDashboardStats {
  const _AdminDashboardStats({
    required this.moduleCount,
    required this.pendingItems,
    required this.dataAlerts,
    required this.productCount,
    required this.categoryCount,
    required this.bannerCount,
    required this.flashSaleCount,
    required this.voucherCount,
    required this.orderCount,
    required this.userCount,
  });

  final int moduleCount;
  final int pendingItems;
  final int dataAlerts;
  final int productCount;
  final int categoryCount;
  final int bannerCount;
  final int flashSaleCount;
  final int voucherCount;
  final int orderCount;
  final int userCount;

  factory _AdminDashboardStats.empty() => const _AdminDashboardStats(
    moduleCount: 7,
    pendingItems: 0,
    dataAlerts: 0,
    productCount: 0,
    categoryCount: 0,
    bannerCount: 0,
    flashSaleCount: 0,
    voucherCount: 0,
    orderCount: 0,
    userCount: 0,
  );
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.bgColor,
    required this.textColor,
  });

  final String label;
  final String value;
  final Color bgColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF7a7a7a),
              height: 1.35,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AdminSection extends StatelessWidget {
  const _AdminSection({
    required this.title,
    required this.subtitle,
    required this.child,
    this.bgColor = Colors.white,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFECECEC)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF7a7a7a),
                  ),
                ),
              ],
            ),
          ),
          Container(color: bgColor, child: child),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.name,
    required this.desc,
    required this.badge,
    required this.onTap,
  });

  final String name;
  final String desc;
  final String badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFECECEC)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: const TextStyle(fontSize: 11, color: Color(0xFF7a7a7a)),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Badge(label: badge),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFfff2e8),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFffd2b1)),
                    ),
                    child: const Text(
                      'Mở',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFea580c),
                      ),
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

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    switch (label) {
      case 'CRUD':
        bgColor = const Color(0xFFfff2e8);
        textColor = const Color(0xFFea580c);
        break;
      case 'Sort':
      case 'Timer':
        bgColor = const Color(0xFFeff5ff);
        textColor = const Color(0xFF2563eb);
        break;
      case 'Active':
        bgColor = const Color(0xFFeafaf0);
        textColor = const Color(0xFF12824a);
        break;
      case 'Coupon':
        bgColor = const Color(0xFFfff2e8);
        textColor = const Color(0xFFea580c);
        break;
      default:
        bgColor = const Color(0xFFfff1f1);
        textColor = const Color(0xFFd12626);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.title,
    required this.desc,
    required this.onTap,
    this.isLast = false,
  });

  final String title;
  final String desc;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          desc,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF7a7a7a),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFfff2e8),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFffd2b1)),
                    ),
                    child: const Text(
                      'Mở',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFea580c),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!isLast) const Divider(height: 1, indent: 12, endIndent: 12),
          ],
        ),
      ),
    );
  }
}
