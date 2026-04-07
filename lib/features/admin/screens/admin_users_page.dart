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
  final Set<String> _updatingUserIds = <String>{};

  @override
  Widget build(BuildContext context) {
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
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: const InputDecoration(
                hintText: 'Tìm theo uid / email / tên',
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
          FutureBuilder<List<ShopUser>>(
            future: widget.repository.getUsers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Text('Lỗi: ${snapshot.error}'),
                  ),
                );
              }

              var users = snapshot.data ?? [];
              if (_searchQuery.isNotEmpty) {
                final query = _searchQuery.toLowerCase();
                users = users.where((u) {
                  return u.uid.toLowerCase().contains(query) ||
                      u.email.toLowerCase().contains(query) ||
                      u.displayName.toLowerCase().contains(query);
                }).toList();
              }

              if (users.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Text('Không có người dùng'),
                  ),
                );
              }

              return Column(
                children: List.generate(users.length, (idx) {
                  final user = users[idx];
                  return _UserListRow(
                    user: user,
                    onView: () => _showUserDetail(user),
                    isUpdating: _updatingUserIds.contains(user.uid),
                    onRoleChanged: (role) => _changeUserRole(user, role),
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
    var selectedRole = _normalizeRole(user.role);
    var saving = false;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
                const SizedBox(height: 12),
                const Text(
                  'Phân quyền',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  items: const [
                    DropdownMenuItem(value: 'user', child: Text('User')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: saving
                      ? null
                      : (value) {
                          if (value == null) return;
                          setDialogState(() => selectedRole = value);
                        },
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFea580c), width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
            FilledButton(
              onPressed: saving || selectedRole == _normalizeRole(user.role)
                  ? null
                  : () async {
                      final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      setDialogState(() => saving = true);
                      try {
                        await widget.repository.updateUserRole(
                          userId: user.uid,
                          role: selectedRole,
                        );
                        if (!mounted) return;
                        navigator.pop();
                        setState(() {});
                        messenger.showSnackBar(
                          SnackBar(content: Text('Đã cập nhật quyền thành $selectedRole')),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Không đổi được quyền: $e'),
                            backgroundColor: Colors.red.shade700,
                          ),
                        );
                      } finally {
                        if (context.mounted) {
                          setDialogState(() => saving = false);
                        }
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Lưu quyền'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeUserRole(ShopUser user, String role) async {
    final currentRole = _normalizeRole(user.role);
    final nextRole = _normalizeRole(role);
    if (currentRole == nextRole) return;

    setState(() => _updatingUserIds.add(user.uid));
    try {
      await widget.repository.updateUserRole(userId: user.uid, role: nextRole);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã đổi quyền ${user.displayName} -> $nextRole')),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi đổi quyền: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _updatingUserIds.remove(user.uid));
      }
    }
  }

  String _normalizeRole(String role) {
    return role.trim().toLowerCase() == 'admin' ? 'admin' : 'user';
  }
}

class _UserListRow extends StatelessWidget {
  const _UserListRow({
    required this.user,
    required this.onView,
    required this.onRoleChanged,
    this.isUpdating = false,
  });

  final ShopUser user;
  final VoidCallback onView;
  final ValueChanged<String> onRoleChanged;
  final bool isUpdating;

  @override
  Widget build(BuildContext context) {
    final role = user.role.trim().toLowerCase() == 'admin' ? 'admin' : 'user';
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
          const SizedBox(width: 6),
          SizedBox(
            width: 96,
            child: DropdownButtonFormField<String>(
              initialValue: role,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'user', child: Text('user')),
                DropdownMenuItem(value: 'admin', child: Text('admin')),
              ],
              onChanged: isUpdating
                  ? null
                  : (value) {
                      if (value == null) return;
                      onRoleChanged(value);
                    },
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFea580c), width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
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
              child: isUpdating
                  ? const SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
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
