import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../models/shop_models.dart';
import '../../../services/shop_repository.dart';
import '../../../widgets/smart_shop_image.dart';
import '../widgets/admin_loading_states.dart';

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
              Container(
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFECECEC)),
                ),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: const InputDecoration(
                    hintText: 'Tìm theo id / tên / category',
                    hintStyle: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF7a7a7a),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    suffixIcon: Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(
                        Icons.search,
                        size: 18,
                        color: Color(0xFF7a7a7a),
                      ),
                    ),
                  ),
                ),
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
                      label: 'Có giảm giá',
                      isSelected: _selectedFilter == 'Có giảm giá',
                      onTap: () =>
                          setState(() => _selectedFilter = 'Có giảm giá'),
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
                  ],
                ),
              ),
              const SizedBox(height: 10),
              FutureBuilder<List<ShopProduct>>(
                future: widget.repository.getProducts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const AdminLoadingState();
                  }
                  if (snapshot.hasError) {
                    return AdminErrorState(error: snapshot.error.toString());
                  }

                  var products = _applyFilters(
                    snapshot.data ?? const <ShopProduct>[],
                  );
                  if (products.isEmpty) {
                    return const AdminEmptyState(title: 'Không có sản phẩm');
                  }

                  return Column(
                    children: products
                        .map(
                          (product) => _ProductListRow(
                            product: product,
                            onEdit: () => _openEdit(product),
                            onDelete: () => _openDelete(product),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 68),
            ],
          ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: _openAdd,
            backgroundColor: const Color(0xFFea580c),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  List<ShopProduct> _applyFilters(List<ShopProduct> products) {
    var filtered = products;
    if (_searchQuery.isNotEmpty) {
      final keyword = _searchQuery.toLowerCase();
      filtered = filtered
          .where(
            (p) =>
                p.id.toLowerCase().contains(keyword) ||
                p.name.toLowerCase().contains(keyword) ||
                p.categoryId.toLowerCase().contains(keyword),
          )
          .toList();
    }

    switch (_selectedFilter) {
      case 'Có giảm giá':
        filtered = filtered.where((p) => p.oldPrice > p.price).toList();
        break;
      case 'Đang bán':
        filtered = filtered.where((p) => p.stock > 0).toList();
        break;
      case 'Hết hàng':
        filtered = filtered.where((p) => p.stock <= 0).toList();
        break;
    }

    return filtered;
  }

  Future<void> _openAdd() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ProductFormPage(repository: widget.repository),
      ),
    );
    if (changed == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _openEdit(ShopProduct product) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ProductFormPage(
          repository: widget.repository,
          initialProduct: product,
        ),
      ),
    );
    if (changed == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _openDelete(ShopProduct product) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            ProductDeletePage(repository: widget.repository, product: product),
      ),
    );
    if (changed == true && mounted) {
      setState(() {});
    }
  }
}

class ProductFormPage extends StatefulWidget {
  const ProductFormPage({
    required this.repository,
    this.initialProduct,
    super.key,
  });

  final ShopRepository repository;
  final ShopProduct? initialProduct;

  bool get isEdit => initialProduct != null;

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  late final TextEditingController _idCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _imageUrlCtrl;
  late final TextEditingController _sizesCtrl;
  late final TextEditingController _colorsCtrl;
  late final TextEditingController _descCtrl;
  List<ShopCategory> _categories = const [];
  String? _selectedCategoryId;
  Uint8List? _pickedImageBytes;
  String? _pickedImageName;
  bool _loadingMeta = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.initialProduct;
    _idCtrl = TextEditingController(text: p?.id ?? '');
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _priceCtrl = TextEditingController(text: p?.price.toString() ?? '');
    _stockCtrl = TextEditingController(text: p?.stock.toString() ?? '0');
    _imageUrlCtrl = TextEditingController(text: p?.image ?? '');
    _sizesCtrl = TextEditingController(text: p?.sizeOptions.join(', ') ?? '');
    _colorsCtrl = TextEditingController(text: p?.colorOptions.join(', ') ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _selectedCategoryId = p?.categoryId;
    _loadMeta();
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _imageUrlCtrl.dispose();
    _sizesCtrl.dispose();
    _colorsCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Sửa sản phẩm' : 'Thêm sản phẩm'),
      ),
      body: _loadingMeta
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _FormCard(
                  title: 'Thông tin cơ bản',
                  children: [
                    _LabeledField(
                      label: 'ID',
                      controller: _idCtrl,
                      enabled: false,
                    ),
                    _LabeledField(label: 'Tên sản phẩm', controller: _nameCtrl),
                    _LabeledField(
                      label: 'Giá bán',
                      controller: _priceCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _FormCard(
                  title: 'Phân loại và hiển thị',
                  children: [
                    _CategoryDropdownField(
                      value: _selectedCategoryId,
                      items: _categories,
                      onChanged: (value) {
                        setState(() => _selectedCategoryId = value);
                      },
                    ),
                    _LabeledField(
                      label: 'URL ảnh',
                      controller: _imageUrlCtrl,
                      onChanged: (_) => setState(() {}),
                    ),
                    _ImagePickerBlock(
                      source: _imageUrlCtrl.text.trim(),
                      memoryBytes: _pickedImageBytes,
                      onPick: _pickImage,
                    ),
                    _LabeledField(
                      label: 'Tồn kho',
                      controller: _stockCtrl,
                      keyboardType: TextInputType.number,
                    ),
                    _LabeledField(
                      label: 'Size (phân tách bằng dấu phẩy)',
                      controller: _sizesCtrl,
                    ),
                    _LabeledField(
                      label: 'Màu sắc (phân tách bằng dấu phẩy)',
                      controller: _colorsCtrl,
                    ),
                    _LabeledField(
                      label: 'Mô tả',
                      controller: _descCtrl,
                      maxLines: 4,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () => Navigator.of(context).pop(false),
                        child: const Text('Hủy'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFea580c),
                        ),
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
    if (name.isEmpty) {
      _snack('Tên sản phẩm không được để trống');
      return;
    }
    final id = _idCtrl.text.trim();
    if (id.isEmpty) {
      _snack('ID không được để trống');
      return;
    }
    if ((_selectedCategoryId ?? '').isEmpty) {
      _snack('Vui lòng chọn danh mục');
      return;
    }
    final stock = int.tryParse(_stockCtrl.text.trim()) ?? 0;
    if (stock < 0) {
      _snack('Tồn kho không hợp lệ');
      return;
    }
    final sizes = _splitCsv(_sizesCtrl.text);
    final colors = _splitCsv(_colorsCtrl.text);
    if (sizes.isEmpty) {
      _snack('Vui lòng nhập ít nhất 1 size');
      return;
    }
    if (colors.isEmpty) {
      _snack('Vui lòng nhập ít nhất 1 màu');
      return;
    }

    setState(() => _saving = true);
    try {
      var imageRef = _imageUrlCtrl.text.trim();
      if (_pickedImageBytes != null) {
        try {
          imageRef = await widget.repository
              .uploadAdminImage(
                bytes: _pickedImageBytes!,
                folder: 'products',
                fileName: _pickedImageName ?? '$id.jpg',
              )
              .timeout(const Duration(seconds: 20));
        } catch (_) {
          imageRef = _imageUrlCtrl.text.trim();
          _snack('Upload ảnh lỗi, hệ thống sẽ lưu với ảnh mặc định.');
        }
      }
      if (imageRef.isEmpty) {
        imageRef = widget.initialProduct?.image ?? 'product_shirt.png';
      }

      final product = ShopProduct(
        id: id,
        name: name,
        price: int.tryParse(_priceCtrl.text.trim()) ?? 0,
        oldPrice: int.tryParse(_priceCtrl.text.trim()) ?? 0,
        stock: stock,
        image: imageRef,
        categoryId: _selectedCategoryId!,
        description: _descCtrl.text.trim(),
        soldText: stock <= 0 ? 'Hết hàng' : 'Còn $stock sản phẩm',
        imageKey: imageRef,
        sizeOptions: sizes,
        colorOptions: colors,
      );

      if (widget.isEdit) {
        await widget.repository
            .updateProduct(product)
            .timeout(const Duration(seconds: 20));
      } else {
        await widget.repository
            .addProduct(product)
            .timeout(const Duration(seconds: 20));
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on TimeoutException {
      _snack('Lưu thất bại: Kết nối tới Firebase quá chậm, thử lại.');
      setState(() => _saving = false);
    } catch (e) {
      _snack('Lưu thất bại: ${_friendlyError(e)}');
      setState(() => _saving = false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _friendlyError(Object error) {
    final text = '$error';
    if (text.contains('permission-denied')) {
      return 'Không có quyền upload ảnh hoặc ghi dữ liệu. Kiểm tra role admin và storage rules.';
    }
    if (text.contains('object-not-found')) {
      return 'Không tìm thấy tệp ảnh đã chọn.';
    }
    return text;
  }

  Future<void> _loadMeta() async {
    try {
      final categories = await widget.repository.getCategories();
      String nextId = _idCtrl.text.trim();
      if (!widget.isEdit) {
        final products = await widget.repository.getProducts();
        nextId = _buildNextProductId(products);
      }
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _selectedCategoryId =
            _selectedCategoryId ??
            (categories.isNotEmpty ? categories.first.id : null);
        if (!widget.isEdit) {
          _idCtrl.text = nextId;
        }
        _loadingMeta = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMeta = false);
    }
  }

  String _buildNextProductId(List<ShopProduct> products) {
    var maxNumber = 0;
    final regex = RegExp(r'(\d+)$');
    for (final product in products) {
      final match = regex.firstMatch(product.id);
      final value = int.tryParse(match?.group(1) ?? '');
      if (value != null && value > maxNumber) {
        maxNumber = value;
      }
    }
    if (maxNumber == 0) {
      return 'p_${DateTime.now().millisecondsSinceEpoch}';
    }
    return 'p_${maxNumber + 1}';
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final picked = result?.files.single;
    if (picked == null || picked.bytes == null) {
      _snack('Chưa chọn được ảnh');
      return;
    }
    setState(() {
      _pickedImageBytes = picked.bytes;
      _pickedImageName = picked.name;
      _imageUrlCtrl.clear();
    });
  }

  List<String> _splitCsv(String raw) {
    return raw
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();
  }
}

class ProductDeletePage extends StatefulWidget {
  const ProductDeletePage({
    required this.repository,
    required this.product,
    super.key,
  });

  final ShopRepository repository;
  final ShopProduct product;

  @override
  State<ProductDeletePage> createState() => _ProductDeletePageState();
}

class _ProductDeletePageState extends State<ProductDeletePage> {
  bool _deleting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Xóa sản phẩm')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF3C9C9)),
            ),
            child: const Text(
              'Xóa sẽ làm sản phẩm biến mất khỏi giao diện người dùng và các danh sách tìm kiếm.',
              style: TextStyle(fontSize: 12, color: Color(0xFF8E2A2A)),
            ),
          ),
          const SizedBox(height: 10),
          _FormCard(
            title: 'Thông tin bản ghi',
            children: [
              _InfoLine(label: 'ID', value: widget.product.id),
              _InfoLine(label: 'Tên', value: widget.product.name),
              _InfoLine(label: 'Category', value: widget.product.categoryId),
              _InfoLine(label: 'Giá', value: '${widget.product.price}₫'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _deleting
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: const Text('Hủy'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _deleting ? null : _delete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD12626),
                  ),
                  child: Text(_deleting ? 'Đang xóa...' : 'Xóa'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _delete() async {
    setState(() => _deleting = true);
    try {
      await widget.repository.deleteProduct(widget.product.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Xóa thất bại: $e')));
      setState(() => _deleting = false);
    }
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
            clipBehavior: Clip.antiAlias,
            child: SmartShopImage(source: product.image, fit: BoxFit.cover),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${product.id}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF7a7a7a),
                  ),
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
                const SizedBox(height: 2),
                Text(
                  'Tồn kho: ${product.stock}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF7a7a7a),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Size: ${product.sizeOptions.join('/')}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF7a7a7a),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Màu: ${product.colorOptions.join('/')}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF7a7a7a),
                  ),
                  maxLines: 1,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ảnh xem trước',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF7a7a7a),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
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
        ],
      ),
    );
  }
}

class _CategoryDropdownField extends StatelessWidget {
  const _CategoryDropdownField({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String? value;
  final List<ShopCategory> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Danh mục',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF7a7a7a),
            ),
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                hint: const Text('Chọn danh mục'),
                items: items
                    .map(
                      (category) => DropdownMenuItem<String>(
                        value: category.id,
                        child: Text('${category.name} (${category.id})'),
                      ),
                    )
                    .toList(),
                onChanged: onChanged,
              ),
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

class _FormCard extends StatelessWidget {
  const _FormCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF171717),
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    this.enabled = true,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final bool enabled;
  final TextInputType keyboardType;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF7a7a7a),
            ),
          ),
          const SizedBox(height: 5),
          TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            maxLines: maxLines,
            onChanged: onChanged,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFFea580c),
                  width: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF7a7a7a)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
