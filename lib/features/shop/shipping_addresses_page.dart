import 'package:flutter/material.dart';

import '../../models/shop_models.dart';
import '../../services/shop_repository.dart';
import '../../theme/app_theme.dart';

class ShippingAddressesPage extends StatelessWidget {
  const ShippingAddressesPage({
    required this.repository,
    required this.userId,
    this.selectMode = false,
    super.key,
  });

  final ShopRepository repository;
  final String userId;
  final bool selectMode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(selectMode ? 'Chọn địa chỉ giao hàng' : 'Vận chuyển'),
      ),
      body: StreamBuilder<List<ShippingAddress>>(
        stream: repository.shippingAddresses(userId),
        builder: (context, snapshot) {
          final addresses = snapshot.data ?? const <ShippingAddress>[];
          if (addresses.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.location_off_outlined,
                      size: 52,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Bạn chưa có địa chỉ giao hàng',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () => _openAddressForm(context),
                      child: const Text('Thêm địa chỉ'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: addresses.length,
            itemBuilder: (context, index) {
              final address = addresses[index];
              return _AddressCard(
                address: address,
                onTap: selectMode
                    ? () => Navigator.of(context).pop(address)
                    : null,
                onSetDefault: address.isDefault
                    ? null
                    : () => repository.setDefaultShippingAddress(
                          userId: userId,
                          addressId: address.id,
                        ),
                onEdit: () => _openAddressForm(context, initial: address),
                onDelete: () => _deleteAddress(context, address),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddressForm(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _deleteAddress(BuildContext context, ShippingAddress address) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa địa chỉ?'),
        content: Text('Xóa địa chỉ "${address.addressLine}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await repository.deleteShippingAddress(userId: userId, addressId: address.id);
  }

  Future<void> _openAddressForm(
    BuildContext context, {
    ShippingAddress? initial,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddressFormSheet(
        repository: repository,
        userId: userId,
        initial: initial,
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.onEdit,
    required this.onDelete,
    this.onSetDefault,
    this.onTap,
  });

  final ShippingAddress address;
  final VoidCallback? onSetDefault;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFECECEC)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${address.recipientName} • ${address.phone}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
                if (address.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFfff2e8),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Mặc định',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              address.addressLine,
              style: const TextStyle(fontSize: 12, color: Color(0xFF505050)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (!address.isDefault)
                  TextButton(
                    onPressed: onSetDefault,
                    child: const Text('Đặt mặc định'),
                  ),
                const Spacer(),
                TextButton(onPressed: onEdit, child: const Text('Sửa')),
                TextButton(
                  onPressed: onDelete,
                  child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressFormSheet extends StatefulWidget {
  const _AddressFormSheet({
    required this.repository,
    required this.userId,
    this.initial,
  });

  final ShopRepository repository;
  final String userId;
  final ShippingAddress? initial;

  @override
  State<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<_AddressFormSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late bool _isDefault;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initial?.recipientName ?? '');
    _phoneCtrl = TextEditingController(text: widget.initial?.phone ?? '');
    _addressCtrl = TextEditingController(text: widget.initial?.addressLine ?? '');
    _isDefault = widget.initial?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isEdit ? 'Sửa địa chỉ' : 'Thêm địa chỉ',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _Field(controller: _nameCtrl, hint: 'Tên người nhận'),
          const SizedBox(height: 10),
          _Field(
            controller: _phoneCtrl,
            hint: 'Số điện thoại',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 10),
          _Field(
            controller: _addressCtrl,
            hint: 'Địa chỉ chi tiết',
            maxLines: 3,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Checkbox(
                value: _isDefault,
                onChanged: (v) => setState(() => _isDefault = v ?? false),
              ),
              const Text('Đặt làm mặc định'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Đang lưu...' : 'Lưu'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final address = _addressCtrl.text.trim();
    if (name.isEmpty || phone.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đủ tên, điện thoại, địa chỉ')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.repository.saveShippingAddress(
        userId: widget.userId,
        address: ShippingAddress(
          id: widget.initial?.id ?? '',
          recipientName: name,
          phone: phone,
          addressLine: address,
          isDefault: _isDefault,
        ),
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không lưu được địa chỉ: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
