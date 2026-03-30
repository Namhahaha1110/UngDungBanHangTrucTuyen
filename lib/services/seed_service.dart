import 'package:cloud_firestore/cloud_firestore.dart';

class SeedService {
  SeedService(this._firestore);

  final FirebaseFirestore _firestore;

  Future<void> seedIfNeeded() async {
    final categoriesRef = _firestore.collection('categories');
    final existing = await categoriesRef.limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final batch = _firestore.batch();

    final categories = <Map<String, dynamic>>[
      {
        'id': 'men',
        'name': 'Thời Trang Nam',
        'image': 'category_men.png',
      },
      {
        'id': 'women',
        'name': 'Thời Trang Nữ',
        'image': 'category_women.png',
      },
      {
        'id': 'kids',
        'name': 'Thời Trang Em Bé',
        'image': 'category_kids.png',
      },
      {
        'id': 'beauty',
        'name': 'Vẻ đẹp & Sang trọng',
        'image': 'category_beauty.png',
      },
      {
        'id': 'home',
        'name': 'Nhà & Bếp',
        'image': 'category_home.png',
      },
      {
        'id': 'toys',
        'name': 'Đồ chơi & Trò chơi',
        'image': 'category_toys.png',
      },
    ];

    for (final category in categories) {
      batch.set(categoriesRef.doc(category['id'] as String), category);
    }

    final bannersRef = _firestore.collection('banners');
    for (var i = 1; i <= 3; i++) {
      batch.set(bannersRef.doc('banner_$i'), {
        'id': 'banner_$i',
        'image': 'banner_$i.png',
      });
    }

    final productsRef = _firestore.collection('products');
    final products = <Map<String, dynamic>>[
      {
        'id': 'jeans_1',
        'name': 'Quần Jeans nam ống suông WHY NOT',
        'price': 330650,
        'oldPrice': 550000,
        'image': 'product_jeans.png',
        'categoryId': 'men',
        'isFavorite': true,
        'soldText': 'Đã bán 1k+',
        'description':
            'Quần jean màu xanh denim, form suông hiện đại, cạp cao tôn dáng, chất liệu dày dặn với đường may nổi tinh tế.',
      },
      {
        'id': 'hoodie_1',
        'name': 'HeaSmile áo nỉ nam cổ tròn basic',
        'price': 217560,
        'oldPrice': 299000,
        'image': 'product_hoodie.png',
        'categoryId': 'men',
        'isFavorite': false,
        'soldText': 'Đã bán 600+',
        'description': 'Áo nỉ basic dễ phối, chất vải dày vừa, form trẻ trung.',
      },
      {
        'id': 'shirt_1',
        'name': 'Áo Thun - Classic Regular Tee',
        'price': 210375,
        'oldPrice': 260000,
        'image': 'product_shirt.png',
        'categoryId': 'women',
        'isFavorite': true,
        'soldText': 'Đã bán 800+',
        'description': 'Áo thun form regular, mặc thường ngày thoải mái.',
      },
      {
        'id': 'powerbank_1',
        'name': 'USAMS Power Bank Sạc nhanh PD 20W',
        'price': 295510,
        'oldPrice': 420000,
        'image': 'product_powerbank.png',
        'categoryId': 'home',
        'isFavorite': false,
        'soldText': 'Đã bán 300+',
        'description': 'Pin sạc dự phòng nhỏ gọn, hỗ trợ sạc nhanh PD 20W.',
      },
    ];

    for (final product in products) {
      batch.set(productsRef.doc(product['id'] as String), product);
    }

    final flashSaleRef = _firestore.collection('flashSale');
    final flashItems = <Map<String, dynamic>>[
      {'id': 'flash_1', 'image': 'flash_1.png'},
      {'id': 'flash_2', 'image': 'flash_2.png'},
      {'id': 'flash_3', 'image': 'flash_3.png'},
      {'id': 'flash_4', 'image': 'flash_4.png'},
      {'id': 'flash_5', 'image': 'flash_5.png'},
      {'id': 'flash_6', 'image': 'flash_6.png'},
    ];

    for (final item in flashItems) {
      batch.set(flashSaleRef.doc(item['id'] as String), item);
    }

    await batch.commit();
  }
}
