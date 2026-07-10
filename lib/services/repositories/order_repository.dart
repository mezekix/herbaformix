import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/order_model.dart';

/// `/users/{distributorId}/orders/{orderId}` — sipariş yönetimi.
class OrderRepository {
  OrderRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<OrderModel> ref(String userId) => _db
      .collection('users')
      .doc(userId)
      .collection('orders')
      .withConverter<OrderModel>(
        fromFirestore: (s, _) => OrderModel.fromMap(s.data()!, s.id),
        toFirestore: (m, _) => m.toMap(),
      );

  Stream<List<OrderModel>> getOrders(String userId, {String? customerId}) {
    Query<OrderModel> query = ref(userId);

    if (customerId != null && customerId.isNotEmpty) {
      query = query.where('customerId', isEqualTo: customerId);
    }

    return query
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  Future<DocumentReference<OrderModel>> addOrder(
    String userId,
    OrderModel order,
  ) =>
      ref(userId).add(order);

  Future<void> updateOrder(String userId, OrderModel order) async {
    await ref(userId).doc(order.id).update(order.toMap());
  }

  Future<void> deleteOrder(String userId, String orderId) async {
    await ref(userId).doc(orderId).delete();
  }
}
