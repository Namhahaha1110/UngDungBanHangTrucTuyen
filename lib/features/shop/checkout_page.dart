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
  static const int _shippingFee = 15000;

  bool _isSubmitting = false;
  String? _selectedAddressId;
  String _paymentMethod = 'cod';

  ShopVoucher? _selectedShippingVoucher;
  ShopVoucher? _selectedShopVoucher;

  List<ShippingAddress> _lastAddresses = const [];

  int get _subtotal =>
      widget.items.fold<int>(0, (value, item) => value + item.totalPrice);

  int get _shippingDiscount => _selectedShippingVoucher == null
      ? 0
      : _computeVoucherDiscount(_selectedShippingVoucher!, isShipping: true);
  int get _shopDiscount => _selectedShopVoucher == null
      ? 0
      : _computeVoucherDiscount(_selectedShopVoucher!, isShipping: false);
  int get _voucherDiscount => _shippingDiscount + _shopDiscount;

  int get _finalTotal {
    final shippingCost = (_shippingFee - _shippingDiscount).clamp(
      0,
      _shippingFee,
    );
    final amount = _subtotal + shippingCost - _shopDiscount;
    return amount < 0 ? 0 : amount;
  }

  String get _voucherSummary {
    final parts = <String>[];
    if (_selectedShippingVoucher != null) {
      parts.add(_selectedShippingVoucher!.code);
    }
    if (_selectedShopVoucher != null) {
      parts.add(_selectedShopVoucher!.code);
    }
    return parts.join(' | ');
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
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 110),
            children: [
              _AddressSection(
                address: selected,
                onTap: () => _openAddressSelector(context),
              ),
              const Divider(height: 1),
              _ProductsSection(items: widget.items),
              const Divider(height: 1),
              _ActionRow(
                title: 'Voucher của Shop',
                value: _voucherSummary.isEmpty
                    ? 'Chọn voucher'
                    : _voucherSummary,
                onTap: _openVoucherSelector,
              ),
              if (_voucherSummary.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7F1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFD9BF)),
                    ),
                    child: Text(
                      'Đã áp dụng: $_voucherSummary  •  Giảm ${formatCurrency(_voucherDiscount)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFB54A00),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
              const Divider(height: 1),
              _ActionRow(
                title: 'Lời nhắn cho Shop',
                value: 'Để lại lời nhắn',
                onTap: () {},
              ),
              const Divider(height: 1),
              _ShippingMethodSection(
                shippingFee: _shippingFee,
                shippingDiscount: _shippingDiscount,
              ),
              const Divider(height: 1),
              _PaymentSection(
                method: _paymentMethod,
                onSelect: _onSelectPaymentMethod,
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Tổng số tiền (1 sản phẩm)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      formatCurrency(_finalTotal),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
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
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE6E6E6))),
          ),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                    children: [
                      const TextSpan(text: 'Tổng cộng '),
                      TextSpan(
                        text: formatCurrency(_finalTotal),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 110,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _onCheckoutPressed,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(_isSubmitting ? 'Đang xử lý...' : 'Đặt hàng'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openVoucherSelector() async {
    final result = await Navigator.of(context).push<_VoucherSelectionResult>(
      MaterialPageRoute<_VoucherSelectionResult>(
        builder: (_) => VoucherSelectionPage(
          repository: widget.repository,
          selectedShippingVoucherId: _selectedShippingVoucher?.id,
          selectedShopVoucherId: _selectedShopVoucher?.id,
          subtotal: _subtotal,
          shippingFee: _shippingFee,
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      _selectedShippingVoucher = result.shippingVoucher;
      _selectedShopVoucher = result.shopVoucher;
    });
  }

  Future<void> _onCheckoutPressed() async {
    final selected = _resolveSelectedAddressFromCache();
    if (selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn địa chỉ giao hàng')),
      );
      return;
    }
    await _placeOrder(selected);
  }

  Future<void> _placeOrder(ShippingAddress address) async {
    if (_paymentMethod != 'cod') {
      _showNotReady();
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final orderAddress =
          '${address.recipientName} • ${address.phone}\n${address.addressLine}';
      await widget.repository.checkout(
        widget.userId,
        items: widget.items,
        address: orderAddress,
        paymentMethod: _paymentMethod,
        voucherDiscount: _voucherDiscount,
        voucherSummary: _voucherSummary,
        finalTotal: _finalTotal,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đặt hàng thành công.')));
      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _onSelectPaymentMethod(String method) {
    if (method != 'cod') {
      _showNotReady();
      return;
    }
    setState(() => _paymentMethod = method);
  }

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
      const SnackBar(
        content: Text('Phương thức này chưa phát triển, vui lòng chọn COD'),
      ),
    );
  }

  int _computeVoucherDiscount(ShopVoucher voucher, {required bool isShipping}) {
    final base = isShipping ? _shippingFee : _subtotal;
    if (base <= 0) return 0;
    if (voucher.minOrder > 0 && _subtotal < voucher.minOrder) return 0;
    var discount = 0;
    if (voucher.discountType.trim().toLowerCase() == 'percent') {
      discount = (base * voucher.discountValue / 100).round();
    } else {
      discount = voucher.discountValue;
    }
    if (voucher.maxDiscount > 0 && discount > voucher.maxDiscount) {
      discount = voucher.maxDiscount;
    }
    if (discount > base) return base;
    return discount < 0 ? 0 : discount;
  }
}

class _AddressSection extends StatelessWidget {
  const _AddressSection({required this.address, required this.onTap});

  final ShippingAddress? address;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final addressText = address == null
        ? 'Bạn chưa có địa chỉ giao hàng.'
        : '${address!.recipientName}\n${address!.addressLine}';
    final phone = address?.phone ?? '';
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE6E6E6)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 3),
                child: Icon(
                  Icons.location_on,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (phone.isNotEmpty)
                      Text(
                        '+84 $phone',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    Text(
                      addressText,
                      style: const TextStyle(fontSize: 14, height: 1.35),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFFBDBDBD)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductsSection extends StatelessWidget {
  const _ProductsSection({required this.items});

  final List<UserProductItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE9E9E9)),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SmartShopImage(
                          source: item.image,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Đen,Size L',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  formatCurrency(item.totalPrice),
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 20,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'x${item.quantity}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE6E6E6)),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 16,
                          color: Color(0xFFBDBDBD),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Bảo hiểm hàng giá trị cao và có bảo hành nếu có sự cố.',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Color(0xFFBDBDBD)),
                      ],
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

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.title,
    required this.value,
    required this.onTap,
  });

  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Text(title, style: const TextStyle(fontSize: 14)),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, size: 18, color: Color(0xFFBDBDBD)),
          ],
        ),
      ),
    );
  }
}

class _ShippingMethodSection extends StatelessWidget {
  const _ShippingMethodSection({
    required this.shippingFee,
    required this.shippingDiscount,
  });

  final int shippingFee;
  final int shippingDiscount;

  @override
  Widget build(BuildContext context) {
    final finalFee = (shippingFee - shippingDiscount).clamp(0, shippingFee);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Phương thức vận chuyển',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                'Xem tất cả',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE0E0E0)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nhanh',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Nhận từ 15 Th03 - 18 Th03',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  finalFee == 0 ? 'Miễn phí' : formatCurrency(finalFee),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentSection extends StatelessWidget {
  const _PaymentSection({required this.method, required this.onSelect});

  final String method;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Phương thức thanh toán',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                'Xem tất cả',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _PaymentOptionTile(
            title: 'ShoppePay',
            method: 'shoppepay',
            selectedMethod: method,
            onTap: onSelect,
          ),
          _PaymentOptionTile(
            title: 'Thanh toán khi nhận hàng',
            method: 'cod',
            selectedMethod: method,
            onTap: onSelect,
          ),
          _PaymentOptionTile(
            title: 'Chuyển khoản',
            method: 'bank',
            selectedMethod: method,
            onTap: onSelect,
          ),
          _PaymentOptionTile(
            title: 'Thẻ',
            method: 'card',
            selectedMethod: method,
            onTap: onSelect,
          ),
        ],
      ),
    );
  }
}

class _PaymentOptionTile extends StatelessWidget {
  const _PaymentOptionTile({
    required this.title,
    required this.method,
    required this.selectedMethod,
    required this.onTap,
  });

  final String title;
  final String method;
  final String selectedMethod;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final selected = selectedMethod == method;
    return InkWell(
      onTap: () => onTap(method),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.primary : const Color(0xFFBDBDBD),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: selected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VoucherSelectionPage extends StatefulWidget {
  const VoucherSelectionPage({
    required this.repository,
    required this.selectedShippingVoucherId,
    required this.selectedShopVoucherId,
    required this.subtotal,
    required this.shippingFee,
    super.key,
  });

  final ShopRepository repository;
  final String? selectedShippingVoucherId;
  final String? selectedShopVoucherId;
  final int subtotal;
  final int shippingFee;

  @override
  State<VoucherSelectionPage> createState() => _VoucherSelectionPageState();
}

class _VoucherSelectionPageState extends State<VoucherSelectionPage> {
  String? _selectedShippingId;
  String? _selectedShopId;
  late Future<List<ShopVoucher>> _vouchersFuture;

  @override
  void initState() {
    super.initState();
    _selectedShippingId = widget.selectedShippingVoucherId;
    _selectedShopId = widget.selectedShopVoucherId;
    _vouchersFuture = widget.repository.getVouchers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chọn Shoppe Voucher')),
      body: FutureBuilder<List<ShopVoucher>>(
        future: _vouchersFuture,
        builder: (context, snapshot) {
          final all = snapshot.data ?? const <ShopVoucher>[];
          final active = all.where(_isUsableVoucher).toList();
          final shipping = active
              .where((v) => v.type.trim().toLowerCase() == 'shipping')
              .toList();
          final shop = active
              .where((v) => v.type.trim().toLowerCase() != 'shipping')
              .toList();
          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Chọn trực tiếp voucher bên dưới để áp dụng',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (snapshot.hasError)
                Expanded(
                  child: Center(
                    child: Text('Lỗi tải voucher: ${snapshot.error}'),
                  ),
                )
              else
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    children: [
                      const Text(
                        'Ưu đãi phí vận chuyển',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (shipping.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: Text(
                            'Hiện chưa có voucher vận chuyển',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ...shipping.map((v) => _buildVoucherCard(v, true)),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      const Text(
                        'Mã giảm giá/hoàn xu',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (shop.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: Text(
                            'Hiện chưa có voucher shop',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ...shop.map((v) => _buildVoucherCard(v, false)),
                      const SizedBox(height: 10),
                      Text(
                        '$_selectedCount voucher đã được chọn tự động',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE6E6E6))),
                ),
                child: ElevatedButton(
                  onPressed: () => _onConfirm(active),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text('OK'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  int get _selectedCount {
    var count = 0;
    if (_selectedShippingId != null) count++;
    if (_selectedShopId != null) count++;
    return count;
  }

  Widget _buildVoucherCard(ShopVoucher voucher, bool isShipping) {
    final selected = isShipping
        ? _selectedShippingId == voucher.id
        : _selectedShopId == voucher.id;
    final discountAmount = _calculateDiscount(voucher, isShipping: isShipping);
    final discountLabel = discountAmount > 0
        ? 'Giảm ${formatCurrency(discountAmount)}'
        : 'Chưa đủ điều kiện';
    return GestureDetector(
      onTap: () => _toggleVoucher(voucher, isShipping),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          children: [
            Container(
              width: 84,
              height: 92,
              decoration: BoxDecoration(
                color: isShipping ? const Color(0xFF00C853) : AppColors.primary,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(8),
                ),
              ),
              child: Center(
                child: Text(
                  isShipping ? 'FREE SHIP' : 'shoppe',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Số lượng có hạn',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      discountLabel,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Đơn tối thiểu ${formatCurrency(voucher.minOrder)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          'Mã: ${voucher.code.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          selected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          size: 16,
                          color: selected
                              ? AppColors.primary
                              : const Color(0xFFBDBDBD),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleVoucher(ShopVoucher voucher, bool isShipping) {
    final discount = _calculateDiscount(voucher, isShipping: isShipping);
    if (discount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voucher chưa đủ điều kiện áp dụng')),
      );
      return;
    }
    setState(() {
      if (isShipping) {
        _selectedShippingId = _selectedShippingId == voucher.id
            ? null
            : voucher.id;
      } else {
        _selectedShopId = _selectedShopId == voucher.id ? null : voucher.id;
      }
    });
  }

  void _onConfirm(List<ShopVoucher> activeVouchers) {
    final shippingVoucher = _findVoucher(activeVouchers, _selectedShippingId);
    final shopVoucher = _findVoucher(activeVouchers, _selectedShopId);
    Navigator.of(context).pop(
      _VoucherSelectionResult(
        shippingVoucher: shippingVoucher,
        shopVoucher: shopVoucher,
      ),
    );
  }

  ShopVoucher? _findVoucher(List<ShopVoucher> vouchers, String? id) {
    if (id == null) return null;
    for (final voucher in vouchers) {
      if (voucher.id == id) return voucher;
    }
    return null;
  }

  bool _isUsableVoucher(ShopVoucher voucher) {
    if (voucher.status.trim().toLowerCase() != 'active') return false;
    if (voucher.quantity > 0 && voucher.usedCount >= voucher.quantity) {
      return false;
    }
    final now = DateTime.now();
    final start = _parseDateTime(voucher.startTime);
    final end = _parseDateTime(voucher.endTime);
    if (start != null && now.isBefore(start)) return false;
    if (end != null && now.isAfter(end)) return false;
    return true;
  }

  int _calculateDiscount(ShopVoucher voucher, {required bool isShipping}) {
    final base = isShipping ? widget.shippingFee : widget.subtotal;
    if (base <= 0) return 0;
    if (voucher.minOrder > 0 && widget.subtotal < voucher.minOrder) return 0;
    var discount = 0;
    if (voucher.discountType.trim().toLowerCase() == 'percent') {
      discount = (base * voucher.discountValue / 100).round();
    } else {
      discount = voucher.discountValue;
    }
    if (voucher.maxDiscount > 0 && discount > voucher.maxDiscount) {
      discount = voucher.maxDiscount;
    }
    if (discount > base) return base;
    return discount < 0 ? 0 : discount;
  }

  DateTime? _parseDateTime(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw.replaceFirst(' ', 'T'));
  }
}

class _VoucherSelectionResult {
  const _VoucherSelectionResult({
    required this.shippingVoucher,
    required this.shopVoucher,
  });

  final ShopVoucher? shippingVoucher;
  final ShopVoucher? shopVoucher;
}
