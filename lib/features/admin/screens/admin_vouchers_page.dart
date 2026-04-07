import 'package:flutter/material.dart';

import '../../../models/shop_models.dart';
import '../../../services/shop_repository.dart';
import '../widgets/admin_loading_states.dart';

class AdminVouchersPage extends StatefulWidget {
  const AdminVouchersPage({
    required this.repository,
    required this.userId,
    super.key,
  });

  final ShopRepository repository;
  final String userId;

  @override
  State<AdminVouchersPage> createState() => _AdminVouchersPageState();
}

class _AdminVouchersPageState extends State<AdminVouchersPage> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: FutureBuilder<List<ShopVoucher>>(
            future: widget.repository.getVouchers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AdminLoadingState();
              }
              if (snapshot.hasError) {
                return AdminErrorState(error: snapshot.error.toString());
              }
              final vouchers = snapshot.data ?? const <ShopVoucher>[];
              if (vouchers.isEmpty) {
                return const AdminEmptyState(title: 'Không có voucher');
              }
              return Column(
                children: vouchers
                    .map(
                      (voucher) => _VoucherListRow(
                        voucher: voucher,
                        onEdit: () => _showEditDialog(voucher),
                        onDelete: () => _showDeleteDialog(voucher),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ),
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
      builder: (_) => _VoucherFormDialog(
        repository: widget.repository,
        onSave: () => setState(() {}),
      ),
    );
  }

  void _showEditDialog(ShopVoucher voucher) {
    showDialog(
      context: context,
      builder: (_) => _VoucherFormDialog(
        repository: widget.repository,
        voucher: voucher,
        onSave: () => setState(() {}),
      ),
    );
  }

  void _showDeleteDialog(ShopVoucher voucher) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa voucher?'),
        content: Text('Xóa voucher "${voucher.code}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              await widget.repository.deleteVoucher(voucher.id);
              if (mounted) {
                Navigator.of(context).pop();
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

class _VoucherListRow extends StatelessWidget {
  const _VoucherListRow({
    required this.voucher,
    required this.onEdit,
    required this.onDelete,
  });

  final ShopVoucher voucher;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final active = voucher.status.trim().toLowerCase() == 'active';
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${voucher.code} • ${voucher.displayTitle}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xFFeafaf0)
                            : const Color(0xFFfff1f1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        active ? 'active' : 'inactive',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: active
                              ? const Color(0xFF12824a)
                              : const Color(0xFFd12626),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${voucher.type} • ${voucher.discountType} ${voucher.discountValue}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF7a7a7a),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Min ${voucher.minOrder} | Max ${voucher.maxDiscount} | SL ${voucher.quantity}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF7a7a7a),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${voucher.startTime} -> ${voucher.endTime}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF999999),
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

class _VoucherFormDialog extends StatefulWidget {
  const _VoucherFormDialog({
    required this.repository,
    required this.onSave,
    this.voucher,
  });

  final ShopRepository repository;
  final VoidCallback onSave;
  final ShopVoucher? voucher;

  @override
  State<_VoucherFormDialog> createState() => _VoucherFormDialogState();
}

class _VoucherFormDialogState extends State<_VoucherFormDialog> {
  late TextEditingController _codeCtrl;
  late TextEditingController _titleCtrl;
  late TextEditingController _discountValueCtrl;
  late TextEditingController _maxDiscountCtrl;
  late TextEditingController _minOrderCtrl;
  late TextEditingController _quantityCtrl;
  late TextEditingController _startCtrl;
  late TextEditingController _endCtrl;
  late TextEditingController _descriptionCtrl;

  String _type = 'shop';
  String _discountType = 'fixed';
  String _status = 'active';

  @override
  void initState() {
    super.initState();
    final v = widget.voucher;
    _codeCtrl = TextEditingController(text: v?.code ?? '');
    _titleCtrl = TextEditingController(text: v?.displayTitle ?? '');
    _discountValueCtrl = TextEditingController(
      text: (v?.discountValue ?? 0).toString(),
    );
    _maxDiscountCtrl = TextEditingController(
      text: (v?.maxDiscount ?? 0).toString(),
    );
    _minOrderCtrl = TextEditingController(text: (v?.minOrder ?? 0).toString());
    _quantityCtrl = TextEditingController(text: (v?.quantity ?? 0).toString());
    _startCtrl = TextEditingController(text: v?.startTime ?? '');
    _endCtrl = TextEditingController(text: v?.endTime ?? '');
    _descriptionCtrl = TextEditingController(text: v?.displayDescription ?? '');
    _type = v?.type ?? 'shop';
    _discountType = v?.discountType ?? 'fixed';
    _status = v?.status ?? 'active';
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _titleCtrl.dispose();
    _discountValueCtrl.dispose();
    _maxDiscountCtrl.dispose();
    _minOrderCtrl.dispose();
    _quantityCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    _descriptionCtrl.dispose();
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
                  widget.voucher == null ? 'Thêm voucher' : 'Sửa voucher',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
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
                children: [
                  _Field(label: 'Mã voucher', controller: _codeCtrl),
                  _Field(label: 'Tiêu đề', controller: _titleCtrl),
                  Row(
                    children: [
                      Expanded(
                        child: _DropdownField(
                          label: 'Loại',
                          value: _type,
                          items: const ['shop', 'shipping'],
                          onChanged: (v) => setState(() => _type = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _DropdownField(
                          label: 'Kiểu giảm',
                          value: _discountType,
                          items: const ['fixed', 'percent'],
                          onChanged: (v) => setState(() => _discountType = v),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _Field(
                          label: 'Giá trị giảm',
                          controller: _discountValueCtrl,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _Field(
                          label: 'Giảm tối đa',
                          controller: _maxDiscountCtrl,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _Field(
                          label: 'Đơn tối thiểu',
                          controller: _minOrderCtrl,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _Field(
                          label: 'Số lượng',
                          controller: _quantityCtrl,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  _DateTimeField(
                    label: 'Bắt đầu',
                    controller: _startCtrl,
                    onPick: () => _pickDateTime(_startCtrl),
                  ),
                  _DateTimeField(
                    label: 'Kết thúc',
                    controller: _endCtrl,
                    onPick: () => _pickDateTime(_endCtrl),
                  ),
                  _DropdownField(
                    label: 'Trạng thái',
                    value: _status,
                    items: const ['active', 'inactive'],
                    onChanged: (v) => setState(() => _status = v),
                  ),
                  _Field(
                    label: 'Mô tả',
                    controller: _descriptionCtrl,
                    maxLines: 3,
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
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Hủy'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    child: const Text('Lưu'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final code = _codeCtrl.text.trim();
    final title = _titleCtrl.text.trim();
    final discountValue = int.tryParse(_discountValueCtrl.text.trim()) ?? 0;
    final maxDiscount = int.tryParse(_maxDiscountCtrl.text.trim()) ?? 0;
    final minOrder = int.tryParse(_minOrderCtrl.text.trim()) ?? 0;
    final quantity = int.tryParse(_quantityCtrl.text.trim()) ?? 0;
    final start = _parseDateTime(_startCtrl.text.trim());
    final end = _parseDateTime(_endCtrl.text.trim());

    if (code.isEmpty || title.isEmpty) {
      _showError('Nhập mã và tiêu đề voucher');
      return;
    }
    if (discountValue <= 0) {
      _showError('Giá trị giảm phải > 0');
      return;
    }
    if (start == null || end == null || !end.isAfter(start)) {
      _showError('Thời gian voucher không hợp lệ');
      return;
    }

    final voucher = ShopVoucher(
      id: widget.voucher?.id ?? 'v_${DateTime.now().millisecondsSinceEpoch}',
      code: code.toUpperCase(),
      title: title,
      type: _type,
      discountType: _discountType,
      discountValue: discountValue,
      maxDiscount: maxDiscount,
      minOrder: minOrder,
      startTime: _formatDateTime(start),
      endTime: _formatDateTime(end),
      status: _status,
      quantity: quantity,
      usedCount: widget.voucher?.usedCount ?? 0,
      description: _descriptionCtrl.text.trim(),
    );

    if (widget.voucher == null) {
      await widget.repository.addVoucher(voucher);
    } else {
      await widget.repository.updateVoucher(voucher);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    widget.onSave();
  }

  Future<void> _pickDateTime(TextEditingController controller) async {
    final initial = _parseDateTime(controller.text.trim()) ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;
    final dt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() => controller.text = _formatDateTime(dt));
  }

  DateTime? _parseDateTime(String raw) {
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw.replaceFirst(' ', 'T'));
  }

  String _formatDateTime(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
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
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
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
        const SizedBox(height: 10),
      ],
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          items: items
              .map(
                (item) =>
                    DropdownMenuItem<String>(value: item, child: Text(item)),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
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
        const SizedBox(height: 10),
      ],
    );
  }
}

class _DateTimeField extends StatelessWidget {
  const _DateTimeField({
    required this.label,
    required this.controller,
    required this.onPick,
  });

  final String label;
  final TextEditingController controller;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        TextField(
          controller: controller,
          readOnly: true,
          onTap: onPick,
          decoration: InputDecoration(
            hintText: 'Chọn ngày giờ',
            suffixIcon: IconButton(
              onPressed: onPick,
              icon: const Icon(Icons.calendar_month_outlined),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
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
        const SizedBox(height: 10),
      ],
    );
  }
}
