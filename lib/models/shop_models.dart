import 'package:cloud_firestore/cloud_firestore.dart';

class ShopCategory {
  ShopCategory({
    required this.id,
    required this.name,
    required this.image,
    this.description = '',
  });

  final String id;
  final String name;
  final String image;
  final String description;

  factory ShopCategory.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return ShopCategory(
      id: data['id'] as String? ?? doc.id,
      name: data['name'] as String? ?? '',
      image: data['image'] as String? ?? '',
      description: data['description'] as String? ?? '',
    );
  }

  ShopCategory copyWith({
    String? id,
    String? name,
    String? image,
    String? description,
  }) => ShopCategory(
    id: id ?? this.id,
    name: name ?? this.name,
    image: image ?? this.image,
    description: description ?? this.description,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'image': image,
    'description': description,
  };
}

class PromoBanner {
  PromoBanner({required this.id, required this.image});

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
    required this.stock,
    required this.image,
    required this.categoryId,
    required this.description,
    required this.soldText,
    this.imageKey = 'default.jpg',
  });

  final String id;
  final String name;
  final int price;
  final int oldPrice;
  final int stock;
  final String image;
  final String categoryId;
  final String description;
  final String soldText;
  final String imageKey;

  factory ShopProduct.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final soldText = data['soldText'] as String? ?? '';
    final stockValue = (data['stock'] as num?)?.toInt();
    return ShopProduct(
      id: data['id'] as String? ?? doc.id,
      name: data['name'] as String? ?? '',
      price: (data['price'] as num?)?.toInt() ?? 0,
      oldPrice: (data['oldPrice'] as num?)?.toInt() ?? 0,
      stock: stockValue ?? (soldText.toLowerCase().contains('hết') ? 0 : 999),
      image: data['image'] as String? ?? '',
      categoryId: data['categoryId'] as String? ?? '',
      description: data['description'] as String? ?? '',
      soldText: soldText,
      imageKey: data['imageKey'] as String? ?? 'default.jpg',
    );
  }

  ShopProduct copyWith({
    String? id,
    String? name,
    int? price,
    int? oldPrice,
    int? stock,
    String? image,
    String? categoryId,
    String? description,
    String? soldText,
    String? imageKey,
  }) => ShopProduct(
    id: id ?? this.id,
    name: name ?? this.name,
    price: price ?? this.price,
    oldPrice: oldPrice ?? this.oldPrice,
    stock: stock ?? this.stock,
    image: image ?? this.image,
    categoryId: categoryId ?? this.categoryId,
    description: description ?? this.description,
    soldText: soldText ?? this.soldText,
    imageKey: imageKey ?? this.imageKey,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'price': price,
    'oldPrice': oldPrice,
    'stock': stock,
    'image': image,
    'categoryId': categoryId,
    'description': description,
    'soldText': soldText,
    'imageKey': imageKey,
  };

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

class ShopOrder {
  ShopOrder({
    required this.id,
    required this.status,
    required this.items,
    required this.total,
    required this.address,
    required this.paymentMethod,
    required this.createdAt,
    this.userId = '',
  });

  final String id;
  final String status;
  final List<OrderItem> items;
  final int total;
  final String address;
  final String paymentMethod;
  final DateTime? createdAt;
  final String userId;

  int get totalAmount => total;

  factory ShopOrder.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final itemsData = (data['items'] as List<dynamic>?) ?? [];
    return ShopOrder(
      id: data['id'] as String? ?? doc.id,
      status: data['status'] as String? ?? 'pending',
      items: itemsData
          .map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      total: (data['total'] as num?)?.toInt() ?? 0,
      address: data['address'] as String? ?? '',
      paymentMethod: data['paymentMethod'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      userId: data['userId'] as String? ?? '',
    );
  }

  ShopOrder copyWith({
    String? id,
    String? status,
    List<OrderItem>? items,
    int? total,
    String? address,
    String? paymentMethod,
    DateTime? createdAt,
    String? userId,
  }) => ShopOrder(
    id: id ?? this.id,
    status: status ?? this.status,
    items: items ?? this.items,
    total: total ?? this.total,
    address: address ?? this.address,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    createdAt: createdAt ?? this.createdAt,
    userId: userId ?? this.userId,
  );

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Đang xử lý';
      case 'paid':
        return 'Đã thanh toán';
      case 'review':
        return 'Đang rà soát';
      case 'completed':
        return 'Hoàn thành';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'shipping':
        return 'Đang giao';
      case 'delivered':
        return 'Đã giao';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }
}

class OrderItem {
  OrderItem({
    required this.productId,
    required this.name,
    required this.image,
    required this.price,
    required this.quantity,
  });

  final String productId;
  final String name;
  final String image;
  final int price;
  final int quantity;

  factory OrderItem.fromMap(Map<String, dynamic> data) {
    return OrderItem(
      productId: data['productId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      image: data['image'] as String? ?? '',
      price: (data['price'] as num?)?.toInt() ?? 0,
      quantity: (data['quantity'] as num?)?.toInt() ?? 1,
    );
  }

  int get totalPrice => price * quantity;
}

// Admin models
class ShopBanner {
  ShopBanner({
    required this.id,
    required this.imageKey,
    required this.position,
    required this.status,
    this.link = '',
    this.notes = '',
  });

  final String id;
  final String imageKey;
  final String position;
  final String status; // 'active' | 'draft'
  final String link;
  final String notes;

  factory ShopBanner.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return ShopBanner(
      id: data['id'] as String? ?? doc.id,
      imageKey: data['imageKey'] as String? ?? '',
      position: data['position'] as String? ?? '',
      status: data['status'] as String? ?? 'draft',
      link: data['link'] as String? ?? '',
      notes: data['notes'] as String? ?? '',
    );
  }

  ShopBanner copyWith({
    String? id,
    String? imageKey,
    String? position,
    String? status,
    String? link,
    String? notes,
  }) => ShopBanner(
    id: id ?? this.id,
    imageKey: imageKey ?? this.imageKey,
    position: position ?? this.position,
    status: status ?? this.status,
    link: link ?? this.link,
    notes: notes ?? this.notes,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'imageKey': imageKey,
    'position': position,
    'status': status,
    'link': link,
    'notes': notes,
  };
}

class ShopFlashSale {
  ShopFlashSale({
    required this.id,
    required this.productId,
    required this.discountPercent,
    required this.startTime,
    required this.endTime,
    this.status = 'active',
  });

  final String id;
  final String productId;
  final int discountPercent;
  final String startTime; // e.g. "09:00" or "2024-01-15 09:00"
  final String endTime; // e.g. "18:00" or "2024-01-15 18:00"
  final String status; // 'active' | 'inactive'

  factory ShopFlashSale.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return ShopFlashSale(
      id: data['id'] as String? ?? doc.id,
      productId: data['productId'] as String? ?? '',
      discountPercent: (data['discountPercent'] as num?)?.toInt() ?? 0,
      startTime: data['startTime'] as String? ?? '',
      endTime: data['endTime'] as String? ?? '',
      status: data['status'] as String? ?? 'active',
    );
  }

  ShopFlashSale copyWith({
    String? id,
    String? productId,
    int? discountPercent,
    String? startTime,
    String? endTime,
    String? status,
  }) => ShopFlashSale(
    id: id ?? this.id,
    productId: productId ?? this.productId,
    discountPercent: discountPercent ?? this.discountPercent,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    status: status ?? this.status,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'productId': productId,
    'discountPercent': discountPercent,
    'startTime': startTime,
    'endTime': endTime,
    'status': status,
  };
}

class ShopUser {
  ShopUser({
    required this.id,
    required this.email,
    this.name,
    this.phone,
    this.role = 'user',
    this.favorites,
    this.cart,
    this.ordersCount,
  });

  final String id;
  final String email;
  final String? name;
  final String? phone;
  final String role;
  final List<String>? favorites;
  final List<String>? cart;
  final int? ordersCount;

  String get uid => id;
  String get displayName => name ?? email;
  int get favoriteCount => favorites?.length ?? 0;
  int get cartCount => cart?.length ?? 0;
  int get orderCount => ordersCount ?? 0;

  factory ShopUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return ShopUser(
      id: doc.id,
      email: data['email'] as String? ?? '',
      name: data['displayName'] as String?,
      phone: data['phone'] as String?,
      role: data['role'] as String? ?? 'user',
      favorites: List<String>.from(data['favorites'] as List? ?? []),
      cart: List<String>.from(data['cart'] as List? ?? []),
      ordersCount: (data['ordersCount'] as num?)?.toInt(),
    );
  }
}

class ShippingAddress {
  ShippingAddress({
    required this.id,
    required this.recipientName,
    required this.phone,
    required this.addressLine,
    this.isDefault = false,
  });

  final String id;
  final String recipientName;
  final String phone;
  final String addressLine;
  final bool isDefault;

  factory ShippingAddress.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return ShippingAddress(
      id: doc.id,
      recipientName: data['recipientName'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      addressLine: data['addressLine'] as String? ?? '',
      isDefault: data['isDefault'] as bool? ?? false,
    );
  }

  ShippingAddress copyWith({
    String? id,
    String? recipientName,
    String? phone,
    String? addressLine,
    bool? isDefault,
  }) => ShippingAddress(
    id: id ?? this.id,
    recipientName: recipientName ?? this.recipientName,
    phone: phone ?? this.phone,
    addressLine: addressLine ?? this.addressLine,
    isDefault: isDefault ?? this.isDefault,
  );

  Map<String, dynamic> toMap() => {
    'recipientName': recipientName,
    'phone': phone,
    'addressLine': addressLine,
    'isDefault': isDefault,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
