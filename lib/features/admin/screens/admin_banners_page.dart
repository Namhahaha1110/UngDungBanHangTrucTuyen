import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../models/shop_models.dart';
import '../../../services/shop_repository.dart';
import '../../../widgets/smart_shop_image.dart';
import '../widgets/admin_loading_states.dart';

class AdminBannersPage extends StatefulWidget {
  const AdminBannersPage({
    required this.repository,
    required this.userId,
    super.key,
  });

  final ShopRepository repository;
  final String userId;

  @override
  State<AdminBannersPage> createState() => _AdminBannersPageState();
}

class _AdminBannersPageState extends State<AdminBannersPage> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Quản lý banner chiến dịch',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),

              // Banner list
              FutureBuilder<List<ShopBanner>>(
                future: widget.repository.getBanners(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const AdminLoadingState();
                  }

                  if (snapshot.hasError) {
                    return AdminErrorState(error: snapshot.error.toString());
                  }

                  var banners = snapshot.data ?? [];
                  if (banners.isEmpty) {
                    return const AdminEmptyState(title: 'Không có banner');
                  }

                  return Column(
                    children: List.generate(banners.length, (idx) {
                      final banner = banners[idx];
                      return _BannerListRow(
                        banner: banner,
                        onEdit: () => _showEditDialog(banner),
                        onDelete: () => _showDeleteDialog(banner),
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
      builder: (_) => _BannerFormDialog(
        repository: widget.repository,
        onSave: () => setState(() {}),
      ),
    );
  }

  void _showEditDialog(ShopBanner banner) {
    showDialog(
      context: context,
      builder: (_) => _BannerFormDialog(
        repository: widget.repository,
        banner: banner,
        onSave: () => setState(() {}),
      ),
    );
  }

  void _showDeleteDialog(ShopBanner banner) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa banner?'),
        content: Text('Xóa "${banner.id}"?'),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              await widget.repository.deleteBanner(banner.id);
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

class _BannerListRow extends StatelessWidget {
  const _BannerListRow({
    required this.banner,
    required this.onEdit,
    required this.onDelete,
  });

  final ShopBanner banner;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isActive = banner.status == 'active';
    final imageSource = _resolveBannerImage(
      bannerId: banner.id,
      imageKey: banner.imageKey,
    );

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
            child: SmartShopImage(source: imageSource, fit: BoxFit.cover),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  banner.id,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFFeafaf0)
                            : const Color(0xFFfff2e8),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isActive ? 'Active' : 'Draft',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? const Color(0xFF12824a)
                              : const Color(0xFFea580c),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Vị trí: ${banner.position}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF7a7a7a),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'SP: ${banner.productIds.length}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF7a7a7a),
                      ),
                    ),
                    if (banner.campaignDiscountPercent > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Giảm ${banner.campaignDiscountPercent}%',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFFea580c),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
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

  String _resolveBannerImage({
    required String bannerId,
    required String imageKey,
  }) {
    final id = bannerId.trim().toLowerCase();
    if (id == 'banner_1' || id == 'banner_2' || id == 'banner_3') {
      return _defaultBannerAssetForId(bannerId);
    }

    final source = imageKey.trim();
    if (source.isNotEmpty &&
        source != 'default.jpg' &&
        !source.startsWith('data:image/')) {
      return source;
    }
    return _defaultBannerAssetForId(bannerId);
  }

  String _defaultBannerAssetForId(String bannerId) {
    final id = bannerId.trim().toLowerCase();
    if (id == 'banner_1') return 'banner_1.png';
    if (id == 'banner_2') return 'banner_2.png';
    if (id == 'banner_3') return 'banner_3.png';
    return 'banner_1.png';
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

class _BannerFormDialog extends StatefulWidget {
  const _BannerFormDialog({
    required this.repository,
    this.banner,
    required this.onSave,
  });

  final ShopRepository repository;
  final ShopBanner? banner;
  final VoidCallback onSave;

  @override
  State<_BannerFormDialog> createState() => _BannerFormDialogState();
}

class _BannerFormDialogState extends State<_BannerFormDialog> {
  late TextEditingController _idCtrl;
  late TextEditingController _positionCtrl;
  late TextEditingController _linkCtrl;
  late TextEditingController _imageCtrl;
  late TextEditingController _campaignNameCtrl;
  late TextEditingController _campaignDiscountCtrl;
  late String _status;
  Uint8List? _pickedImageBytes;
  String? _pickedImageName;
  bool _saving = false;
  bool _loadingProducts = true;
  List<ShopProduct> _allProducts = const [];
  final Set<String> _selectedProductIds = <String>{};

  @override
  void initState() {
    super.initState();
    _idCtrl = TextEditingController(text: widget.banner?.id ?? '');
    _positionCtrl = TextEditingController(text: widget.banner?.position ?? '');
    _linkCtrl = TextEditingController(text: widget.banner?.link ?? '');
    _imageCtrl = TextEditingController(text: widget.banner?.imageKey ?? '');
    _campaignNameCtrl = TextEditingController(
      text: widget.banner?.campaignName ?? '',
    );
    _campaignDiscountCtrl = TextEditingController(
      text: (widget.banner?.campaignDiscountPercent ?? 0).toString(),
    );
    _status = widget.banner?.status ?? 'active';
    _selectedProductIds.addAll(widget.banner?.productIds ?? const []);
    _loadProducts();
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _positionCtrl.dispose();
    _linkCtrl.dispose();
    _imageCtrl.dispose();
    _campaignNameCtrl.dispose();
    _campaignDiscountCtrl.dispose();
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
                  widget.banner == null ? 'Thêm banner' : 'Sửa banner',
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
                  _FormField(label: 'ID Banner', controller: _idCtrl),
                  _FormField(label: 'Vị trí', controller: _positionCtrl),
                  _FormField(label: 'Link', controller: _linkCtrl),
                  _FormField(
                    label: 'Tên chương trình',
                    controller: _campaignNameCtrl,
                  ),
                  _FormField(
                    label: 'Giảm giá (%) cho banner',
                    controller: _campaignDiscountCtrl,
                  ),
                  _FormField(
                    label: 'Image key / URL',
                    controller: _imageCtrl,
                    onChanged: (_) => setState(() {}),
                  ),
                  _ImagePickerBlock(
                    source: _imageCtrl.text.trim().isEmpty
                        ? _defaultBannerAssetForId(_idCtrl.text.trim())
                        : _imageCtrl.text.trim(),
                    memoryBytes: _pickedImageBytes,
                    onPick: _pickImage,
                  ),
                  const SizedBox(height: 2),
                  _ProductSelectorSection(
                    loading: _loadingProducts,
                    products: _allProducts,
                    selectedIds: _selectedProductIds,
                    onToggle: _toggleProduct,
                  ),
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
                              onTap: () => setState(() => _status = 'draft'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _status == 'draft'
                                      ? const Color(0xFFea580c)
                                      : Colors.white,
                                  border: Border.all(
                                    color: _status == 'draft'
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
                                    'Draft',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _status == 'draft'
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
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
      _imageCtrl.clear();
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      var imageRef = _imageCtrl.text.trim();
      if (_pickedImageBytes != null) {
        imageRef = await widget.repository.uploadAdminImage(
          bytes: _pickedImageBytes!,
          folder: 'banners',
          fileName: _pickedImageName ?? 'banner.jpg',
        );
      }
      if (imageRef.isEmpty) {
        imageRef =
            widget.banner?.imageKey ??
            _defaultBannerAssetForId(_idCtrl.text.trim());
      }

      final banner = ShopBanner(
        id: _idCtrl.text.trim(),
        imageKey: imageRef,
        position: _positionCtrl.text.trim(),
        status: _status,
        link: _linkCtrl.text.trim(),
        notes: widget.banner?.notes ?? '',
        productIds: _selectedProductIds.toList(),
        campaignName: _campaignNameCtrl.text.trim(),
        campaignDiscountPercent:
            int.tryParse(_campaignDiscountCtrl.text.trim()) ?? 0,
      );

      if (widget.banner == null) {
        await widget.repository.addBanner(banner);
      } else {
        await widget.repository.updateBanner(banner);
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

  Future<void> _loadProducts() async {
    try {
      final products = await widget.repository.getProducts();
      if (!mounted) return;
      setState(() {
        _allProducts = products;
        _loadingProducts = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingProducts = false);
    }
  }

  void _toggleProduct(String productId) {
    setState(() {
      if (_selectedProductIds.contains(productId)) {
        _selectedProductIds.remove(productId);
      } else {
        _selectedProductIds.add(productId);
      }
    });
  }

  String _defaultBannerAssetForId(String bannerId) {
    final id = bannerId.toLowerCase();
    if (id == 'banner_1') return 'banner_1.png';
    if (id == 'banner_2') return 'banner_2.png';
    if (id == 'banner_3') return 'banner_3.png';
    return 'banner_1.png';
  }
}

class _ProductSelectorSection extends StatefulWidget {
  const _ProductSelectorSection({
    required this.loading,
    required this.products,
    required this.selectedIds,
    required this.onToggle,
  });

  final bool loading;
  final List<ShopProduct> products;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;

  @override
  State<_ProductSelectorSection> createState() => _ProductSelectorSectionState();
}

class _ProductSelectorSectionState extends State<_ProductSelectorSection> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = widget.products.where((product) {
      if (_query.isEmpty) return true;
      final keyword = _query.toLowerCase();
      return product.name.toLowerCase().contains(keyword) ||
          product.id.toLowerCase().contains(keyword);
    }).toList();
    final preview = filteredProducts.take(40).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 6),
          child: Text(
            'Sản phẩm trong chương trình banner',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF171717),
            ),
          ),
        ),
        TextField(
          controller: _searchCtrl,
          onChanged: (value) {
            setState(() => _query = value.trim());
          },
          decoration: InputDecoration(
            hintText: 'Tìm theo tên hoặc ID sản phẩm',
            hintStyle: const TextStyle(fontSize: 11),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 9,
            ),
            suffixIcon: const Icon(
              Icons.search_rounded,
              size: 16,
              color: Color(0xFF7A7A7A),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFEA580C)),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Đã chọn: ${widget.selectedIds.length} sản phẩm',
          style: const TextStyle(fontSize: 11, color: Color(0xFF7A7A7A)),
        ),
        const SizedBox(height: 6),
        if (widget.loading)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: LinearProgressIndicator(minHeight: 2),
          )
        else if (widget.products.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Chưa có sản phẩm để chọn',
              style: TextStyle(fontSize: 11, color: Color(0xFF7A7A7A)),
            ),
          )
        else if (filteredProducts.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Không tìm thấy sản phẩm phù hợp',
              style: TextStyle(fontSize: 11, color: Color(0xFF7A7A7A)),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFDDDDDD)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: preview.map((product) {
                final selected = widget.selectedIds.contains(product.id);
                return FilterChip(
                  selected: selected,
                  onSelected: (_) => widget.onToggle(product.id),
                  label: Text(
                    '${product.name} (${product.id})',
                    overflow: TextOverflow.ellipsis,
                  ),
                  selectedColor: const Color(0xFFFFF2E8),
                  checkmarkColor: const Color(0xFFEA580C),
                  side: BorderSide(
                    color: selected
                        ? const Color(0xFFEA580C)
                        : const Color(0xFFDDDDDD),
                  ),
                  labelStyle: TextStyle(
                    fontSize: 11,
                    color: selected
                        ? const Color(0xFFB54A00)
                        : const Color(0xFF171717),
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                );
              }).toList(),
            ),
          ),
        if (filteredProducts.length > preview.length)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'Hiển thị ${preview.length}/${filteredProducts.length} kết quả. Hãy gõ thêm để lọc chính xác hơn.',
              style: const TextStyle(fontSize: 10, color: Color(0xFF7A7A7A)),
            ),
          ),
      ],
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.controller,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

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
          maxLines: 1,
          minLines: 1,
          onChanged: onChanged,
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
