import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/shop_models.dart';
import '../../services/shop_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/smart_shop_image.dart';
import 'cart_page.dart';
import 'formatting.dart';
import 'search_page.dart';

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({
    required this.repository,
    required this.userId,
    required this.product,
    super.key,
  });

  final ShopRepository repository;
  final String userId;
  final ShopProduct product;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<List<ShopCategory>>(
          stream: repository.categories(),
          builder: (context, categorySnapshot) {
            final categories = categorySnapshot.data ?? const <ShopCategory>[];
            final category = categories
                .where((item) => item.id == product.categoryId)
                .cast<ShopCategory?>()
                .firstOrNull;

            return StreamBuilder<List<ShopProduct>>(
              stream: repository.products(),
              builder: (context, productSnapshot) {
                final products = productSnapshot.data ?? const <ShopProduct>[];
                final relatedProducts = [...products]
                  ..removeWhere((item) => item.id == product.id)
                  ..sort((left, right) {
                    final leftScore = left.categoryId == product.categoryId
                        ? 0
                        : 1;
                    final rightScore = right.categoryId == product.categoryId
                        ? 0
                        : 1;
                    if (leftScore != rightScore) {
                      return leftScore.compareTo(rightScore);
                    }
                    return left.name.compareTo(right.name);
                  });

                return ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _DetailHeader(
                      onBack: () => Navigator.of(context).pop(),
                      onCartTap: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (_) => CartPage(
                              repository: repository,
                              userId: userId,
                            ),
                          ),
                        );
                      },
                      onSearchTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => SearchPage(
                              repository: repository,
                              userId: userId,
                            ),
                          ),
                        );
                      },
                    ),
                    _HeroProductSection(product: product),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 20, 12, 0),
                      child: Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 1,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(2, 12, 16, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatCurrency(product.price),
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              height: 1,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 1),
                            child: Text(
                              formatCurrency(product.oldPrice),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                height: 1,
                                color: Colors.red,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                      child: Row(
                        children: [
                          _ActionButton(
                            width: 139,
                            backgroundColor: const Color(0x801975D2),
                            label: 'Thêm vào giỏ hàng',
                            onTap: () => _handleAddToCart(context),
                          ),
                          const SizedBox(width: 20),
                          _ActionButton(
                            width: 102,
                            backgroundColor: const Color(0x80F81140),
                            label: 'Mua ngay',
                            onTap: () => _handleBuyNow(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 61),
                    const _SectionBar(title: 'CHI TIẾT SẢN PHẨM'),
                    const SizedBox(height: 23),
                    _InfoRow(
                      label: 'Danh mục',
                      value:
                          'Shoppe>${category?.name ?? 'Sản phẩm'}>${product.name}',
                      slotWidth: 80,
                      valueMaxLines: 1,
                      valueOverflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 27),
                    _SizeRow(
                      value: product.sizeOptions.isEmpty
                          ? 'Đang cập nhật'
                          : product.sizeOptions.join(' • '),
                    ),
                    if (product.colorOptions.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _InfoRow(
                        label: 'Màu sắc',
                        value: product.colorOptions.join(' • '),
                        slotWidth: 120,
                      ),
                    ],
                    const SizedBox(height: 29),
                    const _InfoRow(
                      label: 'Địa chỉ',
                      value: 'Hà Nội',
                      slotWidth: 120,
                    ),
                    const SizedBox(height: 41),
                    const _InfoRow(
                      label: 'Số lượng',
                      value: '1',
                      slotWidth: 120,
                    ),
                    const SizedBox(height: 20),
                    const _SectionBar(title: 'MÔ TẢ SẢN PHẨM'),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(25, 13, 38, 0),
                      child: Text(
                        product.description,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.3,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Padding(
                      padding: const EdgeInsets.only(left: 7),
                      child: Text(
                        'Các sản phẩm khác',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          height: 1,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 31),
                    SizedBox(
                      height: 244,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 21),
                        scrollDirection: Axis.horizontal,
                        itemCount: math.min(relatedProducts.length, 6),
                        separatorBuilder: (_, index) =>
                            const SizedBox(width: 18),
                        itemBuilder: (context, index) {
                          final related = relatedProducts[index];
                          return _RelatedProductCard(
                            product: related,
                            onTap: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute<void>(
                                  builder: (_) => ProductDetailPage(
                                    repository: repository,
                                    userId: userId,
                                    product: related,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleAddToCart(BuildContext context) async {
    final selection = await _pickVariant(context);
    if (selection == null) return;
    await repository.addToCart(
      userId,
      product,
      selectedSize: selection.$1,
      selectedColor: selection.$2,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã thêm sản phẩm vào giỏ'
          '${selection.$1.isEmpty ? '' : ' (Size ${selection.$1})'}'
          '${selection.$2.isEmpty ? '' : ' - Màu ${selection.$2}'}.',
        ),
      ),
    );
  }

  Future<void> _handleBuyNow(BuildContext context) async {
    final selection = await _pickVariant(context);
    if (selection == null) return;
    await repository.addToCart(
      userId,
      product,
      selectedSize: selection.$1,
      selectedColor: selection.$2,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Đã thêm sản phẩm. Bạn có thể thanh toán trong giỏ hàng.',
        ),
      ),
    );
  }

  Future<(String, String)?> _pickVariant(BuildContext context) async {
    final sizes = product.sizeOptions.isEmpty
        ? const <String>['M']
        : product.sizeOptions;
    final colors = product.colorOptions;
    var selectedSize = sizes.first;
    var selectedColor = colors.isNotEmpty ? colors.first : '';

    return showModalBottomSheet<(String, String)>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chọn phiên bản',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Size',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: sizes.map((size) {
                      final selected = size == selectedSize;
                      return ChoiceChip(
                        label: Text(size),
                        selected: selected,
                        onSelected: (_) {
                          setLocalState(() => selectedSize = size);
                        },
                      );
                    }).toList(),
                  ),
                  if (colors.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      'Màu sắc',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: colors.map((color) {
                        final selected = color == selectedColor;
                        return ChoiceChip(
                          label: Text(color),
                          selected: selected,
                          onSelected: (_) {
                            setLocalState(() => selectedColor = color);
                          },
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).pop((selectedSize, selectedColor));
                      },
                      child: const Text('Xác nhận'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SearchPlaceholder extends StatelessWidget {
  const _SearchPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Tìm kiếm',
      style: GoogleFonts.roboto(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.onBack,
    required this.onCartTap,
    required this.onSearchTap,
  });

  final VoidCallback onBack;
  final VoidCallback onCartTap;
  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 119,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF7C08), Color(0xFFFF6B00)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 20, 11, 20),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: IconButton(
                onPressed: onBack,
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 22,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: onSearchTap,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 39,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.primary),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: AppColors.textPrimary,
                      ),
                      SizedBox(width: 8),
                      _SearchPlaceholder(),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            SizedBox(
              width: 35,
              height: 35,
              child: IconButton(
                onPressed: onCartTap,
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.shopping_cart_outlined,
                  size: 26,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroProductSection extends StatelessWidget {
  const _HeroProductSection({required this.product});

  final ShopProduct product;

  @override
  Widget build(BuildContext context) {
    final discountPercent = _discountPercent(product.oldPrice, product.price);
    return Padding(
      padding: const EdgeInsets.fromLTRB(42, 14, 42, 0),
      child: SizedBox(
        width: 347,
        height: 334,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 347,
              height: 319,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(5),
              ),
              alignment: Alignment.center,
              child: SizedBox(
                width: 313,
                height: 313,
                child: SmartShopImage(
                  source: product.image,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            if (discountPercent > 0)
              Positioned(
                top: 151,
                right: 10,
                child: _DiscountBadge(label: '-$discountPercent%'),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 6,
              child: Center(
                child: Column(
                  children: [
                    Container(width: 347, height: 1, color: AppColors.border),
                    Container(width: 98, height: 1, color: Colors.black),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _discountPercent(int oldPrice, int price) {
    if (oldPrice <= 0 || oldPrice <= price) return 0;
    return (((oldPrice - price) / oldPrice) * 100).round();
  }
}

class _DiscountBadge extends StatelessWidget {
  const _DiscountBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 39,
      height: 18,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF81140), Color(0xFFFF5790)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: GoogleFonts.raleway(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1,
          letterSpacing: -0.13,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.width,
    required this.backgroundColor,
    required this.label,
    required this.onTap,
  });

  final double width;
  final Color backgroundColor;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 32,
      child: Material(
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: Colors.black),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionBar extends StatelessWidget {
  const _SectionBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 23,
      width: double.infinity,
      color: AppColors.primary,
      padding: const EdgeInsets.only(left: 20, top: 3),
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1,
          color: Colors.black,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.slotWidth = 75,
    this.valueMaxLines,
    this.valueOverflow,
  });

  final String label;
  final String value;
  final double slotWidth;
  final int? valueMaxLines;
  final TextOverflow? valueOverflow;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: slotWidth,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: valueMaxLines,
              overflow: valueOverflow,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SizeRow extends StatelessWidget {
  const _SizeRow({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 13),
      child: Row(
        children: [
          SizedBox(width: 107, child: _SizeLabel()),
          _SizeValue(value: value),
        ],
      ),
    );
  }
}

class _SizeLabel extends StatelessWidget {
  const _SizeLabel();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Size',
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1,
        color: Colors.black,
      ),
    );
  }
}

class _SizeValue extends StatelessWidget {
  const _SizeValue({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1,
        color: Colors.black,
      ),
    );
  }
}

class _RelatedProductCard extends StatelessWidget {
  const _RelatedProductCard({required this.product, required this.onTap});

  final ShopProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final discountPercent = _discountPercent(product.oldPrice, product.price);
    return SizedBox(
      width: 162,
      height: 244,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(5),
              child: Container(
                width: 162,
                height: 244,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 161,
                      height: 164,
                      child: SmartShopImage(
                        source: product.image,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 3),
                    SizedBox(
                      height: 28,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            height: 1.2,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Align(
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Text(
                            formatCurrency(product.price),
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              height: 1,
                              color: AppColors.primary,
                            ),
                          ),
                          if (discountPercent > 0) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${formatCurrency(product.oldPrice)}  (-$discountPercent%)',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                height: 1,
                                color: const Color(0xFF9b9b9b),
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (discountPercent > 0)
            Positioned(
              top: 10,
              right: 10,
              child: _DiscountBadge(label: '-$discountPercent%'),
            ),
        ],
      ),
    );
  }

  int _discountPercent(int oldPrice, int price) {
    if (oldPrice <= 0 || oldPrice <= price) return 0;
    return (((oldPrice - price) / oldPrice) * 100).round();
  }
}
