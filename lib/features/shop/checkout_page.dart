import 'package:flutter/material.dart';

import '../../models/shop_models.dart';
import '../../services/shop_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/smart_shop_image.dart';
import 'formatting.dart';
import 'shipping_addresses_page.dart';

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
  String? _selectedAddressId;
  String _paymentMethod = 'cod';

  int get _total =>
      widget.items.fold<int>(0, (value, item) => value + item.totalPrice);

  Future<void> _placeOrder(ShippingAddress address) async {
    if (_paymentMethod != 'cod') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phương thức này chưa phát triển, vui lòng chọn COD')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final orderAddress =
          '${address.recipientName} • ${address.phone}\n${address.addressLine}';
      await widget.repository.checkout(
        widget.userId,
        items: widget.items,
        address: orderAddress,
        paymentMethod: _paymentMethod,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đặt hàng thành công.')));
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
      body: StreamBuilder<List<ShippingAddress>>(
        stream: widget.repository.shippingAddresses(widget.userId),
        builder: (context, snapshot) {
          final addresses = snapshot.data ?? const <ShippingAddress>[];
          final selected = _resolveSelectedAddress(addresses);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            children: [
              _CheckoutBlock(
                title: 'Địa chỉ nhận hàng',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (selected == null)
                      const _CheckoutText('Bạn chưa có địa chỉ giao hàng.')
                    else ...[
                      Text(
                        '${selected.recipientName} • ${selected.phone}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 6),
                      _CheckoutText(selected.addressLine),
                    ],
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: () => _openAddressSelector(context),
                      child: Text(selected == null ? 'Thêm địa chỉ' : 'Chọn địa chỉ khác'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _CheckoutBlock(
                title: 'Phương thức thanh toán',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _PaymentChip(
                      label: 'ShoppePay',
                      selected: _paymentMethod == 'shoppepay',
                      onTap: () => _showNotReady(),
                    ),
                    _PaymentChip(
                      label: 'COD',
                      selected: _paymentMethod == 'cod',
                      onTap: () => setState(() => _paymentMethod = 'cod'),
                    ),
                    _PaymentChip(
                      label: 'Chuyển khoản',
                      selected: _paymentMethod == 'bank',
                      onTap: () => _showNotReady(),
                    ),
                    _PaymentChip(
                      label: 'Thẻ',
                      selected: _paymentMethod == 'card',
                      onTap: () => _showNotReady(),
                    ),
                  ],
                ),
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
                                child: SmartShopImage(
                                  source: item.image,
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
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
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
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: ElevatedButton(
            onPressed: _isSubmitting
                ? null
                : () {
                    final selected = _resolveSelectedAddressFromCache();
                    if (selected == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng chọn địa chỉ giao hàng')),
                      );
                      return;
                    }
                    _placeOrder(selected);
                  },
            child: Text(_isSubmitting ? 'Đang xử lý...' : 'Đặt hàng'),
          ),
        ),
      ),
    );
  }

  List<ShippingAddress> _lastAddresses = const [];

  ShippingAddress? _resolveSelectedAddress(List<ShippingAddress> addresses) {
    _lastAddresses = addresses;
    if (addresses.isEmpty) return null;
    if (_selectedAddressId != null) {
      for (final item in addresses) {
        if (item.id == _selectedAddressId) return item;
      }
    }
    ShippingAddress? fromDefault;
    for (final item in addresses) {
      if (item.isDefault) {
        fromDefault = item;
        break;
      }
    }
    final selected = fromDefault ?? addresses.first;
    _selectedAddressId = selected.id;
    return selected;
  }

  ShippingAddress? _resolveSelectedAddressFromCache() {
    if (_lastAddresses.isEmpty) return null;
    return _resolveSelectedAddress(_lastAddresses);
  }

  Future<void> _openAddressSelector(BuildContext context) async {
    final selected = await Navigator.of(context).push<ShippingAddress>(
      MaterialPageRoute<ShippingAddress>(
        builder: (_) => ShippingAddressesPage(
          repository: widget.repository,
          userId: widget.userId,
          selectMode: true,
        ),
      ),
    );
    if (!mounted || selected == null) return;
    setState(() => _selectedAddressId = selected.id);
  }

  void _showNotReady() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Phương thức này chưa phát triển, vui lòng chọn COD')),
    );
  }
}

class _CheckoutBlock extends StatelessWidget {
  const _CheckoutBlock({required this.title, required this.child});

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
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
    );
  }
}

class _PaymentChip extends StatelessWidget {
  const _PaymentChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFfff2e8) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primary : const Color(0xFFE0E0E0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
