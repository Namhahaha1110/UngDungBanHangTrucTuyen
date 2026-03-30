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
}
