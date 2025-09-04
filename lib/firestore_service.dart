import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

// Payment method enum
enum PaymentMethod {
  cod, // Cash on Delivery
  card, // Credit/Debit Card
}

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Orders ---

  Future<void> placeOrder({
    required String userId,
    required Map<String, String> userDetails,
    required double total,
    required List<Map<String, dynamic>> items,
    required PaymentMethod paymentMethod,
  }) async {
    String customOrderId = '';
    bool idIsUnique = false;

    while (!idIsUnique) {
      customOrderId = _generateRandomOrderId();
      final doc = await _db.collection('orders').doc(customOrderId).get();
      if (!doc.exists) idIsUnique = true;
    }

    final orderData = {
      'userId': userId,
      'userDetails': userDetails,
      'total_usd': total,
      'items': items,
      'type': 'delivery',
      'status': 'Pending',
      'paymentMethod': paymentMethod.name,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    await _db.collection('orders').doc(customOrderId).set(orderData);
  }

  static String _generateRandomOrderId() {
    final random = Random();
    return (1000 + random.nextInt(9000)).toString(); // 4-digit
  }

  Stream<QuerySnapshot> getOrders() {
    return _db.collection('orders').snapshots();
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) {
    return _db.collection('orders').doc(orderId).update({'status': newStatus});
  }

  // --- Menu Items ---
  static Stream<QuerySnapshot> getMenuItems() {
    return FirebaseFirestore.instance
        .collection('menuItems')
        .snapshots();
  }

  Future<void> addMenuItem(Map<String, dynamic> itemData) {
    return _db.collection('menuItems').add(itemData);
  }

  Future<void> deleteMenuItem(String docId) {
    return _db.collection('menuItems').doc(docId).delete();
  }

  // --- Users ---
  Future<void> saveUser({
    required String uid,
    required String name,
    required String email,
    required String phone,
  }) {
    return _db.collection('users').doc(uid).set({
      'name': name,
      'email': email,
      'phone': phone,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // --- Dine-in Orders ---
  Stream<QuerySnapshot> getDineInOrders() {
    return _db.collection('dineInOrders').snapshots();
  }

  Future<void> addDineInOrder(Map<String, dynamic> orderData) {
    return _db.collection('dineInOrders').add(orderData);
  }
}
