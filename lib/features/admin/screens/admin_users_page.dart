import 'package:flutter/material.dart';

import '../../../models/shop_models.dart';
import '../../../services/shop_repository.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({
    required this.repository,
    required this.userId,
    super.key,
  });

  final ShopRepository repository;
  final String userId;

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  String _searchQuery = '';

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
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: const InputDecoration(
                hintText: 'Tìm người dùng theo uid',
                hintStyle: TextStyle(fontSize: 11, color: Color(0xFF7a7a7a)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                suffixIcon: Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.search, size: 18, color: Color(0xFF7a7a7a)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // User list
          FutureBuilder<List<ShopUser>>(
            future: widget.repository.getUsers(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              var users = snapshot.data ?? [];
              if (_searchQuery.isNotEmpty) {
                users = users
                    .where((u) => u.uid.toLowerCase().contains(_searchQuery.toLowerCase()))
                    .toList();
              }

              return Column(
                children: List.generate(users.length, (idx) {
                  final user = users[idx];
                  return _UserListRow(
                    user: user,
                    onView: () => _showUserDetail(user),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showUserDetail(ShopUser user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Thông tin người dùng'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('UID: ${user.uid}'),
              const SizedBox(height: 8),
              Text('Email: ${user.email}'),
              const SizedBox(height: 8),
              Text('Tên: ${user.displayName}'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thông tin tài khoản',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(label: 'Đã yêu thích', value: user.favoriteCount.toString()),
                    _InfoRow(label: 'Giỏ hàng', value: user.cartCount.toString()),
                    _InfoRow(label: 'Đơn hàng', value: user.orderCount.toString()),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: Navigator.of(context).pop, child: const Text('Đóng')),
        ],
      ),
    );
  }
}

class _UserListRow extends StatelessWidget {
  const _UserListRow({
    required this.user,
    required this.onView,
  });

  final ShopUser user;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFECECEC)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFfff2e8),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Icon(Icons.person, size: 20, color: Color(0xFFea580c)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  user.uid,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF7a7a7a)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Stats badges
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _StatBadge(icon: '♡', label: user.favoriteCount.toString()),
              const SizedBox(height: 4),
              _StatBadge(icon: '🛒', label: user.cartCount.toString()),
              const SizedBox(height: 4),
              _StatBadge(icon: '📦', label: user.orderCount.toString()),
            ],
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onView,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFeff5ff),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFeff5ff)),
              ),
              child: const Text(
                'Xem',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2563eb),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.icon,
    required this.label,
  });

  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFECECEC)),
      ),
      child: Text(
        '$icon $label',
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: Color(0xFF7a7a7a),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF7a7a7a))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFefeff0),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
