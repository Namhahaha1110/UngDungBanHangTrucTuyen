import 'package:flutter/material.dart';

import '../../../models/shop_models.dart';
import '../../../services/shop_repository.dart';

class AdminRevenuePage extends StatefulWidget {
  const AdminRevenuePage({
    required this.repository,
    required this.userId,
    super.key,
  });

  final ShopRepository repository;
  final String userId;

  @override
  State<AdminRevenuePage> createState() => _AdminRevenuePageState();
}

class _AdminRevenuePageState extends State<AdminRevenuePage> {
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Text('Lỗi tải báo cáo: ${snapshot.error}'),
              ),
            );
          }

          final orders = snapshot.data ?? const <ShopOrder>[];
          final paidOrders = orders.where(_isRevenueOrder).toList();
          final grossRevenue = paidOrders.fold<int>(
            0,
            (sum, item) => sum + item.totalAmount,
          );
          final voucherTotal = paidOrders.fold<int>(
            0,
            (sum, item) => sum + item.voucherDiscount,
          );
          final orderCount = paidOrders.length;
          final avgOrder = orderCount == 0
              ? 0
              : (grossRevenue / orderCount).round();

          final last7Days = _buildLast7DayData(paidOrders);
          final statusStats = _buildStatusStats(orders);
          final paymentStats = _buildPaymentStats(paidOrders);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _SummaryChip(
                      label: 'Doanh thu',
                      value: _currency(grossRevenue),
                      bgColor: const Color(0xFFeafaf0),
                      textColor: const Color(0xFF12824a),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SummaryChip(
                      label: 'Đơn thanh toán',
                      value: '$orderCount',
                      bgColor: const Color(0xFFeff5ff),
                      textColor: const Color(0xFF2563eb),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SummaryChip(
                      label: 'Voucher giảm',
                      value: _currency(voucherTotal),
                      bgColor: const Color(0xFFfff2e8),
                      textColor: const Color(0xFFea580c),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Giá trị đơn TB: ${_currency(avgOrder)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7a7a7a),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _ChartCard(
                title: 'Doanh thu 7 ngày gần nhất',
                child: _RevenueBarChart(data: last7Days),
              ),
              const SizedBox(height: 10),
              _ChartCard(
                title: 'Phân bổ theo trạng thái',
                child: _LegendList(data: statusStats),
              ),
              const SizedBox(height: 10),
              _ChartCard(
                title: 'Phân bổ theo phương thức thanh toán',
                child: _LegendList(data: paymentStats),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _isRevenueOrder(ShopOrder order) {
    final status = order.status.trim().toLowerCase();
    return status == 'paid' ||
        status == 'completed' ||
        status == 'confirmed' ||
        status == 'delivered';
  }

  List<_BarPoint> _buildLast7DayData(List<ShopOrder> orders) {
    final now = DateTime.now();
    final points = <_BarPoint>[];
    for (var offset = 6; offset >= 0; offset--) {
      final day = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: offset));
      final value = orders
          .where((order) {
            final created = order.createdAt;
            if (created == null) return false;
            return created.year == day.year &&
                created.month == day.month &&
                created.day == day.day;
          })
          .fold<int>(0, (sum, item) => sum + item.totalAmount);
      points.add(_BarPoint(label: '${day.day}/${day.month}', value: value));
    }
    return points;
  }

  List<_LegendPoint> _buildStatusStats(List<ShopOrder> orders) {
    final map = <String, int>{};
    for (final order in orders) {
      final status = order.status.trim().toLowerCase();
      map[status] = (map[status] ?? 0) + 1;
    }
    return map.entries
        .map((e) => _LegendPoint(label: e.key, value: e.value))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  List<_LegendPoint> _buildPaymentStats(List<ShopOrder> orders) {
    final map = <String, int>{};
    for (final order in orders) {
      final method = order.paymentMethod.trim().isEmpty
          ? 'unknown'
          : order.paymentMethod.trim().toLowerCase();
      map[method] = (map[method] ?? 0) + 1;
    }
    return map.entries
        .map((e) => _LegendPoint(label: e.key, value: e.value))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  String _currency(int value) => '${value.toString()}đ';
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
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF7a7a7a)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFECECEC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _RevenueBarChart extends StatelessWidget {
  const _RevenueBarChart({required this.data});

  final List<_BarPoint> data;

  @override
  Widget build(BuildContext context) {
    final maxValue = data.fold<int>(0, (m, e) => e.value > m ? e.value : m);
    return SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((point) {
          final ratio = maxValue <= 0 ? 0.0 : (point.value / maxValue);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    point.value == 0 ? '0' : '${(point.value / 1000).round()}k',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF7a7a7a),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 120 * ratio + 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFea580c),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    point.label,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF7a7a7a),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _LegendList extends StatelessWidget {
  const _LegendList({required this.data});

  final List<_LegendPoint> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Chưa có dữ liệu',
          style: TextStyle(fontSize: 12, color: Color(0xFF7a7a7a)),
        ),
      );
    }
    final total = data.fold<int>(0, (sum, item) => sum + item.value);
    return Column(
      children: data.map((item) {
        final percent = total <= 0 ? 0 : ((item.value * 100) / total).round();
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFea580c).withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(item.label, style: const TextStyle(fontSize: 12)),
              ),
              Text(
                '${item.value} ($percent%)',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF171717),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _BarPoint {
  const _BarPoint({required this.label, required this.value});

  final String label;
  final int value;
}

class _LegendPoint {
  const _LegendPoint({required this.label, required this.value});

  final String label;
  final int value;
}
