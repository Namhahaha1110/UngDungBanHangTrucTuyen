import 'package:flutter/material.dart';

import '../../../models/shop_models.dart';
import '../../../services/shop_repository.dart';
import '../widgets/admin_loading_states.dart';

class AdminSalesPage extends StatefulWidget {
  const AdminSalesPage({
    required this.repository,
    required this.userId,
    super.key,
  });

  final ShopRepository repository;
  final String userId;

  @override
  State<AdminSalesPage> createState() => _AdminSalesPageState();
}

class _AdminSalesPageState extends State<AdminSalesPage> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary row
              Row(
                children: [
                  Expanded(
                    child: _SummaryChip(
                      label: 'đang chạy',
                      value: '6',
                      bgColor: const Color(0xFFeafaf0),
                      textColor: const Color(0xFF12824a),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SummaryChip(
                      label: 'mức off cao nhất',
                      value: '40%',
                      bgColor: const Color(0xFFfff1f1),
                      textColor: const Color(0xFFd12626),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SummaryChip(
                      label: 'đóng lúc',
                      value: '18:00',
                      bgColor: const Color(0xFFfff2e8),
                      textColor: const Color(0xFFea580c),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Flash sale list
              FutureBuilder<List<ShopFlashSale>>(
                future: widget.repository.getFlashSales(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const AdminLoadingState();
                  }

                  if (snapshot.hasError) {
                    return AdminErrorState(error: snapshot.error.toString());
                  }

                  var sales = snapshot.data ?? [];
                  if (sales.isEmpty) {
                    return const AdminEmptyState(title: 'Không có flash sale');
                  }

                  return Column(
                    children: List.generate(sales.length, (idx) {
                      final sale = sales[idx];
                      return _FlashSaleListRow(
                        sale: sale,
                        onEdit: () => _showEditDialog(sale),
                        onDelete: () => _showDeleteDialog(sale),
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
          bottom: 76,
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
      builder: (_) => _FlashSaleFormDialog(
        repository: widget.repository,
        onSave: () => setState(() {}),
      ),
    );
  }

  void _showEditDialog(ShopFlashSale sale) {
    showDialog(
      context: context,
      builder: (_) => _FlashSaleFormDialog(
        repository: widget.repository,
        sale: sale,
        onSave: () => setState(() {}),
      ),
    );
  }

  void _showDeleteDialog(ShopFlashSale sale) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa flash sale?'),
        content: Text('Xóa sale cho sản phẩm "${sale.productId}"?'),
        actions: [
          TextButton(onPressed: Navigator.of(context).pop, child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              await widget.repository.deleteFlashSale(sale.id);
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

class _FlashSaleListRow extends StatelessWidget {
  const _FlashSaleListRow({
    required this.sale,
    required this.onEdit,
    required this.onDelete,
  });

  final ShopFlashSale sale;
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sản phẩm: ${sale.productId}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFfff2e8),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${sale.discountPercent}% off',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFea580c),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Kết thúc: ${sale.endTime}',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF7a7a7a)),
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

class _FlashSaleFormDialog extends StatefulWidget {
  const _FlashSaleFormDialog({
    required this.repository,
    this.sale,
    required this.onSave,
  });

  final ShopRepository repository;
  final ShopFlashSale? sale;
  final VoidCallback onSave;

  @override
  State<_FlashSaleFormDialog> createState() => _FlashSaleFormDialogState();
}

class _FlashSaleFormDialogState extends State<_FlashSaleFormDialog> {
  late TextEditingController _productIdCtrl;
  late TextEditingController _discountCtrl;
  late TextEditingController _startTimeCtrl;
  late TextEditingController _endTimeCtrl;
  late String _status;

  @override
  void initState() {
    super.initState();
    _productIdCtrl = TextEditingController(text: widget.sale?.productId ?? '');
    _discountCtrl = TextEditingController(text: widget.sale?.discountPercent.toString() ?? '');
    _startTimeCtrl = TextEditingController(text: widget.sale?.startTime ?? '');
    _endTimeCtrl = TextEditingController(text: widget.sale?.endTime ?? '');
    _status = widget.sale?.status ?? 'active';
  }

  @override
  void dispose() {
    _productIdCtrl.dispose();
    _discountCtrl.dispose();
    _startTimeCtrl.dispose();
    _endTimeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFECECEC))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.sale == null ? 'Thêm flash sale' : 'Sửa flash sale',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF171717),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    '✕',
                    style: TextStyle(fontSize: 20, color: Color(0xFF999999)),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _FormField(label: 'Sản phẩm ID', controller: _productIdCtrl),
                  _FormField(
                    label: 'Giảm giá (%)',
                    controller: _discountCtrl,
                    keyboardType: TextInputType.number,
                  ),
                  _FormField(label: 'Thời gian bắt đầu', controller: _startTimeCtrl),
                  _FormField(label: 'Thời gian kết thúc', controller: _endTimeCtrl),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(bottom: 6),
                        child: Text(
                          'Trạng thái',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF171717),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _status = 'inactive'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: _status == 'inactive'
                                      ? const Color(0xFFea580c)
                                      : Colors.white,
                                  border: Border.all(
                                    color: _status == 'inactive'
                                        ? const Color(0xFFea580c)
                                        : const Color(0xFFDDDDDD),
                                  ),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(4),
                                    bottomLeft: Radius.circular(4),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'Inactive',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _status == 'inactive'
                                          ? Colors.white
                                          : const Color(0xFF999999),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _status = 'active'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: _status == 'active'
                                      ? const Color(0xFFea580c)
                                      : Colors.white,
                                  border: Border.all(
                                    color: _status == 'active'
                                        ? const Color(0xFFea580c)
                                        : const Color(0xFFDDDDDD),
                                  ),
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(4),
                                    bottomRight: Radius.circular(4),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'Active',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _status == 'active'
                                          ? Colors.white
                                          : const Color(0xFF999999),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFECECEC))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFDDDDDD)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Center(
                        child: Text(
                          'Huỷ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF171717),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final sale = ShopFlashSale(
                        id: widget.sale?.id ?? DateTime.now().toString(),
                        productId: _productIdCtrl.text,
                        discountPercent: int.tryParse(_discountCtrl.text) ?? 0,
                        startTime: _startTimeCtrl.text,
                        endTime: _endTimeCtrl.text,
                        status: _status,
                      );

                      if (widget.sale == null) {
                        await widget.repository.addFlashSale(sale);
                      } else {
                        await widget.repository.updateFlashSale(sale);
                      }

                      if (context.mounted) {
                        Navigator.pop(context);
                        widget.onSave();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFea580c),
                        border: Border.all(color: const Color(0xFFea580c)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Center(
                        child: Text(
                          'Lưu',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
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

class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF171717),
            ),
          ),
        ),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: 1,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFFea580c), width: 2),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
