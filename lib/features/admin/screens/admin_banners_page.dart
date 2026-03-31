import 'package:flutter/material.dart';

import '../../../models/shop_models.dart';
import '../../../services/shop_repository.dart';

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
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var banners = snapshot.data ?? [];
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
          TextButton(onPressed: Navigator.of(context).pop, child: const Text('Hủy')),
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
                  banner.id,
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
                        color: isActive ? const Color(0xFFeafaf0) : const Color(0xFFfff2e8),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isActive ? 'Active' : 'Draft',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isActive ? const Color(0xFF12824a) : const Color(0xFFea580c),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Vị trí: ${banner.position}',
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
  late String _status;

  @override
  void initState() {
    super.initState();
    _idCtrl = TextEditingController(text: widget.banner?.id ?? '');
    _positionCtrl = TextEditingController(text: widget.banner?.position ?? '');
    _linkCtrl = TextEditingController(text: widget.banner?.link ?? '');
    _status = widget.banner?.status ?? 'draft';
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _positionCtrl.dispose();
    _linkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.banner == null ? 'Thêm banner' : 'Sửa banner'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FormField(label: 'ID', controller: _idCtrl),
            const SizedBox(height: 12),
            _FormField(label: 'Vị trí', controller: _positionCtrl),
            const SizedBox(height: 12),
            _FormField(label: 'Link', controller: _linkCtrl),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Trạng thái',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Row(
                  children: ['draft', 'active'].map((status) {
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: _status == status ? const Color(0xFFfff2e8) : Colors.white,
                          border: Border.all(
                            color: _status == status ? const Color(0xFFffd2b1) : const Color(0xFFECECEC),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => setState(() => _status = status),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                status == 'draft' ? 'Draft' : 'Active',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _status == status
                                      ? const Color(0xFFea580c)
                                      : const Color(0xFF7a7a7a),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: Navigator.of(context).pop, child: const Text('Hủy')),
        TextButton(
          onPressed: () async {
            final banner = ShopBanner(
              id: _idCtrl.text,
              imageKey: widget.banner?.imageKey ?? 'default.jpg',
              position: _positionCtrl.text,
              status: _status,
              link: _linkCtrl.text,
              notes: widget.banner?.notes ?? '',
            );

            if (widget.banner == null) {
              await widget.repository.addBanner(banner);
            } else {
              await widget.repository.updateBanner(banner);
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
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
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
