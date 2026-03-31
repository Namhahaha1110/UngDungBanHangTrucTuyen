import 'package:flutter/material.dart';

import '../../../models/shop_models.dart';
import '../../../services/shop_repository.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({
    required this.repository,
    required this.userId,
    super.key,
  });

  final ShopRepository repository;
  final String userId;

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search box
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFECECEC)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Tìm bảng, record hoặc mã đơn hàng',
                    style: TextStyle(fontSize: 11, color: Color(0xFF7a7a7a)),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.search, size: 18, color: Color(0xFF7a7a7a)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Summary row
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  label: 'mục quản lý chính',
                  value: '6',
                  bgColor: const Color(0xFFfff2e8),
                  textColor: const Color(0xFFea580c),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatChip(
                  label: 'mục chờ xử lý',
                  value: '17',
                  bgColor: const Color(0xFFeafaf0),
                  textColor: const Color(0xFF12824a),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatChip(
                  label: 'cảnh báo dữ liệu',
                  value: '3',
                  bgColor: const Color(0xFFeff5ff),
                  textColor: const Color(0xFF2563eb),
                ),
              ),
            ],
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
              children: const [
                _ModuleCard(name: 'Sản phẩm', desc: '4 record đang bán', badge: 'CRUD'),
                _ModuleCard(name: 'Danh mục', desc: '5 nhóm chính', badge: 'Sort'),
                _ModuleCard(name: 'Banner', desc: '3 asset homepage', badge: 'Active'),
                _ModuleCard(name: 'Flash sale', desc: '6 record giảm giá', badge: 'Timer'),
                _ModuleCard(name: 'Đơn hàng', desc: '24 đơn gần nhất', badge: 'Theo dõi'),
                _ModuleCard(name: 'Người dùng', desc: '18 tài khoản', badge: 'Cẩn thận'),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Quick actions
          _AdminSection(
            title: 'Thao tác nhanh',
            subtitle: 'CRUD',
            bgColor: const Color(0xFFF7F7F7),
            child: Column(
              children: [
                _QuickAction(
                  title: 'Thêm sản phẩm mới',
                  desc: 'Tạo record mới cho bảng products',
                ),
                _QuickAction(
                  title: 'Tạo banner chiến dịch',
                  desc: 'Thêm asset mới cho homepage',
                ),
                _QuickAction(
                  title: 'Sửa flash sale',
                  desc: 'Điều chỉnh off %, thời gian, trạng thái',
                ),
                _QuickAction(
                  title: 'Rà soát người dùng',
                  desc: 'Kiểm tra favorites, cart, orders theo uid',
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
          Container(
            color: bgColor,
            child: child,
          ),
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
  });

  final String name;
  final String desc;
  final String badge;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
    this.isLast = false,
  });

  final String title;
  final String desc;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFfff2e8),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFffd2b1)),
                ),
                child: const Text(
                  'Thêm',
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
    );
  }
}
