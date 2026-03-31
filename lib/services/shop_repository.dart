import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/shop_models.dart';

class ShopRepository {
  ShopRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<List<PromoBanner>> banners() {
    return _firestore
        .collection('banners')
        .orderBy('id')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(PromoBanner.fromDoc).toList());
  }

  Stream<List<ShopCategory>> categories() {
    return _firestore
        .collection('categories')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(ShopCategory.fromDoc).toList());
  }

  Stream<List<ShopProduct>> products() {
    return _firestore
        .collection('products')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(ShopProduct.fromDoc).toList());
  }

  Stream<List<PromoBanner>> flashSale() {
    return _firestore
        .collection('flashSale')
        .orderBy('id')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(PromoBanner.fromDoc).toList());
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

  Future<void> addToCart(String userId, ShopProduct product) async {
    final ref = _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(product.id);
    final snapshot = await ref.get();
    final quantity = ((snapshot.data()?['quantity'] as num?)?.toInt() ?? 0) + 1;
    await ref.set(product.toUserMap(quantity: quantity), SetOptions(merge: true));
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
        .doc(item.productId);
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
      },
      'quantity': quantity,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> checkout(
    String userId, {
    required List<UserProductItem> items,
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
      'address':
          '431/71/1a Hà Thanh Lộc, Phường Thạnh Lộc, Quận 12, TP.Hồ Chí Minh',
      'items': items
          .map((item) => {
                'productId': item.productId,
                'name': item.name,
                'image': item.image,
                'price': item.price,
                'quantity': item.quantity,
              })
          .toList(),
      'total': total,
      'paymentMethod': 'ShoppePay',
      'createdAt': FieldValue.serverTimestamp(),
    });

    for (final item in items) {
      final cartRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc(item.productId);
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

  Future<List<ShopOrder>> getOrders() async {
    final snapshot = await _firestore.collectionGroup('orders').get();
    return snapshot.docs.map(ShopOrder.fromDoc).toList();
  }

  Future<List<ShopBanner>> getBanners() async {
    final snapshot = await _firestore.collection('banners').get();
    return snapshot.docs.map(ShopBanner.fromDoc).toList();
  }

  Future<List<ShopFlashSale>> getFlashSales() async {
    final snapshot = await _firestore.collection('flashSale').get();
    return snapshot.docs.map(ShopFlashSale.fromDoc).toList();
  }

  Future<List<ShopUser>> getUsers() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs.map(ShopUser.fromDoc).toList();
  }

  Future<void> addProduct(ShopProduct product) async {
    await _firestore
        .collection('products')
        .doc(product.id)
        .set({
          'id': product.id,
          'name': product.name,
          'price': product.price,
          'oldPrice': product.oldPrice,
          'image': product.image,
          'categoryId': product.categoryId,
          'description': product.description,
          'soldText': product.soldText,
        });
  }

  Future<void> updateProduct(ShopProduct product) async {
    await _firestore
        .collection('products')
        .doc(product.id)
        .update({
          'name': product.name,
          'price': product.price,
          'oldPrice': product.oldPrice,
          'description': product.description,
        });
  }

  Future<void> deleteProduct(String productId) async {
    await _firestore.collection('products').doc(productId).delete();
  }

  Future<void> addCategory(ShopCategory category) async {
    await _firestore
        .collection('categories')
        .doc(category.id)
        .set({
          'id': category.id,
          'name': category.name,
          'image': category.image,
        });
  }

  Future<void> updateCategory(ShopCategory category) async {
    await _firestore
        .collection('categories')
        .doc(category.id)
        .update({'name': category.name});
  }

  Future<void> deleteCategory(String categoryId) async {
    await _firestore.collection('categories').doc(categoryId).delete();
  }

  Future<void> addBanner(ShopBanner banner) async {
    await _firestore
        .collection('banners')
        .doc(banner.id)
        .set(banner.toMap());
  }

  Future<void> updateBanner(ShopBanner banner) async {
    await _firestore
        .collection('banners')
        .doc(banner.id)
        .update(banner.toMap());
  }

  Future<void> deleteBanner(String bannerId) async {
    await _firestore.collection('banners').doc(bannerId).delete();
  }

  Future<void> addFlashSale(ShopFlashSale sale) async {
    await _firestore
        .collection('flashSale')
        .doc(sale.id)
        .set(sale.toMap());
  }

  Future<void> updateFlashSale(ShopFlashSale sale) async {
    await _firestore
        .collection('flashSale')
        .doc(sale.id)
        .update(sale.toMap());
  }

  Future<void> deleteFlashSale(String saleId) async {
    await _firestore.collection('flashSale').doc(saleId).delete();
  }

  Future<void> updateOrder(ShopOrder order) async {
    // Find and update the order in user subcollection
    final snapshot = await _firestore
        .collectionGroup('orders')
        .where('id', isEqualTo: order.id)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      await snapshot.docs.first.reference.update({'status': order.status});
    }
  }
}
