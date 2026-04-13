import 'package:flutter/material.dart';

import '../../../models/shop_models.dart';
import '../../../services/shop_repository.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({
    required this.repository,
    required this.userId,
    super.key,
  });

  final ShopRepository repository;
  final String userId;

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  String _selectedFilter = 'Tất cả';

  String _normalizedStatus(String status) {
    final value = status.toLowerCase().trim();
    if (value == 'pending' || value == 'processing') return 'pending';
    if (value == 'paid' ||
        value == 'completed' ||
        value == 'delivered' ||
        value == 'confirmed') {
      return 'paid';
    }
    if (value == 'review' || value == 'shipping') return 'review';
    return value;
  }

  List<ShopOrder> _applyFilter(List<ShopOrder> orders) {
    switch (_selectedFilter) {
      case 'Chờ xử lý':
        return orders
            .where((order) => _normalizedStatus(order.status) == 'pending')
            .toList();
      case 'Đã thanh toán':
        return orders
            .where((order) => _normalizedStatus(order.status) == 'paid')
            .toList();
      default:
        return orders;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: FutureBuilder<List<ShopOrder>>(
        future: widget.repository.getOrders(requesterUserId: widget.userId),
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
            final errorText = '${snapshot.error}';
            final isPermissionDenied = errorText.contains('permission-denied');
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  isPermissionDenied
                      ? 'Lỗi quyền truy cập đơn hàng. Kiểm tra users/{uid}.role=admin rồi đăng nhập lại.'
                      : 'Lỗi: ${snapshot.error}',
                ),
              ),
            );
          }

          final orders = snapshot.data ?? [];
          final pendingCount = orders
              .where((order) => _normalizedStatus(order.status) == 'pending')
              .length;
          final paidCount = orders
              .where((order) => _normalizedStatus(order.status) == 'paid')
              .length;
          final reviewCount = orders
              .where((order) => _normalizedStatus(order.status) == 'review')
              .length;
          final filteredOrders = _applyFilter(orders);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _SummaryChip(
                      label: 'chờ xử lý',
                      value: '$pendingCount',
                      bgColor: const Color(0xFFfff2e8),
                      textColor: const Color(0xFFea580c),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SummaryChip(
                      label: 'đã thanh toán',
                      value: '$paidCount',
                      bgColor: const Color(0xFFeafaf0),
                      textColor: const Color(0xFF12824a),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SummaryChip(
                      label: 'đang rà soát',
                      value: '$reviewCount',
                      bgColor: const Color(0xFFeff5ff),
                      textColor: const Color(0xFF2563eb),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 32,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _FilterPill(
                      label: 'Tất cả',
                      isSelected: _selectedFilter == 'Tất cả',
                      onTap: () => setState(() => _selectedFilter = 'Tất cả'),
                    ),
                    const SizedBox(width: 8),
                    _FilterPill(
                      label: 'Chờ xử lý',
                      isSelected: _selectedFilter == 'Chờ xử lý',
                      onTap: () =>
                          setState(() => _selectedFilter = 'Chờ xử lý'),
                    ),
                    const SizedBox(width: 8),
                    _FilterPill(
                      label: 'Đã thanh toán',
                      isSelected: _selectedFilter == 'Đã thanh toán',
                      onTap: () =>
                          setState(() => _selectedFilter = 'Đã thanh toán'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              if (filteredOrders.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Text('Không có đơn hàng theo bộ lọc đã chọn'),
                  ),
                )
              else
                Column(
                  children: List.generate(filteredOrders.length, (idx) {
                    final order = filteredOrders[idx];
                    return _OrderListRow(
                      order: order,
                      onView: () => _showOrderDetail(order),
                      onUpdate: () => _showUpdateDialog(order),
                    );
                  }),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showOrderDetail(ShopOrder order) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Chi tiết đơn hàng'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ID: ${order.id}'),
              const SizedBox(height: 8),
              Text('Người dùng: ${order.userId}'),
              const SizedBox(height: 8),
              Text('Tổng tiền: ${order.totalAmount}₫'),
              const SizedBox(height: 8),
              Text('Trạng thái: ${order.status}'),
              const SizedBox(height: 8),
              Text('Ngày tạo: ${order.createdAt}'),
              const SizedBox(height: 12),
              const Text(
                'Địa chỉ giao hàng',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFECECEC)),
                ),
                child: SelectableText(
                  order.address.trim().isEmpty
                      ? 'Chưa có địa chỉ giao hàng'
                      : order.address,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Color(0xFF171717),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showUpdateDialog(ShopOrder order) {
    String status = order.status;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Cập nhật trạng thái'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: status,
                isExpanded: true,
                items: ['pending', 'paid', 'review', 'completed']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) => setModalState(() => status = val ?? status),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                final updatedOrder = order.copyWith(status: status);
                await widget.repository.updateOrder(updatedOrder);
                if (!mounted) return;
                if (context.mounted) {
                  Navigator.pop(context);
                }
                setState(() {});
              },
              child: const Text(
                'Cập nhật',
                style: TextStyle(color: Color(0xFFea580c)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
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

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFfff2e8) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFffd2b1)
                : const Color(0xFFECECEC),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? const Color(0xFFea580c)
                : const Color(0xFF7a7a7a),
          ),
        ),
      ),
    );
  }
}

class _OrderListRow extends StatelessWidget {
  const _OrderListRow({
    required this.order,
    required this.onView,
    required this.onUpdate,
  });

  final ShopOrder order;
  final VoidCallback onView;
  final VoidCallback onUpdate;

  Color _getStatusColor(String status) {
    switch (status.toLowerCase().trim()) {
      case 'pending':
        return const Color(0xFFfff2e8);
      case 'paid':
      case 'completed':
      case 'delivered':
      case 'confirmed':
        return const Color(0xFFeafaf0);
      case 'review':
      case 'shipping':
        return const Color(0xFFeff5ff);
      default:
        return const Color(0xFFF7F7F7);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toLowerCase().trim()) {
      case 'pending':
        return const Color(0xFFea580c);
      case 'paid':
      case 'completed':
      case 'delivered':
      case 'confirmed':
        return const Color(0xFF12824a);
      case 'review':
      case 'shipping':
        return const Color(0xFF2563eb);
      default:
        return const Color(0xFF7a7a7a);
    }
  }

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đơn #${order.id.substring(0, 8)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(order.status),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        order.status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _getStatusTextColor(order.status),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${order.totalAmount}₫',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFea580c),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              _TinyButton(
                label: 'Xem',
                color: const Color(0xFFeff5ff),
                textColor: const Color(0xFF2563eb),
                onTap: onView,
              ),
              const SizedBox(height: 4),
              _TinyButton(
                label: 'Cập nhật',
                color: const Color(0xFFfff2e8),
                textColor: const Color(0xFFea580c),
                onTap: onUpdate,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TinyButton extends StatelessWidget {
  const _TinyButton({
    required this.label,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
