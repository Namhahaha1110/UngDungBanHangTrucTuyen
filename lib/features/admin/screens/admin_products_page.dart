import 'package:flutter/material.dart';

import '../../../models/shop_models.dart';
import '../../../services/shop_repository.dart';

class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({
    required this.repository,
    required this.userId,
    super.key,
  });

  final ShopRepository repository;
  final String userId;

  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  String _searchQuery = '';
  String _selectedFilter = 'Tất cả';

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
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
                    hintText: 'Tìm sản phẩm theo tên',
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

              // Filter pills
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
                      label: 'Đang bán',
                      isSelected: _selectedFilter == 'Đang bán',
                      onTap: () => setState(() => _selectedFilter = 'Đang bán'),
                    ),
                    const SizedBox(width: 8),
                    _FilterPill(
                      label: 'Hết hàng',
                      isSelected: _selectedFilter == 'Hết hàng',
                      onTap: () => setState(() => _selectedFilter = 'Hết hàng'),
                    ),
                    const SizedBox(width: 8),
                    _FilterPill(
                      label: 'Chỉnh sửa',
                      isSelected: _selectedFilter == 'Chỉnh sửa',
                      onTap: () => setState(() => _selectedFilter = 'Chỉnh sửa'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Product list
              FutureBuilder<List<ShopProduct>>(
                future: widget.repository.getProducts(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var products = snapshot.data ?? [];
                  if (_searchQuery.isNotEmpty) {
                    products = products
                        .where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
                        .toList();
                  }

                  return Column(
                    children: List.generate(products.length, (idx) {
                      final product = products[idx];
                      return _ProductListRow(
                        product: product,
                        onEdit: () => _showEditDialog(product),
                        onDelete: () => _showDeleteDialog(product),
                      );
                    }),
                  );
                },
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),

        // FAB
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: _showAddDialog,
            backgroundColor: const Color(0xFFea580c),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => _ProductFormDialog(
        repository: widget.repository,
        onSave: () => setState(() {}),
      ),
    );
  }

  void _showEditDialog(ShopProduct product) {
    showDialog(
      context: context,
      builder: (_) => _ProductFormDialog(
        repository: widget.repository,
        product: product,
        onSave: () => setState(() {}),
      ),
    );
  }

  void _showDeleteDialog(ShopProduct product) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa sản phẩm?'),
        content: Text('Xóa "${product.name}"?'),
        actions: [
          TextButton(onPressed: Navigator.of(context).pop, child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              await widget.repository.deleteProduct(product.id);
              if (mounted) {
                Navigator.pop(context);
                setState(() {});
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
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
            color: isSelected ? const Color(0xFFffd2b1) : const Color(0xFFECECEC),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? const Color(0xFFea580c) : const Color(0xFF7a7a7a),
          ),
        ),
      ),
    );
  }
}

class _ProductListRow extends StatelessWidget {
  const _ProductListRow({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  final ShopProduct product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

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
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.image, size: 24, color: Color(0xFFCCCCCC)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${product.price}₫',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFea580c),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              _TinyButton(
                label: 'Sửa',
                color: const Color(0xFFeff5ff),
                textColor: const Color(0xFF2563eb),
                onTap: onEdit,
              ),
              const SizedBox(height: 4),
              _TinyButton(
                label: 'Xóa',
                color: const Color(0xFFfff1f1),
                textColor: const Color(0xFFd12626),
                onTap: onDelete,
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

class _ProductFormDialog extends StatefulWidget {
  const _ProductFormDialog({
    required this.repository,
    this.product,
    required this.onSave,
  });

  final ShopRepository repository;
  final ShopProduct? product;
  final VoidCallback onSave;

  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _oldPriceCtrl;
  late TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.product?.name ?? '');
    _priceCtrl = TextEditingController(text: widget.product?.price.toString() ?? '');
    _oldPriceCtrl = TextEditingController(text: widget.product?.oldPrice.toString() ?? '');
    _descCtrl = TextEditingController(text: widget.product?.description ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _oldPriceCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product == null ? 'Thêm sản phẩm' : 'Sửa sản phẩm'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FormField(label: 'Tên', controller: _nameCtrl),
            const SizedBox(height: 12),
            _FormField(label: 'Giá', controller: _priceCtrl, keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            _FormField(label: 'Giá cũ', controller: _oldPriceCtrl, keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            _FormField(label: 'Mô tả', controller: _descCtrl, maxLines: 3),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: Navigator.of(context).pop, child: const Text('Hủy')),
        TextButton(
          onPressed: () async {
            final product = ShopProduct(
              id: widget.product?.id ?? DateTime.now().toString(),
              name: _nameCtrl.text,
              price: int.tryParse(_priceCtrl.text) ?? 0,
              oldPrice: int.tryParse(_oldPriceCtrl.text) ?? 0,
              description: _descCtrl.text,
              image: widget.product?.image ?? 'default.jpg',
              soldText: widget.product?.soldText ?? '',
              categoryId: widget.product?.categoryId ?? 'uncategorized',
              imageKey: widget.product?.imageKey ?? 'default.jpg',
            );

            if (widget.product == null) {
              await widget.repository.addProduct(product);
            } else {
              await widget.repository.updateProduct(product);
            }

            if (context.mounted) {
              Navigator.pop(context);
              widget.onSave();
            }
          },
          child: const Text('Lưu', style: TextStyle(color: Color(0xFFea580c))),
        ),
      ],
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            isDense: true,
          ),
        ),
      ],
    );
  }
}
