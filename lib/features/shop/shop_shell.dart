import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/shop_models.dart';
import '../../services/auth_service.dart';
import '../../services/shop_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/smart_shop_image.dart';
import '../admin/admin_view_mode.dart';
import 'checkout_page.dart';
import 'formatting.dart';
import 'orders_page.dart';
import 'product_detail_page.dart';
import 'search_page.dart';
import 'shipping_addresses_page.dart';

class ShopShell extends StatefulWidget {
  const ShopShell({required this.authService, required this.user, super.key});

  final AuthService authService;
  final User user;

  @override
  State<ShopShell> createState() => _ShopShellState();
}

class _ShopShellState extends State<ShopShell> {
  late final ShopRepository _repository = ShopRepository(
    FirebaseFirestore.instance,
  );
  late final Future<void> _setupUserFuture = _repository.ensureUserDocument(
    widget.user,
  );
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _setupUserFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final pages = [
          _HomeTab(
            repository: _repository,
            userId: widget.user.uid,
            onCartTap: () => setState(() => _currentIndex = 3),
          ),
          _WishlistTab(repository: _repository, userId: widget.user.uid),
          _CategoryTab(
            repository: _repository,
            userId: widget.user.uid,
            onCartTap: () => setState(() => _currentIndex = 3),
          ),
          _CartTab(repository: _repository, userId: widget.user.uid),
          _ProfileTab(
            repository: _repository,
            authService: widget.authService,
            user: widget.user,
          ),
        ];

        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: IndexedStack(index: _currentIndex, children: pages),
          ),
          bottomNavigationBar: _BottomBar(
            currentIndex: _currentIndex,
            onChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        );
      },
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({
    required this.repository,
    required this.userId,
    this.onCartTap,
  });

  final ShopRepository repository;
  final String userId;
  final VoidCallback? onCartTap;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            height: 119,
            color: AppColors.primary,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => SearchPage(
                              repository: repository,
                              userId: userId,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        height: 39,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.search_rounded,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Tìm kiếm',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  StreamBuilder<List<UserProductItem>>(
                    stream: repository.cartItems(userId),
                    builder: (context, snapshot) {
                      final cartCount = snapshot.data?.length ?? 0;
                      return GestureDetector(
                        onTap: onCartTap,
                        child: SizedBox(
                          width: 35,
                          height: 35,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Center(
                                child: Icon(
                                  Icons.shopping_cart_outlined,
                                  size: 26,
                                  color: Color(0xFF111111),
                                ),
                              ),
                              if (cartCount > 0)
                                Positioned(
                                  right: -2,
                                  top: -4,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      cartCount.toString(),
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _HomeBannerCarousel(repository: repository, userId: userId),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 33, 16, 0),
            child: _SectionTitle(title: 'Danh mục', actionLabel: 'Xem tất cả'),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 606,
            child: StreamBuilder<List<ShopCategory>>(
              stream: repository.categories(),
              builder: (context, snapshot) {
                final categories = snapshot.data ?? const <ShopCategory>[];
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: categories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.045,
                  ),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return _CategoryCard(
                      category: category,
                      onTap: () => _openCategory(context, category),
                    );
                  },
                );
              },
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 28, 20, 0),
            child: SizedBox(
              height: 67,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/banner_3.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 17, 19, 0),
            child: _SectionTitle(title: 'Flash Sale', actionLabel: ''),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 276,
            child: StreamBuilder<List<ShopFlashSale>>(
              stream: repository.flashSale(),
              builder: (context, snapshot) {
                final sales = snapshot.data ?? const <ShopFlashSale>[];
                return StreamBuilder<List<ShopProduct>>(
                  stream: repository.products(),
                  builder: (context, productSnapshot) {
                    final products =
                        productSnapshot.data ?? const <ShopProduct>[];
                    final flashProducts = products
                        .where((p) => sales.any((s) => s.productId == p.id))
                        .take(6)
                        .toList();

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              height: 27,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE2D1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'LIVE',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: flashProducts.length,
                              separatorBuilder: (_, index) =>
                                  const SizedBox(width: 9),
                              itemBuilder: (context, index) {
                                final product = flashProducts[index];
                                return SizedBox(
                                  width: 120,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () => _openProduct(context, product),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: SmartShopImage(
                                        source: product.image,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(19, 17, 19, 0),
            child: Text(
              'Sản phẩm bán chạy',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(11, 20, 11, 24),
            child: StreamBuilder<List<UserProductItem>>(
              stream: repository.favorites(userId),
              builder: (context, favoriteSnapshot) {
                final favoriteIds =
                    favoriteSnapshot.data
                        ?.map((item) => item.productId)
                        .toSet() ??
                    <String>{};
                return StreamBuilder<List<ShopProduct>>(
                  stream: repository.products(),
                  builder: (context, productSnapshot) {
                    final products =
                        productSnapshot.data ?? const <ShopProduct>[];
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: products.take(4).map((product) {
                        return SizedBox(
                          width: 196,
                          child: _ProductCard(
                            compact: true,
                            product: product,
                            isFavorite: favoriteIds.contains(product.id),
                            onTap: () => _openProduct(context, product),
                            onFavoriteToggle: () =>
                                repository.toggleFavorite(userId, product),
                            onAddToCart: () =>
                                repository.addToCart(userId, product),
                          ),
                        );
                      }).toList(),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _openProduct(BuildContext context, ShopProduct product) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailPage(
          repository: repository,
          userId: userId,
          product: product,
        ),
      ),
    );
  }

  void _openCategory(BuildContext context, ShopCategory category) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _CategoryProductsPage(
          repository: repository,
          userId: userId,
          category: category,
        ),
      ),
    );
  }
}

class _HomeBannerCarousel extends StatefulWidget {
  const _HomeBannerCarousel({required this.repository, required this.userId});

  final ShopRepository repository;
  final String userId;

  @override
  State<_HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends State<_HomeBannerCarousel> {
  late final PageController _pageController;
  StreamSubscription<List<PromoBanner>>? _bannerSub;
  Timer? _autoSlideTimer;
  List<PromoBanner> _banners = const [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.928);
    _bannerSub = widget.repository.banners().listen((fetched) {
      final byId = <String, PromoBanner>{
        for (final item in fetched) item.id.trim().toLowerCase(): item,
      };
      final banners = <PromoBanner>[
        PromoBanner(
          id: 'home_fixed_banner_1',
          image: 'banner_1.png',
          productIds: byId['banner_1']?.productIds ?? const [],
          campaignName: byId['banner_1']?.campaignName ?? '',
          campaignDiscountPercent:
              byId['banner_1']?.campaignDiscountPercent ?? 0,
        ),
        PromoBanner(
          id: 'home_fixed_banner_2',
          image: 'banner_2.png',
          productIds: byId['banner_2']?.productIds ?? const [],
          campaignName: byId['banner_2']?.campaignName ?? '',
          campaignDiscountPercent:
              byId['banner_2']?.campaignDiscountPercent ?? 0,
        ),
        PromoBanner(
          id: 'home_fixed_banner_3',
          image: 'banner_3.png',
          productIds: byId['banner_3']?.productIds ?? const [],
          campaignName: byId['banner_3']?.campaignName ?? '',
          campaignDiscountPercent:
              byId['banner_3']?.campaignDiscountPercent ?? 0,
        ),
        ...fetched.where((item) {
          final id = item.id.trim().toLowerCase();
          if (id == 'banner_1' || id == 'banner_2' || id == 'banner_3') {
            return false;
          }
          return item.image.trim().isNotEmpty;
        }),
      ];
      if (!mounted) return;
      setState(() {
        _banners = banners;
        if (_currentIndex >= _banners.length) {
          _currentIndex = 0;
        }
      });
      _syncAutoSlide();
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _bannerSub?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_banners.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 182,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) => _currentIndex = index,
        itemCount: _banners.length,
        itemBuilder: (context, index) {
          final banner = _banners[index];
          return Padding(
            padding: const EdgeInsets.only(left: 16, right: 8, top: 18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => _openBannerCampaign(context, banner),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SmartShopImage(source: banner.image, fit: BoxFit.cover),
              ),
            ),
          );
        },
      ),
    );
  }

  void _syncAutoSlide() {
    _autoSlideTimer?.cancel();
    if (_banners.length <= 1) return;
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_pageController.hasClients || _banners.isEmpty) return;
      final next = (_currentIndex + 1) % _banners.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOut,
      );
      _currentIndex = next;
    });
  }

  void _openBannerCampaign(BuildContext context, PromoBanner banner) {
    if (banner.productIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Banner này chưa gắn sản phẩm chương trình')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _BannerCampaignProductsPage(
          repository: widget.repository,
          userId: widget.userId,
          banner: banner,
        ),
      ),
    );
  }
}

class _BannerCampaignProductsPage extends StatelessWidget {
  const _BannerCampaignProductsPage({
    required this.repository,
    required this.userId,
    required this.banner,
  });

  final ShopRepository repository;
  final String userId;
  final PromoBanner banner;

  @override
  Widget build(BuildContext context) {
    final campaignTitle = banner.campaignName.trim().isNotEmpty
        ? banner.campaignName.trim()
        : 'Ưu đãi theo banner';
    return Scaffold(
      appBar: AppBar(title: Text(campaignTitle)),
      body: StreamBuilder<List<ShopProduct>>(
        stream: repository.products(),
        builder: (context, snapshot) {
          final all = snapshot.data ?? const <ShopProduct>[];
          final ids = banner.productIds.toSet();
          var products = all.where((item) => ids.contains(item.id)).toList();
          if (products.isEmpty) {
            return const Center(
              child: Text('Banner này hiện chưa có sản phẩm chương trình'),
            );
          }
          products.sort((a, b) {
            final aDiscount = (a.oldPrice - a.price);
            final bDiscount = (b.oldPrice - b.price);
            return bDiscount.compareTo(aDiscount);
          });
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
            itemCount: products.length,
            separatorBuilder: (_, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final product = products[index];
              final isDiscounted = product.oldPrice > product.price;
              final campaignDiscount = banner.campaignDiscountPercent.clamp(
                0,
                95,
              );
              final campaignPrice = campaignDiscount > 0
                  ? (product.price * (100 - campaignDiscount) / 100).round()
                  : product.price;
              return ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFECECEC)),
                ),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SmartShopImage(
                    source: product.image,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  _buildCampaignPriceText(
                    product: product,
                    isDiscounted: isDiscounted,
                    campaignDiscount: campaignDiscount,
                    campaignPrice: campaignPrice,
                  ),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  final openProduct = _applyBannerDiscount(
                    product,
                    banner.campaignDiscountPercent,
                  );
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ProductDetailPage(
                        repository: repository,
                        userId: userId,
                        product: openProduct,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _buildCampaignPriceText({
    required ShopProduct product,
    required bool isDiscounted,
    required int campaignDiscount,
    required int campaignPrice,
  }) {
    if (campaignDiscount > 0) {
      return '${formatCurrency(campaignPrice)}  (banner -$campaignDiscount%)';
    }
    if (isDiscounted) {
      return '${formatCurrency(product.price)}  (giảm từ ${formatCurrency(product.oldPrice)})';
    }
    return formatCurrency(product.price);
  }

  ShopProduct _applyBannerDiscount(ShopProduct product, int percentRaw) {
    final percent = percentRaw.clamp(0, 95);
    if (percent <= 0) return product;
    final basePrice = product.price;
    final discounted = (basePrice * (100 - percent) / 100).round();
    final safePrice = discounted < 0 ? 0 : discounted;
    // Keep oldPrice = basePrice so detail page discount badge matches banner campaign percent.
    return product.copyWith(price: safePrice, oldPrice: basePrice);
  }
}

class _CategoryTab extends StatelessWidget {
  const _CategoryTab({
    required this.repository,
    required this.userId,
    this.onCartTap,
  });

  final ShopRepository repository;
  final String userId;
  final VoidCallback? onCartTap;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ShopCategory>>(
      stream: repository.categories(),
      builder: (context, categorySnapshot) {
        final categories = categorySnapshot.data ?? const <ShopCategory>[];
        return StreamBuilder<List<ShopProduct>>(
          stream: repository.products(),
          builder: (context, productSnapshot) {
            final products = productSnapshot.data ?? const <ShopProduct>[];
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                Container(
                  height: 119,
                  color: AppColors.primary,
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => SearchPage(
                                  repository: repository,
                                  userId: userId,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            height: 39,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.search_rounded,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Tìm kiếm',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      StreamBuilder<List<UserProductItem>>(
                        stream: repository.cartItems(userId),
                        builder: (context, snapshot) {
                          final cartCount = snapshot.data?.length ?? 0;
                          return GestureDetector(
                            onTap: onCartTap,
                            child: SizedBox(
                              width: 35,
                              height: 35,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  const Center(
                                    child: Icon(
                                      Icons.shopping_cart_outlined,
                                      size: 27,
                                      color: Color(0xFF111111),
                                    ),
                                  ),
                                  if (cartCount > 0)
                                    Positioned(
                                      right: -2,
                                      top: -4,
                                      child: Container(
                                        width: 16,
                                        height: 16,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          cartCount.toString(),
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: Text(
                    'Mua sắm theo danh mục',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: categories.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.045,
                        ),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return _CategoryCard(
                        category: category,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => _CategoryProductsPage(
                                repository: repository,
                                userId: userId,
                                category: category,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                ...categories.map((category) {
                  final groupedProducts = products
                      .where((product) => product.categoryId == category.id)
                      .toList();
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0D000000),
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 54,
                                height: 54,
                                child: Image.asset(
                                  'assets/images/${category.image}',
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  category.name,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          if (groupedProducts.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            ...groupedProducts.map(
                              (product) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SmartShopImage(
                                    source: product.image,
                                    width: 54,
                                    height: 54,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                title: Text(
                                  product.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(product.soldText),
                                trailing: Text(
                                  formatCurrency(product.price),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(color: AppColors.primary),
                                ),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => ProductDetailPage(
                                        repository: repository,
                                        userId: userId,
                                        product: product,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }
}

class _WishlistTab extends StatelessWidget {
  const _WishlistTab({required this.repository, required this.userId});

  final ShopRepository repository;
  final String userId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserProductItem>>(
      stream: repository.favorites(userId),
      builder: (context, snapshot) {
        final favorites = snapshot.data ?? const <UserProductItem>[];
        if (favorites.isEmpty) {
          return const _EmptyState(
            icon: Icons.favorite_border_rounded,
            title: 'Chưa có sản phẩm yêu thích',
            message: 'Nhấn tim ở trang chủ để lưu sản phẩm.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          itemBuilder: (context, index) {
            final item = favorites[index];
            return _SavedProductTile(
              item: item,
              onOpen: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ProductDetailPage(
                      repository: repository,
                      userId: userId,
                      product: _productFromItem(item),
                    ),
                  ),
                );
              },
              onAddToCart: () =>
                  repository.addToCart(userId, _productFromItem(item)),
              onRemove: () =>
                  repository.toggleFavorite(userId, _productFromItem(item)),
            );
          },
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemCount: favorites.length,
        );
      },
    );
  }
}

// Wrapper pages for navigation from profile menu
class CartPageWrapper extends StatelessWidget {
  const CartPageWrapper({
    required this.repository,
    required this.userId,
    super.key,
  });

  final ShopRepository repository;
  final String userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Giỏ hàng'), centerTitle: true),
      body: _CartTab(repository: repository, userId: userId),
    );
  }
}

class WishlistPageWrapper extends StatelessWidget {
  const WishlistPageWrapper({
    required this.repository,
    required this.userId,
    super.key,
  });

  final ShopRepository repository;
  final String userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sản phẩm yêu thích'),
        centerTitle: true,
      ),
      body: _WishlistTab(repository: repository, userId: userId),
    );
  }
}

class ProfileVouchersPage extends StatelessWidget {
  const ProfileVouchersPage({
    required this.repository,
    required this.userId,
    super.key,
  });

  final ShopRepository repository;
  final String userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voucher của tôi'), centerTitle: true),
      body: FutureBuilder<List<ShopVoucher>>(
        future: repository.getVouchers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Lỗi tải voucher: ${snapshot.error}'),
              ),
            );
          }
          final vouchers =
              (snapshot.data ?? const <ShopVoucher>[])
                  .where(_isActiveVoucher)
                  .toList()
                ..sort((a, b) => a.code.compareTo(b.code));
          if (vouchers.isEmpty) {
            return const _EmptyState(
              icon: Icons.confirmation_num_outlined,
              title: 'Chưa có voucher khả dụng',
              message: 'Voucher sẽ hiển thị tại đây khi đang hoạt động.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
            itemCount: vouchers.length,
            separatorBuilder: (_, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final voucher = vouchers[index];
              final isShipping =
                  voucher.type.trim().toLowerCase() == 'shipping';
              final discountLabel = _voucherDiscountLabel(voucher);
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFECECEC)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: isShipping
                            ? const Color(0xFF00C853)
                            : AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          isShipping ? 'FREE\nSHIP' : 'shoppe',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${voucher.code} • ${voucher.displayTitle}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            discountLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Đơn tối thiểu ${formatCurrency(voucher.minOrder)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Hiệu lực: ${voucher.startTime} - ${voucher.endTime}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              OutlinedButton(
                                onPressed: () async {
                                  await Clipboard.setData(
                                    ClipboardData(text: voucher.code),
                                  );
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Đã sao chép mã ${voucher.code}',
                                      ),
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 34),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                ),
                                child: const Text('Sao chép mã'),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Voucher sẽ tự áp dụng ở màn Thanh toán',
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(0, 34),
                                  ),
                                  child: const Text('Dùng ngay'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  bool _isActiveVoucher(ShopVoucher voucher) {
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

  DateTime? _parseDateTime(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw.replaceFirst(' ', 'T'));
  }

  String _voucherDiscountLabel(ShopVoucher voucher) {
    final isPercent = voucher.discountType.trim().toLowerCase() == 'percent';
    if (isPercent) {
      if (voucher.maxDiscount > 0) {
        return 'Giảm ${voucher.discountValue}% tối đa ${formatCurrency(voucher.maxDiscount)}';
      }
      return 'Giảm ${voucher.discountValue}%';
    }
    if (voucher.maxDiscount > 0 &&
        voucher.maxDiscount != voucher.discountValue) {
      return 'Giảm ${formatCurrency(voucher.discountValue)} tối đa ${formatCurrency(voucher.maxDiscount)}';
    }
    return 'Giảm ${formatCurrency(voucher.discountValue)}';
  }
}

class _CartTab extends StatelessWidget {
  const _CartTab({required this.repository, required this.userId});

  final ShopRepository repository;
  final String userId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserProductItem>>(
      stream: repository.cartItems(userId),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <UserProductItem>[];
        if (items.isEmpty) {
          return const _EmptyState(
            icon: Icons.shopping_cart_outlined,
            title: 'Giỏ hàng đang trống',
            message: 'Thêm sản phẩm để bắt đầu tạo đơn hàng.',
          );
        }

        final total = items.fold<int>(
          0,
          (value, item) => value + item.totalPrice,
        );

        return Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _CartTile(
                    item: item,
                    onAdd: () => repository.updateCartQuantity(
                      userId,
                      item,
                      item.quantity + 1,
                    ),
                    onRemove: () => repository.updateCartQuantity(
                      userId,
                      item,
                      item.quantity - 1,
                    ),
                  );
                },
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemCount: items.length,
              ),
            ),
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Tổng thanh toán',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatCurrency(total),
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => CheckoutPage(
                                repository: repository,
                                userId: userId,
                                items: items,
                              ),
                            ),
                          );
                        },
                        child: const Text('Thanh toán'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({
    required this.repository,
    required this.authService,
    required this.user,
  });

  final ShopRepository repository;
  final AuthService authService;
  final User user;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          color: AppColors.primary,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(9, 28, 10, 20),
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tính năng đang phát triển'),
                          ),
                        );
                      },
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(19),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.sell_outlined,
                              color: Colors.white,
                              size: 19,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Bắt đầu bán',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => CartPageWrapper(
                            repository: ShopRepository(
                              FirebaseFirestore.instance,
                            ),
                            userId: user.uid,
                          ),
                        ),
                      ),
                      child: const Icon(
                        Icons.shopping_cart_outlined,
                        color: Colors.white,
                        size: 29,
                      ),
                    ),
                    const SizedBox(width: 18),
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tính năng đang phát triển'),
                          ),
                        );
                      },
                      child: const Icon(
                        Icons.message_outlined,
                        color: Colors.white,
                        size: 27,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person_rounded,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.email?.split('@').first ?? 'Người dùng',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'Thành viên >',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '0 người theo   3 người theo dõi',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          OrdersPage(repository: repository, userId: user.uid),
                    ),
                  ),
                  child: Container(
                    height: 74,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Text(
                          'Đơn mua',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Spacer(),
                        Text(
                          'Xem lịch sử mua hàng',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(width: 10),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 15,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 44),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            children: [
              // Admin button - show at top if user is admin
              StreamBuilder<bool>(
                stream: repository.isAdmin(user.uid).asStream(),
                builder: (context, snapshot) {
                  final isAdmin = snapshot.data ?? false;
                  if (!isAdmin) return const SizedBox.shrink();
                  return Column(
                    children: [
                      GestureDetector(
                        onTap: AdminViewMode.openAdmin,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B00),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.admin_panel_settings_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Quản lý cửa hàng',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Truy cập bảng điều khiển',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.8,
                                        ),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                  );
                },
              ),
              _MenuTile(
                icon: Icons.shopping_bag_outlined,
                label: 'Giỏ hàng của tôi',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CartPageWrapper(
                      repository: ShopRepository(FirebaseFirestore.instance),
                      userId: user.uid,
                    ),
                  ),
                ),
              ),
              _MenuTile(
                icon: Icons.receipt_long_outlined,
                label: 'Đơn hàng của tôi',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => OrdersPage(
                      repository: ShopRepository(FirebaseFirestore.instance),
                      userId: user.uid,
                    ),
                  ),
                ),
              ),
              _MenuTile(
                icon: Icons.favorite_border_rounded,
                label: 'Sản phẩm yêu thích',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => WishlistPageWrapper(
                      repository: ShopRepository(FirebaseFirestore.instance),
                      userId: user.uid,
                    ),
                  ),
                ),
              ),
              _MenuTile(
                icon: Icons.local_shipping_outlined,
                label: 'Vận chuyển',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ShippingAddressesPage(
                      repository: ShopRepository(FirebaseFirestore.instance),
                      userId: user.uid,
                    ),
                  ),
                ),
              ),
              _MenuTile(
                icon: Icons.confirmation_num_outlined,
                label: 'Voucher',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ProfileVouchersPage(
                      repository: repository,
                      userId: user.uid,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          child: ElevatedButton(
            onPressed: authService.signOut,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.textPrimary,
            ),
            child: const Text('Đăng xuất'),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.actionLabel});

  final String title;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (actionLabel.isNotEmpty)
          Text(
            actionLabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 58,
        margin: const EdgeInsets.only(bottom: 6),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: AppColors.textPrimary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontSize: 16),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, this.onTap});

  final ShopCategory category;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    color: const Color(0xFFF8F6F2),
                    padding: const EdgeInsets.all(12),
                    child: Image.asset(
                      'assets/images/${category.image}',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                category.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryProductsPage extends StatelessWidget {
  const _CategoryProductsPage({
    required this.repository,
    required this.userId,
    required this.category,
  });

  final ShopRepository repository;
  final String userId;
  final ShopCategory category;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(category.name), centerTitle: true),
      body: StreamBuilder<List<ShopProduct>>(
        stream: repository.products(),
        builder: (context, snapshot) {
          final allProducts = snapshot.data ?? const <ShopProduct>[];
          final products = allProducts
              .where((item) => item.categoryId == category.id)
              .toList();

          if (products.isEmpty) {
            return const Center(child: Text('Danh mục này chưa có sản phẩm'));
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: products.length,
            separatorBuilder: (_, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFECECEC)),
                ),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SmartShopImage(
                    source: product.image,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  formatCurrency(product.price),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ProductDetailPage(
                        repository: repository,
                        userId: userId,
                        product: product,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.currentIndex, required this.onChanged});

  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_rounded, 'Home'),
      (Icons.favorite_border_rounded, 'Yêu thích'),
      (Icons.grid_view_rounded, 'Danh mục'),
      (Icons.shopping_cart_outlined, 'Giỏ hàng'),
      (Icons.person_rounded, 'Tôi'),
    ];

    return Container(
      height: 85,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(4, 0),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 5, 14, 10),
      child: Row(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final selected = index == currentIndex;
          return Expanded(
            child: InkWell(
              onTap: () => onChanged(index),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.$1,
                      size: 24,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.$2,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: selected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteToggle,
    required this.onAddToCart,
    this.compact = false,
  });

  final ShopProduct product;
  final bool isFavorite;
  final VoidCallback onTap;
  final Future<void> Function() onFavoriteToggle;
  final Future<void> Function() onAddToCart;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final discountPercent = _discountPercent(product.oldPrice, product.price);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(compact ? 16 : 24),
      child: InkWell(
        borderRadius: BorderRadius.circular(compact ? 16 : 24),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(compact ? 8 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (compact)
                SizedBox(
                  height: 164,
                  child: _ProductImage(
                    image: product.image,
                    isFavorite: isFavorite,
                    compact: compact,
                    discountPercent: discountPercent,
                    onFavoriteToggle: onFavoriteToggle,
                  ),
                )
              else
                Expanded(
                  child: _ProductImage(
                    image: product.image,
                    isFavorite: isFavorite,
                    compact: compact,
                    discountPercent: discountPercent,
                    onFavoriteToggle: onFavoriteToggle,
                  ),
                ),
              SizedBox(height: compact ? 8 : 12),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: compact ? 14 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (!compact) ...[
                const SizedBox(height: 6),
                Text(
                  product.soldText,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
              ] else
                const SizedBox(height: 6),
              Text(
                formatCurrency(product.price),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontSize: compact ? 15 : 16,
                ),
              ),
              if (discountPercent > 0) ...[
                const SizedBox(height: 2),
                Text(
                  '-$discountPercent%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFd12626),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              if (!compact) ...[
                Text(
                  formatCurrency(product.oldPrice),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: onAddToCart,
                    child: const Text('Thêm vào giỏ'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  int _discountPercent(int oldPrice, int price) {
    if (oldPrice <= 0 || oldPrice <= price) return 0;
    return (((oldPrice - price) / oldPrice) * 100).round();
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({
    required this.image,
    required this.isFavorite,
    required this.compact,
    required this.discountPercent,
    required this.onFavoriteToggle,
  });

  final String image;
  final bool isFavorite;
  final bool compact;
  final int discountPercent;
  final Future<void> Function() onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(compact ? 12 : 20),
            child: SmartShopImage(source: image, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: CircleAvatar(
            radius: 16,
            backgroundColor: Colors.white,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: onFavoriteToggle,
              icon: Icon(
                isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                size: 18,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        if (discountPercent > 0)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFd12626),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '-$discountPercent%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SavedProductTile extends StatelessWidget {
  const _SavedProductTile({
    required this.item,
    required this.onOpen,
    required this.onAddToCart,
    required this.onRemove,
  });

  final UserProductItem item;
  final VoidCallback onOpen;
  final Future<void> Function() onAddToCart;
  final Future<void> Function() onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SmartShopImage(
                  source: item.image,
                  width: 82,
                  height: 82,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.soldText,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      formatCurrency(item.price),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(
                      Icons.favorite_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: onAddToCart,
                    child: const Text('Thêm'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartTile extends StatelessWidget {
  const _CartTile({
    required this.item,
    required this.onAdd,
    required this.onRemove,
  });

  final UserProductItem item;
  final Future<void> Function() onAdd;
  final Future<void> Function() onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SmartShopImage(
              source: item.image,
              width: 82,
              height: 82,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  formatCurrency(item.price),
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _QtyButton(icon: Icons.remove_rounded, onTap: onRemove),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('${item.quantity}'),
                    ),
                    _QtyButton(icon: Icons.add_rounded, onTap: onAdd),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});

  final IconData icon;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }
}

ShopProduct _productFromItem(UserProductItem item) {
  return ShopProduct(
    id: item.productId,
    name: item.name,
    price: item.price,
    oldPrice: item.oldPrice,
    stock: 0,
    image: item.image,
    categoryId: '',
    description: item.description,
    soldText: item.soldText,
    sizeOptions: item.selectedSize.isEmpty ? const [] : [item.selectedSize],
    colorOptions: item.selectedColor.isEmpty ? const [] : [item.selectedColor],
  );
}
