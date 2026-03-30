import 'package:cloud_firestore/cloud_firestore.dart';

class ShopCategory {
  ShopCategory({
    required this.id,
    required this.name,
    required this.image,
  });

  final String id;
  final String name;
  final String image;

  factory ShopCategory.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return ShopCategory(
      id: data['id'] as String? ?? doc.id,
      name: data['name'] as String? ?? '',
      image: data['image'] as String? ?? '',
    );
  }
}

class PromoBanner {
  PromoBanner({
    required this.id,
    required this.image,
  });

  final String id;
  final String image;

  factory PromoBanner.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return PromoBanner(
      id: data['id'] as String? ?? doc.id,
      image: data['image'] as String? ?? '',
    );
  }
}

class ShopProduct {
  ShopProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.oldPrice,
    required this.image,
    required this.categoryId,
    required this.description,
    required this.soldText,
  });

  final String id;
  final String name;
  final int price;
  final int oldPrice;
  final String image;
  final String categoryId;
  final String description;
  final String soldText;

  factory ShopProduct.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return ShopProduct(
      id: data['id'] as String? ?? doc.id,
      name: data['name'] as String? ?? '',
      price: (data['price'] as num?)?.toInt() ?? 0,
      oldPrice: (data['oldPrice'] as num?)?.toInt() ?? 0,
      image: data['image'] as String? ?? '',
      categoryId: data['categoryId'] as String? ?? '',
      description: data['description'] as String? ?? '',
      soldText: data['soldText'] as String? ?? '',
    );
  }

  Map<String, dynamic> toUserMap({int quantity = 1}) {
    return {
      'productId': id,
      'name': name,
      'price': price,
      'oldPrice': oldPrice,
      'image': image,
      'description': description,
      'soldText': soldText,
      'quantity': quantity,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class UserProductItem {
  UserProductItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    required this.oldPrice,
    required this.image,
    required this.description,
    required this.soldText,
    required this.quantity,
  });

  final String id;
  final String productId;
  final String name;
  final int price;
  final int oldPrice;
  final String image;
  final String description;
  final String soldText;
  final int quantity;

  factory UserProductItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return UserProductItem(
      id: doc.id,
      productId: data['productId'] as String? ?? doc.id,
      name: data['name'] as String? ?? '',
      price: (data['price'] as num?)?.toInt() ?? 0,
      oldPrice: (data['oldPrice'] as num?)?.toInt() ?? 0,
      image: data['image'] as String? ?? '',
      description: data['description'] as String? ?? '',
      soldText: data['soldText'] as String? ?? '',
      quantity: (data['quantity'] as num?)?.toInt() ?? 1,
    );
  }

  int get totalPrice => price * quantity;
}
