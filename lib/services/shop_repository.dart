import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../models/shop_models.dart';

class ShopRepository {
  ShopRepository(this._firestore) : _storage = FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  Stream<List<PromoBanner>> banners() {
    return _firestore.collection('banners').snapshots().map((snapshot) {
      final banners = snapshot.docs.map(PromoBanner.fromDoc).where((banner) {
        final status = banner.status.trim().toLowerCase();
        return status.isEmpty || status == 'active';
      }).toList();

      banners.sort((a, b) {
        final aPos = int.tryParse(a.position);
        final bPos = int.tryParse(b.position);
        if (aPos != null && bPos != null) return aPos.compareTo(bPos);
        if (aPos != null) return -1;
        if (bPos != null) return 1;
        return a.id.compareTo(b.id);
      });
      return banners;
    });
  }

  Stream<List<ShopCategory>> categories() {
    return _firestore
        .collection('categories')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(ShopCategory.fromDoc).toList());
  }

  Stream<List<ShopProduct>> products() {
    late StreamController<List<ShopProduct>> controller;
    late StreamSubscription<QuerySnapshot<Map<String, dynamic>>> productsSub;
    late StreamSubscription<QuerySnapshot<Map<String, dynamic>>> flashSaleSub;
    var latestProducts = <ShopProduct>[];
    var latestSales = <ShopFlashSale>[];

    void emit() {
      if (controller.isClosed) return;
      controller.add(_applyFlashSalePricing(latestProducts, latestSales));
    }

    controller = StreamController<List<ShopProduct>>(
      onListen: () {
        productsSub = _firestore.collection('products').snapshots().listen((
          snapshot,
        ) {
          latestProducts = snapshot.docs.map(ShopProduct.fromDoc).toList();
          emit();
        }, onError: controller.addError);

        flashSaleSub = _firestore.collection('flashSale').snapshots().listen((
          snapshot,
        ) {
          latestSales = snapshot.docs.map(ShopFlashSale.fromDoc).toList();
          emit();
        }, onError: controller.addError);
      },
      onCancel: () async {
        await productsSub.cancel();
        await flashSaleSub.cancel();
      },
    );

    return controller.stream;
  }

  Stream<List<ShopFlashSale>> flashSale() {
    return _firestore
        .collection('flashSale')
        .orderBy('id')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(ShopFlashSale.fromDoc).toList());
  }

  Stream<List<ShopVoucher>> vouchers() {
    return _firestore
        .collection('vouchers')
        .orderBy('code')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(ShopVoucher.fromDoc).toList());
  }

  Future<void> ensureUserDocument(User user) async {
    final ref = _firestore.collection('users').doc(user.uid);
    await ref.set({
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<UserProductItem>> favorites(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(UserProductItem.fromDoc).toList());
  }

  Stream<List<UserProductItem>> cartItems(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(UserProductItem.fromDoc).toList());
  }

  Stream<List<ShopOrder>> orders(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(ShopOrder.fromDoc).toList());
  }

  Future<ShopOrder?> orderDetails(String userId, String orderId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('orders')
        .doc(orderId)
        .get();
    return doc.exists ? ShopOrder.fromDoc(doc) : null;
  }

  Future<void> toggleFavorite(String userId, ShopProduct product) async {
    final ref = _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(product.id);
    final snapshot = await ref.get();
    if (snapshot.exists) {
      await ref.delete();
      return;
    }
    await ref.set(product.toUserMap());
  }

  Future<void> addToCart(
    String userId,
    ShopProduct product, {
    String? selectedSize,
    String? selectedColor,
  }) async {
    final normalizedSize = (selectedSize ?? '').trim();
    final normalizedColor = (selectedColor ?? '').trim();
    final variantKey = _buildCartVariantKey(
      productId: product.id,
      selectedSize: normalizedSize,
      selectedColor: normalizedColor,
    );
    final ref = _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(variantKey);
    final snapshot = await ref.get();
    final quantity = ((snapshot.data()?['quantity'] as num?)?.toInt() ?? 0) + 1;
    await ref.set(
      product.toUserMap(
        quantity: quantity,
        selectedSize: normalizedSize,
        selectedColor: normalizedColor,
      ),
      SetOptions(merge: true),
    );
  }

  Future<void> updateCartQuantity(
    String userId,
    UserProductItem item,
    int quantity,
  ) async {
    final ref = _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(item.id);
    if (quantity <= 0) {
      await ref.delete();
      return;
    }
    await ref.set({
      ...{
        'productId': item.productId,
        'name': item.name,
        'price': item.price,
        'oldPrice': item.oldPrice,
        'image': item.image,
        'description': item.description,
        'soldText': item.soldText,
        'selectedSize': item.selectedSize,
        'selectedColor': item.selectedColor,
      },
      'quantity': quantity,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> checkout(
    String userId, {
    required List<UserProductItem> items,
    required String address,
    required String paymentMethod,
    int voucherDiscount = 0,
    String voucherSummary = '',
    int? finalTotal,
  }) async {
    if (items.isEmpty) return;
    final orderRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('orders')
        .doc();
    final batch = _firestore.batch();

    final total = items.fold<int>(
      0,
      (runningTotal, item) => runningTotal + item.totalPrice,
    );
    batch.set(orderRef, {
      'id': orderRef.id,
      'status': 'pending',
      'address': address,
      'items': items
          .map(
            (item) => {
              'productId': item.productId,
              'name': item.name,
              'image': item.image,
              'price': item.price,
              'quantity': item.quantity,
              'selectedSize': item.selectedSize,
              'selectedColor': item.selectedColor,
            },
          )
          .toList(),
      'total': total,
      'voucherDiscount': voucherDiscount,
      'finalTotal': finalTotal ?? (total - voucherDiscount).clamp(0, 1 << 31),
      'voucherSummary': voucherSummary,
      'paymentMethod': paymentMethod,
      'createdAt': FieldValue.serverTimestamp(),
    });

    for (final item in items) {
      final cartRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc(item.id);
      batch.delete(cartRef);
    }

    await batch.commit();
  }

  Future<bool> isAdmin(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data()?['role'] == 'admin' || false;
    } catch (_) {
      return false;
    }
  }

  // Admin CRUD methods
  Future<List<ShopProduct>> getProducts() async {
    final snapshot = await _firestore.collection('products').get();
    return snapshot.docs.map(ShopProduct.fromDoc).toList();
  }

  Future<List<ShopCategory>> getCategories() async {
    final snapshot = await _firestore.collection('categories').get();
    return snapshot.docs.map(ShopCategory.fromDoc).toList();
  }

  Future<List<ShopOrder>> getOrders({String? requesterUserId}) async {
    final List<ShopOrder> orders = [];

    Future<List<ShopOrder>> readByUsersScan() async {
      final usersSnapshot = await _firestore.collection('users').get();
      final List<ShopOrder> result = [];
      for (final userDoc in usersSnapshot.docs) {
        final orderSnapshot = await userDoc.reference
            .collection('orders')
            .get();
        for (final doc in orderSnapshot.docs) {
          result.add(ShopOrder.fromDoc(doc).copyWith(userId: userDoc.id));
        }
      }
      return result;
    }

    Future<List<ShopOrder>> readByCollectionGroup() async {
      final snapshot = await _firestore.collectionGroup('orders').get();
      return snapshot.docs.map((doc) {
        final userId = doc.reference.parent.parent?.id ?? '';
        return ShopOrder.fromDoc(doc).copyWith(userId: userId);
      }).toList();
    }

    Future<List<ShopOrder>> readOwnOrders(String userId) async {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('orders')
          .get();
      return snapshot.docs
          .map((doc) => ShopOrder.fromDoc(doc).copyWith(userId: userId))
          .toList();
    }

    try {
      orders.addAll(await readByUsersScan());
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
      try {
        orders.addAll(await readByCollectionGroup());
      } on FirebaseException catch (e2) {
        if (e2.code != 'permission-denied') rethrow;
        if (requesterUserId != null && requesterUserId.isNotEmpty) {
          orders.addAll(await readOwnOrders(requesterUserId));
        } else {
          rethrow;
        }
      }
    }

    orders.sort((a, b) {
      final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
      final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
      return bTime.compareTo(aTime);
    });
    return orders;
  }

  Future<List<ShopBanner>> getBanners() async {
    final snapshot = await _firestore.collection('banners').get();
    return snapshot.docs.map(ShopBanner.fromDoc).toList();
  }

  Future<List<ShopFlashSale>> getFlashSales() async {
    final snapshot = await _firestore.collection('flashSale').get();
    return snapshot.docs.map(ShopFlashSale.fromDoc).toList();
  }

  Future<List<ShopVoucher>> getVouchers() async {
    final snapshot = await _firestore.collection('vouchers').get();
    return snapshot.docs.map(ShopVoucher.fromDoc).toList();
  }

  Future<List<ShopUser>> getUsers() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs.map(ShopUser.fromDoc).toList();
  }

  Future<void> updateUserRole({
    required String userId,
    required String role,
  }) async {
    await _firestore.collection('users').doc(userId).set({
      'role': role,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> addProduct(ShopProduct product) async {
    await _firestore.collection('products').doc(product.id).set({
      'id': product.id,
      'name': product.name,
      'price': product.price,
      'oldPrice': product.oldPrice,
      'stock': product.stock,
      'image': product.image,
      'categoryId': product.categoryId,
      'description': product.description,
      'soldText': product.soldText,
      'sizeOptions': product.sizeOptions,
      'colorOptions': product.colorOptions,
    });
  }

  Future<void> updateProduct(ShopProduct product) async {
    await _firestore.collection('products').doc(product.id).update({
      'name': product.name,
      'price': product.price,
      'oldPrice': product.oldPrice,
      'stock': product.stock,
      'categoryId': product.categoryId,
      'image': product.image,
      'imageKey': product.imageKey,
      'soldText': product.soldText,
      'description': product.description,
      'sizeOptions': product.sizeOptions,
      'colorOptions': product.colorOptions,
    });
  }

  Future<void> deleteProduct(String productId) async {
    await _firestore.collection('products').doc(productId).delete();
  }

  Future<void> addCategory(ShopCategory category) async {
    await _firestore.collection('categories').doc(category.id).set({
      'id': category.id,
      'name': category.name,
      'image': category.image,
      'description': category.description,
    });
  }

  Future<void> updateCategory(ShopCategory category) async {
    await _firestore.collection('categories').doc(category.id).update({
      'name': category.name,
      'image': category.image,
      'description': category.description,
    });
  }

  Future<void> deleteCategory(String categoryId) async {
    await _firestore.collection('categories').doc(categoryId).delete();
  }

  Future<void> addBanner(ShopBanner banner) async {
    await _firestore.collection('banners').doc(banner.id).set(banner.toMap());
  }

  Future<void> updateBanner(ShopBanner banner) async {
    await _firestore
        .collection('banners')
        .doc(banner.id)
        .set(banner.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteBanner(String bannerId) async {
    await _firestore.collection('banners').doc(bannerId).delete();
  }

  Future<void> addFlashSale(ShopFlashSale sale) async {
    await _firestore.collection('flashSale').doc(sale.id).set(sale.toMap());
  }

  Future<void> updateFlashSale(ShopFlashSale sale) async {
    await _firestore.collection('flashSale').doc(sale.id).update(sale.toMap());
  }

  Future<void> deleteFlashSale(String saleId) async {
    await _firestore.collection('flashSale').doc(saleId).delete();
  }

  Future<void> addVoucher(ShopVoucher voucher) async {
    await _firestore
        .collection('vouchers')
        .doc(voucher.id)
        .set(voucher.toMap());
  }

  Future<void> updateVoucher(ShopVoucher voucher) async {
    await _firestore
        .collection('vouchers')
        .doc(voucher.id)
        .update(voucher.toMap());
  }

  Future<void> deleteVoucher(String voucherId) async {
    await _firestore.collection('vouchers').doc(voucherId).delete();
  }

  Future<void> updateOrder(ShopOrder order) async {
    if (order.userId.isNotEmpty) {
      final directRef = _firestore
          .collection('users')
          .doc(order.userId)
          .collection('orders')
          .doc(order.id);
      final directDoc = await directRef.get();
      if (directDoc.exists) {
        await directRef.update({'status': order.status});
        return;
      }
    }

    final usersSnapshot = await _firestore.collection('users').get();
    for (final userDoc in usersSnapshot.docs) {
      final ref = userDoc.reference.collection('orders').doc(order.id);
      final doc = await ref.get();
      if (doc.exists) {
        await ref.update({'status': order.status});
        break;
      }
    }
  }

  Future<void> completeOwnOrder({
    required String userId,
    required String orderId,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('orders')
        .doc(orderId)
        .update({
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  Stream<List<ShippingAddress>> shippingAddresses(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final addresses = snapshot.docs.map(ShippingAddress.fromDoc).toList();
          addresses.sort((a, b) {
            if (a.isDefault == b.isDefault) return 0;
            return a.isDefault ? -1 : 1;
          });
          return addresses;
        });
  }

  Future<ShippingAddress?> getDefaultShippingAddress(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .where('isDefault', isEqualTo: true)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return ShippingAddress.fromDoc(snapshot.docs.first);
    }
    final fallback = await _firestore
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .limit(1)
        .get();
    if (fallback.docs.isEmpty) return null;
    return ShippingAddress.fromDoc(fallback.docs.first);
  }

  Future<void> saveShippingAddress({
    required String userId,
    required ShippingAddress address,
  }) async {
    final col = _firestore
        .collection('users')
        .doc(userId)
        .collection('addresses');
    final isNew = address.id.trim().isEmpty;
    final docRef = isNew ? col.doc() : col.doc(address.id);

    final existing = await col.get();
    final hasAnyDefault = existing.docs.any(
      (doc) => (doc.data()['isDefault'] as bool?) ?? false,
    );
    final shouldDefault =
        address.isDefault || (existing.docs.isEmpty && isNew) || !hasAnyDefault;

    if (shouldDefault) {
      final batch = _firestore.batch();
      for (final doc in existing.docs) {
        batch.update(doc.reference, {'isDefault': false});
      }
      batch.set(docRef, {
        ...address.copyWith(id: docRef.id, isDefault: true).toMap(),
        'createdAt': isNew
            ? FieldValue.serverTimestamp()
            : FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await batch.commit();
      return;
    }

    await docRef.set({
      ...address.copyWith(id: docRef.id, isDefault: false).toMap(),
      'createdAt': isNew
          ? FieldValue.serverTimestamp()
          : FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setDefaultShippingAddress({
    required String userId,
    required String addressId,
  }) async {
    final col = _firestore
        .collection('users')
        .doc(userId)
        .collection('addresses');
    final snapshot = await col.get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      final isTarget = doc.id == addressId;
      batch.update(doc.reference, {
        'isDefault': isTarget,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<void> deleteShippingAddress({
    required String userId,
    required String addressId,
  }) async {
    final col = _firestore
        .collection('users')
        .doc(userId)
        .collection('addresses');
    final doc = await col.doc(addressId).get();
    final wasDefault = (doc.data()?['isDefault'] as bool?) ?? false;
    await col.doc(addressId).delete();

    if (!wasDefault) return;
    final remain = await col.limit(1).get();
    if (remain.docs.isNotEmpty) {
      await remain.docs.first.reference.update({
        'isDefault': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<String> uploadAdminImage({
    required Uint8List bytes,
    required String folder,
    required String fileName,
  }) async {
    final mime = _guessContentType(fileName);

    // No-billing fallback for local web/dev: store image directly in Firestore as data URI.
    if (kIsWeb && Uri.base.host.toLowerCase() == 'localhost') {
      return _toDataUri(bytes: bytes, mime: mime);
    }

    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final now = DateTime.now().millisecondsSinceEpoch;
    final path = 'admin-assets/$folder/${now}_$safeName';
    final ref = _storage.ref(path);
    final metadata = SettableMetadata(contentType: _guessContentType(safeName));
    try {
      await ref.putData(bytes, metadata);
      return ref.getDownloadURL();
    } catch (_) {
      // If Storage is unavailable (CORS / missing bucket / permission), fallback to data URI.
      return _toDataUri(bytes: bytes, mime: mime);
    }
  }

  String _guessContentType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  String _toDataUri({required Uint8List bytes, required String mime}) {
    // Firestore document limit is 1 MiB, keep a safe margin.
    if (bytes.lengthInBytes > 350 * 1024) {
      throw StateError(
        'Ảnh quá lớn cho chế độ không dùng Storage. Chọn ảnh nhỏ hơn 350KB.',
      );
    }
    return 'data:$mime;base64,${base64Encode(bytes)}';
  }

  List<ShopProduct> _applyFlashSalePricing(
    List<ShopProduct> products,
    List<ShopFlashSale> sales,
  ) {
    final now = DateTime.now();
    final discountByProductId = <String, int>{};

    for (final sale in sales) {
      if (!_isSaleActive(sale, now)) continue;
      final id = sale.productId.trim();
      if (id.isEmpty) continue;
      if (sale.discountPercent <= 0) continue;
      final current = discountByProductId[id] ?? 0;
      if (sale.discountPercent > current) {
        discountByProductId[id] = sale.discountPercent;
      }
    }

    return products.map((product) {
      final discount = discountByProductId[product.id];
      if (discount == null) return product;

      final basePrice = product.oldPrice > product.price
          ? product.oldPrice
          : product.price;
      final discounted = (basePrice * (100 - discount) / 100).round();
      final safePrice = discounted < 0 ? 0 : discounted;

      return product.copyWith(price: safePrice, oldPrice: basePrice);
    }).toList();
  }

  bool _isSaleActive(ShopFlashSale sale, DateTime now) {
    if (sale.status.trim().toLowerCase() != 'active') return false;
    final start = _parseSaleDateTime(sale.startTime);
    final end = _parseSaleDateTime(sale.endTime);
    if (start != null && now.isBefore(start)) return false;
    if (end != null && now.isAfter(end)) return false;
    return true;
  }

  DateTime? _parseSaleDateTime(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw.replaceFirst(' ', 'T'));
    if (parsed != null) return parsed;
    final pieces = raw.split(':');
    if (pieces.length == 2) {
      final hour = int.tryParse(pieces[0]);
      final minute = int.tryParse(pieces[1]);
      if (hour == null || minute == null) return null;
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, hour, minute);
    }
    return null;
  }

  String _buildCartVariantKey({
    required String productId,
    required String selectedSize,
    required String selectedColor,
  }) {
    final size = selectedSize.isEmpty ? 'nosize' : selectedSize;
    final color = selectedColor.isEmpty ? 'nocolor' : selectedColor;
    String sanitize(String value) {
      return value
          .toLowerCase()
          .replaceAll(RegExp(r'\s+'), '_')
          .replaceAll(RegExp(r'[^a-z0-9_-]'), '');
    }
    return '${sanitize(productId)}__${sanitize(size)}__${sanitize(color)}';
  }
}
