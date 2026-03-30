import 'package:flutter/material.dart';

import '../../models/shop_models.dart';
import '../../services/shop_repository.dart';
import '../../theme/app_theme.dart';
import 'formatting.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({
    required this.repository,
    required this.userId,
    required this.items,
    super.key,
  });

  final ShopRepository repository;
  final String userId;
  final List<UserProductItem> items;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool _isSubmitting = false;

  int get _total =>
      widget.items.fold<int>(0, (value, item) => value + item.totalPrice);

  Future<void> _placeOrder() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.repository.checkout(
        widget.userId,
        items: widget.items,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đặt hàng thành công.')),
      );
      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          const _CheckoutBlock(
            title: 'Địa chỉ nhận hàng',
            child: _CheckoutText(
              '431/71/1a Hà Thanh Lộc, Phường Thạnh Lộc, Quận 12, TP.Hồ Chí Minh',
            ),
          ),
          const SizedBox(height: 16),
          const _CheckoutBlock(
            title: 'Phương thức thanh toán',
            child: _CheckoutText('ShoppePay'),
          ),
          const SizedBox(height: 16),
          _CheckoutBlock(
            title: 'Sản phẩm',
            child: Column(
              children: widget.items
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.asset(
                              'assets/images/${item.image}',
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Số lượng: ${item.quantity}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            formatCurrency(item.totalPrice),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          _CheckoutBlock(
            title: 'Tổng thanh toán',
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Tổng cộng',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Text(
                  formatCurrency(_total),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.primary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _placeOrder,
            child: Text(_isSubmitting ? 'Đang xử lý...' : 'Đặt hàng'),
          ),
        ),
      ),
    );
  }
}

class _CheckoutBlock extends StatelessWidget {
  const _CheckoutBlock({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _CheckoutText extends StatelessWidget {
  const _CheckoutText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
    );
  }
}
