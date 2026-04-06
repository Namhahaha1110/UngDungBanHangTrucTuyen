import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../models/shop_models.dart';
import '../../../services/shop_repository.dart';
import '../../../widgets/smart_shop_image.dart';
import '../widgets/admin_loading_states.dart';

class AdminCategoriesPage extends StatefulWidget {
  const AdminCategoriesPage({
    required this.repository,
    required this.userId,
    super.key,
  });

  final ShopRepository repository;
  final String userId;

  @override
  State<AdminCategoriesPage> createState() => _AdminCategoriesPageState();
}

class _AdminCategoriesPageState extends State<AdminCategoriesPage> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with sorting
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Danh mục sản phẩm',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFfff2e8),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFffd2b1)),
                    ),
                    child: const Text(
                      'Sắp xếp',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFea580c),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Category list
              FutureBuilder<List<ShopCategory>>(
                future: widget.repository.getCategories(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const AdminLoadingState();
                  }

                  if (snapshot.hasError) {
                    return AdminErrorState(error: snapshot.error.toString());
                  }

                  var categories = snapshot.data ?? [];
                  if (categories.isEmpty) {
                    return const AdminEmptyState(title: 'Không có danh mục');
                  }

                  return Column(
                    children: List.generate(categories.length, (idx) {
                      final cat = categories[idx];
                      return _CategoryListRow(
                        category: cat,
                        onEdit: () => _showEditDialog(cat),
                        onDelete: () => _showDeleteDialog(cat),
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
      builder: (_) => _CategoryFormDialog(
        repository: widget.repository,
        onSave: () => setState(() {}),
      ),
    );
  }

  void _showEditDialog(ShopCategory category) {
    showDialog(
      context: context,
      builder: (_) => _CategoryFormDialog(
        repository: widget.repository,
        category: category,
        onSave: () => setState(() {}),
      ),
    );
  }

  void _showDeleteDialog(ShopCategory category) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa danh mục?'),
        content: Text('Xóa "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              await widget.repository.deleteCategory(category.id);
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

class _CategoryListRow extends StatelessWidget {
  const _CategoryListRow({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  final ShopCategory category;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category.description,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF7a7a7a),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
          const SizedBox(height: 8),
          // Product count info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sản phẩm trong danh mục',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFeafaf0),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    '4',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF12824a),
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

class _CategoryFormDialog extends StatefulWidget {
  const _CategoryFormDialog({
    required this.repository,
    this.category,
    required this.onSave,
  });

  final ShopRepository repository;
  final ShopCategory? category;
  final VoidCallback onSave;

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _imageCtrl;
  Uint8List? _pickedImageBytes;
  String? _pickedImageName;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.category?.name ?? '');
    _descCtrl = TextEditingController(text: widget.category?.description ?? '');
    _imageCtrl = TextEditingController(text: widget.category?.image ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _imageCtrl.dispose();
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
                  widget.category == null ? 'Thêm danh mục' : 'Sửa danh mục',
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
                  _FormField(label: 'Tên danh mục', controller: _nameCtrl),
                  _FormField(
                    label: 'Mô tả',
                    controller: _descCtrl,
                    maxLines: 2,
                  ),
                  _FormField(label: 'Image key / URL', controller: _imageCtrl),
                  _ImagePickerBlock(
                    source: _imageCtrl.text.trim(),
                    memoryBytes: _pickedImageBytes,
                    onPick: _pickImage,
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
                    onTap: _saving ? null : _save,
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

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final picked = result?.files.single;
    if (picked == null || picked.bytes == null) return;
    setState(() {
      _pickedImageBytes = picked.bytes;
      _pickedImageName = picked.name;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      var imageRef = _imageCtrl.text.trim();
      if (_pickedImageBytes != null) {
        imageRef = await widget.repository.uploadAdminImage(
          bytes: _pickedImageBytes!,
          folder: 'categories',
          fileName: _pickedImageName ?? 'category.jpg',
        );
      }
      if (imageRef.isEmpty) {
        imageRef = widget.category?.image ?? 'default.jpg';
      }

      final category = ShopCategory(
        id:
            widget.category?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        image: imageRef,
      );

      if (widget.category == null) {
        await widget.repository.addCategory(category);
      } else {
        await widget.repository.updateCategory(category);
      }

      if (!mounted) return;
      Navigator.pop(context);
      widget.onSave();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lưu thất bại: $e')));
      setState(() => _saving = false);
    }
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.controller,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
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
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF171717),
            ),
          ),
        ),
        TextField(
          controller: controller,
          maxLines: maxLines,
          minLines: maxLines > 1 ? maxLines : null,
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
        const SizedBox(height: 12),
      ],
    );
  }
}

class _ImagePickerBlock extends StatelessWidget {
  const _ImagePickerBlock({
    required this.source,
    required this.memoryBytes,
    required this.onPick,
  });

  final String source;
  final Uint8List? memoryBytes;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 6),
          child: Text(
            'Ảnh xem trước',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF171717),
            ),
          ),
        ),
        Row(
          children: [
            Container(
              width: 64,
              height: 64,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFDDDDDD)),
              ),
              child: SmartShopImage(
                source: source,
                memoryBytes: memoryBytes,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.upload_file_rounded, size: 18),
                label: const Text('Chọn ảnh từ máy'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
